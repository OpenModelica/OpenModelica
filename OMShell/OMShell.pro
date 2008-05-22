TEMPLATE = app

DEPENDPATH += .
INCLUDEPATH += /home/openmodelica/dev/mico/include
LIBS+=-L/home/openmodelica/dev/mico/lib -lmico2.3.12  -lm  -lpthread
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