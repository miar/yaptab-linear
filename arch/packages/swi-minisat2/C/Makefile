#
# default base directory for YAP installation
# (EROOT for architecture-dependent files)
#
GCC=yes
prefix = /home/miguel/Desktop/yap-ns/arch
exec_prefix = ${prefix}
ROOTDIR = $(prefix)
EROOTDIR = ${prefix}
abs_top_builddir = /home/miguel/Desktop/yap-ns/arch
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
CXX=g++
CXXFLAGS= -DBP_FREE -O3 -fomit-frame-pointer -Wall $(YAP_EXTRAS) $(DEFS)  -D_YAP_NOT_INSTALLED_=1 -I$(srcdir) -I../../.. -I$(srcdir)/../../../include
#
#
# You shouldn't need to change what follows.
#
INSTALL=/usr/bin/install -c
INSTALL_DATA=${INSTALL} -m 644
INSTALL_PROGRAM=${INSTALL}
SHELL=/bin/sh
RANLIB=ranlib
srcdir=../../../../packages/swi-minisat2/C
SHLIB_CFLAGS=-shared -fPIC
SHLIB_SUFFIX=.so
#4.1VPATH=../../../../packages/swi-minisat2/C:../../../../packages/swi-minisat2/C/OPTYap
CWD=$(PWD)
#

HEADERS= \
	$(srcdir)/Alg.h \
	$(srcdir)/BasicHeap.h \
	$(srcdir)/BoxedVec.h  \
	$(srcdir)/Heap.h \
	$(srcdir)/Map.h \
	$(srcdir)/Queue.h  \
	$(srcdir)/Solver.h \
	$(srcdir)/SolverTypes.h \
	$(srcdir)/Sort.h \
	$(srcdir)/Vec.h
C_SOURCES=$(srcdir)/pl-minisat.C $(srcdir)/Solver.C

OBJS = \
	Solver.o \
	pl-minisat.o

SOBJS=pl-minisat.so

#in some systems we just create a single object, in others we need to
# create a libray

all: $(SOBJS) 

# default rule
Solver.o : $(srcdir)/Solver.C
	$(CXX) -c $(CXXFLAGS)  $(SHLIB_CFLAGS) $(srcdir)/Solver.C -o Solver.o

pl-minisat.o : $(srcdir)/pl-minisat.C
	$(CXX) -c $(CXXFLAGS)  $(SHLIB_CFLAGS) $(srcdir)/pl-minisat.C -o pl-minisat.o

pl-minisat.so: $(OBJS)
	g++ -shared -export-dynamic -o pl-minisat.so $(OBJS)

install: all
	$(INSTALL_PROGRAM) $(SOBJS) $(DESTDIR)$(LIBDIR)

clean:
	rm -f *.o *~ $(OBJS) $(SOBJS) *.BAK


depend: $(HEADERS) $(C_SOURCES)
	-@if test "$(GCC)" = yes; then\
	  $(CC) -MM -MG $(CFLAGS) -I$(srcdir) -I$(srcdir)/../../../include -I$(srcdir)/../../../H $(C_SOURCES) >> Makefile;\
	else\
          makedepend -f - -- $(CFLAGS) -I$(srcdir)/../../../H -I$(srcdir)/../../../include -- $(C_SOURCES) |\
          sed 's|.*/\([^:]*\):|\1:|' >> Makefile ;\
	fi

# DO NOT DELETE THIS LINE -- make depend depends on it.
