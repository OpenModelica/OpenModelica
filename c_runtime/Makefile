# Adrian Pop, adrpo@ida.liu.se, Martin Sjölund, marsj@ida.liu.se
# - Use make -f Makefile.omdev.mingw if you want to compile on Windows/MinGW
# - Please leave the UNIX Makefile as it is if you are not using UNIX/Linux
# If you need to add files, etc, you modify Makefile.common - a common file
# for both UNIX/Linux and Windows platforms.

top_builddir = ..
builddir_bin=$(top_builddir)/build/bin
builddir_lib=$(top_builddir)/build/lib
builddir_inc=$(top_builddir)/build/include

UNAME := $(shell uname -m)
CMDFPUFLAGS := `case ${UNAME} in i[3456]86) echo "-msse2 -mfpmath=sse";; x86_64) echo "-msse2 -mfpmath=sse -fPIC";; *) echo "";; esac`
FPUFLAGS := ${CMDFPUFLAGS}

ifdef QTHOME
PLTPKGCMD = cd ./sendData && $(QTHOME)/bin/qmake && $(MAKE) -f Makefile
else
PLTPKGCMD = mkdir -p sendData/release && \
g++ -c -o sendData/libsendData.o sendData/humbug.cpp && \
ar -ru sendData/release/libsendData.a sendData/libsendData.o
endif

LIBF2CMAKEFILE = makefile.u
JAVAMAKEFILE = Makefile
include Makefile.common

