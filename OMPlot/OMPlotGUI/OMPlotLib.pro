#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg

TARGET = OMPlot
TEMPLATE = lib

CONFIG += release
win32 {
 CONFIG += staticlib
}
QMAKE_LFLAGS += -enable-auto-import

SOURCES += ../../SimulationRuntime/c/util/read_matlab4.c \
    ../../SimulationRuntime/c/util/libcsv.c \
    ../../SimulationRuntime/c/util/read_csv.c \
    ../../SimulationRuntime/c/util/string_util.c \
    Plot.cpp \
    PlotZoomer.cpp \
    Legend.cpp \
    PlotPanner.cpp \
    PlotGrid.cpp \
    ScaleDraw.cpp \
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
    ScaleDraw.h \
    PlotCurve.h \
    PlotWindow.h \
    PlotApplication.h \
    PlotWindowContainer.h \
    PlotMainWindow.h

win32 {
CONFIG(debug, debug|release){
LIBS += -L../../build/lib/omc -lomqwtd -L../../3rdParty/gc-7.2/.libs
}
else {
LIBS += -L../../build/lib/omc -lomqwt -L../../3rdParty/gc-7.2/.libs
}
INCLUDEPATH += ../../3rdParty/qwt/build/include \
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
