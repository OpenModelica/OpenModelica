top_builddir = ..
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib
builddir_inc=$(top_builddir)/build/include

CC = gcc
FC = g77
AR = ar -ru 
CFLAGS = -g -Wall -ansi -pedantic -I$(top_builddir)/mosh/src/ $(EXTRA_CFLAGS)
CPPFLAGS = $(CFLAGS)
FFLAGS  = -O
# P.A: before, g77 had -O3 or -O2 but that caused a bug in DDASRT, giving infinite loop.
OSTYP = $(OSTYPE)
OS_MSYS=msys


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
SIMOBJS = $(FOBJS) simulation_runtime.o ../mosh/src/options.o dgesv_aux.o 

HFILES = blaswrap.h f2c.h integer_array.h memory_pool.h modelica_string.h \
	real_array.h string_array.h boolean_array.h index_spec.h matrix.h \
	modelica.h read_write.h simulation_runtime.h utility.h

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
ifeq ($(OSTYP),$(OS_MSYS))
	cd libf2c && $(MAKE) -f makefile.mingw
else
	cd libf2c && $(MAKE) -f makefile.u
endif


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

