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
srcdir=../../../library/regex
SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
#4.1VPATH=../../../library/regex:../../../library/regex/OPTYap
CWD=$(PWD)
#

OBJS=regexp.o # regcomp.o regexec.o regerror.o regfree.o
SOBJS=regexp.so  # regcomp.so regexec.so regerror.so regfree.so 

#in some systems we just create a single object, in others we need to
# create a libray

all: $(SOBJS)

regexp.o: $(srcdir)/regexp.c  # $(srcdir)/regex2.h  $(srcdir)/engine.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/regexp.c -o regexp.o

regcomp.o: $(srcdir)/regcomp.c $(srcdir)/regex2.h
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/regcomp.c -o regcomp.o

regerror.o: $(srcdir)/regerror.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/regerror.c -o regerror.o

regfree.o: $(srcdir)/regfree.c $(srcdir)/regex2.h
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/regfree.c -o regfree.o

regexec.o: $(srcdir)/regexec.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/regexec.c -o regexec.o

%.so: %.o
	gcc -shared -export-dynamic -o $@ $<

regexp.so: regexp.o # regcomp.o regerror.o regfree.o regexec.o
	gcc -shared -export-dynamic -o regexp.so regexp.o # regcomp.o regerror.o regfree.o regexec.o

regcomp.so: regcomp.o # regfree.o
	gcc -shared -export-dynamic -o regcomp.so regcomp.o # regfree.o

regerror.so: regerror.o
	gcc -shared -export-dynamic -o regerror.so regerror.o

regfree.so: regfree.o
	gcc -shared -export-dynamic -o regfree.so regfree.o

regexec.so: regexec.o
	gcc -shared -export-dynamic -o regexec.so regexec.o

install: all
	$(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK

