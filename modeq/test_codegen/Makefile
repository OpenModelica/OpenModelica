MODEQ=../modeq
CC=gcc

CFLAGS= -Wall -ansi -pedantic -I../../c_runtime

LDFLAGS= -L../../c_runtime 

MOFILES = \
	test.mo \
	matrix_vector_product.mo \
	if_algorithm.mo \
	while_algorithm.mo

TARGETS = $(MOFILES:.mo=)
OBJS = $(MOFILES:%.mo=%.main.o)
GENC = $(MOFILES:%.mo=%.c)

all : $(MOFILES:.mo=) 


$(TARGETS) : % : %.main.o
	gcc -o $@ $(LDFLAGS) $< -lc_runtime

$(OBJS) : %.main.o : %.main.c %.c


.SUFFIXES: .mo


.mo.c:
	$(MODEQ) $< +d=codegen > $(<:.mo=.c)

clean :
	rm -f $(TARGETS)
	rm -f $(OBJS)
	rm -f $(GENC)
