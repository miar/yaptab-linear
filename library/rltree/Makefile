#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
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
MPI_CC=mpicc
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
#

OBJS=yaprl.o range_list.o
SOBJS=yap_rl.so

#in some systems we just create a single object, in others we need to
# create a libray
all: $(SOBJS)

range_list.o: $(srcdir)/range_list.c $(srcdir)/range_list.h
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/range_list.c -o range_list.o

yaprl.o: $(srcdir)/yap_rl.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/yap_rl.c -o yaprl.o

%.so: %.o
	gcc -shared -export-dynamic -o $@ $<

yap_rl.so: $(OBJS)
	gcc -shared -export-dynamic  -o yap_rl.so $(OBJS)

install: all
	@if test "$(SOBJS)" = "no"; then echo ""; else $(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR); fi

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK

no:
	@echo "YAP RL module not compiled."

