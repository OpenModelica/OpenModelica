cmake_minimum_required(VERSION 3.5)

project(${DataExchangeName})

add_library(${DataExchangeName} SimData.cpp FactoryExport.cpp XmlPropertyReader.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${DataExchangeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${DataExchangeName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

if(NOT BOOST_STATIC_LINKING)
  target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES} ${ExtensionUtilitiesName}  ${ModelicaName})

endif(NOT BOOST_STATIC_LINKING)

add_precompiled_header(${DataExchangeName} runtime/include/Core/Modelica.h)



install(TARGETS ${DataExchangeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/IHistory.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/ISimVar.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/SimData.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/Writer.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/SimDouble.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/SimBoolean.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/XmlPropertyReader.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/IPropertyReader.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/FactoryExport.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/FactoryPolicy.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/DefaultContainerManager.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/ParallelContainerManager.h
  DESTINATION include/omc/omsicpp/Core/DataExchange)
