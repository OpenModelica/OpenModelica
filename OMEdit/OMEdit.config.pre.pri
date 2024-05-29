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

QT += network core gui xml svg opengl printsupport widgets concurrent
equals(QT_MAJOR_VERSION, 6) {
  QT += core5compat openglwidgets
  win32 {
    # disable documentation since we don't have webkit on qt6 and webengine is not yet supported.
    QMAKE_CXXFLAGS += -DOM_DISABLE_DOCUMENTATION
  } else {
    _OM_OMEDIT_ENABLE_QTWEBENGINE = $$(OM_OMEDIT_ENABLE_QTWEBENGINE)
    equals(_OM_OMEDIT_ENABLE_QTWEBENGINE, ON) {
      QMAKE_CXXFLAGS += -DOM_OMEDIT_ENABLE_QTWEBENGINE
      QT += WebEngineWidgets
    } else {
      QMAKE_CXXFLAGS += -DOM_DISABLE_DOCUMENTATION
    }
  }
} else {
  QT += xmlpatterns webkit webkitwidgets
}

# Set the C++ standard.
CONFIG += c++17
# Please read the warnings. They are like vegetables; good for you even if you hate them.
CONFIG += warn_on

DEFINES += OM_HAVE_PTHREADS

_OM_OMEDIT_ENABLE_LIBXML2 = $$(OM_OMEDIT_ENABLE_LIBXML2)
equals(_OM_OMEDIT_ENABLE_LIBXML2, ON) {
  QMAKE_CXXFLAGS += -DOM_OMEDIT_ENABLE_LIBXML2
}

win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport -mthreads")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS_EXCEPTIONS_ON -= -mthreads
  } else {
    # -Wno-clobbered is not recognized by clang
    QMAKE_CXXFLAGS += -Wno-clobbered
  }

  # if OM_ENABLE_ENCRYPTION
  _OM_ENABLE_ENCRYPTION = $$(OM_ENABLE_ENCRYPTION)
  equals(_OM_ENABLE_ENCRYPTION, yes) {
    QMAKE_CXXFLAGS += -DOM_ENABLE_ENCRYPTION
  }
}

UI_DIR = generatedfiles/ui

MOC_DIR = generatedfiles/moc

RCC_DIR = generatedfiles/rcc

TARGET = OMEdit
