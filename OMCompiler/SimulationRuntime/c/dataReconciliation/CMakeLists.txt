cmake_minimum_required(VERSION 3.14)

find_package(LAPACK REQUIRED)

# Define sources with a local glob
file(GLOB OMC_SIMRT_DATA_RECONCILIATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
file(GLOB OMC_SIMRT_DATA_RECONCILIATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCDataReconciliation OBJECT ${OMC_SIMRT_DATA_RECONCILIATION_SOURCES})
add_library(omc::simrt::simruntime::dataReconciliation ALIAS OpenModelicaRuntimeCDataReconciliation)

target_include_directories(OpenModelicaRuntimeCDataReconciliation
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/dataReconciliation>
)

target_link_libraries(OpenModelicaRuntimeCDataReconciliation
  PUBLIC
    omc::config
    omc::simrt::runtime::headers
    ${LAPACK_LIBRARIES}
)

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeCDataReconciliation PUBLIC regex)
elseif(MSVC)
  target_link_libraries(OpenModelicaRuntimeCDataReconciliation PUBLIC omc::3rd::regex)
endif()

# Install headers
install(
  FILES ${OMC_SIMRT_DATA_RECONCILIATION_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/dataReconciliation)
