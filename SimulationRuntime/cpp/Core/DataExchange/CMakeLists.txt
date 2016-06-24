cmake_minimum_required(VERSION 2.8.9)

project(${DataExchangeName})

add_library(${DataExchangeName} SimData.cpp FactoryExport.cpp XmlPropertyReader.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${DataExchangeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName})
endif(NOT BOOST_STATIC_LINKING)

add_precompiled_header(${DataExchangeName} Include/Core/Modelica.h)

install(TARGETS ${DataExchangeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/IHistory.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/ISimVar.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimData.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Writer.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimDouble.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimBoolean.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/XmlPropertyReader.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/IPropertyReader.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/FactoryPolicy.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/DefaultContainerManager.h
  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/ParallelContainerManager.h
  DESTINATION include/omc/cpp/Core/DataExchange)
