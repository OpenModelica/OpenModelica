cmake_minimum_required(VERSION 3.14)
project(OMParser CXX)

find_package(Java REQUIRED Runtime)

option(WITH_LIBCXX OFF)
omc_add_subdirectory(3rdParty/antlr4/runtime/Cpp)
set(OMAntlr4_ANTLRJAR ${CMAKE_CURRENT_SOURCE_DIR}/3rdParty/antlr4/tool/antlr-4.8-complete.jar CACHE PATH "Path to antlr jar.")


add_custom_command(
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/modelica.g4
    SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/modelica.g4
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr4_ANTLRJAR}
          org.antlr.v4.Tool -Dlanguage=Cpp -package openmodelica -listener -visitor
          -o ${CMAKE_CURRENT_BINARY_DIR}
          ${CMAKE_CURRENT_SOURCE_DIR}/modelica.g4
    COMMENT "Generating ${output_file_path_no_ext}.c/h for ANTLR file modelica.g4."
    OUTPUT modelicaBaseListener.cpp
           modelicaBaseVisitor.cpp
           modelicaLexer.cpp
           modelicaListener.cpp
           modelicaParser.cpp
           modelicaVisitor.cpp
           modelica.interp
           modelica.tokens
           modelicaBaseListener.h
           modelicaBaseVisitor.h
           modelicaLexer.h
           modelicaLexer.interp
           modelicaLexer.tokens
           modelicaListener.h
           modelicaParser.h
           modelicaVisitor.h
  )


add_library(OMParser STATIC)
target_sources(OMParser PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/modelicaBaseListener.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaBaseVisitor.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaLexer.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaListener.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaParser.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaVisitor.cpp
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaBaseListener.h
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaBaseVisitor.h
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaLexer.h
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaListener.h
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaParser.h
                                ${CMAKE_CURRENT_BINARY_DIR}/modelicaVisitor.h)

target_link_libraries(OMParser PUBLIC antlr4_static)
target_include_directories(OMParser PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
