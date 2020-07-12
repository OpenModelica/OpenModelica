
cmake_minimum_required(VERSION 3.14)
# project(OMParser)

find_package(Java REQUIRED Runtime)
omc_add_to_report(Java_JAVA_EXECUTABLE)



function(ADD_ANTLR_GRAMMAR_TARGET input_file output_dir)

  get_filename_component(file_name_no_ext ${input_file} NAME_WE)
  set(output_file_path_no_ext ${output_dir}/${file_name_no_ext}Parser)

  add_custom_command(
    DEPENDS ${input_file}
    SOURCE ${input_file}
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr3_ANTLRJAR}
          org.antlr.Tool -Xconversiontimeout 10000 -report
          -o ${output_dir}
          ${input_file}
    COMMENT "Generating ${output_file_path_no_ext}.c/h for ANTLR file ${input_file}."
    OUTPUT ${output_file_path_no_ext}.c
    OUTPUT ${output_file_path_no_ext}.h
  )
  set_source_files_properties(${output_file_path_no_ext}.c GENERATED)
  set_source_files_properties(${output_file_path_no_ext}.h GENERATED)
  message(STATUS "added antrl target ${output_file_path_no_ext}")
endfunction(ADD_ANTLR_GRAMMAR_TARGET)

function(ADD_ANTLR_LEXER_TARGET input_file output_dir)

  get_filename_component(file_name_no_ext ${input_file} NAME_WE)
  set(output_file_path_no_ext ${output_dir}/${file_name_no_ext})

  add_custom_command(
    DEPENDS ${input_file}
    SOURCE ${input_file}
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr3_ANTLRJAR}
          org.antlr.Tool -Xconversiontimeout 10000
          -o ${output_dir}
          ${input_file}
    COMMENT "Generating ${output_file_path_no_ext}.c/h for ANTLR file ${input_file}."
    OUTPUT ${output_file_path_no_ext}.c
    OUTPUT ${output_file_path_no_ext}.h
  )
  set_source_files_properties(${output_file_path_no_ext}.c GENERATED)
  set_source_files_properties(${output_file_path_no_ext}.h GENERATED)
  message(STATUS "added antrl target ${output_file_path_no_ext}")
endfunction(ADD_ANTLR_LEXER_TARGET)


set (GNERATED_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated)
file(MAKE_DIRECTORY ${GNERATED_DIRECTORY})

# ADD_ANTLR_GRAMMAR_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/Modelica.g ${GNERATED_DIRECTORY})
# set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${GNERATED_DIRECTORY}/ModelicaParser.c)

ADD_ANTLR_LEXER_TARGET(${CMAKE_CURRENT_SOURCE_DIR}/Modelica_3_Lexer.g ${GNERATED_DIRECTORY})


# set(OM_PARSE_SOURCES ${OM_PARSE_SOURCES} ${GNERATED_DIRECTORY}/*.c)
file(GLOB OM_PARSE_SOURCES ${GNERATED_DIRECTORY}/*.c)


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