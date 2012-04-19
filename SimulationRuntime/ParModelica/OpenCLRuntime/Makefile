
OPENMODELICA_INC=$(OPENMODELICAHOME)/include/omc/
OPENMODELICA_LIB=$(OPENMODELICAHOME)/lib/omc/
OPENMODELICA_BIN=$(OPENMODELICAHOME)/bin/


AR_=ar -rcs
COPY=cp -rpu
CC=g++
CXX=g++
EXEEXT=.exe
DLLEXT=.dll
CFLAGS= -O3 -Wall -I. -I"$(OPENMODELICAHOME)/include/omc"


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
	$(COPY) OpenCL.lib $(OPENMODELICA_LIB)
	mkdir -p $(OPENMODELICA_INC)/CL/
	$(COPY) ./CL/* $(OPENMODELICA_INC)/CL/
# cp OCLRuntimeUtil.cl $(OPENMODELICAHOME)/include/omc/
# cp OCLRuntimeUtil.cl $(OPENMODELICAHOME)/bin/
# cp ocloffcomp$(EXEEXT) $(OPENMODELICAHOME)/bin/

ocloffc: ocl_offcomp.c ocl_util.hpp libOMOCLRuntime
	 $(CXX) -I.  -o ocloffcomp$(EXEEXT) ocl_offcomp.c libOMOCLRuntime.a OpenCL.lib $(CFLAGS) 
	 
libOMOCLRuntime.a: $(OBJS)
	@rm -f $@
	$(AR_) $@ $(OBJS)
	
clean :
	rm -f *.o *.a
	