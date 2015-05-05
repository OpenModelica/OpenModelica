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

SOURCES += Plot.cpp \
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

HEADERS  += Plot.h \
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
    LIBS += -L../../../OMCompiler/build/lib/omc -lomqwtd
  }
  else {
    LIBS += -L../../../OMCompiler/build/lib/omc -lomqwt
  }
  INCLUDEPATH += ../../../OMCompiler/build/include/omc/qwt ../../../OMCompiler/build/include/omc/c
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
