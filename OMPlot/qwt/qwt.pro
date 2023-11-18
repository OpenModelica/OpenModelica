################################################################
# Qwt Widget Library
# Copyright (C) 1997   Josef Wilgen
# Copyright (C) 2002   Uwe Rathmann
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Qwt License, Version 1.0
################################################################

lessThan(QT_MAJOR_VERSION, 5) {

    lessThan(QT_MINOR_VERSION, 8) {
        error(Qt >= 4.8 required.)
    }
}

include( qwtconfig.pri )

TEMPLATE = subdirs
CONFIG   += ordered

SUBDIRS = src

contains(QWT_CONFIG, QwtDesigner ) {
    SUBDIRS += designer
}

contains(QWT_CONFIG, QwtExamples ) {
    SUBDIRS += examples
}

contains(QWT_CONFIG, QwtPlayground ) {
    SUBDIRS += playground
}

qwtspec.files  = qwtconfig.pri qwtfunctions.pri qwt.prf
qwtspec.path  = $${QWT_INSTALL_FEATURES}

INSTALLS += qwtspec

include ( qwt.config )

win32 {
  _cxx = $$(CXX)
  contains(_cxx, clang++) {
    message("Found clang++ on windows in $CXX, removing unknown flags: -fno-keep-inline-dllexport")
    QMAKE_CFLAGS -= -fno-keep-inline-dllexport
    QMAKE_CXXFLAGS -= -fno-keep-inline-dllexport
  }
}
