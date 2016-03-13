cmake_minimum_required(VERSION 2.8.9)

project(${MathName})

add_library(${MathName}_static STATIC ArrayOperations.cpp Functions.cpp  FactoryExport.cpp)
add_library(${MathName} SHARED ArrayOperations.cpp Functions.cpp FactoryExport.cpp)

install (TARGETS ${MathName}_static DESTINATION ${LIBINSTALLEXT})

target_link_libraries (${MathName} ${Boost_LIBRARIES} ${UMFPACK_LIB} ${LAPACK_LIBRARIES})
set_target_properties(${MathName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

install (TARGETS ${MathName} DESTINATION ${LIBINSTALLEXT})
add_precompiled_header(${MathName} Include/Core/Modelica.h )

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Math/Functions.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/ArrayOperations.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/Utility.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/Constants.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/SparseMatrix.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/ILapack.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/OMAPI.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/Array.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/ArraySlice.h
	 DESTINATION include/omc/cpp/Core/Math)
