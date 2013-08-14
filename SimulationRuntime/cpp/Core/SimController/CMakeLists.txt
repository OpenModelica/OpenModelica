cmake_minimum_required (VERSION 2.6)

project(${SimManagerName})
add_executable(${SimManagerName}  Configuration.cpp Main.cpp FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp)
target_link_libraries( ${SimManagerName}  ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )


install (TARGETS ${SimManagerName} DESTINATION bin)

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimData.h
        
      DESTINATION include/omc/cpp/Core/SimController)