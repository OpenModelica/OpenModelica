#
# PCCTS makefile for: modgram.g
#
# Created from: genmk -CC -class ModParse -trees -project m2o modgram.g
#
# PCCTS release 1.32
# Project: m2o
# C++ output
# DLG scanner
# ANTLR-defined token types
#
TOKENS = tokens.h
#
# The following filenames must be consistent with ANTLR/DLG flags
DLG_FILE = parser.dlg
ERR = err
HDR_FILE =
SCAN = DLGLexer
PCCTS = /home/pelab/pkg/pccts
ANTLR_H = $(PCCTS)/h
BIN = $(PCCTS)/bin
ANTLR = $(BIN)/antlr
DLG = $(BIN)/dlg
#CFLAGS = -ggdb -I. -I$(ANTLR_H) #does not work in linux
CFLAGS = -g -I. -I.. -I$(ANTLR_H)
AFLAGS = -CC -gt 
DFLAGS = -C2 -CC -cs
GRM = modgram.g
SRC = modgram.cpp \
      ModParse.cpp \
	modAST.cpp codegen.cpp ModParseToken.cpp modAST.h ModParseToken.h codegen.h comments.cpp comments.h \
      $(ANTLR_H)/AParser.cpp $(ANTLR_H)/DLexerBase.cpp \
      $(ANTLR_H)/ASTBase.cpp $(ANTLR_H)/PCCTSAST.cpp \
       $(ANTLR_H)/ATokenBuffer.cpp $(SCAN).cpp
OBJ = modgram.o \
      ModParse.o \
	modAST.o codegen.o ModParseToken.o comments.o \
       AParser.o DLexerBase.o \
      ASTBase.o PCCTSAST.o \
       ATokenBuffer.o $(SCAN).o
ANTLR_SPAWN = modgram.cpp ModParse.cpp \
              ModParse.h $(DLG_FILE) $(TOKENS)
DLG_SPAWN = $(SCAN).cpp $(SCAN).h
CCC=g++
CC=$(CCC)

libast.a : $(OBJ)
	ar -rc $@ $(OBJ)

modgram.o : $(TOKENS) $(SCAN).h modgram.cpp parser.h
	$(CCC) -c $(CFLAGS) -o modgram.o modgram.cpp

ModParse.o : $(TOKENS) $(SCAN).h ModParse.cpp ModParse.h
	$(CCC) -c $(CFLAGS) -o ModParse.o ModParse.cpp

modAST.o : modAST.cpp modAST.h
	$(CCC) -c $(CFLAGS) -o modAST.o modAST.cpp	

ModParseToken.o : ModParseToken.cpp ModParseToken.h
	$(CCC) -c $(CFLAGS) -o ModParseToken.o ModParseToken.cpp	

comments.o : comments.cpp comments.h
	$(CCC) -c $(CFLAGS) -o comments.o comments.cpp

codegen.o : codegen.cpp codegen.h comments.h
	$(CCC) -c $(CFLAGS) -o codegen.o codegen.cpp	

$(SCAN).o : $(SCAN).cpp $(TOKENS)
	$(CCC) -c $(CFLAGS) -o $(SCAN).o $(SCAN).cpp

$(ANTLR_SPAWN) : $(GRM)
	$(ANTLR) $(AFLAGS) $(GRM)

$(DLG_SPAWN) : $(DLG_FILE)
	$(DLG) $(DFLAGS) $(DLG_FILE)

AParser.o : $(ANTLR_H)/AParser.cpp
	$(CCC) -c $(CFLAGS) -o AParser.o $(ANTLR_H)/AParser.cpp

ATokenBuffer.o : $(ANTLR_H)/ATokenBuffer.cpp
	$(CCC) -c $(CFLAGS) -o ATokenBuffer.o $(ANTLR_H)/ATokenBuffer.cpp

DLexerBase.o : $(ANTLR_H)/DLexerBase.cpp
	$(CCC) -c $(CFLAGS) -o DLexerBase.o $(ANTLR_H)/DLexerBase.cpp

ASTBase.o : $(ANTLR_H)/ASTBase.cpp
	$(CCC) -c $(CFLAGS) -o ASTBase.o $(ANTLR_H)/ASTBase.cpp

PCCTSAST.o : $(ANTLR_H)/PCCTSAST.cpp
	$(CCC) -c $(CFLAGS) -o PCCTSAST.o $(ANTLR_H)/PCCTSAST.cpp


clean:
	rm -f *.o core libast.a

scrub:
	rm -f *.o core $(ANTLR_SPAWN) $(DLG_SPAWN)

install:
	cp mod2om5 ../../System
	cp mod2om5 $(HOME)/bin

linux:
	make PCCTS=$(HOME)/pccts


