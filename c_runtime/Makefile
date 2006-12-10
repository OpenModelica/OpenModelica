top_builddir = ..
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib
builddir_inc=$(top_builddir)/build/include

CC = gcc
FC = g77
AR = ar -ru 
CFLAGS = -O1 -Wall -ansi -pedantic -I$(top_builddir)/mosh/src/ $(EXTRA_CFLAGS)
CPPFLAGS = $(CFLAGS)
FFLAGS  = -O
# P.A: before, g77 had -O3 or -O2 but that caused a bug in DDASRT, giving infinite loop.
# Adrian Pop, adrpo@ida.liu.se
# - please leave makefile.u as if you don't it breaks the compilation on UNIX/LINUX
# - use make -f Makefile.omdev.mingw if you want to compile on MinGW


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
	r1updt.f \
	nelmead.f \
	newuoa.f \
	newuob.f \
	biglag.f \
	bigden.f \
	trsapp.f \
	update.f

FOBJS = $(patsubst %.f,%.o,$(FSRCS))

OBJS = $(FOBJS) boolean_array.o index_spec.o integer_array.o memory_pool.o \
	real_array.o string_array.o read_write.o utility.o modelica_string.o $(EXTRA_OBJS)
SIMOBJS = $(FOBJS) simulation_runtime.o simulation_init.o simulation_input.o simulation_events.o \
solver_dasrt.o solver_euler.o simulation_result.o ../mosh/src/options.o dgesv_aux.o $(EXTRA_SIMOBJS)

HFILES = blaswrap.h f2c.h integer_array.h memory_pool.h modelica_string.h \
	real_array.h string_array.h boolean_array.h index_spec.h matrix.h \
	modelica.h read_write.h simulation_runtime.h simulation_events.h utility.h \
	simulation_init.h simulation_input.h solver_dasrt.h solver_euler.h simulation_result.h

LIBS = libc_runtime.a libsim.a 


all : libc_runtime.a libsim.a libf2c.a install

libc_runtime.a : $(OBJS)
	$(AR) $@ $(OBJS)


install: libc_runtime.a libsim.a libf2c/libf2c.a
	cp $(HFILES) $(builddir_inc)/
	cp $(LIBS) $(builddir_lib)/
	cp libf2c/libf2c.* $(builddir_lib)/

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
	rm -f $(builddir_lib)/libc_runtime.a
	rm -f $(builddir_lib)/libsim.a
	rm -f $(builddir_lib)/libf2c.*
	cd $(builddir_inc)/ && rm -f $(HFILES)

