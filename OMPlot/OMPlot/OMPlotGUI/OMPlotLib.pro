#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg
greaterThan(QT_MAJOR_VERSION, 4) {
  QT *= printsupport widgets
}

# Set the C++ standard.
CONFIG += c++1z

TARGET = OMPlot
TEMPLATE = lib

win32 {
 CONFIG += staticlib
}
QMAKE_LFLAGS += -Wl,--enable-auto-import

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
  ScaleDraw.cpp \
  LogScaleEngine.cpp \
  LinearScaleEngine.cpp

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
  ScaleDraw.h \
  LogScaleEngine.h \
  LinearScaleEngine.h

win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS_EXCEPTIONS_ON -= -mthreads
  }

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

# Please read the warnings. They are like vegetables; good for you even if you hate them.
CONFIG += warn_on
win32 {
  # -Wno-clobbered is not recognized by clang
  !contains(_cxx, clang++) {
    QMAKE_CXXFLAGS += -Wno-clobbered
  }
}

QMAKE_CXXFLAGS += "-DLOG_MIN=1e-20 -DLOG_MAX=1e20"

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

RESOURCES += resource_omplot.qrc
