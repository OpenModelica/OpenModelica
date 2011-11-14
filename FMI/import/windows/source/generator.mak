# Project: Code Generator for FMU Import to OpenModelica 1.7.0
# Author: Wuzhu Chen, TU-Clausthal

#CPP  = g++.exe
CC   = gcc
RES  = 
OBJS  = xmlparser.o stack.o fmuWrapper.o moGenerator.o$(RES)
LINKOBJS  = xmlparser.o stack.o fmuWrapper.o moGenerator.o $(RES)
LIBS =  -L"/mingw/lib" -lexpat
INCS =  -I"/mingw/include"	
CXXINCS =  -I"../include/"	-I"/mingw/msys/1.0/include/" 
BIN  = ../bin/generator.exe
CXXFLAGS = $(CXXINCS)  
CFLAGS = $(INCS)  
RM = rm -f

.PHONY: all all-before all-after clean clean-custom

all: all-before $(BIN) all-after


clean: clean-custom
	${RM} $(OBJS) $(BIN)

$(BIN): $(OBJS)
	$(CC) -Wall -o $(BIN) $(LINKOBJS) $(LIBS)
	
moGenerator.o: moGenerator.c
	$(CC) -Wall -c moGenerator.c -o moGenerator.o $(INCS)
	
fmuWrapper.o: fmuWrapper.c
	$(CC) -Wall -c fmuWrapper.c -o fmuWrapper.o $(INCS)
	
xmlparser.o: xmlparser.c
	$(CC) -Wall -c xmlparser.c -o xmlparser.o $(INCS)
	
stack.o: stack.c
	$(CC) -Wall -c stack.c -o stack.o $(INCS)