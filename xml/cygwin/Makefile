CC=gcc -Wall
CXX=g++ -Wall

ANTLR_HOME = "./antlr-2.7.2/lib/cpp/"

ANTLR_INCP = -I"./antlr-2.7.2/lib/cpp"
ANTLR_LIBP = -L"./lib" -L"./xercesc/lib/"

PARSE_INCP = -I"./":"./xercesc/include"
PARSE_LIBP = -L./

CP="./antlr-2.7.2/antlr.jar"

INCP = $(ANTLR_INCP) $(PARSE_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP)

CFLAGS = $(INCP) -g -Wall -DDEBUG -fpic -w -O -DAPP_NO_THREADS -DXML_USE_NO_THREADS
CXXFLAGS = $(CFLAGS)
LINKFLAGS = $(LIBP)

LIBS = -lantlr -lmodelica_parser -lxerces-c_2

PARSER_OBJS = modelica_parser.o modelica_lexer.o token_names.o parse_tree_dumper.o

walkergen= modelica_tree_parser.cpp modelica_tree_parser.hpp \
	   modelica_tree_parserTokenTypes.hpp modelica_tree_parserTokenTypes.txt

walkersrcs=$(filter %.cpp,$(walkergen))
walkerobjs=$(walkersrcs:.cpp=.o)

OBJS += $(walkerobjs) walker.o $(PARSER_OBJS) 
#OBJS += $(walkerobjs)  $(PARSER_OBJS) 

ANTLR = java -cp $(ANTLR_HOME) antlr.Tool

all : parser walker

parser:
	$(MAKE) -f Makefile_parser

walker : $(OBJS) 
	$(CXX) -o modelicaxml $(OBJS) $(LINKFLAGS) $(LIBS) 

$(walkergen): walker.g modelica_parserTokenTypes.txt
	java -cp $(CP) antlr.Tool $(ANTLRFLAGS) $<


clean:
	rm -f modelicaxml modelicaxml.exe *.o *.obj *~ core *.core 

reallyclean: clean
	rm -f $(walkergen) modelica_parserTokenTypes.txt
	$(MAKE) -f Makefile_parser reallyclean


walker.o : walker.cpp modelica_lexer.hpp modelica_parser.hpp

walker.cpp : ModelicaXML.cpp
	cp ModelicaXML.cpp walker.cpp
