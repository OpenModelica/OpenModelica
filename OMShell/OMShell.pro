TEMPLATE = app

DEPENDPATH += .
win32 {
  CORBAINC = $$system(mico-config --prefix)/include
  CORBALIBS = $$system(mico-config --libs)
} else {
  CORBAINC = $$(CORBACFLAGS)
  CORBALIBS = $$(CORBALIBS)
}

INCLUDEPATH += $${CORBAINC)
LIBS+= $${CORBALIBS}

CONFIG += warn_on
QT += network xml

HEADERS += commandcompletion.h \
           omc_communication.h \
           omc_communicator.h \
           omcinteractiveenvironment.h \
           oms.h
SOURCES += commandcompletion.cpp \
           omc_communication.cc \
           omc_communicator.cpp \
           omcinteractiveenvironment.cpp \
           oms.cpp \
           main.cpp

RESOURCES += oms.qrc
