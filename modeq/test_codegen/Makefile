# -*- Mode: Makefile -*-

MODEQ=../modeq
CC=gcc

CFLAGS= -Wall -ansi -pedantic -I../../c_runtime

LDFLAGS= -L../../c_runtime 

CDIR = csrc
ODIR = obj
BDIR = bin


MOFILES = \
	algorithm_for1.mo \
	algorithm_if1.mo \
	algorithm_while1.mo \
	expression_if1.mo \
	expression_matrix_vector_product1.mo \
	expression_range1.mo

TARGETS = $(MOFILES:.mo=)
OBJS = $(MOFILES:%.mo=%.main.o)
GENC = $(MOFILES:%.mo=%.c)

all : $(MOFILES:.mo=) 


$(TARGETS) : % : %.main.o
	gcc -o $@ $(LDFLAGS) $< -lc_runtime

$(OBJS) : %.main.o : %.c main.c
	@echo compiling $(subst .main.o,,$@)
	@$(CC) $(CFLAGS) \
	-DCFILE_TO_INCLUDE="\"$(subst .main.o,.c,$@)\""\
	 -DCFUNCTION_TO_CALL="$(subst .main.o,,$@)_read_call_write"\
	 -c -o $@ main.c

.SUFFIXES: .mo


.mo.c:
	@$(MODEQ) $< +d=codegen > $(<:.mo=.c)

clean :
	rm -f $(TARGETS)
	rm -f $(OBJS)
	rm -f $(GENC)
	rm -f *~
