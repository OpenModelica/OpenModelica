#-------------------------------------------------
#
# Project created by QtCreator 2010-09-23T18:14:43
#
#-------------------------------------------------

QT += network core gui webkit xml svg

TRANSLATIONS = \
    Resources/nls/OMEdit_de.ts \
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

SOURCES += main.cpp \
    mainwindow.cpp \
    ProjectTabWidget.cpp \
    LibraryWidget.cpp \
    ProblemsWidget.cpp \
    omc_communication.cc \
    OMCProxy.cpp \
    OMCThread.cpp \
    StringHandler.cpp \
    ModelWidget.cpp \
    Helper.cpp \
    SplashScreen.cpp \
    ShapeAnnotation.cpp \
    LineAnnotation.cpp \
    PolygonAnnotation.cpp \
    RectangleAnnotation.cpp \
    EllipseAnnotation.cpp \
    TextAnnotation.cpp \
    ComponentsProperties.cpp \
    CornerItem.cpp \
    ConnectorWidget.cpp \
    PlotWidget.cpp \
    ModelicaEditor.cpp \
    IconParameters.cpp \
    SimulationWidget.cpp \
    IconProperties.cpp \
    Component.cpp \
    Transformation.cpp \
    DocumentationWidget.cpp \
    OptionsWidget.cpp \
    BitmapAnnotation.cpp \
    InteractiveSimulationTabWidget.cpp \
    PlotWindowContainer.cpp \
    FMIWidget.cpp

HEADERS  += mainwindow.h \
    ProjectTabWidget.h \
    LibraryWidget.h \
    ProblemsWidget.h \
    omc_communication.h \
    OMCProxy.h \
    OMCThread.h \
    StringHandler.h \
    ModelWidget.h \
    Helper.h \
    SplashScreen.h \
    ShapeAnnotation.h \
    LineAnnotation.h \
    PolygonAnnotation.h \
    RectangleAnnotation.h \
    EllipseAnnotation.h \
    TextAnnotation.h \
    ComponentsProperties.h \
    CornerItem.h \
    ConnectorWidget.h \
    PlotWidget.h \
    ModelicaEditor.h \
    IconParameters.h \
    SimulationWidget.h \
    IconProperties.h \
    Component.h \
    Transformation.h \
    DocumentationWidget.h \
    OptionsWidget.h \
    BitmapAnnotation.h \
    InteractiveSimulationTabWidget.h \
    PlotWindowContainer.h \
    FMIWidget.h

# -------For OMNIorb
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
} else {
    include(OMEdit.config)
}
#---------End OMNIorb

INCLUDEPATH += .

OTHER_FILES += \
    Resources/css/stylesheet.qss

CONFIG += warn_off

RESOURCES += resource_omedit.qrc

RC_FILE = rc_omedit.rc

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

ICON = Resources/icons/omedit.icns
