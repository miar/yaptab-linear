#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
prefix = /home/miguel/Desktop/yap-ns/arch
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
#
# where the binary should be
#
BINDIR = $(EROOTDIR)/bin
#
# where YAP should look for libraries
#
LIBDIR=$(EROOTDIR)/lib/Yap
DESTDIR=$(prefix)/share/Yap
#
#
CC=gcc
#
#
# You shouldn't need to change what follows.
#
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_PROGRAM=${INSTALL}
SHELL=/bin/sh
RANLIB=ranlib
SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
CWD=$(PWD)
srcdir=../../../../../packages/cplint/approx/simplecuddLPADs
CPLINT_CFLAGS=
CPLINT_LDFLAGS=
CPLINT_LIBS=

#


default:  LPADBDD

LPADBDD: ProblogBDD.o simplecudd.o general.o
	@echo Making ProblogBDD...
	@echo Copyright T. Mantadelis, A. Kimmig, B. Gutmann and Katholieke Universiteit Leuven 2008
	$(CC) $(CPLINT_LDFLAGS) ProblogBDD.o simplecudd.o general.o  $(CPLINT_LIBS) -o LPADBDD

%.o : $(srcdir)/%.c
	$(CC)  $(CPLINT_CFLAGS)  -c $<

clean: 
	rm -f *.o LPADBDD 

install: default
	$(INSTALL_PROGRAM) LPADBDD $(DESTDIR)
