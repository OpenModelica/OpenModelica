CC = gcc
FC = g77
AR = ar -ru
CFLAGS = -O3 -Wall -ansi -pedantic -I../mosh/src/
CPPFLAGS = $(CFLAGS)
FFLAGS  = -O3

FSRCS = daux.f \
          ddasrt.f \
          ddassl.f \
          dlamch.f \
          dlinpk.f \
          lsame.f
FOBJS = $(patsubst %.f,%.o,$(FSRCS))

OBJS = $(FOBJS) boolean_array.o index_spec.o integer_array.o memory_pool.o \
	real_array.o string_array.o read_write.o utility.o modelica_string.o 
SIMOBJS = $(FOBJS) simulation_runtime.o ../mosh/src/options.o

all : libc_runtime.a libsim.a


libc_runtime.a : $(OBJS) 
	$(AR) $@ $(OBJS) 
libsim.a : $(SIMOBJS)
	$(AR) $@ $(SIMOBJS)

clean :
	rm -f libc_runtime.a
	rm -f libsim.a
	rm -f $(OBJS)
	rm -f $(SIMOBJS)
