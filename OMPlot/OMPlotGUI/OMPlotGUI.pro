#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT       += core gui

TARGET = OMPlot
TEMPLATE = lib

CONFIG += release

SOURCES += main.cpp \
        plotwindow.cpp \
    ../../c_runtime/read_matlab4.c

HEADERS  += plotwindow.h \
    ../../c_runtime/read_matlab4.h

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
