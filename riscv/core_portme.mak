OUTFLAG  = -o
CC       = riscv64-unknown-elf-gcc
LD       = riscv64-unknown-elf-gcc
AS       = riscv64-unknown-elf-as

MARCH    = rv32imac_zicsr
MABI     = ilp32

PORT_CFLAGS = -O2 -march=$(MARCH) -mabi=$(MABI) -nostdlib -nostartfiles
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS) $(LFLAGS_END)"
CFLAGS = $(PORT_CFLAGS) -I$(PORT_DIR) -I. -DFLAGS_STR=\"$(FLAGS_STR)\" \
         -DPERFORMANCE_RUN=1 -DITERATIONS=100

SEPARATE_COMPILE = 1
OBJOUT  = -o
OFLAG   = -o
COUT    = -c
LFLAGS  = -march=$(MARCH) -mabi=$(MABI) -nostdlib -nostartfiles
LFLAGS_END =

OEXT = .o
EXE  = .elf

PORT_SRCS = $(PORT_DIR)/core_portme.c
vpath %.c $(PORT_DIR)

LOAD = echo "Load not needed for size analysis"
RUN  = echo "Run not needed for size analysis"

$(OPATH)$(PORT_DIR)/%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

$(OPATH)%$(OEXT) : %.c
	$(CC) $(CFLAGS) $(XCFLAGS) $(COUT) $< $(OBJOUT) $@

.PHONY: port_prebuild port_postbuild port_prerun port_postrun port_preload port_postload
port_pre% port_post% :

OPATH = ./
MKDIR = mkdir -p
