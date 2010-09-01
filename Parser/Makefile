RMLHOME=/usr
COMPILERHOME=../Compiler/
LIBRML=-lrml -lm
ANTLRCMD=java -cp ./antlr-3.2/lib/antlr-3.2.jar org.antlr.Tool -report
CFLAGS=-g -O3
LDFLAGS=-L$(RMLHOME)/lib/plain/ $(LIBRML) -L. -lantlr3
CPPFLAGS=-I$(COMPILERHOME) -I$(RMLHOME)/include/plain -I. -Iantlr-3.2/runtime/C -Iantlr-3.2/runtime/C/include
CC=gcc

all: libantlr3.a ModelicaLexer.c ModelicaParser.c ModelicaParser libomparse.a

libantlr3.a: antlr-3.2/runtime/C/src/* antlr-3.2/runtime/C/include/* 
	# build the library
	gcc -O3 -c antlr-3.2/runtime/C/src/*.c -Iantlr-3.2/runtime/C/include -Iantlr-3.2/runtime/C
	ar -ru libantlr3.a antlr3*.o
	ranlib libantlr3.a
	rm -f antlr3*.o

libomparse.a: parse.o ModelicaLexer.o ModelicaParser.o 
	ar -ru $@ parse.o ModelicaLexer.o ModelicaParser.o
	ranlib $@

ModelicaLexer.c ModelicaParser.c: Modelica.g
	$(ANTLRCMD) $<

ModelicaParser: libantlr3.a ModelicaLexer.o ModelicaParser.o main.o
	gcc -o $@ main.o ModelicaLexer.o ModelicaParser.o $(LDFLAGS) libantlr3.a

test: ModelicaParser
	sh -c "time ./Release/ModelicaParser -f FullModelica3.1.mo" 

clean:
	rm -f *.o *.a ModelicaParser.c ModelicaParser.h ModelicaLexer.c ModelicaLexer.h ModelicaParser \
	ModelicaParser.exe ./Release/ModelicaParser.exe ./Release/ModelicaParser
	
	 
