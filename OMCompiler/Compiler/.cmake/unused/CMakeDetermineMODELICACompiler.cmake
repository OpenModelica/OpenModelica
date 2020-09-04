# Find the compiler
# find_program(
#     CMAKE_MODELICA_COMPILER
#         NAMES "omc"
#         HINTS "${CMAKE_SOURCE_DIR}"
#         DOC "OpenModelicaModelica compiler"
# )

set(CMAKE_MODELICA_COMPILER ${PROJECT_SOURCE_DIR}/../build/bin/omc.exe)

mark_as_advanced(CMAKE_MODELICA_COMPILER)

set(CMAKE_MODELICA_SOURCE_FILE_EXTENSIONS mo)
set(CMAKE_MODELICA_OUTPUT_EXTENSION .c)
set(CMAKE_MODELICA_COMPILER_ENV_VAR "Modelica")

configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeMODELICACompiler.cmake.in
               ${CMAKE_PLATFORM_INFO_DIR}/CMakeMODELICACompiler.cmake)
