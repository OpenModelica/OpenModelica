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

SRCRML=	class.rml exp.rml dae.rml main.rml absyn.rml
SRCC=	$(SRCRML:.rml=.c)
SRCO=	$(SRCRML:.rml=.o)

SUBDIRS	= ast

.SUFFIXES: .rml
.PHONY: subdirs

.rml.c:
	$(RML) -c $<

.rml.o:
	$(RML) -c $<
#	$(CC) -c $*.c

$(PROG): subdirs $(SRCO) $(AST)
	$(CC) -o $(PROG) $(SRCO) $(LDFLAGS) ast/modgram.o $(AST)

$(SRCO):	rml.h
modelica.o:	modelica.rml
class.o:	class.rml
exp.o:		exp.rml
dae.o:		dae.rml
main.o:		main.rml
absyn.o:	absyn.rml
parse.o:	parse.rml

ast/libast.a:
	(cd ast ; $(MAKE) libast.a)

subdirs:
	@for d in $(SUBDIRS); do \
		(cd $$d ; $(MAKE)) \
	done

clean:
	@for d in $(SUBDIRS); do \
		(cd $$d ; $(MAKE) clean) \
	done
	$(RM) $(SRCO) $(SRCC) $(PROG)

reallyclean: clean
	$(RM) class.h dae.h exp.h main.h modelica.h
