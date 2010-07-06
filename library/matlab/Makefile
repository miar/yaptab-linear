#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
prefix = /home/miguel/Desktop/git/mainline/build
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
abs_top_builddir = /home/miguel/Desktop/git/mainline
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
srcdir=.
SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
#4.1VPATH=.:./OPTYap
CWD=$(PWD)
#

OBJS=matlab.o
SOBJS=matlab.so

#in some systems we just create a single object, in others we need to
# create a libray

all: $(SOBJS) 

matlab.o: $(srcdir)/matlab.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/matlab.c -o matlab.o

%.so: %.o
	gcc -shared -export-dynamic -o $@ $<

matlab.so: matlab.o
	gcc -shared -export-dynamic -o matlab.so matlab.o

install: all
	$(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK

