CC=gcc
CXX=g++

ANTLR_HOME = /home/pelab/pub/pkg/antlr-2.7.1
ANTLR_CPP = $(ANTLR_HOME)/lib/cpp/gcc-2.95.2

ANTLR_INCP = -I$(ANTLR_CPP)/include
ANTLR_LIBP = -L$(ANTLR_CPP)/lib

RML_HOME =  /home/pelab/pub/pkg/rml/current
RML_INCP = -I$(RML_HOME)/sparc-sol2-gcc/include/plain

PARSE_HOME = ../../modelica_parser
PARSE_INCP = -I$(PARSE_HOME)/src
PARSE_LIBP = -L$(PARSE_HOME)/src

INCP = $(ANTLR_INCP) $(PARSE_INCP) $(RML_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP)

CFLAGS = $(INCP) -g -Wall
CXXFLAGS = $(CFLAGS)
LINKFLAGS = $(LIBP)

LIBS = -lantlr -lmodelica_parser

PARSER_OBJS = $(PARSE_HOME)/src/modelica_parser.o $(PARSE_HOME)/src/modelica_lexer.o \
	$(PARSE_HOME)/src/token_names.o $(PARSE_HOME)/src/parse_tree_dumper.o


walkergen= modelica_tree_parser.cpp modelica_tree_parser.hpp \
	   modelica_tree_parserTokenTypes.hpp modelica_tree_parserTokenTypes.txt

walkersrcs=$(filter %.cpp,$(walkergen))
walkerobjs=$(walkersrcs:.cpp=.o)

OBJS += $(walkerobjs) $(PARSER_OBJS) parse.o yacclib.o

ANTLR = java -cp $(ANTLR_HOME) antlr.Tool

all : parser absyn_builder.a


parser:
	cd $(PARSE_HOME)/src; $(MAKE) -f Makefile

absyn_builder.a : $(OBJS)
	ar -r $@ $(OBJS)

#walker : $(OBJS) 
#	$(CXX) -o $@ $(OBJS) $(LINKFLAGS) $(LIBS) 

$(walkergen): walker.g modelica_parserTokenTypes.txt
	java antlr.Tool $(ANTLRFLAGS) $<


modelica_parserTokenTypes.txt : $(PARSE_HOME)/src/modelica_parserTokenTypes.txt
	cp $(PARSE_HOME)/src/modelica_parserTokenTypes.txt .

clean:
	-rm -f *.o *~ core *.core walker absyn_builder.a
	-rm -f $(walkergen) modelica_parserTokenTypes.txt

reallyclean: clean



walker.o : walker.cpp $(PARSE_HOME)/src/modelica_lexer.hpp $(PARSE_HOME)/src/modelica_parser.hpp


