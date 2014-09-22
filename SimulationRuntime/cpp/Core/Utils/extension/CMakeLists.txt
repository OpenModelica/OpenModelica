cmake_minimum_required (VERSION 2.6)

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
