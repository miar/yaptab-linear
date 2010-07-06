################################################################
# SWI-Prolog `sgml2pl' package
# Author:    Jan Wielemaker. jan@swi.psy.uva.nl
# Copyright: LGPL (see COPYING or www.gnu.org
################################################################

.SUFFIXES: .tex .dvi .doc .pl

ifeq (yap,yap)

prefix = /home/miguel/Desktop/git/mainline/build
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
abs_top_builddir = /home/miguel/Desktop/git/mainline

srcdir=.

BINDIR = $(EROOTDIR)/bin
LIBDIR=${exec_prefix}/lib
YAPLIBDIR=${exec_prefix}/lib/Yap
SHAREDIR=$(ROOTDIR)/share/Yap

SHELL=/bin/bash
PL=YAPSHAREDIR=$(DESTDIR)$(SHAREDIR) YAPLIBDIR=$(DESTDIR)$(YAPLIBDIR) $(DESTDIR)$(BINDIR)/yap $(DESTDIR)$(YAPLIBDIR)/startup.yss
CHRDIR=$(SHAREDIR)/chr
EXDIR=$(CHRDIR)/examples/chr
LN_S=ln -s
#
#
CC=gcc
CFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall -Wstrict-prototypes -Wmissing-prototypes $(YAP_EXTRAS) $(DEFS) -D_YAP_NOT_INSTALLED_=1 -I$(srcdir) -I../.. -I$(srcdir)/../../include
MKINDEX=true

LD=$(CC)
PLLD=$(CC)

SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
#4.1VPATH=.:./OPTYap
CWD=$(PWD)
#

TARGETS=	sgml2pl.so

else	# SWI

PL=@PL@
LD=@LD@
PLLD=@PLLD@
PLBASE=@PLBASE@
PLARCH=@PLARCH@
PKGDOC=$(PLBASE)/doc/packages
PCEHOME=../xpce
PLLIB=$(PLBASE)/library
PLFOREIGN=$(PLBASE)/lib/$(PLARCH)
DESTDIR=
SO=@SO@

DOCTOTEX=$(PCEHOME)/bin/doc2tex
PLTOTEX=$(PCEHOME)/bin/pl2tex
LATEX=latex
DOC=sgml
TEX=$(DOC).tex
DVI=$(DOC).dvi
PDF=$(DOC).pdf
HTML=$(DOC).html

CC=gcc
COFLAGS=@COFLAGS@
CWFLAGS=@CWFLAGS@
CMFLAGS=@CMFLAGS@
CIFLAGS=-I. -I@PLINCL@
CFLAGS=$(COFLAGS) $(CWFLAGS) $(CMFLAGS) $(CIFLAGS) -DHAVE_CONFIG_H
LDFLAGS=$(COFLAGS)

LDSOFLAGS=@LDSOFLAGS@

TARGETS=	sgml2pl.@SO@

endif	#YAP/SWI

INSTALL=/usr/bin/install -c
INSTALL_PROGRAM=${INSTALL}
INSTALL_DATA=${INSTALL} -m 644

LIBOBJ=		parser.o util.o charmap.o catalog.o model.o xmlns.o utf8.o \
		xml_unicode.o
PLOBJ=		$(LIBOBJ) error.o sgml2pl.o quote.o
SGMLOBJ=	$(LIBOBJ) sgml.o
DTD2PLOBJ=	$(LIBOBJ) dtd2pl.o prolog.o

HDRS=		$(srcdir)/catalog.h $(srcdir)/dtd.h \
		$(srcdir)/model.h $(srcdir)/prolog.h \
		$(srcdir)/utf8.h $(srcdir)/xmlns.h \
		$(srcdir)/config.h $(srcdir)/error.h \
		$(srcdir)/parser.h $(srcdir)/sgmldefs.h $(srcdir)/util.h

ALLCSRC=	$(LIBOBJ:.o=.c) \
		$(PLOBJ:.o=.c) $(SGMLOBJ:.o=.c) $(DTD2PLOBJ:.o=.c) \
		$(HDRS)

LIBPL=		$(srcdir)/sgml.pl $(srcdir)/xsdp_types.pl \
		$(srcdir)/iso_639.pl $(srcdir)/sgml_write.pl
PROGRAMS=	dtd2pl sgml
DTDFILES=	HTML4.dcl HTML4.dtd \
		HTML4.soc \
		HTMLlat1.ent \
		HTMLspec.ent HTMLsym.ent

ifeq (yap,yap)

%.o : $(srcdir)/%.c
	$(CC) $(CFLAGS) $(SHLIB_CFLAGS)  -o $@ -c $<

sgml2pl.so: $(PLOBJ)
	gcc -shared -export-dynamic -o sgml2pl.so $(PLOBJ)

all:		$(TARGETS) $(PROGRAMS)

install:	$(TARGETS) $(LIBPL) install-dtd
		mkdir -p $(DESTDIR)$(YAPLIBDIR)
		$(INSTALL_PROGRAM) $(TARGETS) $(DESTDIR)$(YAPLIBDIR)
		$(INSTALL_DATA) $(LIBPL) $(DESTDIR)$(SHAREDIR)
		$(PL) -f none -g make -t halt

install-dtd::
		mkdir -p $(DESTDIR)$(SHAREDIR)/DTD
		for f in $(DTDFILES); do \
		   $(INSTALL_DATA) $(srcdir)/DTD/$$f $(DESTDIR)$(SHAREDIR)/DTD; \
		done

else

sgml2pl.@SO@:	$(PLOBJ)
		$(PLLD) -shared -o $@ $(PLOBJ)

all:		coflags $(TARGETS) $(PROGRAMS)

coflags::
		@echo $(COFLAGS) > .coflags

install:	$(TARGETS) $(LIBPL) install-dtd
		mkdir -p $(DESTDIR)$(PLBASE)/lib/$(PLARCH)
		$(INSTALL_PROGRAM) $(TARGETS) $(DESTDIR)$(PLFOREIGN)
		$(INSTALL_DATA) $(LIBPL) $(DESTDIR)$(PLLIB)
		$(PL) -f none -g make -t halt

install-dtd::
		mkdir -p $(DESTDIR)$(PLBASE)/library/DTD
		for f in $(DTDFILES); do \
		   $(INSTALL_DATA) DTD/$$f $(DESTDIR)$(PLBASE)/library/DTD; \
		done

endif

ln-install::
		@$(MAKE) INSTALL_DATA=../ln-install install 

rpm-install:	install

pdf-install::
		mkdir -p $(DESTDIR)$(PKGDOC)
		$(INSTALL_DATA) sgml.pdf $(DESTDIR)$(PKGDOC)

html-install::
		mkdir -p $(DESTDIR)$(PKGDOC)
		$(INSTALL_DATA) sgml.html $(DESTDIR)$(PKGDOC)

check::
		$(PL) -f Test/test.pl -g test,halt
		$(PL) -f Test/wrtest.pl -g test,halt

uninstall::
		(cd $(PLBASE)/lib/$(PLARCH) && rm -f $(TARGETS))
		(cd $(PLBASE)/library && rm -f $(LIBPL))
		$(PL) -f none -g make -t halt

dtd2pl:		$(DTD2PLOBJ)
		$(LD) $(LDFLAGS) -o $@ $(DTD2PLOBJ)

sgml:		$(SGMLOBJ)
		$(LD) $(LDFLAGS) -o $@ $(SGMLOBJ)

tags:		TAGS

TAGS:		$(ALLCSRC)
		etags $(ALLCSRC)

################################################################
# Documentation
################################################################

doc:		$(PDF) $(HTML)
pdf:		$(PDF)
html:		$(HTML)

$(HTML):	$(TEX)
		latex2html $(DOC)
		mv html/index.html $@
		rmdir html

$(PDF):		$(TEX)
		../../man/runtex --pdf $(DOC)

$(TEX):		$(DOCTOTEX)

.doc.tex:
		$(DOCTOTEX) $*.doc > $*.tex
.pl.tex:
		$(PLTOTEX) $*.pl > $*.tex

docclean::
		rm -f $(TEX)
		rm -rf html
		../../man/runtex --clean $(DOC)

################################################################
# Clean
################################################################

clean::
		rm -f $(PLOBJ) *~ *.o *% a.out core config.log

distclean:	clean
		rm -f $(TARGETS) $(PROGRAMS)
		rm -f config.cache config.h config.status Makefile
		rm -f .coflags

