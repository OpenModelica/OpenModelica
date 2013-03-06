cmake_minimum_required (VERSION 2.6)

project(${ModelicaName})

add_library(${ModelicaName} SHARED ModelicaSystem.cpp )

target_link_libraries (${ModelicaName}  ${SystemName} ${ModelicaExternalCName}  ${MathName})


GET_TARGET_PROPERTY(libModelicaSystem ${ModelicaName} LOCATION)
GET_FILENAME_COMPONENT(libModelicaSystemName ${libModelicaSystem} NAME)


set (BOOST_INCLUDE ${Boost_INCLUDE_DIRS})
set (BOOST_LIBS ${Boost_LIBRARY_DIRS})
set (MODELICA_SYSTEM_LIB ${libModelicaSystemName})
 configure_file (
  "ModelicaConfic.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfic.inc"
  )



install (FILES

				${PROJECT_BINARY_DIR}/ModelicaConfic.inc
				DESTINATION include/omc/cpp)


install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/HistoryImpl.h  ${CMAKE_SOURCE_DIR}/Include/Core/Modelica.h DESTINATION include/omc/cpp)
install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Policies/TextfileWriter.h DESTINATION include/omc/cpp/Core/DataExchange/Policies)
#if(REDUCE_DAE)
#install (FILES Policies/BufferReaderWriter.h DESTINATION include/omc/cpp/policies)
#endif()



