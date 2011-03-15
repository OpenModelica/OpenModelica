#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT       += core gui

TARGET = OMPlot
TEMPLATE = lib

CONFIG += release staticlib

SOURCES += main.cpp \
    ../../c_runtime/read_matlab4.c \
    Plot.cpp \
    PlotCanvas.cpp \
    PlotZoomer.cpp \
    Legend.cpp \
    PlotPanner.cpp \
    PlotGrid.cpp \
    PlotCurve.cpp \
    PlotPicker.cpp \
    PlotWindow.cpp

HEADERS  += ../../c_runtime/read_matlab4.h \
    Plot.h \
    PlotCanvas.h \
    PlotZoomer.h \
    Legend.h \
    PlotPanner.h \
    PlotGrid.h \
    PlotCurve.h \
    PlotPicker.h \
    PlotWindow.h

win32 {
LIBS += -L$$(OMDEV)/lib/qwt-5.2.1-mingw/lib -lqwt5
INCLUDEPATH += $$(OMDEV)/lib/qwt-5.2.1-mingw/include
} else {
  include(OMPlotGUI.config)
}

CONFIG += warn_off

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc
