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

OMEDIT_ROOT = ../../

LIBS += -L$$OMEDIT_ROOT/bin -lOMEdit

include($$OMEDIT_ROOT/OMEdit.config.pre.pri)
QT += testlib
# Windows libraries and includes
win32 {
  include($$OMEDIT_ROOT/OMEditGUI/OMEditGUI.win.config.pri)
} else { # Unix libraries and includes
  include($$OMEDIT_ROOT/OMEditGUI/OMEditGUI.unix.config.pri)
}

INCLUDEPATH += $$OMEDIT_ROOT \
  $$OMEDIT_ROOT/OMEditLIB \
  ../Util \
  $$OPENMODELICAHOME/include \
  $$OPENMODELICAHOME/include/omplot \
  $$OPENMODELICAHOME/include/omplot/qwt \
  $$OPENMODELICAHOME/include/omc/c \
  $$OPENMODELICAHOME/include/omc/scripting-API \
  $$OPENMODELICAHOME/../OMSimulator/include/

# Don't show the warnings from included headers.
# Don't add a space between for and open parenthesis below. Qt4 complains about it.
for(path, INCLUDEPATH) {
  QMAKE_CXXFLAGS += -isystem $${path}
}

DESTDIR = $$OMEDIT_ROOT/bin/tests

MOC_DIR = generatedfiles/moc

DEFINES += OM_HAVE_PTHREADS
