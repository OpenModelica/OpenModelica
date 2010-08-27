RMLHOME=/usr
COMPILERHOME=../Compiler/
LIBRML=-lrml -lm
ANTLRCMD=java -cp ./antlr-3.2/lib/antlr-3.2.jar org.antlr.Tool -report

all: libantlr3.a ModelicaLexer.c ModelicaParser.c ModelicaParser

libantlr3.a: antlr-3.2/runtime/C/src/* antlr-3.2/runtime/C/include/* 
	# build the library
	gcc -O3 -c antlr-3.2/runtime/C/src/*.c -Iantlr-3.2/runtime/C/include -Iantlr-3.2/runtime/C
	ar -ru libantlr3.a *.o
	ranlib libantlr3.a
	rm -f *.o

ModelicaLexer.c ModelicaParser.c: Modelica.g
	$(ANTLRCMD) $<

ModelicaParser: libantlr3.a ModelicaLexer.c ModelicaParser.c
	gcc -O3 -o ModelicaParser *.c -I$(COMPILERHOME) -L$(RMLHOME)/lib/plain/ $(LIBRML) -I$(RMLHOME)/include/plain -I. -Iantlr-3.2/runtime/C -Iantlr-3.2/runtime/C/include -L. -lantlr3
	mkdir -p Release
	cp -f ModelicaParser Release/ModelicaParser
	
test: ModelicaParser
	sh -c "time ./Release/ModelicaParser -f FullModelica3.1.mo" 

clean:
	rm -f *.o *.a ModelicaParser.c ModelicaParser.h ModelicaLexer.c ModelicaLexer.h ModelicaParser \
	ModelicaParser.exe ./Release/ModelicaParser.exe ./Release/ModelicaParser
	
	 
