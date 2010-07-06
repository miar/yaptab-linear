################################################################
# SWI-Prolog `PlDoc' package
# Author:    Jan Wielemaker. wielemak@science.uva.nl
# Copyright: GPL (see COPYING or www.gnu.org
################################################################

.SUFFIXES: .tex .dvi .doc .pl

SHELL=/bin/bash

ifeq (yap,yap)

prefix = /home/miguel/Desktop/git/mainline/build
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}

srcdir=.

BINDIR = $(EROOTDIR)/bin
LIBDIR=${exec_prefix}/lib
SHAREDIR=$(EROOTDIR)/share/Yap
YAPLIBDIR=${exec_prefix}/lib/Yap

PL=YAPSHAREDIR=$(DESTDIR)$(SHAREDIR) YAPLIBDIR=$(DESTDIR)$(YAPLIBDIR) $(DESTDIR)$(BINDIR)/yap $(DESTDIR)$(YAPLIBDIR)/startup.yss
LN_S=ln -s
EXDIR=$(LIBDIR)/examples/plunit

INSTALLDIR=$(SHAREDIR)

else	# SWI

srcdir=.

PLBASE=@PLBASE@
PLARCH=@PLARCH@
PL=@PL@
XPCEBASE=$(PLBASE)/xpce
PKGDOC=$(PLBASE)/doc/packages
PCEHOME=../xpce
LIBDIR=$(PLBASE)/library
EXDIR=$(PKGDOC)/examples/plunit

INSTALLDIR=$(LIBDIR)

endif

DESTDIR=

DOCTOTEX=$(PCEHOME)/bin/doc2tex
PLTOTEX=$(PCEHOME)/bin/pl2tex
vLATEX=latex
DOC=plunit
TEX=$(DOC).tex
DVI=$(DOC).dvi
PDF=$(DOC).pdf
HTML=$(DOC).html

INSTALL=/usr/bin/install -c
INSTALL_PROGRAM=${INSTALL}
INSTALL_DATA=${INSTALL} -m 644

LIBPL=		$(srcdir)/plunit.pl $(srcdir)/test_wizard.pl $(srcdir)/test_cover.pl
LIBALL=		$(LIBPL) $(SUPPORT)
EXAMPLES=	$(srcdir)/read.pl $(srcdir)/simple.pl

all:		
		@echo "Nothing to do for this package"

install:	$(LIBPL)
		mkdir -p $(DESTDIR)$(INSTALLDIR)
		$(INSTALL_DATA) $(LIBALL) $(DESTDIR)$(INSTALLDIR)
		$(PL) -f none -g make -t halt

ln-install:	$(LIBPL)
		mkdir -p $(DESTDIR)$(INSTALLDIR)
		for f in $(LIBALL); do \
		    rm -f $(DESTDIR)$(INSTALLDIR)/$$f; \
		    ln -s `pwd`/$$f $(DESTDIR)$(INSTALLDIR); \
		done
		$(PL) -f none -g make -t halt

rpm-install:	install

pdf-install:	install-examples
		$(INSTALL_DATA) $(DOC).pdf $(DESTDIR)$(PKGDOC)

html-install:	install-examples
		$(INSTALL_DATA) $(DOC).html $(DESTDIR)$(PKGDOC)

install-examples::
		mkdir -p $(DESTDIR)$(EXDIR)
		(cd examples && $(INSTALL_DATA) $(EXAMPLES) $(DESTDIR)$(EXDIR))

uninstall::
		rm -f $(DESTDIR)$(INSTALLDIR)/plunit.pl
		$(PL) -f none -g make -t halt

check::
		true

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

################################################################
# Clean
################################################################

clean:
		rm -f *~ *% config.log

#		rm -f $(TEX)
#		../../man/runtex --clean $(DOC)
#		rm -rf html

distclean:	clean
		rm -f $(TARGETS) config.cache config.status Makefile
