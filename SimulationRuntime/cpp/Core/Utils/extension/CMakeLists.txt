cmake_minimum_required (VERSION 2.8.6)

project(${ExtensionUtilitiesName})

add_library(${ExtensionUtilitiesName}_static STATIC measure_time.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp)
IF(NOT BOOST_STATIC_LINKING)
	target_link_libraries (${ExtensionUtilitiesName}_static ${Boost_LIBRARIES})
ENDIF(NOT BOOST_STATIC_LINKING)
IF(UNIX)
	set_target_properties(${ExtensionUtilitiesName}_static PROPERTIES COMPILE_FLAGS -fPIC)
ENDIF(UNIX)
set_target_properties(${ExtensionUtilitiesName}_static PROPERTIES COMPILE_DEFINITIONS "DRUNTIME_STATIC_LINKING")
install (TARGETS ${ExtensionUtilitiesName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${ExtensionUtilitiesName} SHARED measure_time.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp)
IF(NOT BOOST_STATIC_LINKING)
	target_link_libraries (${ExtensionUtilitiesName} ${Boost_LIBRARIES})
ENDIF(NOT BOOST_STATIC_LINKING)
IF(UNIX)
	set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_FLAGS -fPIC)
ENDIF(UNIX)

install (TARGETS ${ExtensionUtilitiesName} DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time.hpp
                ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_rdtsc.hpp
                ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_scorep.hpp
		${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/busywaiting_barrier.hpp
         DESTINATION include/omc/cpp/Core/Utils/extension)

IF(PAPI_FOUND)
	add_library("${ExtensionUtilitiesName}_papi" SHARED measure_time_papi.cpp)

	IF(NOT BOOST_STATIC_LINKING)
		target_link_libraries ("${ExtensionUtilitiesName}_papi" ${Boost_LIBRARIES})
	ENDIF(NOT BOOST_STATIC_LINKING)
	
	install (TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION ${LIBINSTALLEXT})

	install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_papi.hpp
		 DESTINATION include/omc/cpp/Core/Utils/extension)
ENDIF(PAPI_FOUND)
