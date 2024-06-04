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

QT += network core gui webkit xml xmlpatterns svg opengl
greaterThan(QT_MAJOR_VERSION, 4) {
  QT += printsupport widgets webkitwidgets concurrent
}

# Set the C++ standard.
CONFIG += c++1z

TARGET = OMEdit
TEMPLATE = app

PRE_TARGETDEPS += ../bin/libOMEdit.a

LIBS += -L../bin -lOMEdit

OMEDIT_ROOT = ../

DEFINES += OM_HAVE_PTHREADS

# Windows libraries and includes
win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport -mthreads")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS_EXCEPTIONS_ON -= -mthreads
  }

  include(OMEditGUI.win.config.pri)
  RC_FILE = rc_omedit.rc
} else { # Unix libraries and includes
  include(OMEditGUI.unix.config.pri)
}

INCLUDEPATH += ../ \
  ../OMEditLIB \
  ../OMEditLIB/CrashReport \
  $$OPENMODELICAHOME/include/omc/c

# Don't show the warnings from included headers.
# Don't add a space between for and open parenthesis below. Qt4 complains about it.
for(path, INCLUDEPATH) {
  QMAKE_CXXFLAGS += -isystem $${path}
}

SOURCES += main.cpp

# Please read the warnings. They are like vegetables; good for you even if you hate them.
CONFIG += warn_on
win32 {
  # -Wno-clobbered is not recognized by clang
  !contains(_cxx, clang++) {
    QMAKE_CXXFLAGS += -Wno-clobbered
  }
}

DESTDIR = ../bin

ICON = ../OMEditLIB/Resources/icons/omedit.icns

QMAKE_INFO_PLIST = Info.plist

HEADERS +=
