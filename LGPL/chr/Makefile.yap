################################################################
# SWI-Prolog CHR package
# Author:    Jan Wielemaker. jan@swi.psy.uva.nl
# Copyright: LGPL (see COPYING or www.gnu.org
################################################################

.SUFFIXES: .tex .dvi .doc .pl

SHELL=/bin/sh
PLBASE=/usr/lib/pl-5.5.31
#PL=~/Yap/bins/devel/yap
PL=~/osx/yap
XPCEBASE=$(PLBASE)/xpce
PKGDOC=$(PLBASE)/doc/packages
PCEHOME=../../xpce
LIBDIR=$(PLBASE)/library
CHRDIR=$(LIBDIR)/chr
EXDIR=$(PKGDOC)/examples/chr
DESTDIR=

DOCTOTEX=$(PCEHOME)/bin/doc2tex
PLTOTEX=$(PCEHOME)/bin/pl2tex
LATEX=latex
DOC=chr
TEX=$(DOC).tex
DVI=$(DOC).dvi
PDF=$(DOC).pdf
HTML=$(DOC).html

INSTALL=/usr/bin/install -c
INSTALL_PROGRAM=${INSTALL}
INSTALL_DATA=/usr/bin/install -c -m 644

LIBPL=		chr_runtime.pl chr_op.pl chr_translate.pl chr_debug.pl \
		chr_messages.pl hprolog.pl pairlist.pl clean_code.pl \
		find.pl a_star.pl binomialheap.pl builtins.pl \
		chr_hashtable_store.pl listmap.pl guard_entailment.pl \
		chr_compiler_options.pl chr_compiler_utility.pl
CHRPL=		chr_swi.pl
EXAMPLES=	chrfreeze.chr fib.chr gcd.chr primes.chr \
		bool.chr family.chr fibonacci.chr leq.chr listdom.chr \
		chrdif.chr

all:		chr_translate.pl

chr_translate_bootstrap1.pl: chr_translate_bootstrap1.chr 
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step1('$<','$@'),halt." \
		      -z 'halt(1).'
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step2('$<','$@'),halt." \
		      -z 'halt(1).'

chr_translate_bootstrap2.pl: chr_translate_bootstrap2.chr chr_translate_bootstrap1.pl 
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step2('$<','$@'),halt." \
		      -z  'halt(1).'
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step3('$<','$@'),halt." \
		      -z  'halt(1).'

guard_entailment.pl: guard_entailment.chr chr_translate_bootstrap2.pl 
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step3('$<','$@'),halt." \
		      -z  'halt(1).'

chr_translate.pl: chr_translate.chr chr_translate_bootstrap2.pl guard_entailment.pl
		$(PL) -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step3('$<','$@'),halt." \
		      -z  'halt(1)'
		$(PL) -p chr=. -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step4('guard_entailment.chr','guard_entailment.pl'),halt." \
		      -z  'halt(1).'
		$(PL) -p chr=. -l chr_swi_bootstrap.yap \
		      -g "chr_compile_step4('$<','$@'),halt." \
		      -z  'halt(1).'

chr.pl:		chr_swi.pl
		cp $< $@

install:	$(LIBPL)
		mkdir -p $(DESTDIR)$(CHRDIR)
		$(INSTALL) -m 644 $(LIBPL) $(DESTDIR)$(CHRDIR)
		$(INSTALL) -m 644 $(CHRPL) $(DESTDIR)$(LIBDIR)/chr.pl
		$(INSTALL) -m 644 README   $(DESTDIR)$(CHRDIR)
		$(PL) -f none -g make -z  halt

rpm-install:	install

pdf-install:	install-examples

html-install:	install-examples

install-examples::
		mkdir -p $(DESTDIR)$(EXDIR)
		(cd Examples && $(INSTALL_DATA) $(EXAMPLES) $(DESTDIR)$(EXDIR))

uninstall:
		(cd $(PLBASE)/library && rm -f $(LIBPL))
		$(PL) -f none -g make -z  halt

check:		chr.pl
		$(PL) -f chr_test.pl -g "test,halt." -z  'halt(1).'


################################################################
# Documentation
################################################################

doc:		$(PDF) $(HTML)
pdf:		$(PDF)
html:		$(HTML)

$(HTML):	$(TEX)
		latex2html $(DOC)
		mv html/index.html $@

$(PDF):		$(TEX)
		runtex --pdf $(DOC)

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
		rm -f chr.pl chr_translate.pl
		rm -f chr_translate_bootstrap1.pl chr_translate_bootstrap2.pl
		rm -f guard_entailment.pl

distclean:	clean
		rm -f $(TARGETS) config.h config.cache config.status Makefile
		rm -f $(TEX)
		runtex --clean $(DOC)