ifdef OMDEV
CC = gcc
EXT=.exe
endif
ifdef WSL_DISTRO_NAME
OBJ=.wsl.o
else
OBJ=.o
endif

OMBUILDDIR=../../build

$(OMBUILDDIR)/bin/omc-diff$(EXT): lex.yy$(OBJ) $(OMBUILDDIR)/bin
	$(CC) -o $@ lex.yy$(OBJ)
lex.yy.wsl.c: lex.yy.c
	cp "$<" "$@"
lex.yy.c: omc-diff.l
	flex omc-diff.l
$(OMBUILDDIR)/bin:
	mkdir -p "$@"
clean:
	rm -f $(OMBUILDDIR)/bin/omc-diff$(EXT) lex.yy.c lex.yy$(OBJ)
