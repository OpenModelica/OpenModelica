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
  QT += printsupport widgets webkitwidgets concurrent testlib
} else {
  CONFIG += qtestlib
}

LIBS += -L../../bin -lOMEdit

OMEDIT_ROOT = ../../

# Windows libraries and includes
win32 {
  include(../../OMEditGUI/OMEditGUI.win.config.pri)
} else { # Unix libraries and includes
  include(../../OMEditGUI/OMEditGUI.unix.config.pri)
}

INCLUDEPATH += ../../ \
  ../../OMEditLIB \
  ../Common \
  $$OPENMODELICAHOME/include \
  $$OPENMODELICAHOME/include/omplot \
  $$OPENMODELICAHOME/include/omplot/qwt \
  $$OPENMODELICAHOME/include/omc/c \
  $$OPENMODELICAHOME/include/omc/scripting-API

# Don't show the warnings from included headers.
# Don't add a space between for and open parenthesis below. Qt4 complains about it.
for(path, INCLUDEPATH) {
  QMAKE_CXXFLAGS += -isystem $${path}
}

DESTDIR = ../../bin/tests

MOC_DIR = generatedfiles/moc

