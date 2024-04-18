cmake_minimum_required(VERSION 3.14)
project(bomc)

# fetch the sources from the OM server, maybe we should put them in git someplace
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/bomc/sources.tar.gz")
# do nothing!
else()
#download and unpack the sources
file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bomc/)
file(DOWNLOAD https://github.com/OpenModelica/OMBootstrapping/archive/refs/heads/master.tar.gz
     ${CMAKE_CURRENT_SOURCE_DIR}/bomc/sources.tar.gz
     SHOW_PROGRESS
     STATUS status
     LOG log)
# fetch the elements of the status!
list(GET status 0 status_code)
list(GET status 1 status_string)
# check the download status!
if(NOT status_code EQUAL 0)
message(FATAL_ERROR "error: downloading 'https://github.com/OpenModelica/OMBootstrapping/archive/refs/heads/master.tar.gz' failed
        status_code: ${status_code}
        status_string: ${status_string}
        log: ${log}")
endif()
message(STATUS "downloading bootstrapping sources ... done")
execute_process(COMMAND tar xzf sources.tar.gz --strip-components=1
                 WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bomc/)
endif()

# OpenModelicaBootstrappingHeader.h should probably be added to source control and
# updated just like the bootstrap-source c files.
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/bomc/tarball-include/OpenModelicaBootstrappingHeader.h
                ${CMAKE_CURRENT_SOURCE_DIR}/../OpenModelicaBootstrappingHeader.h)

file(GLOB BOOTSTRAP_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/bomc/bootstrap-sources/build/*.c)

add_executable(bomc)
target_sources(bomc PRIVATE ${BOOTSTRAP_SOURCES})
target_sources(bomc PRIVATE ../.cmake/omc_main.c)

target_compile_definitions(bomc PRIVATE ADD_METARECORD_DEFINITIONS=)

# Silence warnings about extra parenthesized equality checks. if((a==b)).
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  target_compile_options(bomc PRIVATE -Wno-parentheses-equality)
endif()

# Silence GCC warnings about invalid reads of MetaModelica strings.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  target_compile_options(bomc PRIVATE -Wno-stringop-overread)
endif()

# OMC will overflow the stack (at least on Windows old OMDev) on very deep recursive calls.
# E.g., try translating the CodegenCpp* tpl files to mo files with
# an omc compiled without large stack size. The tpl parser is quite recursive and will
# overflow on parsing comments with very long lines ~300. *CPP tpl files have lines longer
# than that.
if(MINGW)
  target_link_options(bomc PRIVATE -Wl,--stack,33554432)
elseif(MSVC)
  target_link_options(bomc PRIVATE /STACK:33554432)
endif()

# For now disable some warnings for MSVC. These should of course be fixed properly.
if(MSVC)
  target_compile_options(bomc PRIVATE /wd4101) # unreferenced local variable
  target_compile_options(bomc PRIVATE /wd4102) # unreferenced label
  target_compile_options(bomc PRIVATE /wd4267) # conversion from 'size_t' to 'int', possible loss of data
  target_compile_options(bomc PRIVATE /wd4244) # conversion from '' to '', possible loss of data
endif()


# There is a lonely omc_file.h in Util/. It belongs in runtime/. Remove this when it is moved.
target_include_directories(bomc PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../Util)

target_link_libraries(bomc PRIVATE omc::parser)
target_link_libraries(bomc PRIVATE omc::compiler::runtime)


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
    # We need to specify these explicitly for multi-config generators like MSVC and Xcode.
    # Otherwise they will still add the release/, debug/ ... directories within the
    # RUNTIME_OUTPUT_DIRECTORY specified above.
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
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
# think of this as a manual install for it. Luckily it depends only on just two dlls for now,
if(WIN32)
  add_custom_command (
    TARGET bomc
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:omc::simrt::runtime> ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:omc::3rd::omcgc> ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin
    COMMENT "Copying libOpenModelicaRuntimeC.dll and libomcgc.dll for the bootstrapped omc (to ${CMAKE_CURRENT_BINARY_DIR}/bootstrapped/bin).")
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
