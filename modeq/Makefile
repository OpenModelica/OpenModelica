#
# Makefile for modeq
#
# David Kågedal <x97davka@ida.liu.se>
#

SHELL	= /bin/sh
CC	= cc
CFLAGS	= 
LDFLAGS = -lrml -lm
RML	= rmlc -g
PROG	= modeq
AST	= ast/libast.a

SRCRML=	exp.rml \
	dae.rml \
	types.rml \
	absyn.rml \
	explode.rml \
	dump.rml \
	prefix.rml \
	mod.rml \
	env.rml \
	lookup.rml \
	builtin.rml \
	connect.rml \
	classinf.rml \
	staticexp.rml \
	values.rml \
	inst.rml \
	main.rml

SRCC=	$(SRCRML:.rml=.c)
SRCH=	$(SRCRML:.rml=.h)
SRCO=	$(SRCC:.c=.o)

SUBDIRS	= ast

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

$(PROG): $(SRCO) ast/libast.a
	$(RML) -o $(PROG) $(SRCO) $(AST) $(LDFLAGS)

absyn.o:	absyn.rml
exp.o:		exp.rml
env.o:		env.rml exp.h values.h
explode.o:	explode.rml
inst.o:		inst.rml env.rml values.h
mod.o:		mod.rml exp.rml absyn.h dae.h prefix.h env.h
main.o:		main.rml
dump.o:		dump.rml
package.o:	env.h
lookup.o:	env.h
builtin.o:	builtin.rml env.h
staticexp.o:	staticexp.rml env.h values.h

#main.o:		main.rml absyn.rml parse.rml dump.rml \
#		lform.rml dae.rml inst.rml

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
	$(RM) dae.h exp.h main.h modelica.h

report:
	@(cd report ; $(MAKE))
