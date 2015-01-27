CMAKE_MINIMUM_REQUIRED (VERSION 2.6)

project(${ExtensionUtilitiesName})
IF(RUNTIME_STATIC_LINKING)
	add_library(${ExtensionUtilitiesName} STATIC measure_time.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp)
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${ExtensionUtilitiesName} SHARED measure_time.cpp measure_time_rdtsc.cpp measure_time_scorep.cpp)
ENDIF(RUNTIME_STATIC_LINKING)

IF(NOT BOOST_STATIC_LINKING)
	target_link_libraries (${ExtensionUtilitiesName} ${Boost_LIBRARIES})
ENDIF(NOT BOOST_STATIC_LINKING)

IF(UNIX)
	set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_FLAGS -fPIC)
ENDIF(UNIX)

install (TARGETS ${ExtensionUtilitiesName} DESTINATION lib/omc/${LIBINSTALLEXT})

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
	
	install (TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION lib/omc/${LIBINSTALLEXT})

	install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_papi.hpp
		 DESTINATION include/omc/cpp/Core/Utils/extension)
ENDIF(PAPI_FOUND)
