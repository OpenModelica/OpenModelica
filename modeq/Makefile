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

SRCRML=	dae.rml \
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
