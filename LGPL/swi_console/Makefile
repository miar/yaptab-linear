#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
prefix = /home/miguel/Desktop/git/mainline/build
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
#
# where YAP should look for libraries
#
LIBDIR=${exec_prefix}/lib/Yap
#
#
CC=gcc
CPPFLAGS= 
CFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall -Wstrict-prototypes -Wmissing-prototypes $(DEFS) $(CPPFLAGS)  -I$(srcdir)
#
#
# You shouldn't need to change what follows.
#
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_PROGRAM=${INSTALL}
RANLIB=ranlib
AR=ar
srcdir=.

SOURCES= \
	$(srcdir)/complete.c $(srcdir)/console.c \
	$(srcdir)/edit.c $(srcdir)/history.c \
	$(srcdir)/menu.c
HEADERS= \
	$(srcdir)/common.h $(srcdir)/console.h \
	$(srcdir)/console_i.h $(srcdir)/history.h \
	$(srcdir)/menu.h

OBJECTS=	complete.o console.o edit.o history.o menu.o

LIBS=-lgdi32 -lcomdlg32

all: plterm.dll

plterm.dll:  libplterm.a
	$(CC) $(CFLAGS) -shared -o plterm.dll \
	-Wl,--export-all-symbols \
	-Wl,--enable-auto-import \
	-Wl,--whole-archive libplterm.a \
	-Wl,--no-whole-archive $(LIBS) $(LDFLAGS)

libplterm.a: $(OBJECTS) $(SOURCES) $(HEADERS)
	-rm -f libplterm.a
	$(AR) rc libplterm.a $(OBJECTS)
	$(RANLIB) libplterm.a

install:	plterm.dll
	$(INSTALL_PROGRAM) plterm.dll $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ *.dll

complete.o: $(srcdir)/complete.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/complete.c -o complete.o

console.o: $(srcdir)/console.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/console.c -o console.o

history.o: $(srcdir)/history.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/history.c -o history.o

menu.o: $(srcdir)/menu.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/menu.c -o menu.o

edit.o: $(srcdir)/edit.c
	$(CC) -c $(CFLAGS) $(SHLIB_CFLAGS) $(srcdir)/edit.c -o edit.o

