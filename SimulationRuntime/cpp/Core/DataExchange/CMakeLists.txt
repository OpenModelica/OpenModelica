cmake_minimum_required (VERSION 2.8.6)

project(${DataExchangeName})

add_library(${DataExchangeName} SHARED SimData.cpp FactoryExport.cpp )

IF(NOT BOOST_STATIC_LINKING)
	target_link_libraries (${DataExchangeName} ${Boost_LIBRARIES})
ENDIF(NOT BOOST_STATIC_LINKING)

IF(RUNTIME_STATIC_LINKING)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
ELSE(RUNTIME_STATIC_LINKING)
add_precompiled_header(${DataExchangeName} Include/Core/Modelica.h )
ENDIF(RUNTIME_STATIC_LINKING)

add_library(${DataExchangeName}_static STATIC SimData.cpp  )

IF(NOT BOOST_STATIC_LINKING)
	target_link_libraries (${DataExchangeName}_static ${Boost_LIBRARIES})
ENDIF(NOT BOOST_STATIC_LINKING)

if (UNIX)
	set_target_properties(${DataExchangeName}_static PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${DataExchangeName} DESTINATION ${LIBINSTALLEXT})
install (TARGETS ${DataExchangeName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/IHistory.h
				${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/ISimVar.h
				${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimData.h
				${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/Writer.h
                ${CMAKE_SOURCE_DIR}/Include/Core/DataExchange/SimDouble.h
  DESTINATION include/omc/cpp/Core/DataExchange)






