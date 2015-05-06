ifdef OMDEV
CC = gcc
EXT=".exe"
endif

OMBUILDDIR=../../build

$(OMBUILDDIR)/bin/omc-diff$(EXT): lex.yy.o
	$(CC) -o $@ lex.yy.o
lex.yy.c: omc-diff.l
	flex omc-diff.l
