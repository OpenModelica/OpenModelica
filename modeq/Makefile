CC=cc
CFLAGS=
RML=rmlc
LIB=/home/pelab/pub/pkg/rml/current/sol2-sparc/lib/plain/librml.a

SRCRML=	modelica.rml class.rml exp.rml dae.rml main.rml
SRCC=	$(SRCRML:.rml=.c)
SRCO=	$(SRCRML:.rml=.o)

.SUFFIXES: .rml

#.rml.c:
#	$(RML) -c $<

.rml.o:
	$(RML) -c $<
#	$(CC) -c $*.c

modelica:	$(SRCO) $(LIB)
		$(RML) -o modelica $(SRCO) $(LIB) -lm

$(SRCO):	rml.h

dae.rml:	exp.rml
env.rml:	modelica.rml
main.rml:	exp.rml dae.rml

clean:
	$(RM) $(SRCO) $(SRCC)

reallyclean: clean
	$(RM) class.h dae.h exp.h main.h modelica.h
