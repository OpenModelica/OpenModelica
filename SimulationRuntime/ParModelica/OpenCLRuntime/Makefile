
TOP_BUILDDIR = ../../../build/

OPENMODELICA_INC=$(TOP_BUILDDIR)/include/omc/
OPENMODELICA_LIB=$(TOP_BUILDDIR)/lib/omc/
OPENMODELICA_BIN=$(TOP_BUILDDIR)/bin/


AR_=ar -rcs
COPY=cp -rpu
CC=g++
CXX=g++
EXEEXT=
DLLEXT=.so
CFLAGS= -O3 -Wall -I. -I"$(TOP_BUILDDIR)/include/omc"
OPENLC_LIB= lOpenCL


OBJS = \
omc_ocl_memory_ops.o \
omc_ocl_interface.o \
omc_ocl_builtin_kernels.o \
omc_ocl_util.o 

all: transfer
	 
transfer: libOMOCLRuntime.a 
	$(COPY) omc_ocl_interface.h $(OPENMODELICA_INC)
	$(COPY) omc_ocl_common_header.h $(OPENMODELICA_INC)
	$(COPY) omc_ocl_memory_ops.h $(OPENMODELICA_INC)
	$(COPY) libOMOCLRuntime.a $(OPENMODELICA_LIB)
#	$(COPY) $(OPENLC_LIB) $(OPENMODELICA_LIB)
	$(COPY) ParModelicaBuiltin.mo $(OPENMODELICA_LIB)
#	mkdir -p $(OPENMODELICA_INC)/CL/
#	$(COPY) ./CL/* $(OPENMODELICA_INC)/CL/
	$(COPY) OCLRuntimeUtil_new.cl $(TOP_BUILDDIR)/include/omc/
# cp OCLRuntimeUtil.cl $(TOP_BUILDDIR)/bin/
# cp ocloffcomp$(EXEEXT) $(TOP_BUILDDIR)/bin/

ocloffc: omc_ocl_util.h libOMOCLRuntime.a
	 $(CXX) -I.  -o ocloffcomp$(EXEEXT) ocl_offcomp.c libOMOCLRuntime.a $(OPENLC_LIB) $(CFLAGS) 
	 
libOMOCLRuntime.a: $(OBJS)
	@rm -f $@
	$(AR_) $@ $(OBJS)
	
clean :
	rm -f *.o *.a
	