cmake_minimum_required(VERSION 2.8.9)

project(${CppDASSLName})

add_library(${CppDASSLName} ddaskr.cpp CppDASSL.cpp CppDASSLSettings.cpp FactoryExport.cpp)

set(CPPDASSL_COMPILE_DEFINITIONS "")
if(OPENMP_FOUND)
  set(CPPDASSL_COMPILE_DEFINITIONS "USE_OPENMP")
else(OPENMP_FOUND)
  set(OpenMP_CXX_FLAGS "")
endif(OPENMP_FOUND)

target_link_libraries(${CppDASSLName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${UMFPACK_LIB})

if(OPENMP_FOUND)
  set_target_properties(${CppDASSLName} PROPERTIES LINK_FLAGS ${OpenMP_CXX_FLAGS})
endif(OPENMP_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${CppDASSLName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:${CppDASSLName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

set_target_properties(${CppDASSLName} PROPERTIES COMPILE_DEFINITIONS "${CPPDASSL_COMPILE_DEFINITIONS}")
set_target_properties(${CppDASSLName} PROPERTIES COMPILE_FLAGS "${OpenMP_CXX_FLAGS}")

add_precompiled_header(${CppDASSLName} runtime/include/Solver/Modelica.h)



install(TARGETS ${CppDASSLName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/CppDASSL/CppDASSL.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/CppDASSL/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/CppDASSL)
