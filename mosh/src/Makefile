CC=gcc
CXX=g++

ANTLR_HOME = /home/pelab/pub/pkg/antlr-2.7.1
ANTLR_CPP = $(ANTLR_HOME)/lib/cpp/gcc-2.95.2

ANTLR_INCP = -I$(ANTLR_CPP)/include
ANTLR_LIBP = -L$(ANTLR_CPP)/lib

PARSE_INCP = -I../../modelica_parser/src
PARSE_LIBP = -L../../modelica_parser/src

READLINE_INCP = -I /home/pelab/pkg/gnu/include
READLINE_LIBP = -L /home/pelab/pkg/gnu/lib

INCP = $(ANTLR_INCP) $(PARSE_INCP) $(READLINE_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP) $(READLINE_LIBP)

CFLAGS = $(INCP) -g -Wall -DDEBUG
CXXFLAGS = $(CFLAGS)
LINKFLAGS = $(LIBP)

LIBS = -lantlr -lmodelica_parser -lreadline -ltermcap

PARSER_OBJS = ../../modelica_parser/src/modelica_lexer.o ../../modelica_parser/src/token_names.o ../../modelica_parser/src/parse_tree_dumper.o

HELPER_OBJS = value.o symboltable.o builtin_function.o \
		modelica_function.o compiled_function.o function_argument.o

parsergen= modelica_expression_parser.cpp modelica_expression_parser.hpp \
	   modelica_expression_parserTokenTypes.hpp modelica_expression_parserTokenTypes.txt

walkergen= modelica_tree_parser.cpp modelica_tree_parser.hpp \
	   modelica_tree_parserTokenTypes.hpp modelica_tree_parserTokenTypes.txt

parsersrcs=$(filter %.cpp,$(parsergen))
parserobjs=$(parsersrcs:.cpp=.o)

walkersrcs=$(filter %.cpp,$(walkergen))
walkerobjs=$(walkersrcs:.cpp=.o)

OBJS += $(parserobjs) $(walkerobjs) $(HELPER_OBJS) mosh.o $(PARSER_OBJS) 

ANTLR = java -cp $(ANTLR_HOME) antlr.Tool

all : parser mosh

parser:
	cd ../../modelica_parser/src; $(MAKE) -f Makefile

mosh : $(OBJS) 
	$(CXX) -o $@ $(OBJS) $(LINKFLAGS) $(LIBS)

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $<

$(parsergen): expandedexpression_parser.g
	java antlr.Tool $(ANTLRFLAGS) expandedexpression_parser.g

$(walkergen): walker.g modelica_expression_parserTokenTypes.txt
	java antlr.Tool $(ANTLRFLAGS) walker.g
#$<

expandedexpression_parser.g: expression_parser.g
	java antlr.Tool -glib ../../modelica_parser/src/modelica_parser.g expression_parser.g

#modelica_parserTokenTypes.txt : ../../src/modelica_parserTokenTypes.txt
#	cp ../../src/modelica_parserTokenTypes.txt .


clean:
	-rm -f *.o *~ core *.core mosh

reallyclean: clean
	-rm -f $(parsergen) $(walkergen) modelica_expression_parserTokenTypes.txt expandedexpression_parser.g modelica_parserTokenTypes.txt


mosh.o : mosh.cpp ../../modelica_parser/src/modelica_lexer.hpp ../../modelica_parser/src/modelica_parser.hpp

