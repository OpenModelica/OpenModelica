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

include(../OMEdit.config.pre.pri)

DESTDIR = ../bin
ICON = ../OMEditLIB/Resources/icons/omedit.icns
QMAKE_INFO_PLIST = Info.plist

TEMPLATE = app

PRE_TARGETDEPS += ../bin/libOMEdit.a

LIBS += -L../bin -lOMEdit

OMEDIT_ROOT = ../

# Windows libraries and includes
win32 {
  include(OMEditGUI.win.config.pri)
  RC_FILE = rc_omedit.rc
} else { # Unix libraries and includes
  include(OMEditGUI.unix.config.pri)
}

INCLUDEPATH += ../ \
  ../OMEditLIB \
  ../OMEditLIB/CrashReport \
  $$OPENMODELICAHOME/include/omc/c

SOURCES += main.cpp

include(../OMEdit.config.post.pri)
