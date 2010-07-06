#
# default base directory for YAP installation
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
srcdir=../../LGPL
YAP_EXTRAS= -DCOROUTINING=1 -DRATIONAL_TREES=1 -DDEPTH_LIMIT=1 -DTABLING=1 

PROGRAMS= $(srcdir)/debug.pl \
	$(srcdir)/maplist.pl \
	$(srcdir)/operators.pl \
	$(srcdir)/option.pl \
	$(srcdir)/prolog_source.pl \
	$(srcdir)/prolog_xref.pl


install: $(PROGRAMS)
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap
	for p in $(PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap; done

