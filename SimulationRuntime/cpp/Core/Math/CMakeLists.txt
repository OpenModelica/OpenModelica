cmake_minimum_required (VERSION 2.8.6)

project(${MathName})
# add the solver default implementation library

add_library(${MathName}_static STATIC ArrayOperations.cpp Functions.cpp SparseMatrix.cpp FactoryExport.cpp)
IF(UNIX)
	set_target_properties(${MathName}_static PROPERTIES COMPILE_FLAGS -fPIC)
ENDIF(UNIX)
install (TARGETS ${MathName}_static DESTINATION lib/omc/${LIBINSTALLEXT})

IF(RUNTIME_STATIC_LINKING)
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${MathName} SHARED ArrayOperations.cpp Functions.cpp SparseMatrix.cpp FactoryExport.cpp)
	target_link_libraries (${MathName} ${Boost_LIBRARIES} ${UMFPACK_LIB} ${LAPACK_LIBRARIES})
	IF(UNIX)
		set_target_properties(${MathName} PROPERTIES COMPILE_FLAGS -fPIC)
	ENDIF(UNIX)
	install (TARGETS ${MathName} DESTINATION lib/omc/${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Math/Functions.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/ArrayOperations.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/Utility.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/Constants.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/SparseMatrix.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/ILapack.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/OMAPI.h
		   ${CMAKE_SOURCE_DIR}/Include/Core/Math/Array.h
         DESTINATION include/omc/cpp/Core/Math)
