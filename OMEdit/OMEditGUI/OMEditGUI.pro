#-------------------------------------------------
#
# Project created by QtCreator 2010-09-23T18:14:43
#
#-------------------------------------------------

QT += network xml core gui opengl

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
    IconAnnotation.cpp \
    InheritanceAnnotation.cpp \
    ComponentAnnotation.cpp \
    ComponentsProperties.cpp \
    CornerItem.cpp \
    ConnectorWidget.cpp \
    Components.cpp \
    SimulationWidget.cpp \
    PlotWidget.cpp \
    ModelicaEditor.cpp \
    ../3Dpkg/VisualizationWidget.cpp \
    ../3Dpkg/SimulationData.cpp \
    ../Pltpkg2/variablewindow.cpp \
    ../Pltpkg2/variableData.cpp \
    ../Pltpkg2/preferenceWindow.cpp \
    ../Pltpkg2/point.cpp \
    ../Pltpkg2/lineGroup.cpp \
    ../Pltpkg2/line2D.cpp \
    ../Pltpkg2/legendLabel.cpp \
    ../Pltpkg2/graphWindow.cpp \
    ../Pltpkg2/graphWidget.cpp \
    ../Pltpkg2/dataSelect.cpp \
    ../Pltpkg2/curve.cpp \
    ../Pltpkg2/compoundWidget.cpp \
    IconProperties.cpp \
    IconParameters.cpp

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
    IconAnnotation.h \
    InheritanceAnnotation.h \
    ComponentAnnotation.h \
    ComponentsProperties.h \
    CornerItem.h \
    ConnectorWidget.h \
    Components.h \
    SimulationWidget.h \
    PlotWidget.h \
    ModelicaEditor.h \
    ../3Dpkg/VisualizationWidget.h \
    ../3Dpkg/SimulationData.h \
    ../Pltpkg2/verticalLabel.h \
    ../Pltpkg2/variablewindow.h \
    ../Pltpkg2/variableData.h \
    ../Pltpkg2/preferenceWindow.h \
    ../Pltpkg2/point.h \
    ../Pltpkg2/lineGroup.h \
    ../Pltpkg2/line2D.h \
    ../Pltpkg2/legendLabel.h \
    ../Pltpkg2/label.h \
    ../Pltpkg2/graphWindow.h \
    ../Pltpkg2/graphWidget.h \
    ../Pltpkg2/graphScene.h \
    ../Pltpkg2/focusRect.h \
    ../Pltpkg2/dataSelect.h \
    ../Pltpkg2/curve.h \
    ../Pltpkg2/compoundWidget.h \
    IconProperties.h \
    IconParameters.h

# -------For OMNIorb
win32 {
DEFINES += __x86__ \
    __NT__ \
    __OSVERSION__=4 \
    __WIN32__
LIBS += -L. \
    -lomniORB414_rtd \
    -lomnithread34_rtd

INCLUDEPATH += C:\\Thesis\\omniORB-4.1.4\\include \
               ../Pltpkg2 \
               ../3Dpkg
} else {
LIBS += -L/usr/lib/ -lomniORB4 -lomnithread
INCLUDEPATH += /usr/include/omniORB4 \
               ../Pltpkg2 \
               ../3Dpkg
}
#---------End OMNIorb

OTHER_FILES += \
    Resources/css/stylesheet.qss

CONFIG += warn_off

FORMS += \
    SimulationWidget.ui \
    ../Pltpkg2/preferences.ui \
    ../Pltpkg2/newgraph.ui \
    ../Pltpkg2/graphWindow.ui \
    ../Pltpkg2/dataSelect.ui \
    ../Pltpkg2/compoundWidget.ui \
    IconProperties.ui
