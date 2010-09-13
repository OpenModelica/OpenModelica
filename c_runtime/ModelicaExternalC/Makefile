CC = gcc
CFLAGS := $(CFLAGS) -O3 -I..
OBJS = ModelicaInternal.o ModelicaStrings.o ModelicaTablesImpl.o 
AR = ar -ru

all: libModelicaExternalC.a

libModelicaExternalC.a : $(OBJS)
	$(AR) $@ $(OBJS)
	ranlib $@

%.o: %.c
	$(CC) $(CFLAGS) -c $^

clean:
	rm -f libModelicaExternalC.a $(OBJS)
