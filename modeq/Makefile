#
# Makefile for modeq
#
# David Kågedal <x97davka@ida.liu.se>
#
# $Id$
#

SHELL	= /bin/sh
CC	= cc
CFLAGS	= 
LDFLAGS = -lrml -lm
#RML	= /net/senilix/files/senilix3/labs/pelab/pub/pkg/rml/rml-2.1/sparc-sol2-gcc/bin/rmlc -g
RML	= /home/pelab/pub/pkg/rml/current/sparc-sol2-gcc/bin/rmlc -g
#RML	= rmlc -g
PROG	= modeq
AST	= ast/libast.a
RTOBJ   = runtime/rtopts.o

SRCRML=	debug.rml \
	types.rml \
	absyn.rml \
	explode.rml \
	dump.rml \
	prefix.rml \
	env.rml \
	lookup.rml \
	builtin.rml \
	connect.rml \
	classinf.rml \
	exp.rml \
	algorithm.rml \
	staticexp.rml \
	values.rml \
	dae.rml \
	mod.rml \
	inst.rml \
	main.rml

SRCC=	$(SRCRML:.rml=.c)
SRCH=	$(SRCRML:.rml=.h)
SRCO=	$(SRCC:.c=.o)

SUBDIRS	= ast runtime

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
	$(RML) -o $(PROG) $(SRCO) $(AST) $(RTOBJ) $(LDFLAGS)

#absyn.o:	absyn.rml
#exp.o:		exp.rml
#env.o:		env.rml values.h
#explode.o:	explode.rml
#inst.o:		inst.rml env.rml values.h
#mod.o:		mod.rml absyn.h dae.h prefix.h env.h
#main.o:		main.rml
#dump.o:		dump.rml
#lookup.o:	env.h
#builtin.o:	builtin.rml env.h
#staticexp.o:	staticexp.rml env.h values.h

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
