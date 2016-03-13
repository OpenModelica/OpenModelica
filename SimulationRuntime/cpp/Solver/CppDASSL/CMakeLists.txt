cmake_minimum_required(VERSION 2.8.9)

project(${CppDASSLName})

add_library(${CppDASSLName}_static STATIC ddaskr.cpp CppDASSL.cpp CppDASSLSettings.cpp FactoryExport.cpp)

SET(CPPDASSL_COMPILE_DEFINITIONS "")
IF(OPENMP_FOUND)
	SET(CPPDASSL_COMPILE_DEFINITIONS "USE_OPENMP")
ELSE(OPENMP_FOUND)
	SET(OpenMP_CXX_FLAGS "")
ENDIF(OPENMP_FOUND)

add_precompiled_header(${CppDASSLName}_static Include/Core/Modelica.h )
install (TARGETS ${CppDASSLName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${CppDASSLName} SHARED ddaskr.cpp CppDASSL.cpp CppDASSLSettings.cpp FactoryExport.cpp  )
target_link_libraries (${CppDASSLName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${UMFPACK_LIB})

IF(OPENMP_FOUND)
	set_target_properties(${CppDASSLName}_static PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
	set_target_properties(${CppDASSLName} PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
ENDIF(OPENMP_FOUND)

set_target_properties(${CppDASSLName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;${CPPDASSL_COMPILE_DEFINITIONS}")
set_target_properties(${CppDASSLName} PROPERTIES COMPILE_DEFINITIONS "${CPPDASSL_COMPILE_DEFINITIONS}")

set_target_properties(${CppDASSLName}_static PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")
set_target_properties(${CppDASSLName} PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")

add_precompiled_header(${CppDASSLName} Include/Core/Modelica.h )

install (TARGETS ${CppDASSLName} ${CppDASSLName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/CppDASSL/CppDASSL.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CppDASSL/FactoryExport.h
DESTINATION include/omc/cpp/Solver/CppDASSL)
