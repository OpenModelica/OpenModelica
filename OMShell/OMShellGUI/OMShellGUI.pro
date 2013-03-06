QT += core gui xml

TRANSLATIONS = \
  OMShell_de.ts \
  OMShell_sv.ts

TARGET = OMShell
TEMPLATE = app

SOURCES += commandcompletion.cpp \
    omc_communication.cc \
    omc_communicator.cpp \
    omcinteractiveenvironment.cpp \
    oms.cpp \
    main.cpp

HEADERS += commandcompletion.h \
    omc_communication.h \
    omc_communicator.h \
    omcinteractiveenvironment.h \
    oms.h

# -------For OMNIorb
win32 {
  QMAKE_LFLAGS += -enable-auto-import
  DEFINES += __x86__ \
             __NT__ \
             __OSVERSION__=4 \
             __WIN32__
  CORBAINC = $$(OMDEV)/lib/omniORB-4.1.6-mingw/include
  CORBALIBS = -L$$(OMDEV)/lib/omniORB-4.1.6-mingw/lib/x86_win32 -lomniORB416_rt -lomnithread34_rt
  INCLUDEPATH += ../../
} else {
  include(OMShell.config)
}
#---------End OMNIorb

INCLUDEPATH += $${CORBAINC}
LIBS += $${CORBALIBS}

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
