cmake_minimum_required(VERSION 3.14)

# Define sources with a local glob
file(GLOB OMC_SIMRT_MOO_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
file(GLOB OMC_SIMRT_MOO_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCMoo OBJECT ${OMC_SIMRT_MOO_SOURCES})
add_library(omc::simrt::simruntime::moo ALIAS OpenModelicaRuntimeCMoo)

target_include_directories(OpenModelicaRuntimeCMoo
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

target_include_directories(OpenModelicaRuntimeCMoo
  PRIVATE
    omc::simrt::simruntime # TODO: Update to omc::simrt::simulation::solver
    sundials_interface # TODO: The simulation/solver stuff needs to link this...
    omc::3rd::suitesparse::klu
    omc::3rd::suitesparse::config
)

target_link_libraries(OpenModelicaRuntimeCMoo
  PUBLIC
    omc::config
    omc::simrt::runtime::headers
    omc::3rd::moo
    sundials_interface
    omc::3rd::suitesparse::klu
    omc::3rd::suitesparse::config
)

target_compile_definitions(OpenModelicaRuntimeCMoo PUBLIC OMC_HAVE_MOO)

# Install headers
install(
  FILES ${OMC_SIMRT_MOO_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/SimulationRuntime/c/moo)
