TEMPLATE = app

DEPENDPATH += .
INCLUDEPATH += /home/adrpo/dev/mico-2.3.12/include
LIBS+=-L/home/adrpo/dev/mico-2.3.12/lib -lmico2.3.12   -lssl -lcrypto -ldl -lbsd -lm  -lpthread
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

