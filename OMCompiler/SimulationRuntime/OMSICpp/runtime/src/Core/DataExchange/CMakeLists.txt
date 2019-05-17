cmake_minimum_required(VERSION 2.8.9)

project(${DataExchangeName})

add_library(${DataExchangeName} SimData.cpp FactoryExport.cpp XmlPropertyReader.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${DataExchangeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
 install(FILES $<TARGET_PDB_FILE:${DataExchangeName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName}  ${ModelicaName})

endif(NOT BOOST_STATIC_LINKING)

add_precompiled_header(${DataExchangeName} runtime/include/Core/Modelica.h)



install(TARGETS ${DataExchangeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/IHistory.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/ISimVar.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/SimData.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/Writer.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/SimDouble.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/SimBoolean.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/XmlPropertyReader.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/IPropertyReader.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/FactoryPolicy.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/DefaultContainerManager.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Core/DataExchange/ParallelContainerManager.h
  DESTINATION include/omc/omsicpp/Core/DataExchange)
