#
# Makefile for modeq
#
# David Kågedal <x97davka@ida.liu.se>
#

SHELL	= /bin/sh
CC	= cc
CFLAGS	=
LDFLAGS = -lm -L/home/pelab/pub/pkg/rml/current/sol2-sparc/lib/plain -lrml
RML	= rmlc
PROG	= modeq
AST	= ast/libast.a

SRCRML=	exp.rml \
	dae.rml \
	absyn.rml \
	dump.rml \
	prefix.rml \
	env.rml \
	lform.rml \
	mod.rml \
	builtin.rml \
	inst.rml \
	main.rml
SRCC=	$(SRCRML:.rml=.c)
SRCH=	$(SRCRML:.rml=.h)
SRCO=	$(SRCC:.c=.o)

SUBDIRS	= ast

.SUFFIXES: .rml
.PHONY: subdirs

.rml.c:
	$(RML) -c $<

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

# .rml.o:
# 	  $(RML) -c $<
# 	  $(CC) -c $(CFLAGS) -o $@ $*.c

all : $(SRCO) subdirs $(PROG)

$(PROG): $(SRCO) ast/libast.a
	$(CC) -o $(PROG) $(SRCO) $(LDFLAGS) $(AST)

# $(SRCO):	rml.h
# inst.o:		inst.rml mod.h env.h

main.c:		main.rml absyn.rml parse.rml dump.rml \
		lform.rml dae.rml inst.rml

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
