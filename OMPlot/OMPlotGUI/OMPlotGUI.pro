#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg

TARGET = OMPlot
TEMPLATE = app
CONFIG += console

SOURCES += main.cpp

HEADERS += Plot.h \
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
  QMAKE_LFLAGS += -enable-auto-import
  CONFIG(debug, debug|release){
    LIBS += -L../../../OMCompiler/build/lib/omc -lOMPlot -lomqwtd
  }
  else {
    LIBS += -L../../../OMCompiler/build/lib/omc -lOMPlot -lomqwt
  }
  INCLUDEPATH += ../../../OMCompiler/build/include/omc/qwt ../../../OMCompiler/build/include/omc/c
} else {
  include(OMPlotGUI.config)
  LIBS += -lOMPlot
}

INCLUDEPATH += .

CONFIG += warn_off

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

RESOURCES += resource_omplot.qrc

RC_FILE = rc_omplot.rc
