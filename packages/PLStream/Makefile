#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
GCC=yes
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
CFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall -Wstrict-prototypes -Wmissing-prototypes $(YAP_EXTRAS) $(DEFS)  -D_YAP_NOT_INSTALLED_=1 -I$(srcdir) -I../.. -I$(srcdir)/../../include -I$(srcdir)/uxnt
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

HEADERS=$(srcdir)/atoms.h $(srcdir)/pl-buffer.h $(srcdir)/pl-ctype.h  \
	$(srcdir)/pl-incl.h \
	$(srcdir)/pl-mswchar.h \
	$(srcdir)/pl-opts.h  \
	$(srcdir)/pl-os.h \
	$(srcdir)/pl-privitf.h \
	$(srcdir)/pl-stream.h \
	$(srcdir)/pl-table.h \
	$(srcdir)/pl-text.h $(srcdir)/pl-utf8.h \
	$(srcdir)/pl-yap.h # $(srcdir)/uxnt/dirent.h $(srcdir)/uxnt/utf8.h $(srcdir)/pl-utf8.c $(srcdir)/uxnt/uxnt.h
C_SOURCES=$(srcdir)/pl-buffer.c $(srcdir)/pl-ctype.c \
	$(srcdir)/pl-error.c  \
	$(srcdir)/pl-file.c $(srcdir)/pl-files.c   $(srcdir)/pl-os.c \
	$(srcdir)/pl-privitf.c \
	$(srcdir)/pl-stream.c $(srcdir)/pl-string.c \
	$(srcdir)/pl-table.c \
	$(srcdir)/pl-text.c \
	$(srcdir)/pl-utils.c \
	$(srcdir)/pl-yap.c # $(srcdir)/popen.c $(srcdir)/uxnt/uxnt.c
OBJS=pl-buffer.o pl-ctype.o pl-error.o  \
	pl-file.o pl-files.o pl-os.o pl-privitf.o \
	pl-stream.o pl-string.o pl-table.o \
	pl-text.o pl-utils.o pl-utf8.o \
	pl-yap.o # uxnt.o
SOBJS=plstream.so

#in some systems we just create a single object, in others we need to
# create a libray

all: $(SOBJS) 

uxnt.o: $(srcdir)/uxnt/uxnt.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/uxnt/uxnt.c -o uxnt.o

# default rule
%.o : $(srcdir)/%.c
	$(CC) -c $(CFLAGS)  $(SHLIB_CFLAGS) $< -o $@

%.so: %.o
	gcc -shared -export-dynamic -o $@ $<

plstream.so: $(OBJS)
	gcc -shared -export-dynamic -o plstream.so $(OBJS)

install: all
	$(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK


depend: $(HEADERS) $(C_SOURCES)
	-@if test "$(GCC)" = yes; then\
	  $(CC) -MM -MG $(CFLAGS) -I$(srcdir) -I$(srcdir)/../../include -I$(srcdir)/../../H $(C_SOURCES) >> Makefile;\
	else\
          makedepend -f - -- $(CFLAGS) -I$(srcdir)/../../H -I$(srcdir)/../../include -- $(C_SOURCES) |\
          sed 's|.*/\([^:]*\):|\1:|' >> Makefile ;\
	fi

# DO NOT DELETE THIS LINE -- make depend depends on it.

