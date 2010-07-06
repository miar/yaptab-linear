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
srcdir=../../../packages/ProbLog
YAP_EXTRAS= -DCOROUTINING=1 -DRATIONAL_TREES=1 -DDEPTH_LIMIT=1 -DTABLING=1 

PROGRAMS= \
	$(srcdir)/problog.yap \
	$(srcdir)/learning.yap

PROBLOG_PROGRAMS= \
	$(srcdir)/problog/flags.yap \
	$(srcdir)/problog/print.yap \
	$(srcdir)/problog/tptree.yap

LEARNING_PROGRAMS = \
	$(srcdir)/learning/flags_learning.yap \
	$(srcdir)/learning/logger.yap

EXAMPLES = \
	$(srcdir)/examples/graph.pl \
	$(srcdir)/examples/learn_graph.pl

install: $(PROGRAMS) $(LEARNING_PROGRAMS)  $(EXAMPLE_PROGRAMS) 
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap/problog
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap/problog_examples
	mkdir -p $(DESTDIR)$(SHAREDIR)/Yap/problog_learning
	$(INSTALL_DATA) $(srcdir)/problog.yap $(DESTDIR)$(SHAREDIR)/Yap
	$(INSTALL_DATA) $(srcdir)/learning.yap $(DESTDIR)$(SHAREDIR)/Yap/problog_learning.yap
	for p in $(PROBLOG_PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap/problog; done
	for p in $(LEARNING_PROGRAMS); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap/problog_learning; done
	for p in $(EXAMPLES); do $(INSTALL_DATA) $$p $(DESTDIR)$(SHAREDIR)/Yap/problog_examples; done

