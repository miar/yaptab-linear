# -*-Makefile-*- for Yap/library/mpi
#


##
## Directories
##

#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
prefix = /home/miguel/Desktop/yap-ns/arch
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
abs_top_builddir = /home/miguel/Desktop/yap-ns/arch
#
# where the binary should be
#
BINDIR = $(EROOTDIR)/bin
#
# where YAP should look for binary libraries
#
LIBDIR=${exec_prefix}/lib
YAPLIBDIR=${exec_prefix}/lib/Yap
#
# where YAP should look for architecture-independent Prolog libraries
#
SHAREDIR=$(ROOTDIR)/share
#
# where the includes should be stored
#
INCLUDEDIR=$(ROOTDIR)/include/Yap
#
# where to store info files
#
INFODIR=$(SHAREDIR)/info


##
## Tools
##

CC=gcc
CPP=gcc -E
DEFS=-DHAVE_CONFIG_H
CPPFLAGS=  -I../.. -I$(srcdir)/../../H
CFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall -Wstrict-prototypes -Wmissing-prototypes $(DEFS) $(CPPFLAGS)
LIBS=-lreadline -lncurses -ltermcap -lstdc++ -lm  -ldl -lnsl
LDFLAGS=-rdynamic 
LN_S=ln -s
M4=m4
GCC=yes
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_INFO=/usr/sbin/install-info
INSTALL_PROGRAM=${INSTALL}
M4GENHDRS=$(srcdir)/m4/gcc_genhdrs.m4
M4GENABSMI=$(srcdir)/gen_gcc.m4
INDENT=:
SHELL=/bin/sh
RANLIB=ranlib
AR=ar
srcdir=../../../library/mpi
SHLIB_SUFFIX=.so
SHLIB_INTERFACE=@SHLIB_INTERFACE@
RM=rm -f


##
## Files
##

C_SOURCES = $(srcdir)/mpi.c $(srcdir)/mpe.c

#PL_SOURCES = 

HEADERS = 

LIB_OBJECTS = mpi.o mpe.o

RUBBISH = $(OBJECTS)

DISTFILES = $(SRCS) Makefile


##
## Rules
##

all: YapMPI.a
	@echo All done.

YapMPI.a: $(LIB_OBJECTS)
	$(RM) YapMPI.a
	$(AR) rc YapMPI.a $(LIB_OBJECTS)
	$(RANLIB) YapMPI.a


mpi.o: $(srcdir)/mpi.c
	$(CC) -c $(CFLAGS) $(srcdir)/mpi.c -o $@

mpe.o: $(srcdir)/mpe.c
	$(CC) -c $(CFLAGS) $(srcdir)/mpe.c -o $@

depend: $(HEADERS) $(C_SOURCES) 
	-@if test "$(GCC)" = yes; then\
	  $(CC) -MM $(CFLAGS) -I$(srcdir)/include $(C_SOURCES) > .depend;\
	else\
          makedepend -f - -- $(CFLAGS) -I$(srcdir)/include -- $(C_SOURCES) |\
          sed 's|.*/\([^:]*\):|\1:|' > .depend ;\
	fi

clean:
	$(RM) $(RUBBISH)

dist:
	tar cf aa.tar $DISTFILES
	$(COMPRESS) aa.tar


# DO NOT DELETE THIS LINE -- make depend depends on it.

include .depend
