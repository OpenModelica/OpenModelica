#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg
greaterThan(QT_MAJOR_VERSION, 4) {
    QT *= printsupport widgets
}

TARGET = OMPlot
TEMPLATE = app
CONFIG += console

SOURCES += main.cpp

HEADERS += OMPlot.h \
    PlotZoomer.h \
    Legend.h \
    PlotPanner.h \
    PlotPicker.h \
    PlotGrid.h \
    PlotCurve.h \
    PlotWindow.h \
    PlotApplication.h \
    PlotWindowContainer.h \
    PlotMainWindow.h \
    ScaleDraw.h

win32 {
  QMAKE_LFLAGS += -Wl,--enable-auto-import
  CONFIG(debug, debug|release){
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwtd
  }
  else {
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwt
  }
  INCLUDEPATH += $$(OMBUILDDIR)/include/omplot/qwt $$(OMBUILDDIR)/include/omc/c
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
