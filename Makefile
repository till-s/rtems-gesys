#
#  $Id$
#
#

# On a PC console (i.e. VGA, not a serial terminal console)
# tecla should _not_ be used because the RTEMS VGA console
# driver is AFAIK non-ANSI and too dumb to be used by tecla.
# Don't forget to configure Cexp with --disable-tecla in this
# case...
# On a PC, you may have to use a different network driver
# also; YMMV. The value must be 'YES' or 'NO' (no quotes) 
USE_TECLA = YES


# C source names, if any, go here -- minus the .c
# make a system for storing in flash. The compressed binary
# can be generated with the tools and code from 'netboot'.
# Note that this is currently limited to compressed images < 512k
#
#C_PIECES=flashInit rtems_netconfig config flash
#

# Normal (i.e. non-flash) system which can be net-booted
USE_TECLA_YES_C_PIECES = term
C_PIECES=init rtems_netconfig config $(USE_TECLA_$(USE_TECLA)_C_PIECES)
C_FILES=$(C_PIECES:%=%.c)
C_O_FILES=$(C_PIECES:%=${ARCH}/%.o)

# C++ source names, if any, go here -- minus the .cc
CC_PIECES=
CC_FILES=$(CC_PIECES:%=%.cc)
CC_O_FILES=$(CC_PIECES:%=${ARCH}/%.o)

H_FILES=

# Assembly source names, if any, go here -- minus the .S
S_PIECES=
S_FILES=$(S_PIECES:%=%.S)
S_O_FILES=$(S_FILES:%.S=${ARCH}/%.o)

SRCS=$(C_FILES) $(CC_FILES) $(H_FILES) $(S_FILES)
OBJS=$(C_O_FILES) $(CC_O_FILES) $(S_O_FILES)

PGMS=${ARCH}/rtems.exe st.sys

# List of RTEMS managers to be included in the application goes here.
# Use:
#     MANAGERS=all
# to include all RTEMS managers in the application.
MANAGERS=all


include $(RTEMS_MAKEFILE_PATH)/Makefile.inc
include $(RTEMS_CUSTOM)
include $(RTEMS_ROOT)/make/leaf.cfg

ifndef XSYMS
XSYMS = xsyms
endif


#
# (OPTIONAL) Add local stuff here using +=
#
LINK.c = $(LINK.cc)


DEFINES  += -DUSE_POSIX

ifeq  "$(RTEMS_BSP_FAMILY)" "svgm" 
DEFINES  += -DHAVE_BSP_EXCEPTION_EXTENSION
LIBBSPEXT = -lbspExt
ifndef ELFEXT
ELFEXT    = exe
endif
endif

ifeq "$(RTEMS_BSP_FAMILY)" "motorola_powerpc"
DEFINES  += -DRTEMS_BSP_NETWORK_DRIVER_NAME=\"dc1\"
DEFINES  += -DRTEMS_BSP_NETWORK_DRIVER_ATTACH=rtems_dec21140_driver_attach
LIBBSPEXT = -lbspExt
ifndef ELFEXT
ELFEXT    = nxe
endif
endif

ifeq  "$(RTEMS_BSP_FAMILY)" "pc386"
DEFINES  += -DRTEMS_BSP_NETWORK_DRIVER_NAME=\"fxp1\"
DEFINES  += -DRTEMS_BSP_NETWORK_DRIVER_ATTACH=rtems_fxp_attach
ifndef ELFEXT
ELFEXT    = obj
endif
endif



CPPFLAGS += -I.
CFLAGS   += -O2

USE_TECLA_YES_DEFINES = -DWINS_LINE_DISC -DUSE_TECLA

DEFINES+=$(USE_TECLA_$(USE_TECLA)_DEFINES)

#
# CFLAGS_DEBUG_V are used when the `make debug' target is built.
# To link your application with the non-optimized RTEMS routines,
# uncomment the following line:
# CFLAGS_DEBUG_V += -qrtems_debug
#

USE_TECLA_YES_LIB = -ltecla_r

LD_LIBS   += -lcexp -lbfd -lspencer_regexp -lopcodes -liberty $(USE_TECLA_$(USE_TECLA)_LIB) -lm -lrtems++ $(LIBBSPEXT)
# Produce a linker map to help finding 'undefined symbol' references (README.config)
LDFLAGS   += -Wl,-Map,map

OBJS      += ${ARCH}/allsyms.o

#
# Add your list of files to delete here.  The config files
#  already know how to delete some stuff, so you may want
#  to just run 'make clean' first to see what gets missed.
#  'make clobber' already includes 'make clean'
#

CLEAN_ADDITIONS   += map builddate.c
CLOBBER_ADDITIONS +=

all: versioncheck ${ARCH} $(SRCS) $(PGMS)

# Produce an object with undefined references. These are
# all generated by the linker scripts included from 'symlist.lds'.
# We just need an empty object to keep the linker happy

$(ARCH)/allsyms.o:	symlist.lds $(ARCH)/empty.o config/*
	$(LD) -T$< -r -o $@ $(ARCH)/empty.o

# dummy up an empty object file
$(ARCH)/empty.o:
	touch $(@:%.o=%.c)
	$(CC) -c -O -o $@ $(@:%.o=%.c)

$(ARCH)/init.o: builddate.c

builddate.c: $(filter-out $(ARCH)/init.o,$(OBJS))
	echo 'static char *system_build_date="'`date +%Y%m%d%Z%T`'";' > $@

$(filter %.exe,$(PGMS)): ${LINK_FILES}
	$(make-exe)
ifdef ELFEXT
ifdef XSYMS
	$(XSYMS) $(@:%.exe=%.$(ELFEXT)) $(@:%.exe=%.sym)
endif
endif

ifndef RTEMS_SITE_INSTALLDIR
RTEMS_SITE_INSTALLDIR = $(PROJECT_RELEASE)
endif

$(RTEMS_SITE_INSTALLDIR)/$(RTEMS_BSP)/bin:
	test -d $@ || mkdir -p $@

INSTFILES = ${PGMS} ${PGMS:%.exe=%.bin} ${PGMS:%.exe=%.sym}

CONFVERSION = $(shell grep '^gcc-' symlist.lds)
GCCVERSION  = gcc-$(shell $(CC) -dumpversion)

versioncheck:
	@if [ "gcc-`$(CC) -dumpversion`" != $(CONFVERSION)] ; then \
       echo 'WARNING: THIS SYSTEM CONFIGURATION WAS GENERATED FOR'; \
       echo '            $(CONFVERSION)'; \
       echo '         YOU MAY HAVE TO GENERATE A NEW CONFIGURATION (linker errors?) FOR'; \
       echo '            $(GCCVERSION)'; \
       echo '         (at least for libgcc.a, libstdc++, libsupc++; see README.config)'; \
       exit 1; \
    fi

REVISION=$(filter-out $$%,$$Name$$)
tar:
	@$(make-tar)

# Install the program(s), appending _g or _p as appropriate.
# for include files, just use $(INSTALL_CHANGE)
install: all $(RTEMS_SITE_INSTALLDIR)/$(RTEMS_BSP)/bin
	for feil in $(INSTFILES); do if [ -r $$feil ] ; then  \
		$(INSTALL_VARIANT) -m 555 $$feil ${RTEMS_SITE_INSTALLDIR}/$(RTEMS_BSP)/bin ; fi ; done
