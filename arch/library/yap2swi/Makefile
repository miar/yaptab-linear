#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
prefix = /home/miguel/Desktop/yap-ns/arch
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
abs_top_builddir = /home/miguel/Desktop/yap-ns/arch
#
# where the binary should be
#
BINDIR = $(EROOTDIR)/bin
#
# where YAP should look for libraries
#
LIBDIR=${exec_prefix}/lib/Yap
#
#
CC=gcc
CFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall -Wstrict-prototypes -Wmissing-prototypes $(YAP_EXTRAS) $(DEFS) -I$(srcdir) -I../.. -I$(srcdir)/../../include
#
#
# You shouldn't need to change what follows.
#
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_PROGRAM=${INSTALL}
SHELL=/bin/sh
RANLIB=ranlib
srcdir=../../../library/yap2swi
SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
#4.1VPATH=../../../library/yap2swi:../../../library/yap2swi/OPTYap
CWD=$(PWD)
#

OBJS=yap2swi.o
SOBJS=yap2swi.so

#in some systems we just create a single object, in others we need to
# create a libray

# compile yap2swi as part of the main YAP

all:

yap2swi.o: $(srcdir)/yap2swi.c $(srcdir)/yap2swi.h
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/yap2swi.c -o yap2swi.o

%.so: %.o
	gcc -shared -export-dynamic -o $@ $<

yap2swi.so: yap2swi.o
	gcc -shared -export-dynamic -o yap2swi.so yap2swi.o @

install: 
	$(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK

