# Include Directorys

# find and setup Qt4 for this project
find_package(Qt4 REQUIRED)

INCLUDE_DIRECTORIES(${QT_QTCORE_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTNETWORK_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTGUI_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTCORE_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTGUI_INCLUDE_DIR}/../)

SET(QT_LIBRARIES "${QT_LIBRARIES}" ${QT_QTCORE_LIBRARY} ${QT_QTGUI_LIBRARY} ${QT_QTNETWORK_LIBRARY} ${QT_QTDESIGNER_LIBRARY})

# Quellen und Header
SET(sendData_sources  sendData.cpp )
SET(sendData_headers  sendData.h)				 
						 

#ADD_DEFINITIONS(/O2 /frtti /fexceptions /mthreads /Wall /DUNICODE /DQT_LARGEFILE_SUPPORT /DQT_NO_DEBUG /DQT_GUI_LIB /DQT_NETWORK_LIB /DQT_CORE_LIB /DQT_THREAD_SUPPORT)
add_definitions(/MT)
# Bibliothek
ADD_LIBRARY(sendData ${sendData_sources} ${sendData_headers})
TARGET_LINK_LIBRARIES(sendData ${QT_LIBRARIES})

