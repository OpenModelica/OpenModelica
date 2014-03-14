#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui

TARGET = OMPlot
TEMPLATE = lib

CONFIG += release staticlib
QMAKE_LFLAGS += -enable-auto-import

SOURCES += main.cpp \
    ../../SimulationRuntime/c/util/read_matlab4.c \
    ../../SimulationRuntime/c/util/libcsv.c \
    ../../SimulationRuntime/c/util/read_csv.c \
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

HEADERS  += ../../SimulationRuntime/c/util/read_matlab4.h \
    ../../SimulationRuntime/c/util/libcsv.h \
    ../../SimulationRuntime/c/util/read_csv.h \
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
LIBS += -L$$(OMDEV)/lib/qwt-6.1.0-mingw/lib -lqwtd \
    -L../../3rdParty/gc-7.2/.libs -lgc
}
else {
LIBS += -L$$(OMDEV)/lib/qwt-6.1.0-mingw/lib -lqwt \
    -L../../3rdParty/gc-7.2/.libs -lgc
}
INCLUDEPATH += $$(OMDEV)/lib/qwt-6.1.0-mingw/include \
    ../../3rdParty/gc-7.2/include
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
