# Build Environment Einstellungen


CC = g++
AR = ar
PLT=win32
MODELNAME = BouncingBall
MAKEINC = $(PRJDIR)/Build/MakeConf.inc
MAINFILE = $(TMPBINPATH)/SimModel.exe
REDDAEFILE = $(BINPATH)/ReduceDAE.exe
MODELFILE = $(MODELNAME).cpp
LIBPREFIX=""
CFLAGS = -c
BUILDDIR = $(PRJDIR)/Build
SRCDIR = $(PRJDIR)/Source
TMPBINPATH = $(PRJDIR)/Build/bin
LIBPATH = $(PRJDIR)/../../build/lib/omc/cpp
BINPATH = $(PRJDIR)/../../build/bin/cpp
CONFPATH = $(BINPATH)/config
MINGW=$(OPENMODELICAHOME)/MinGW/bin
LAPACKPATH = $(SRCDIR)/3rdParty/Lapack/Lib
BOOSTPATH = $(SRCDIR)/3rdParty/boost_1_45_0/lib
MICOPATH = $(SRCDIR)/3rdParty/mico-msys-mingw/libs
FORTRANPATH = $(SRCDIR)/3rdParty/Fortran/Lib
INCLUDES = -I"$(SRCDIR)/3rdParty/boost_1_45_0/boost" -I"$(SRCDIR)/3rdParty/boost_1_45_0" -I"$(SRCDIR)/3rdParty/mico-msys-mingw/include/" -I"$(SRCDIR)/3rdParty/mico-msys-mingw/include/windows"

LIBMATH = $(TMPBINPATH)/libMath.a
LIBDAESOLVER =$(TMPBINPATH)/DAESolver.dll
LIBEULER = $(TMPBINPATH)/Euler.dll
LIBNEWTON = $(TMPBINPATH)/Newton.dll
LIBDAESYSTEM = $(TMPBINPATH)/DAESystem.dll
LIBMODELICASYSTEM = $(BINPATH)/$(LIBPREFIX)ModelicaSystem.dll
LIBSETTINGSFACTORY =$(TMPBINPATH)/SettingsFactory.dll

LIBBLAS = $(LAPACKPATH)/blasSource.lib
LIBLAPACK = $(LAPACKPATH)/lapackSource.lib
LIBBOOST =-L$(BOOSTPATH)/
LIBMICO = -L$(MICOPATH)/

MINGW32=$(OPENMODELICAHOME)\MinGW\bin
SRCDIRWIN32=$(PRJDIR)\Source
FORTRANWIN32 = $(SRCDIRWIN32)\3rdParty\Fortran\Lib
BOOSTPATHWIN32 = $(SRCDIRWIN32)\3rdParty\boost_1_45_0\lib
MICOPATHWIN32 = $(SRCDIRWIN32)\3rdParty\mico-msys-mingw\libs
BINPATHWIN32 =  $(PRJDIR)\..\..\build\bin\cpp
CONFPATHWIN32  = $(BINPATHWIN32)\config
LIBPATHWIN32 = $(PRJDIR)\..\..\build\lib\omc\cpp
TMPBINPATHWIN32=$(PRJDIR)\Build\bin