RMLHOME=/home/x05emica/utils/rml/rml-2.2/x86-linux-gcc/
CC = gcc -g
LD = gcc -g
RML=${RMLHOME}/bin/rmlc 
CCFLAGS=-I${RMLHOME}/include/plain/ 
LDFLAGS=-L${RMLHOME}/lib/plain/ -lrml 

all: ptest

build: parser.o lexer.o yacclib.o absyn.o rmldump.o

parser.o parser.h: parser.y absyn.h 
	bison -t -d -v --output-file="parser.c" parser.y
	$(CC) $(CCFLAGS) -c parser.c

lexer.o: lexer.c parser.h 
	$(CC) -c lexer.c

yacclib.o: yacclib.c yacclib.h
	$(CC) $(CCFLAGS) -c yacclib.c

rmldump.h rmldump.c:rmldump.rml absyn.h
	$(RML) -g -c rmldump.rml

rmldump.o: rmldump.c rmldump.h absyn.h
	$(RML) -c rmldump.c

rmlrefactor.h rmlrefactor.c:rmlrefactor.rml absyn.h
	$(RML) -g -c rmlrefactor.rml

rmlrefactor.o: rmlrefactor.c rmldump.h absyn.h
	$(RML) -c rmlrefactor.c

absyn.h absyn.c: absyn.rml
	$(RML) -g -c absyn.rml

absyn.o: absyn.c absyn.h
	$(CC) -c absyn.c

scanparse.o: scanparse.c absyn.h
	$(RML) -c scanparse.c

main.c main.h: main.rml scanparse.o
	$(RML) -g -c main.rml

main.o: main.c main.h scanparse.o rmldump.h rmldump.o rmlrefactor.h rmlrefactor.o parser.o yacclib.o lexer.o
	$(RML) -c main.c `ls *.o`

ptest: main.o
	$(RML) -g -o ptest `ls *.o`

clean:
	rm -f *~ *.o *.rdb scanparse.h main.h main.c ptpest parser.h \
		parser.c rmldump.h rmldump.c absyn.h absyn.c \
		rmlrefactor.h rmlrefactor.c ptest 
