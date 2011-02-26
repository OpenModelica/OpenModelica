#-------------------------------------------------
#
# Project created by QtCreator 2010-09-23T18:14:43
#
#-------------------------------------------------

QT += network core gui webkit xml

TARGET = OMEdit
TEMPLATE = app

SOURCES += main.cpp\
        mainwindow.cpp \
    ProjectTabWidget.cpp \
    LibraryWidget.cpp \
    MessageWidget.cpp \
    omc_communication.cpp \
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
    ../../c_runtime/read_matlab4.c

HEADERS  += mainwindow.h \
    ProjectTabWidget.h \
    LibraryWidget.h \
    MessageWidget.h \
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
    ../../c_runtime/read_matlab4.h

# -------For OMNIorb
win32 {
DEFINES += __x86__ \
    __NT__ \
    __OSVERSION__=4 \
    __WIN32__
LIBS += -L$$(OMDEV)/lib/omniORB-4.1.4-mingw/lib/x86_win32 \
    -lomniORB414_rt \
    -lomnithread34_rt
INCLUDEPATH += $$(OMDEV)/lib/omniORB-4.1.4-mingw/include ../../c_runtime/
} else {
    include(OMEdit.config)
}
#---------End OMNIorb

OTHER_FILES += \
    Resources/css/stylesheet.qss

CONFIG += warn_off

RESOURCES += resource_omedit.qrc

RC_FILE = rc_omedit.rc

DESTDIR = ../bin
