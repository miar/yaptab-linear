#
# default base directory for YAP installation
#
ROOTDIR = /home/miguel/Desktop/git/mainline/build
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
srcdir=.

PROGRAMS= $(srcdir)/clp_events.pl

install: $(PROGRAMS)
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap/clp
	for p in $(PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap/clp; done

