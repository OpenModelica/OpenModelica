ifdef OMDEV
CC = gcc
EXT=".exe"
endif

../../build/bin/omc-diff$(EXT): omc-diff.l
	flex omc-diff.l
	$(CC) -o $@ lex.yy.c
