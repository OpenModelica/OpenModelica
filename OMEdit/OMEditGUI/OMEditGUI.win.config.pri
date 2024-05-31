#
 # This file is part of OpenModelica.
 #
 # Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 # c/o Linköpings universitet, Department of Computer and Information Science,
 # SE-58183 Linköping, Sweden.
 #
 # All rights reserved.
 #
 # THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 # THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 # ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 # OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 #
 # The OpenModelica software and the Open Source Modelica
 # Consortium (OSMC) Public License (OSMC-PL) are obtained
 # from OSMC, either from the above address,
 # from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 # http://www.openmodelica.org, and in the OpenModelica distribution.
 # GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 #
 # This program is distributed WITHOUT ANY WARRANTY; without
 # even the implied warranty of  MERCHANTABILITY or FITNESS
 # FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 # IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 #
 # See the full OSMC Public License conditions for more details.
 #
 #/

OPENMODELICAHOME = $$(OMBUILDDIR)
# define used for OpenModelica C-API
DEFINES += IMPORT_INTO=1
QMAKE_LFLAGS += -Wl,--stack,33554432,--enable-auto-import

LIBS += -L$$(OMBUILDDIR)/../OMEdit/OMEditLIB/Debugger/Parser -lGDBMIParser \
  -L$$(OMBUILDDIR)/lib/omc -L$$(OMBUILDDIR)/../OMParser/install/lib -Wl,-Bstatic -lOMParser -lantlr4-runtime -Wl,-Bdynamic -lomantlr3 -lOMPlot -lomqwt -lomopcua -lzmq \
  -lOpenModelicaCompiler -lOpenModelicaRuntimeC -lfmilib -lomcgc -lpthread -lshlwapi \
  -lws2_32 \
  -L$$(OMBUILDDIR)/bin -lOMSimulator

# libbdf links differently on newer MSYS2, e.g. when using UCRT64
msystem_prefix = $$(MSYSTEM_PREFIX)
contains(msystem_prefix, .*ucrt64.*) {
  BFD_PATH = $$(MSYSTEM_PREFIX)/lib
  BFD_LIBS = -lbfd -lintl -liberty -lsframe -lzstd -lzlib
} else {
  BFD_PATH = $$(MSYSTEM_PREFIX)/lib/binutils
  BFD_LIBS = -lbfd -lintl -liberty -lzlib
}

CONFIG(release, debug|release) { # release
  # required for backtrace
  # In order to get the stack trace in Windows we must add -g flag. Qt automatically adds the -O2 flag for optimization.
  # We should also unset the QMAKE_LFLAGS_RELEASE define because it is defined as QMAKE_LFLAGS_RELEASE = -Wl,-s in qmake.conf file for MinGW
  # -s will remove all symbol table and relocation information from the executable.
  QMAKE_CXXFLAGS += -g -DUA_DYNAMIC_LINKING
  QMAKE_LFLAGS_RELEASE =
  OSG_LIBS = -limagehlp $$BFD_LIBS -llibosg.dll -llibosgViewer.dll -llibOpenThreads.dll -llibosgDB.dll -llibosgGA.dll -lOpengl32
} else { # debug
  LIBS += -L$$(MSYSTEM_PREFIX)/bin
  OSG_LIBS = -llibosg.dll -llibosgViewer.dll -llibOpenThreads.dll -llibosgDB.dll -llibosgGA.dll -lOpengl32
}

LIBS += -L$$BFD_PATH -L$$(MSYSTEM_PREFIX)/bin
LIBS += $$OSG_LIBS

contains(QMAKE_CXXFLAGS, -DOM_OMEDIT_ENABLE_LIBXML2) {
  LIBS += -L$$(MSYSTEM_PREFIX)/bin -llibxml2-2
}
