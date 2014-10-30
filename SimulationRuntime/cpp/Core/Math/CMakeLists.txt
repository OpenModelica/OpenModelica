cmake_minimum_required (VERSION 2.6)

project(${MathName})
# add the solver default implementation library
IF(ANALYZATION_MODE)
	add_library(${MathName} STATIC ArrayOperations.cpp Functions.cpp SparseMatrix.cpp FactoryExport.cpp)
ELSE(ANALYZATION_MODE)
	add_library(${MathName} SHARED ArrayOperations.cpp Functions.cpp SparseMatrix.cpp FactoryExport.cpp)
ENDIF(ANALYZATION_MODE)

target_link_libraries (${MathName}  ${Boost_LIBRARIES} )
if (UNIX)
set_target_properties(${MathName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${MathName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/Math/Functions.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/ArrayOperations.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/Utility.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/Constants.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/SparseMatrix.h
	  ${CMAKE_SOURCE_DIR}/Include/Core/Math/ILapack.h
          ${CMAKE_SOURCE_DIR}/Include/Core/Math/OMAPI.h
		   ${CMAKE_SOURCE_DIR}/Include/Core/Math/Array.h
         DESTINATION include/omc/cpp/Core/Math)
