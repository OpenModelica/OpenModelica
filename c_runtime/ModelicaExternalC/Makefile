
OBJS = ModelicaExternalC.o ../*.o
AR = ar -ru

all: libModelicaExternalC.a

libModelicaExternalC.a : $(OBJS)
	$(AR) $@ $(OBJS)
	ranlib $@

ModelicaExternalC.o : ModelicaExternalC.cpp
	g++ -O3 -c ModelicaExternalC.cpp -o ModelicaExternalC.o

clean:
	rm -f libModelicaExternalC.a $(OBJS)
