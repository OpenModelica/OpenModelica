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

RMLINCLUDE = /home/pelab/pub/pkg/rml/current/sol2-sparc/include/plain

TOKENS = tokens.h
#
# The following filenames must be consistent with ANTLR/DLG flags
DLG_FILE = parser.dlg
ERR = err
HDR_FILE =
PCCTS = /home/pelab/pkg/pccts
ANTLR_H = $(PCCTS)/h
BIN = $(PCCTS)/bin
ANTLR = $(BIN)/antlr
DLG = $(BIN)/dlg
#CFLAGS = -ggdb -I. -I$(ANTLR_H) #does not work in linux
CFLAGS = -g -I. -I.. -I$(ANTLR_H) -I$(RMLINCLUDE)
#AFLAGS = -CC -gt 
#AFLAGS = -gt -gl
AFLAGS = -gt -gl -gh
#DFLAGS = -C2 -CC -cs
DFLAGS = -C2
GRM = modgram.g
SRC = modgram.c \
      scanner.c \
      err.c     \
      yacclib.c \
      attrib.c  \
      parsemod.c
OBJ = $(SRC:.c=.o)
ANTLR_SPAWN = modgram.c \
              $(DLG_FILE) $(TOKENS)
DLG_SPAWN = scanner.c mode.h
CCC=g++
#CC=gcc
CC=cc

libast.a : $(OBJ)
	ar -rc $@ $(OBJ)

.c.o:
	$(CC) -c $(CFLAGS) -o $@ $<

modgram.o: modgram.c attrib.h parser.h tokens.h \
	$(RMLINCLUDE)/rml.h ../dae.h ../exp.h ../types.h ../absyn.h mode.h
scanner.o: scanner.c attrib.h parser.h
err.o: err.c attrib.h parser.h tokens.h
yacclib.o: yacclib.c $(RMLINCLUDE)/rml.h yacclib.h
attrib.o: attrib.c attrib.h parser.h tokens.h mode.h stdpccts.h

$(SCAN).o : $(SCAN).c $(TOKENS)
	$(CC) -c $(CFLAGS) -o $(SCAN).o $(SCAN).c

$(ANTLR_SPAWN) : $(GRM)
	$(ANTLR) $(AFLAGS) $(GRM)

$(DLG_SPAWN) : $(DLG_FILE)
	$(DLG) $(DFLAGS) $(DLG_FILE) > scanner.c

AParser.o : $(ANTLR_H)/AParser.c
	$(CC) -c $(CFLAGS) -o AParser.o $(ANTLR_H)/AParser.c

ATokenBuffer.o : $(ANTLR_H)/ATokenBuffer.c
	$(CC) -c $(CFLAGS) -o ATokenBuffer.o $(ANTLR_H)/ATokenBuffer.c

DLexerBase.o : $(ANTLR_H)/DLexerBase.c
	$(CC) -c $(CFLAGS) -o DLexerBase.o $(ANTLR_H)/DLexerBase.c

ASTBase.o : $(ANTLR_H)/ASTBase.c
	$(CC) -c $(CFLAGS) -o ASTBase.o $(ANTLR_H)/ASTBase.c

PCCTSAST.o : $(ANTLR_H)/PCCTSAST.c
	$(CC) -c $(CFLAGS) -o PCCTSAST.o $(ANTLR_H)/PCCTSAST.c

depend:
	gcc -MM $(CFLAGS) $(SRC)

clean:
	$(RM) -f *.o core libast.a $(ANTLR_SPAWN) $(DLG_SPAWN)
