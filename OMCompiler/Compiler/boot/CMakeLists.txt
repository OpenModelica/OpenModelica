cmake_minimum_required(VERSION 3.14)
project(bomc)

# OpenModelicaBootstrappingHeader.h should probably be added to source control and
# updated just like the bootstrap-source c files.
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tarball-include/OpenModelicaBootstrappingHeader.h
                ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h)

file(GLOB BOOTSTRAP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/bootstrap-sources/build/*.c)

add_executable(bomc)
target_sources(bomc PRIVATE ${BOOTSTRAP_SOURCES})
target_sources(bomc PRIVATE ../.cmake/omc_main.c)

target_compile_definitions(bomc PRIVATE ADD_METARECORD_DEFINITIONS=)

# Silence warnings about extra parenthesized equality checks. if((a==b)).
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  target_compile_options(bomc PRIVATE -Wno-parentheses-equality)
endif()

# OMC will overflow the stack (at least on Windows old OMDev) on very deep recursive calls.
# E.g., try translating the CodegenCpp* tpl files to mo files with
# an omc not compiled without large stack size. The tpl parser is quite recursive and will
# overflow on parsing comments with very long lines ~300. *CPP tpl files have lines longer
# than that.
if(MINGW)
  target_link_options(bomc PRIVATE -Wl,--stack,33554432)
endif()


# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(bomc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../Util)

target_link_libraries(bomc PRIVATE omc::parser)
target_link_libraries(bomc PRIVATE omc::compiler::runtime)
target_link_libraries(bomc PRIVATE omc::compiler::graphstream)


# Set up for proper usage of the bootstrap omc (bomc).

# omc (bomc) refuses to run if it is not in a directory named ...../bin/.
# It uses that assumption to locate the lib dir and everything it needs.
# With cmake the bin, lib ... structure is created when installing. We do not want
# to have to build and install bomc before we can start building omc. Although in
# my opinion that should be how it works, most people are used to thinking bootstrapped
# omc and normal omc as equivalent things. So we want to keep and follow that view
# for now.
# One way to think about the difference is: bomc is a MetaModelica compiler while
# omc is a Modelica compiler.
# Anyway for now just output it in a directory called bin within the current cmake
# binary dir (<build_dir>/OMCompiler/Compiler/boot/boostrapped/bin)
set_target_properties(bomc
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
)

# It also wants to have these builtin files in ../lib/ relative to its location.
add_custom_command (
    TARGET bomc
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/ModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/ModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/MetaModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/MetaModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/NFModelicaBuiltin.mo
    COMMENT "Copying (NF/Meta/Modelica)Builtin.mo files for the bootstrapped omc.")


# On Windows it also needs to have the dlls it depends on (remember bomc is being used without being installed)
# think of this as a manual install for it. Luckily it depends only on one dll for now,
if(WIN32)
  add_custom_command (
    TARGET bomc
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:omc::simrt::runtime> ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    COMMENT "Copying OpenModelicaRuntimeC.dll for the bootstrapped omc (to ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin).")
endif()

# add_custom_command(
#     TARGET bomc
#     POST_BUILD

#     DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/Absyn.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Script/GlobalScript.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/Values.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/ErrorTypes.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Config.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Gettext.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/FMI.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFType.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFExpression.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFDimension.mo
#             ${CMAKE_CURRENT_SOURCE_DIR}/../GenerateOMCHeader.mos

#     # The GenerateOMCHeader.mos script expects us to be in OMCompiler/Compiler folder.
#     WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../


#     COMMAND $<TARGET_FILE:bomc> -g=MetaModelica ${CMAKE_CURRENT_SOURCE_DIR}/../GenerateOMCHeader.mos
#     COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h.new
#                                      ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h

#     OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h
#     BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h.new
#     COMMENT "Generating ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h"
# )