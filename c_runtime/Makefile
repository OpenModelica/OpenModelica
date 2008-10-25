top_builddir = ..
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib
builddir_inc=$(top_builddir)/build/include

CC = gcc
FC = g77
AR = ar -ru
UNAME := $(shell uname -m)
CMDFPUFLAGS := `case ${UNAME} in i[3456]86) echo "-msse2 -mfpmath=sse";; x86_64) echo "-msse2 -mfpmath=sse";; *) echo "";; esac`
FPUFLAGS := ${CMDFPUFLAGS}
CFLAGS = -Wall -O3 ${FPUFLAGS} -fexceptions -ansi -pedantic -I. $(EXTRA_CFLAGS)
CPPFLAGS = $(CFLAGS)
FFLAGS  = -O -fexceptions
# P.A: before, g77 had -O3 or -O2 but that caused a bug in DDASRT, giving infinite loop.
# Adrian Pop, adrpo@ida.liu.se
# - please leave makefile.u as if you don't it breaks the compilation on UNIX/LINUX
# - use make -f Makefile.omdev.mingw if you want to compile on MinGW

OBJS = $(FOBJS) boolean_array.o index_spec.o integer_array.o memory_pool.o \
base_array.o real_array.o string_array.o read_write.o utility.o \
modelica_string.o bigden.o \
ddasrt.o  dlinpk.o  enorm.o   hybrd1.o  nelmead.o  qform.o   r1updt.o \
biglag.o  ddassl.o  dogleg.o  fdjac1.o  hybrj.o   newuoa.o   qrfac.o   trsapp.o \
daux.o    dlamch.o  dpmpar.o  hybrd.o   lsame.o   newuob.o   r1mpyq.o  update.o $(EXTRA_OBJS)

SIMOBJS = $(FOBJS) simulation_runtime.o simulation_init.o simulation_input.o simulation_events.o \
solver_dasrt.o solver_euler.o simulation_result.o tables.o options.o dgesv_aux.o meta_modelica.o $(EXTRA_SIMOBJS)

HFILES = blaswrap.h f2c.h integer_array.h memory_pool.h modelica_string.h \
	base_array.h inline.h real_array.h string_array.h boolean_array.h \
    index_spec.h matrix.h \
	modelica.h read_write.h simulation_runtime.h simulation_events.h utility.h \
	simulation_init.h simulation_input.h solver_dasrt.h solver_euler.h simulation_result.h \
	meta_modelica.h sendData/sendData.h sendData/humbug.h

LIBS = libc_runtime.a libsim.a 

ifdef QTHOME
PLTPKGCMD =	cd ./sendData && \
	$(QTHOME)/bin/qmake && \
	$(MAKE) -f Makefile
else
PLTPKGCMD = mkdir -p sendData/release && \
g++ -c -o sendData/libsendData.o sendData/humbug.cpp && \
ar -ru sendData/release/libsendData.a sendData/libsendData.o
endif

all : $(SIMOBJS) $(OBJS) libc_runtime.a libsim.a libf2c.a libsendData.a install

$(SIMOBJS) : $(HFILES) *.c*
$(OBJS) : $(HFILES) *.c*

libc_runtime.a : $(OBJS)
	$(AR) $@ $(OBJS)


install: libc_runtime.a libsim.a libf2c/libf2c.a
	cp $(HFILES) $(builddir_inc)/
	cp $(LIBS) $(builddir_lib)/
	cp libf2c/libf2c.* $(builddir_lib)/
	cp sendData/release/libsendData.a $(builddir_lib)/

libsim.a : $(SIMOBJS)
	$(AR) $@ $(SIMOBJS)

libf2c.a :
	cd libf2c && $(MAKE) -f makefile.u

libsendData.a : sendData/sendData.cpp sendData/sendData.h sendData/sendData.pro sendData/humbug.h sendData/humbug.cpp
#	cd ./sendData && \
#	$(QTHOME)/bin/qmake && \
#	sed -e's/QtNetwork /QtNetwork4 /' -e's/QtGui /QtGui4 /' -e's/QtCore /QtCore4 /' Makefile.Release > Makefile && \
#	$(MAKE) -f Makefile 
	$(PLTPKGCMD)

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
	cd sendData && rm -fr release debug *sendData*.o *sendData*.a	
	rm -rf sendData/release sendData/debug
	rm -f sendData.o sendData.a sendData/releasesendData.o
