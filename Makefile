# This makefile was written based on the 
# https://github.com/NestorDP/ARM-EK-TM4C123GLX_examples


TOOLCHAIN 		= arm-none-eabi-
CC        		= $(TOOLCHAIN)gcc
CXX       		= $(TOOLCHAIN)g++
AS        		= $(TOOLCHAIN)as
LD        		= $(TOOLCHAIN)ld
OBJCOPY   		= $(TOOLCHAIN)objcopy
AR        		= $(TOOLCHAIN)ar
LM4FLASH_TOOL 	= ./tools/lm4flash

# GCC flags
#--------------------
CPUFLAG  = -mthumb -mcpu=cortex-m4
WFLAG    = -Wall 
WFLAG   +=-Wextra

CFLAGS   = $(CPUFLAG) 
CFLAGS  += $(WFLAG) 
CFLAGS  += -std=c99 
CFLAGS  += -ffunction-sections 
CFLAGS  += -fdata-sections 
CFLAGS  += -DPART_TM4C123GH6PM

DEB_FLAG = -g -DDEBUG

# Directories variables 
#---------------------
PORT_TARGET 	= GCC/ARM_CM4F/
OBJ_DIR     	= obj/
SRC_DIR     	= src/
TIVAWARE_DIR	= tivaware/


# Object files
#---------------------

SRC_SOURCES         = $(shell ls $(SRC_DIR)*.c)
SRC_OBJS            = $(patsubst $(SRC_DIR)%,$(OBJ_DIR)%,$(SRC_SOURCES:.c=.o))

OBJS  += $(DRIVERS_OBJS)
OBJS  += $(SRC_OBJS)

# Get the location of libgcc.a, libc.a and libm.a from the GCC front-end.
#---------------------
LIBGCC := ${shell ${CC} ${CFLAGS} -print-libgcc-file-name}
LIBC   := ${shell ${CC} ${CFLAGS} -print-file-name=libc.a}
LIBM   := ${shell ${CC} ${CFLAGS} -print-file-name=libm.a}

# Include paths to be passed to $(CC) where necessary
#---------------------
INC_DIR       			= include/
INC_TIVAWARE  			= $(TIVAWARE_DIR)
INC_FLAGS     			= -I $(SRC_DIR) -I $(INC_DIR) -I $(INC_TIVAWARE)

# Dependency on HW specific settings
#---------------------
DEP_BSP          = $(INC_DIR)drivers/bsp.h

# Definition of the linker script and final targets
#---------------------
LINKER_SCRIPT = $(addprefix , tm4c123gh6pm.lds)
ELF_IMAGE     = image.elf
TARGET_IMAGE  = image.bin

# Make rules:
#---------------------
print-%  : ; @echo $* = $($*)

all : $(TARGET_IMAGE)

rebuild : clean all

$(TARGET_IMAGE) : $(OBJ_DIR) $(ELF_IMAGE)
	$(OBJCOPY) -O binary $(word 2,$^) $@

$(OBJ_DIR) :
	mkdir -p $@

# Linker
$(ELF_IMAGE) : $(OBJS) $(LINKER_SCRIPT)
	$(LD) -L $(OBJ_DIR) -L $(TIVAWARE_DIR)driverlib/gcc -T $(LINKER_SCRIPT) $(OBJS) -o $@ -ldriver '$(LIBGCC)' '$(LIBC)' '$(LIBM)'

debug : _debug_flags all

debug_rebuild : _debug_flags rebuild

_debug_flags :
	$(eval CFLAGS += $(DEB_FLAG))


# Drivers
$(OBJ_DIR)%.o : $(DRIVERS_DIR)%.c
	$(CC) -c $(CFLAGS) $(INC_FLAGS) $< -o $@

# Main Code
$(OBJ_DIR)%.o : $(SRC_DIR)%.c $(DEP_SETTINGS)
	$(CC) -c $(CFLAGS) $(INC_FLAGS) $< -o $@

# Cleanup directives:
#---------------------
clean_obj :
	$(RM) -r $(OBJ_DIR)

clean_intermediate : clean_obj
	$(RM) *.elf
	$(RM) *.img
	
clean : clean_intermediate
	$(RM) *.

burn :
	$(LM4FLASH_TOOL) $(TARGET_IMAGE)

# Short help instructions:
#---------------------
help :
	@echo
	@echo Valid targets:
	@echo - all: builds missing dependencies and creates the target image \'$(TARGET_IMAGE)\'.
	@echo - rebuild: rebuilds all dependencies and creates the target image \'$(TARGET_IMAGE)\'.
	@echo - debug: same as \'all\', also includes debugging symbols to \'$(ELF_IMAGE)\'.
	@echo - debug_rebuild: same as \'rebuild\', also includes debugging symbols to \'$(ELF_IMAGE)\'.
	@echo - clean_obj: deletes all object files, only keeps \'$(ELF_IMAGE)\' and \'$(TARGET_IMAGE)\'.
	@echo - clean_intermediate: deletes all intermediate binaries, only keeps the target image \'$(TARGET_IMAGE)\'.
	@echo - clean: deletes all intermediate binaries, incl. the target image \'$(TARGET_IMAGE)\'.
	@echo - help: displays these help instructions.
	@echo


.PHONY :  all rebuild clean clean_intermediate clean_obj debug debug_rebuild _debug_flags help
