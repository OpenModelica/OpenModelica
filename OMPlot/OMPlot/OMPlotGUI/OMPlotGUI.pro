# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
# RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium)
# Public License (OSMC-PL) are obtained from OSMC, either from the above
# address, from the URLs:
# http://www.openmodelica.org or
# https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica,
# and in the OpenModelica distribution.
#
# GNU AGPL version 3 is obtained from:
# https://www.gnu.org/licenses/licenses.html#GPL
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.

#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg printsupport widgets
equals(QT_MAJOR_VERSION, 6) {
  QT += core5compat
}

# Set the C++ standard.
CONFIG += c++17

TARGET = OMPlot
TEMPLATE = app
CONFIG += cmdline

SOURCES += main.cpp

win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS_EXCEPTIONS_ON -= -mthreads
  }

  QMAKE_LFLAGS += -Wl,--enable-auto-import
  CONFIG(debug, debug|release){
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwtd -lOpenModelicaRuntimeC
  }
  else {
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwt -lOpenModelicaRuntimeC
  }
  INCLUDEPATH += $$(OMBUILDDIR)/include/omplot/qwt $$(OMBUILDDIR)/include/omc/c
} else {
  include(OMPlotGUI.config)
  LIBS += -lOMPlot
}

INCLUDEPATH += .

# Please read the warnings. They are like vegetables; good for you even if you hate them.
CONFIG += warn_on
win32 {
  # -Wno-clobbered is not recognized by clang
  !contains(_cxx, clang++) {
    QMAKE_CXXFLAGS += -Wno-clobbered
  }
}

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

RESOURCES += resource_omplot.qrc

RC_FILE = rc_omplot.rc

