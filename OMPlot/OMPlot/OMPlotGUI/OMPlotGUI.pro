#-------------------------------------------------
#
# Project created by QtCreator 2011-02-01T16:47:11
#
#-------------------------------------------------

QT += core gui svg printsupport widgets
equals(QT_MAJOR_VERSION, 6) {
  QT += core5compat
}

# Set the C++ standard.
CONFIG += c++17

TARGET = OMPlot
TEMPLATE = app
CONFIG += cmdline

SOURCES += main.cpp

win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS_EXCEPTIONS_ON -= -mthreads
  }

  QMAKE_LFLAGS += -Wl,--enable-auto-import
  CONFIG(debug, debug|release){
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwtd -lOpenModelicaRuntimeC
  }
  else {
    LIBS += -L$$(OMBUILDDIR)/lib/omc -lOMPlot -lomqwt -lOpenModelicaRuntimeC
  }
  INCLUDEPATH += $$(OMBUILDDIR)/include/omplot/qwt $$(OMBUILDDIR)/include/omc/c
} else {
  include(OMPlotGUI.config)
  LIBS += -lOMPlot
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

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

RESOURCES += resource_omplot.qrc

RC_FILE = rc_omplot.rc

