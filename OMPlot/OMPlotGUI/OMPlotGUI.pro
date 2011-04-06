#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg

TARGET = OMPlot
TEMPLATE = app

SOURCES += main.cpp \
    ../../c_runtime/read_matlab4.c \
    Plot.cpp \
    PlotZoomer.cpp \
    Legend.cpp \
    PlotPanner.cpp \
    PlotGrid.cpp \
    PlotCurve.cpp \
    PlotWindow.cpp \
    PlotApplication.cpp \
    PlotWindowContainer.cpp \
    PlotMainWindow.cpp

HEADERS  += ../../c_runtime/read_matlab4.h \
    Plot.h \
    PlotZoomer.h \
    Legend.h \
    PlotPanner.h \
    PlotGrid.h \
    PlotCurve.h \
    PlotWindow.h \
    PlotApplication.h \
    PlotWindowContainer.h \
    PlotMainWindow.h

win32 {
CONFIG(debug, debug|release){
LIBS += -L$$(OMDEV)/lib/qwt-5.2.1-mingw/lib -lqwtd5
}
else {
LIBS += -L$$(OMDEV)/lib/qwt-5.2.1-mingw/lib -lqwt5
}
INCLUDEPATH += $$(OMDEV)/lib/qwt-5.2.1-mingw/include
} else {
  include(OMPlotGUI.config)
}

INCLUDEPATH += .

CONFIG += warn_off

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

RESOURCES += resource_omplot.qrc

RC_FILE = rc_omplot.rc
