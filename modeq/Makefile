#
# Makefile for modeq
#
# David Kågedal <x97davka@ida.liu.se>
#

SHELL	= /bin/sh
CC	= cc
CFLAGS	= 
LDFLAGS = -lrml
RML	= rmlc
PROG	= modeq
AST	= ast/libast.a

SRCRML=	exp.rml \
	dae.rml \
	absyn.rml \
	explode.rml \
	dump.rml \
	prefix.rml \
	mod.rml \
	types.rml \
	env.rml \
	builtin.rml \
	inst.rml \
	main.rml
SRCC=	$(SRCRML:.rml=.c)
SRCH=	$(SRCRML:.rml=.h)
SRCO=	$(SRCC:.c=.o)

RMLINCLUDE = $(RMLDIR)/include/plain

SUBDIRS	= ast

.SUFFIXES: .rml
.PHONY: subdirs

.rml.o:
	$(RML) -c $<

#.c.o:
#	$(CC) -c $(CFLAGS) -o $@ $<

# .rml.o:
# 	  $(RML) -c $<
# 	  $(CC) -c $(CFLAGS) -o $@ $*.c

all : $(SRCO) subdirs $(PROG)

$(PROG): $(SRCO) ast/libast.a
	$(RML) -o $(PROG) $(SRCO) $(AST) $(LDFLAGS)

# $(SRCO):	rml.h
absyn.o:	absyn.rml
exp.o:		exp.rml
env.o:		env.rml
	$(RML) -c $<
explode.o:	explode.rml
	$(RML) -c $<
inst.o:		inst.rml
	$(RML) -c $<
mod.o:		mod.rml exp.h absyn.h dae.h prefix.h
	$(RML) -c $<
main.o:		main.rml
	$(RML) -c $<
dump.o:		dump.rml
	$(RML) -c $<

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
