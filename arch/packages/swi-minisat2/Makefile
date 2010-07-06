#
# default base directory for YAP installation
#
#
ROOTDIR = /home/miguel/Desktop/yap-ns/arch
#
# where the binary should be
#
BINDIR = $(ROOTDIR)/bin
#
# where YAP should look for binary libraries
#
LIBDIR=${exec_prefix}/lib/Yap
#
# where YAP should look for architecture-independent Prolog libraries
#
SHAREDIR=$(ROOTDIR)/share
#
#
# You shouldn't need to change what follows.
#
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_PROGRAM=${INSTALL}
srcdir=../../../packages/swi-minisat2
YAP_EXTRAS= -DCOROUTINING=1 -DRATIONAL_TREES=1 -DDEPTH_LIMIT=1 -DTABLING=1 

PROGRAMS= \
	$(srcdir)/cnf.pl \
	$(srcdir)/minisat.pl

EXAMPLE_PROGRAMS= \
	$(srcdir)/examples/adder.pl \
	$(srcdir)/examples/pearl_examples.pl

install: $(PROGRAMS) 
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap/minisat_examples
	for p in $(PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap; done
	for p in $(EXAMPLE_PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap/minisat_examples; done

clean:
