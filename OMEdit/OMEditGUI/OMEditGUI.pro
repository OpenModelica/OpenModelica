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
#!
 #
 # @author Adeel Asghar <adeel.asghar@liu.se>
 #
 # RCS: $Id$
 #
 #/

QT += network core gui webkit xml svg

TRANSLATIONS = Resources/nls/OMEdit_de.ts \
    Resources/nls/OMEdit_es.ts \
    Resources/nls/OMEdit_fr.ts \
    Resources/nls/OMEdit_it.ts \
    Resources/nls/OMEdit_ja.ts \
    Resources/nls/OMEdit_ro.ts \
    Resources/nls/OMEdit_ru.ts \
    Resources/nls/OMEdit_sv.ts \
    Resources/nls/OMEdit_zh_CN.ts

TARGET = OMEdit
TEMPLATE = app

# This is very evil, lupdate just look for SOURCES variable and creates translations. This section is not compiled at all :)
evil_hack_to_fool_lupdate {
    SOURCES += ../../OMPlot/OMPlotGUI/*.cpp
}

SOURCES += main.cpp\
    Util/Helper.cpp \
    GUI/MainWindow.cpp \
    omc_communication.cc \
    OMC/OMCProxy.cpp \
    Util/StringHandler.cpp \
    GUI/Widgets/MessagesWidget.cpp \
    GUI/Widgets/LibraryTreeWidget.cpp \
    GUI/Containers/ModelWidgetContainer.cpp \
    GUI/Dialogs/ModelicaClassDialog.cpp \
    GUI/Dialogs/OptionsDialog.cpp \
    GUI/Widgets/ModelicaTextWidget.cpp \
    GUI/Containers/PlotWindowContainer.cpp \
    Component/Component.cpp \
    Annotations/ShapeAnnotation.cpp \
    Component/CornerItem.cpp \
    Annotations/LineAnnotation.cpp \
    Annotations/PolygonAnnotation.cpp \
    Annotations/RectangleAnnotation.cpp \
    Annotations/EllipseAnnotation.cpp \
    Annotations/TextAnnotation.cpp \
    Annotations/BitmapAnnotation.cpp \
    GUI/Dialogs/ComponentProperties.cpp \
    Component/Transformation.cpp \
    GUI/Widgets/DocumentationWidget.cpp \
    GUI/Dialogs/SimulationDialog.cpp \
    GUI/Dialogs/ImportFMUDialog.cpp \
    GUI/Widgets/VariablesWidget.cpp \
    GUI/Dialogs/NotificationsDialog.cpp \
    GUI/Dialogs/ShapePropertiesDialog.cpp

HEADERS  += Util/Helper.h \
    GUI/MainWindow.h \
    omc_communication.h \
    OMC/OMCProxy.h \
    Util/StringHandler.h \
    GUI/Widgets/MessagesWidget.h \
    GUI/Widgets/LibraryTreeWidget.h \
    GUI/Containers/ModelWidgetContainer.h \
    GUI/Dialogs/ModelicaClassDialog.h \
    GUI/Dialogs/OptionsDialog.h \
    GUI/Widgets/ModelicaTextWidget.h \
    GUI/Containers/PlotWindowContainer.h \
    Component/Component.h \
    Annotations/ShapeAnnotation.h \
    Component/CornerItem.h \
    Annotations/LineAnnotation.h \
    Annotations/PolygonAnnotation.h \
    Annotations/RectangleAnnotation.h \
    Annotations/EllipseAnnotation.h \
    Annotations/TextAnnotation.h \
    Annotations/BitmapAnnotation.h \
    GUI/Dialogs/ComponentProperties.h \
    Component/Transformation.h \
    GUI/Widgets/DocumentationWidget.h \
    GUI/Dialogs/SimulationDialog.h \
    GUI/Dialogs/ImportFMUDialog.h \
    GUI/Widgets/VariablesWidget.h \
    GUI/Dialogs/NotificationsDialog.h \
    GUI/Dialogs/ShapePropertiesDialog.h

# Windows libraries and includes
win32 {
QMAKE_LFLAGS += -enable-auto-import

DEFINES += __x86__ \
    __NT__ \
    __OSVERSION__=4 \
    __WIN32__
CONFIG(debug, debug|release){
LIBS += -L$$(OMDEV)/lib/omniORB-4.1.6-mingw/lib/x86_win32 \
    -lomniORB416_rtd \
    -lomnithread34_rtd \
    -L../../OMPlot/bin \
    -lOMPlot \
    -L$$(OMDEV)/lib/qwt-5.2.1-mingw/lib \
    -lqwtd5
} else {
LIBS += -L$$(OMDEV)/lib/omniORB-4.1.6-mingw/lib/x86_win32 \
    -lomniORB416_rt \
    -lomnithread34_rt \
    -L../../OMPlot/bin \
    -lOMPlot \
    -L$$(OMDEV)/lib/qwt-5.2.1-mingw/lib \
    -lqwt5
}
INCLUDEPATH += $$(OMDEV)/lib/omniORB-4.1.6-mingw/include \
               $$(OMDEV)/lib/qwt-5.2.1-mingw/include \
               ../../OMPlot/OMPlotGUI \
               ../../
} else { # Unix libraries and includes
    include(OMEdit.config)
}

INCLUDEPATH += . \
                Annotations \
                Component \
                OMC \
                Util \
                GUI \
                GUI/Containers \
                GUI/Widgets \
                GUI/Dialogs \

OTHER_FILES += Resources/css/stylesheet.qss

CONFIG += warn_off

RESOURCES += resource_omedit.qrc

RC_FILE = rc_omedit.rc

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

ICON = Resources/icons/omedit.icns
