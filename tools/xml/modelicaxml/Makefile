CC=gcc
CXX=g++

ANTLR_HOME = /home/adrpo/dev/antlr-2.7.6

ANTLR_INCP = -I${ANTLR_HOME}/lib/cpp
ANTLR_LIBP = -L${ANTLR_HOME}/lib/cpp/src

XERCESC_HOME = /home/adrpo/dev/xercesc
XERCESC_INCP = -I${XERCESC_HOME}/include
XERCESC_LIBP = -L${XERCESC_HOME}/lib


PARSE_INCP = -I"./" ${ANTLR_INCP} ${XERCESC_INCP}
PARSE_LIBP = -L"./" ${ANTLR_LIBP} ${XERCESC_LIBP}

INCP = $(ANTLR_INCP) $(PARSE_INCP)
LIBP = $(ANTLR_LIBP) $(PARSE_LIBP)

CFLAGS = $(INCP) -g -Wall -DDEBUG -fpic -w -O -DAPP_NO_THREADS -DXML_USE_NO_THREADS
CXXFLAGS = $(CFLAGS)
LINKFLAGS = $(LIBP)

LIBS = -lantlr -lmodelica_parser -lxerces-c

DIRWALK_OBJS = dirwalk.o

PARSER_OBJS = modelica_parser.o modelica_lexer.o token_names.o parse_tree_dumper.o

walkergen= modelica_tree_parser.cpp modelica_tree_parser.hpp \
	   modelica_tree_parserTokenTypes.hpp modelica_tree_parserTokenTypes.txt

walkersrcs=$(filter %.cpp,$(walkergen))
walkerobjs=$(walkersrcs:.cpp=.o)

OBJS += $(walkerobjs) $(PARSER_OBJS) $(DIRWALK_OBJS)

ANTLR = java -cp $(ANTLR_HOME) antlr.Tool

all : parser main

parser:
	$(MAKE) -f Makefile_parser

$(walkergen): walker.g modelica_parserTokenTypes.txt
	java antlr.Tool $(ANTLRFLAGS) $<

dirwalk.o: dirwalk.cpp dirwalk.h

main: $(OBJS) 
	$(CXX) ModelicaXML.cpp -o modelicaxml $(OBJS) $(LINKFLAGS) $(LIBS) ${INCP}

clean:
	rm -f modelicaxml modelicaxml.exe *.o *.obj *~ core *.core 

reallyclean: clean
	rm -f $(walkergen) modelica_parserTokenTypes.txt
	$(MAKE) -f Makefile_parser reallyclean




