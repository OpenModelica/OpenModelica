QT += core gui xml

TARGET = OMShell
TEMPLATE = app

SOURCES += commandcompletion.cpp \
    ../../OMEdit/OMEditGUI/omc_communication.cpp \
    omc_communicator.cpp \
    omcinteractiveenvironment.cpp \
    oms.cpp \
    main.cpp

HEADERS += commandcompletion.h \
    ../../OMEdit/OMEditGUI/omc_communication.h \
    omc_communicator.h \
    omcinteractiveenvironment.h \
    oms.h

# -------For OMNIorb
win32 {
  DEFINES += __x86__ \
             __NT__ \
             __OSVERSION__=4 \
             __WIN32__
  CORBAINC = $$(OMDEV)/lib/omniORB-4.1.4-mingw/include
  CORBALIBS = $$(OMDEV)/lib/omniORB-4.1.4-mingw/lib/x86_win32
} else {
  include(OMShell.config)
}
#---------End OMNIorb

INCLUDEPATH += $${CORBAINC}
LIBS += -L$${CORBALIBS} -lomniORB414_rt \
        -lomnithread34_rt

CONFIG += warn_off

RESOURCES += oms.qrc

RC_FILE = rc_omshell.rc

DESTDIR = ../bin

UI_DIR = ../generatedfiles/ui

MOC_DIR = ../generatedfiles/moc

RCC_DIR = ../generatedfiles/rcc

ICON = Resources/omshell.icns
