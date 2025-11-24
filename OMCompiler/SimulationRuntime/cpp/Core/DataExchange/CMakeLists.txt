CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${DataExchangeName})

add_library(${DataExchangeName} SimData.cpp FactoryExport.cpp XmlPropertyReader.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${DataExchangeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName}  ${ModelicaName})
endif(NOT BOOST_STATIC_LINKING)

add_precompiled_header(${DataExchangeName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${DataExchangeName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${DataExchangeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/IHistory.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/ISimVar.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/SimData.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/Writer.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/SimDouble.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/SimBoolean.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/XmlPropertyReader.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/IPropertyReader.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/FactoryPolicy.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/DefaultContainerManager.h
  ${CMAKE_SOURCE_DIR}/Core/DataExchange/ParallelContainerManager.h
  DESTINATION include/omc/cpp/Core/DataExchange)
