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

# This flag is interesting. OMC will segfault (at least on Windows old OMDev) on very deep
# recursive calls if this flag is enabled. E.g., try translating the CodegenCpp* tpl files to mo files with
# an omc not compiled without this flag. The tpl parser is quite recursive and will
# segfault on parsing comments with very long lines ~300. *CPP tpl files have lines longer
# than that.
# GCC manual says it is enabled on levels -O and higher. Explicitly disable it.
if(MINGW)
  target_compile_options(bomc PRIVATE -fno-ipa-pure-const)
endif()

# target_link_options(bomc PRIVATE -Wl,--stack,33554432)

# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(bomc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../Util)

target_link_libraries(bomc PRIVATE omc::parser)
target_link_libraries(bomc PRIVATE omc::compiler::runtime)
target_link_libraries(bomc PRIVATE omc::compiler::graphstream)
target_link_libraries(bomc PRIVATE omc::3rd::modelica_external_c)
target_link_libraries(bomc PRIVATE omc::3rd::modelica_io)






set_target_properties(bomc
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
)

add_custom_command (
    TARGET bomc
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/ModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/ModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/MetaModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/MetaModelicaBuiltin.mo
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/../NFFrontEnd/NFModelicaBuiltin.mo ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/lib/omc/NFModelicaBuiltin.mo
    COMMENT "Copying (NF/Meta/Modelica)Builtin.mo files for the bootstrapped omc.")


# add_custom_command(
#     TARGET bomc
#     POST_BUILD

#     DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/Absyn.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Script/GlobalScript.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../FrontEnd/Values.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Error.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Util.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../Util/FMI.mo 
#             ${CMAKE_CURRENT_SOURCE_DIR}/../GenerateOMCHeader.mos

#     # The GenerateOMCHeader.mos script expects us to be in OMCompiler/Compiler folder.
#     WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../


#     COMMAND $<TARGET_FILE:bomc> -g=MetaModelica ${CMAKE_CURRENT_SOURCE_DIR}/../GenerateOMCHeader.mos
#     COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h.new 
#                                      ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h

#     BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h
#     BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h.new
#     COMMENT "Generating ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h"
# )