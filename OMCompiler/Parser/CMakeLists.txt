
cmake_minimum_required(VERSION 3.14)
# project(OMParser)

find_package(Java REQUIRED Runtime)
omc_add_to_report(Java_JAVA_EXECUTABLE)



set(OM_PARSE_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Parser_omc.c)


set (GNERATED_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${GNERATED_DIRECTORY})

include(omc_antlr_target_macros.cmake)

ADD_ANTLR_BASE_LEXER_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/Modelica_3_Lexer.g ${GNERATED_DIRECTORY})
set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${ANTLR_BASE_LEXER_Modelica_3_Lexer_OUTPUT_SOURCES})

ADD_ANTLR_BASE_LEXER_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/ParModelica_Lexer.g ${GNERATED_DIRECTORY})
set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${ANTLR_BASE_LEXER_ParModelica_Lexer_OUTPUT_SOURCES})

ADD_ANTLR_BASE_LEXER_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/MetaModelica_Lexer.g ${GNERATED_DIRECTORY})
set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${ANTLR_BASE_LEXER_MetaModelica_Lexer_OUTPUT_SOURCES})

ADD_ANTLR_GRAMMAR_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/Modelica.g ${GNERATED_DIRECTORY})
set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${GNERATED_DIRECTORY}/ModelicaParser.c)

# message(STATUS ${OM_PARSE_SOURCES})


######################### add libomparser ###########################
add_library(omparse SHARED ${OM_PARSE_SOURCES})
target_link_libraries(omparse PUBLIC omantlr3)
target_link_libraries(omparse PUBLIC OpenModelicaRuntimeC)

# # to find the generated antlr headers
# # SYSTEM to disable warnings on the generated code.
# target_include_directories(omparse SYSTEM PRIVATE ${GNERATED_DIRECTORY})
target_include_directories(omparse PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(omparse PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler) #for OpenModelicaBootstrappingHeader.h :/
target_include_directories(omparse PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler/runtime) #for systemimpl.h :/
target_include_directories(omparse PUBLIC ${SimulationRuntimeC_SOURCE_DIR}) #for openmodelica.h :/
target_include_directories(omparse PUBLIC ${OMCompiler_SOURCE_DIR}) #for revision.h, openmodelica.h :/
######################### end libomparser ###########################


######################### add libomparser-boot ###########################
add_library(omparse-boot STATIC ${OM_PARSE_SOURCES})
target_link_libraries(omparse-boot PUBLIC omantlr3)
target_link_libraries(omparse-boot PUBLIC OpenModelicaRuntimeC)

# Define OMC_BOOTSTRAPPING for the boot lib.
target_compile_definitions(omparse-boot PRIVATE OMC_BOOTSTRAPPING)

# # to find the generated antlr headers
# # SYSTEM to disable warnings on the generated code.
# target_include_directories(omparse SYSTEM PRIVATE ${GNERATED_DIRECTORY})
target_include_directories(omparse-boot PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(omparse-boot PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler) #for OpenModelicaBootstrappingHeader.h :/
target_include_directories(omparse-boot PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler/runtime) #for systemimpl.h :/
target_include_directories(omparse-boot PUBLIC ${SimulationRuntimeC_SOURCE_DIR}) #for openmodelica.h :/
target_include_directories(omparse-boot PUBLIC ${OMCompiler_SOURCE_DIR}) #for revision.h
######################### end libomparser-boot ###########################
