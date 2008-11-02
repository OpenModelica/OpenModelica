TEMPLATE = app

DEPENDPATH += .
MICOHOME = $$system(mico-config --prefix)
INCLUDEPATH += $${MICOHOME}/include
MICO_LIBS = $$system(mico-config --libs)
LIBS+= $${MICO_LIBS}
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
