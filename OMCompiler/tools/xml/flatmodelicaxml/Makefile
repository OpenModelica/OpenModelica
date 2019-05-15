CXX=g++
JAVA=java

ANTLRFLAGS =
ANTLR_HOME = /home/pelab/pub/pkg/antlr-2.7.1
ANTLR_CP= $(ANTLR_HOME)/classes/jdk13

ANTLR_INCP = -I$(ANTLR_HOME)/lib/cpp
ANTLR_LIBP = -L$(ANTLR_HOME)/lib/cpp/gcc-2.95.2/lib

PARSE_HOME = ..
PARSE_INCP = -I$(PARSE_HOME)/src
PARSE_LIBP = -L$(PARSE_HOME)/src

INCP = $(ANTLR_INCP) $(PARSE_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP)

CFLAGS = $(INCP) -g -Wall
CXXFLAGS = $(CFLAGS)

LIBS = -lantlr

ANTLR = $(JAVA) -cp $(ANTLR_CP) antlr.Tool

all : cpp modSimPackTest

tmp : walker modSimPackTest

test : modSimPackTest

modSimPackTest : flat_modelica_lexer.o flat_modelica_parser.o \
	flat_modelica_tree_parser.o parse_tree_dumper.o
	$(CXX) $(CXXFLAGS) -o modSimPackTest modSimPackTest.cc $(LIBP) \
	flat_modelica_lexer.o flat_modelica_parser.o flat_modelica_tree_parser.o \
	parse_tree_dumper.o $(LIBS)

cpp : lexer parser walker

lexer:  flat_modelica_lexer.g
	$(ANTLR) flat_modelica_lexer.g $(ANTLRFLAGS)

parser: flat_modelica_parser.g
	$(ANTLR) flat_modelica_parser.g $(ANTLRFLAGS)

walker: walker.g
	$(ANTLR) walker.g $(ANTLRFLAGS)


flat_modelica_parserTokenTypes.txt:

flat_modelica_lexer.o : flat_modelica_lexer.cpp flat_modelica_lexer.hpp
	$(CXX) $(CXXFLAGS) -c flat_modelica_lexer.cpp

flat_modelica_parser.o : flat_modelica_parser.cpp flat_modelica_lexer.hpp \
	flat_modelica_parser.hpp flat_modelica_parserTokenTypes.txt
	$(CXX) $(CXXFLAGS) -c flat_modelica_parser.cpp

flat_modelica_tree_parser.o : flat_modelica_tree_parser.cpp flat_modelica_lexer.hpp \
	flat_modelica_parser.hpp
	$(CXX) $(CXXFLAGS) -c flat_modelica_tree_parser.cpp

parse_tree_dumper.o : parse_tree_dumper.cpp parse_tree_dumper.hpp
	$(CXX) $(CXXFLAGS) -c parse_tree_dumper.cpp


clean:
	-rm -f *.o *~ core *.core absyn_builder.a
	-rm -f $(walkergen) flat_modelica_parserTokenTypes.txt

reallyclean: clean
	-rm -r *.hpp *.cpp
