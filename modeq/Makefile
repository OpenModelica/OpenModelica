#
# Makefile for modeq
#
# David Kågedal <x97davka@ida.liu.se>
#
# $Id$
#


ANTLR_HOME = /home/pelab/pub/pkg/antlr-2.7.1
ANTLR_CPP = $(ANTLR_HOME)/lib/cpp/gcc-2.95.2

ANTLR_INCP = -I$(ANTLR_CPP)/include
ANTLR_LIBP = -L$(ANTLR_CPP)/lib

SHELL	= /bin/sh
CC	= gcc
CFLAGS	= 
RMLHOME	= /home/pelab/pub/pkg/rml/current/sparc-sol2-gcc
RML	= $(RMLHOME)/bin/rmlc -g
RMLINC  = -I$(RMLHOME)/include/plain

LDFLAGS = -L$(RMLHOME)/lib/plain $(ANTLR_LIBP) -lrml -lm -lantlr

PROG	= modeq
AST	= absyn_builder/absyn_builder.a
RTOBJ   = runtime/rtopts.o

SRCRML= absyn.rml \
	algorithm.rml \
	builtin.rml \
	classinf.rml \
	codegen.rml \
	connect.rml \
	dae.rml \
	debug.rml \
	dump.rml \
	dumpgraphviz.rml \
	env.rml \
	exp.rml \
	explode.rml \
	graphviz.rml \
	inst.rml \
	lookup.rml \
	main.rml \
	mod.rml \
	modutil.rml \
	prefix.rml \
	staticexp.rml \
	types.rml \
	util.rml \
	values.rml

SRCC=	$(SRCRML:.rml=.c)
SRCH=	$(SRCRML:.rml=.h)
SRCO=	$(SRCC:.c=.o)

#SUBDIRS= ast runtime
SUBDIRS	= runtime absyn_builder

.SUFFIXES:
.SUFFIXES: .o .rml .h
.PHONY: all subdirs report

.rml.o:
	$(RML) -c $<

.rml.h:
	$(RML) -c $<

all : $(SRCO) subdirs $(PROG)

test:
	@(cd testsuite ; make)

$(PROG): $(SRCO) $(AST) $(RTOBJ)
	g++ -o $(PROG) $(SRCO) $(AST) $(RTOBJ) $(LDFLAGS)


ast/libast.a:
	@(cd ast ; $(MAKE) libast.a)

subdirs:
	@for d in $(SUBDIRS); do \
		(cd $$d ; $(MAKE)) \
	done

clean:
	@for d in $(SUBDIRS); do \
		(cd $$d ; $(MAKE) clean) \
	done
	$(RM) $(SRCO) $(SRCC) $(SRCH) $(PROG) *~

reallyclean: clean

report:
	@(cd report ; $(MAKE))

depend:
	$(RM) .dep
	for f in $(SRCRML); do \
	  echo `echo $$f | sed "s/\.rml/.o/"`: $$f `sed -n -e 's/.*with "\(.*\)\.rml".*/\1.rml/p' < $$f | egrep -v 'nothing'` >> .dep ; \
	done
	mv Makefile Makefile.save
	sed -n -e "1,/^## dependencies/p" < Makefile.save > Makefile
	cat .dep >> Makefile
	$(RM) .dep Makefile.save

## dependencies
debug.o: debug.rml rtopts.rml dump.rml
util.o: util.rml
types.o: types.rml classinf.rml absyn.rml exp.rml values.rml explode.rml dump.rml debug.rml
absyn.o: absyn.rml debug.rml
explode.o: explode.rml absyn.rml dump.rml debug.rml
dump.o: dump.rml absyn.rml debug.rml classinf.rml rtopts.rml
dumpgraphviz.o: dumpgraphviz.rml absyn.rml debug.rml graphviz.rml classinf.rml dump.rml
graphviz.o: graphviz.rml
prefix.o: prefix.rml absyn.rml exp.rml env.rml lookup.rml
env.o: env.rml absyn.rml values.rml explode.rml types.rml classinf.rml exp.rml dump.rml graphviz.rml dae.rml
lookup.o: lookup.rml classinf.rml types.rml absyn.rml exp.rml env.rml explode.rml parse.rml debug.rml
builtin.o: builtin.rml absyn.rml explode.rml env.rml exp.rml types.rml classinf.rml
connect.o: connect.rml exp.rml staticexp.rml dae.rml dump.rml
classinf.o: classinf.rml absyn.rml
exp.o: exp.rml absyn.rml rtopts.rml
algorithm.o: algorithm.rml exp.rml types.rml staticexp.rml explode.rml
staticexp.o: staticexp.rml absyn.rml exp.rml explode.rml types.rml env.rml values.rml classinf.rml lookup.rml debug.rml dump.rml
values.o: values.rml
dae.o: dae.rml absyn.rml dump.rml exp.rml explode.rml algorithm.rml types.rml staticexp.rml rtopts.rml graphviz.rml
mod.o: mod.rml absyn.rml dae.rml env.rml exp.rml prefix.rml explode.rml types.rml staticexp.rml values.rml dump.rml
modutil.o: modutil.rml absyn.rml dae.rml exp.rml rtopts.rml algorithm.rml
inst.o: inst.rml explode.rml dae.rml debug.rml env.rml prefix.rml mod.rml connect.rml types.rml classinf.rml exp.rml modutil.rml algorithm.rml values.rml absyn.rml lookup.rml builtin.rml dump.rml staticexp.rml rtopts.rml
codegen.o: codegen.rml dae.rml exp.rml types.rml algorithm.rml util.rml modutil.rml dump.rml debug.rml staticexp.rml inst.rml rtopts.rml absyn.rml classinf.rml
main.o: main.rml modutil.rml parse.rml dump.rml dumpgraphviz.rml explode.rml dae.rml inst.rml rtopts.rml debug.rml codegen.rml
