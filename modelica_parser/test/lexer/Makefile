CC=gcc
CXX=g++

ANTLR_HOME = /home/pelab/pub/pkg/antlr-2.7.1
ANTLR_CPP = $(ANTLR_HOME)/lib/cpp/gcc-2.95.2

ANTLR_INCP = -I$(ANTLR_CPP)/include
ANTLR_LIBP = -L$(ANTLR_CPP)/lib

PARSE_INCP = -I../../src
PARSE_LIBP = -L../../src

INCP = $(ANTLR_INCP) $(PARSE_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP)

CFLAGS = $(INCP) -g -Wall -DDEBUG
CXXFLAGS = $(CFLAGS)
LINKFLAGS = $(LIBP)

LIBS = -lantlr -lmodelica_parser

PARSER_OBJS = ../../src/modelica_parser.o ../../src/modelica_lexer.o ../../src/token_names.o ../../src/parse_tree_dumper.o
OBJS = test_lexer.o $(PARSER_OBJS)

ANTLR = java -cp $(ANTLR_HOME) antlr.Tool

all : parser test_lexer modelicaTokenTypes.txt

parser:
	cd ../../src; $(MAKE) -f Makefile

test_lexer : $(OBJS) 
	$(CXX) -o $@ $(OBJS) $(LINKFLAGS) $(LIBS) 



modelicaTokenTypes.txt : ../../src/modelicaTokenTypes.txt
	cp ../../src/modelicaTokenTypes.txt .

clean:
	-rm -f *.o modelicaTokenTypes.txt *~ test_lexer


test_lexer.o : test_lexer.cpp ../../src/modelica_lexer.hpp ../../src/token_names.hpp


