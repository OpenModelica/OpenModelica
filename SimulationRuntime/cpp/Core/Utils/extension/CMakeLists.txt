CMAKE_MINIMUM_REQUIRED (VERSION 2.6)

project(${ExtensionUtilitiesName})

add_library(${ExtensionUtilitiesName} SHARED measure_time.cpp measure_time_rdtsc.cpp)
target_link_libraries (${ExtensionUtilitiesName} ${Boost_LIBRARIES})

if (UNIX)
	set_target_properties(${ExtensionUtilitiesName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${ExtensionUtilitiesName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time.hpp
                ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_rdtsc.hpp
         DESTINATION include/omc/cpp/Core/Utils/extension)

IF(PAPI_FOUND)
	add_library("${ExtensionUtilitiesName}_papi" SHARED measure_time_papi.cpp)
	target_link_libraries ("${ExtensionUtilitiesName}_papi" ${Boost_LIBRARIES})
	install (TARGETS "${ExtensionUtilitiesName}_papi" DESTINATION lib/omc/${LIBINSTALLEXT})

	install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Utils/extension/measure_time_papi.hpp
		 DESTINATION include/omc/cpp/Core/Utils/extension)
ENDIF(PAPI_FOUND)
