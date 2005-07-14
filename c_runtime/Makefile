CC = gcc
FC = g77
AR = ar -ru 
CFLAGS = -O2 -Wall -ansi -pedantic -I../mosh/src/
CPPFLAGS = $(CFLAGS)
FFLAGS  = -O
# P.A: before, g77 had -O3 or -O2 but that caused a bug in DDASRT, giving infinite loop.

FSRCS = daux.f \
          ddasrt.f \
          ddassl.f \
          dlamch.f \
          dlinpk.f \
          lsame.f \
          dogleg.f \
          dpmpar.f \
	  enorm.f \
	  fdjac1.f \
	hybrd1.f \
	  hybrd.f \
	  hybrj.f \
	  qform.f \
	  qrfac.f \
	  r1mpyq.f \
	  r1updt.f 

FOBJS = $(patsubst %.f,%.o,$(FSRCS))

OBJS = $(FOBJS) boolean_array.o index_spec.o integer_array.o memory_pool.o \
	real_array.o string_array.o read_write.o utility.o modelica_string.o 
SIMOBJS = $(FOBJS) simulation_runtime.o ../mosh/src/options.o dgesv_aux.o 

all : libc_runtime.a libsim.a libf2c.a

libc_runtime.a : $(OBJS) 
	$(AR) $@ $(OBJS) 

libsim.a : $(SIMOBJS)
	$(AR) $@ $(SIMOBJS)

libf2c.a :
	cd libf2c && $(MAKE) -f makefile.u 

clean :
	cd ./libf2c && $(MAKE) -f makefile.u clean
	rm -f libc_runtime.a
	rm -f libsim.a
	rm -f $(OBJS)
	rm -f $(SIMOBJS)
