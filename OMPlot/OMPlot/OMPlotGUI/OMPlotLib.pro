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
TEMPLATE = lib

win32 {
 CONFIG += staticlib
}
QMAKE_LFLAGS += -enable-auto-import

SOURCES += Plot.cpp \
    PlotZoomer.cpp \
    Legend.cpp \
    PlotPanner.cpp \
    PlotPicker.cpp \
    PlotGrid.cpp \
    PlotCurve.cpp \
    PlotWindow.cpp \
    PlotApplication.cpp \
    PlotWindowContainer.cpp \
    PlotMainWindow.cpp \
    ScaleDraw.cpp

HEADERS  += OMPlot.h \
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
  CONFIG(debug, debug|release){
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lomqwtd
  }
  else {
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lomqwt
  }
  INCLUDEPATH += $$(OMBUILDDIR)/include/omplot/qwt $$(OMBUILDDIR)/include/omc/c
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
