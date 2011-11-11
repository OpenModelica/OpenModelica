# Include Directorys

# find and setup Qt4 for this project
find_package(Qt4)

IF(QT_QTCORE_INCLUDE_DIR)
INCLUDE_DIRECTORIES(${QT_QTCORE_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTNETWORK_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTGUI_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTCORE_INCLUDE_DIR})
INCLUDE_DIRECTORIES(${QT_QTGUI_INCLUDE_DIR}/../)

SET(QT_LIBRARIES "${QT_LIBRARIES}" ${QT_QTCORE_LIBRARY} ${QT_QTGUI_LIBRARY} ${QT_QTNETWORK_LIBRARY} ${QT_QTDESIGNER_LIBRARY})

# Quellen und Header
SET(sendData_sources  sendData.cpp )
			 
# Library sendData
#ADD_DEFINITIONS(/O2 /frtti /fexceptions /mthreads /Wall /DUNICODE /DQT_LARGEFILE_SUPPORT /DQT_NO_DEBUG /DQT_GUI_LIB /DQT_NETWORK_LIB /DQT_CORE_LIB /DQT_THREAD_SUPPORT)

SET(sendData_headers  sendData.h)				 

ADD_LIBRARY(sendData ${sendData_sources} ${sendData_headers})
TARGET_LINK_LIBRARIES(sendData ${QT_LIBRARIES})

ELSE(QT_QTCORE_INCLUDE_DIR)
MESSAGE(" QT is not availivle use NOSENDDATA")

# Quellen und Header
SET(sendData_sources  nosendData.cpp)				 
SET(sendData_headers  sendData.h)				 

ADD_DEFINITIONS(/DnosendData)
ADD_LIBRARY(sendData ${sendData_sources} ${sendData_headers})

# Install
INSTALL(TARGETS sendData
		ARCHIVE DESTINATION lib)
ENDIF(QT_QTCORE_INCLUDE_DIR)

