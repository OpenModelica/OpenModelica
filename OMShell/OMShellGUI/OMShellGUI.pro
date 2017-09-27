QT += core gui xml
greaterThan(QT_MAJOR_VERSION, 4) {
    QT *= printsupport widgets webkitwidgets
}

TRANSLATIONS = \
  OMShell_de.ts \
  OMShell_sv.ts

TARGET = OMShell
TEMPLATE = app

SOURCES += commandcompletion.cpp \
    omcinteractiveenvironment.cpp \
    oms.cpp \
    main.cpp

HEADERS += commandcompletion.h \
    omcinteractiveenvironment.h \
    oms.h

win32 {
  # define used for OpenModelica C-API
  DEFINES += IMPORT_INTO=1
  # win32 vs. win64
  contains(QT_ARCH, i386) { # 32-bit
    QMAKE_LFLAGS += -Wl,--stack,16777216,--enable-auto-import,--large-address-aware
  } else { # 64-bit
    QMAKE_LFLAGS += -Wl,--stack,33554432,--enable-auto-import
  }
  OMCLIBS = -L$$(OMBUILDDIR)/lib/omc -lOpenModelicaCompiler -lOpenModelicaRuntimeC -lfmilib -lModelicaExternalC -lomcgc -lpthread
  OMCINC = $$(OMBUILDDIR)/include/omc/c
} else {
  include(OMShell.config)
}

LIBS += $${OMCLIBS}
INCLUDEPATH += $${OMCINC}

CONFIG += warn_off

RESOURCES += oms.qrc

RC_FILE = rc_omshell.rc

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

ICON = Resources/omshell.icns

!isEmpty(TRANSLATIONS) {
  isEmpty(QMAKE_LRELEASE) {
    win32:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]\lrelease.exe
    else:QMAKE_LRELEASE = $$[QT_INSTALL_BINS]/lrelease
  }

  TSQM.name = lrelease ${QMAKE_FILE_IN}
  TSQM.input = TRANSLATIONS
  TSQM.output = ${QMAKE_FILE_BASE}.qm
  TSQM.commands = $$QMAKE_LRELEASE ${QMAKE_FILE_IN}
  TSQM.CONFIG = no_link
  QMAKE_EXTRA_COMPILERS += TSQM
  PRE_TARGETDEPS += compiler_TSQM_make_all
} else:message(No translation files in project)
