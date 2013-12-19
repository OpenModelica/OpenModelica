cmake_minimum_required (VERSION 2.6)

project(${SimControllerName})
add_library(${SimControllerName} SHARED Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp)
target_link_libraries( ${SimControllerName}  ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )


install (TARGETS ${SimControllerName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimData.h
			   ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimController.h
        
      DESTINATION include/omc/cpp/Core/SimController)