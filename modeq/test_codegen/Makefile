MODEQ=../modeq
CC=gcc

CFLAGS= -Wall -ansi -pedantic -I../../c_runtime

LDFLAGS= -L../../c_runtime 

MOFILES = test.mo matrix_vector_product.mo

all : $(MOFILES:.mo=) 


test : test.main.o
	gcc -o test  $(LDFLAGS) test.main.o -lc_runtime

matrix_vector_product : matrix_vector_product.main.o
	gcc -o matrix_vector_product  $(LDFLAGS) matrix_vector_product.main.o -lc_runtime


test.main.o : test.main.c test.c
matrix_vector_product.main.o : matrix_vector_product.main.c matrix_vector_product.c

.SUFFIXES: .mo


.mo.c:
	$(MODEQ) $< +d=codegen > $(<:.mo=.c)

clean :
	rm -f $(MOFILES:.mo=)
	rm -f $(MOFILES:.mo=.main.o)
	rm -f $(MOFILES:.mo=.c)
