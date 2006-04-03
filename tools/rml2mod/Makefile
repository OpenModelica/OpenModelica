## RMLHOME=/home/x05emica/utils/rml/rml-2.2/x86-linux-gcc/ 
SHELL =/bin/sh
RMLHOME=/c/OMDEV/tools/rml/
#RMLHOME=/c/bin/cygwin/home/adrpo/rml-2.3.0/x86-mingw32-gcc
#RMLHOME=/c/bin/cygwin/home/adrpo/rml-2.3.0/x86-cygwin-gcc
#RMLHOME=/c/dev/rml/rml-mmc-2.3.3-cygwin-mingw/x86-cygwin-gcc
CC = gcc #-g
LD = gcc #-g
RML=${RMLHOME}/bin/rmlc #-Wr,-ftrace #-Wc,-g
CCFLAGS=-I${RMLHOME}/include/plain/ 
LDFLAGS=-L${RMLHOME}/lib/plain/ -lrml 

all: rml2mod

build: parser.o lexer.o yacclib.o absyn.o rmldump.o \
	rmlrefactor.o rmltomod.o moddump.o modrefactor.o extern.o lookup.o rml-db-parse.o rml-db-scan.o loadprogramdb.o

parser.o parser.h: parser.y absyn.h defs.h
	bison -t -d -v --output-file="parser.c" parser.y
	$(CC) $(CCFLAGS) -c parser.c

lexer.o: lexer.c parser.h defs.h
	$(CC) -c lexer.c

yacclib.o: yacclib.c yacclib.h
	$(CC) $(CCFLAGS) -c yacclib.c

rmldump.h rmldump.c:rmldump.rml absyn.h
	$(RML)  -c rmldump.rml

rmldump.o: rmldump.c rmldump.h absyn.h
	$(RML) -c rmldump.c

rmlrefactor.h rmlrefactor.c:rmlrefactor.rml absyn.h
	$(RML)  -c rmlrefactor.rml

rmlrefactor.o: rmlrefactor.c  absyn.h
	$(RML) -c rmlrefactor.c

rmltomod.h rmltomod.c:rmltomod.rml absyn.h
	$(RML)  -c rmltomod.rml

rmltomod.o: rmltomod.c  absyn.h
	$(RML) -c rmltomod.c

modrefactor.h modrefactor.c:modrefactor.rml absyn.h
	$(RML)  -c modrefactor.rml

modrefactor.o: modrefactor.c absyn.h 
	$(RML) -c modrefactor.c
	
modrefactortypes.h modrefactortypes.c:modrefactortypes.rml absyn.h
	$(RML)  -c modrefactortypes.rml

modrefactortypes.o: modrefactortypes.c absyn.h 
	$(RML) -c modrefactortypes.c

moddump.h moddump.c:moddump.rml absyn.h
	$(RML)  -c moddump.rml

moddump.o: moddump.c absyn.h 
	$(RML) -c moddump.c

lookup.h lookup.c:lookup.rml absyn.h
	$(RML)  -c lookup.rml

lookup.o: lookup.c absyn.h 
	$(RML) -c lookup.c

dictionary.h dictionary.c:dictionary.rml absyn.h
	$(RML)  -c dictionary.rml

dictionary.o: dictionary.c absyn.h 
	$(RML) -c dictionary.c

util.h util.c:util.rml 
	$(RML)  -c util.rml

util.o: util.c  
	$(RML) -c util.c

#print.h print.c:print.rml 
#	$(RML) -g -c print.rml

#print.o: print.c print.h 
#	$(RML) -c print.o

absyn.h absyn.c: absyn.rml
	$(RML)  -c absyn.rml

absyn.o: absyn.c absyn.h
	$(CC) -c absyn.c

scanparse.o: scanparse.c absyn.h
	$(RML) -c scanparse.c

rml-db-parse.c rml-db-parse.h: rml-db-parse.y
	bison -p yyrmldb --defines --output-file=rml-db-parse.c rml-db-parse.y

rml-db-scan.c: rml-db-scan.l rml-db-parse.h
	flex -Pyyrmldb rml-db-scan.l

rml-db-scan.o: rml-db-scan.c rml-db-parse.h
	$(CC) $(CCFLAGS) -c rml-db-scan.c

rml-db-parse.o: rml-db-parse.c rml-db-scan.o
	$(CC) $(CCFLAGS) -c rml-db-parse.c

loadprogramdb.o: loadprogramdb.c absyn.h rml-db-parse.h
	$(RML) -c loadprogramdb.c

external.o: external.c 
	$(RML) -c external.c

main.c main.h: main.rml scanparse.o loadprogramdb.o rml-db-parse.o
	$(RML)  -c main.rml

main.o: main.c main.h scanparse.o rmldump.h rmldump.o rmlrefactor.h rmlrefactor.o \
	rmltomod.h  rmltomod.o moddump.h moddump.o modrefactor.h modrefactor.o \
		modrefactortypes.h modrefactortypes.o parser.o yacclib.o lexer.o \
        rml-db-parse.o rml-db-scan.o loadprogramdb.o util.o external.o lookup.h lookup.o \
        dictionary.h dictionary.o
	$(RML) -c main.c `ls *.o`

rml2mod: main.o
	$(RML) -o rml2mod `ls *.o` 

clean:
	rm -f *~ *.o *.rdb scanparse.h main.h main.c ptpest parser.h \
		parser.c rmldump.h rmldump.c absyn.h absyn.c \
		rmlrefactor.h rmlrefactor.c rmltomod.h rmltomod.c \
		moddump.h moddump.c rml2mod rml-db-*.c rml-db-*.h \
		loadprogramdb.h util.h util.c external.h modrefactor.h modrefactor.c
