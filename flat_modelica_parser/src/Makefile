CC=gcc
CXX=g++
AR=ar -r

ANTLR_HOME=/home/kaj/src/antlr-2.7.3

INCLUDES=-I/usr/local/include/  -I$(ANTLR_HOME)/lib/cpp -I$(MODELICAPARSER)

LIBP=-L$(ANTLR_HOME)/lib/cpp/src

CFLAGS =-g -Wall $(INCLUDES) -D DEBUG
CXXFLAGS = $(CFLAGS)

ANTLRFLAGS=

LIB = $(LIBP) -lantlr

MODELICAPARSER=../../modelica_parser/src

lexergen= $(MODELICAPARSER)/modelica_lexer.cpp $(MODELICAPARSER)/modelica_lexer.hpp

parsergen= flat_modelica_parser.cpp flat_modelica_parser.hpp \
	   flat_modelica_parserTokenTypes.hpp flat_modelica_parserTokenTypes.txt

parsersrcs=$(filter %.cpp,$(parsergen))

parserobjs=$(parsersrcs:.cpp=.o)

helperobjs = $(MODELICAPARSER)/token_names.o $(MODELICAPARSER)/parse_tree_dumper.o

OBJS +=  $(parserobjs) $(helperobjs)

all: libflat_modelica_parser.a

lexer: 
	cd $(MODELICAPARSER); make modelica_lexer; cd ../../flat_modelica_parser2/src

vctarget:  $(parsergen)

libflat_modelica_parser.a: $(OBJS)
	$(AR) $@ $(OBJS)


$(parsergen): flat_modelica_parser.g 
	java antlr.Tool $(ANTLRFLAGS) $<

.c.o:
	$(CC) $(CFLAGS) -c $<

.cpp.o:
	$(CXX) $(CXXFLAGS) -c $<

test: $(MODELICAPARSER)/modelica_lexer.o libflat_modelica_parser.a test.o
	$(CXX) -o test test.o libflat_modelica_parser.a $(MODELICAPARSER)/modelica_lexer.o $(LIB)


depend: $(DFILES)

clean:
	-rm -f test* *.o *~ core *.core libflat_modelica_parser.a

reallyclean: clean
	-rm -f $(parsergen)

flat_modelica_parser.o:flat_modelica_parser.cpp flat_modelica_parser.hpp

