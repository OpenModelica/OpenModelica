macro(omc_add_antlr_grammar_target input_file output_dir)

  get_filename_component(file_name_no_ext ${input_file} NAME_WE)
  set(output_file_path_no_ext ${output_dir}/${file_name_no_ext}Parser)

  add_custom_command(
    DEPENDS ${input_file}
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr3_ANTLRJAR}
          org.antlr.Tool -Xconversiontimeout 10000
          -o ${output_dir}
          ${input_file}
    COMMENT "Generating ${output_file_path_no_ext}.c/h for ANTLR file ${input_file}."
    OUTPUT ${output_file_path_no_ext}.c
    OUTPUT ${output_file_path_no_ext}.h
  )

  set(ANTLR_GRAMMAR_${file_name_no_ext}_OUTPUT_SOURCES ${output_file_path_no_ext}.c)
  set(ANTLR_GRAMMAR_${file_name_no_ext}_OUTPUT_HEADERS ${output_file_path_no_ext}.h)

  set(ANTLR_GRAMMAR_${file_name_no_ext}_OUTPUTS ${ANTLR_GRAMMAR_${file_name_no_ext}_OUTPUT_SOURCES}
                                                ${ANTLR_GRAMMAR_${file_name_no_ext}_OUTPUT_HEADERS})

  message(STATUS "added antrl target ${output_file_path_no_ext}")

endmacro(omc_add_antlr_grammar_target)


macro(omc_add_antlr_base_lexer_target input_file output_dir)

  get_filename_component(file_name_no_ext ${input_file} NAME_WE)
  set(output_file_path_no_ext ${output_dir}/${file_name_no_ext})
  set(output_file_base_path_no_ext ${output_dir}/${file_name_no_ext}_BaseModelica_Lexer)

  add_custom_command(
    DEPENDS ${input_file} ${CMAKE_CURRENT_SOURCE_DIR}/BaseModelica_Lexer.g
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr3_ANTLRJAR}
          org.antlr.Tool -Xconversiontimeout 10000
          -o ${output_dir}
          ${input_file}
    COMMENT "Generating ${output_file_path_no_ext}.c/h and ${output_file_base_path_no_ext}.c/h for ANTLR file ${input_file}."
    OUTPUT ${output_file_path_no_ext}.c
    OUTPUT ${output_file_path_no_ext}.h
    OUTPUT ${output_file_base_path_no_ext}.c
    OUTPUT ${output_file_base_path_no_ext}.h
  )

  set(ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUT_SOURCES ${output_file_path_no_ext}.c ${output_file_base_path_no_ext}.c)
  set(ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUT_HEADERS ${output_file_path_no_ext}.h ${output_file_base_path_no_ext}.h)

  set(ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUTS ${ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUT_SOURCES}
                                                ${ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUT_HEADERS})

  # set(ANTLR_BASE_LEXER_${file_name_no_ext}_OUTPUTS ${output_file_path_no_ext}.c ${output_file_base_path_no_ext}.c)

  message(STATUS "added antrl (BaseModelica_Lexer dependent) target ${output_file_path_no_ext}")
endmacro(omc_add_antlr_base_lexer_target)
