
add_custom_command(
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/GDBMIOutput.g
    COMMAND ${Java_JAVA_EXECUTABLE}
    ARGS -cp ${OMAntlr3_ANTLRJAR}
          org.antlr.Tool -Xconversiontimeout 10000
          -o ${CMAKE_CURRENT_BINARY_DIR}
          ${CMAKE_CURRENT_SOURCE_DIR}/GDBMIOutput.g

    COMMENT "Generating ${output_file_path_no_ext}.c/h for ANTLR file ${CMAKE_CURRENT_SOURCE_DIR}/GDBMIOutput.g."
    OUTPUT GDBMIOutputLexer.c
    OUTPUT GDBMIOutputLexer.h
    OUTPUT GDBMIOutputParser.c
    OUTPUT GDBMIOutputParser.h
    OUTPUT GDBMIOutput.tokens
  )

## This generated C files include Parser/GDBMIParser.h. Which is a C++ header. Therefore we need to
## compile them as C++ files.
## antlr3 did not get a C++ support until 3.4. We are using antlr 3.2
set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/GDBMIOutputLexer.c PROPERTIES LANGUAGE CXX)
set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/GDBMIOutputParser.c PROPERTIES LANGUAGE CXX)


add_library(libGDBMIParser STATIC GDBMIOutputLexer.c GDBMIOutputParser.c GDBMIParser.cpp)
add_library(omedit::debugger::parser ALIAS libGDBMIParser)

# set_target_properties(libGDBMIParser PROPERTIES POSITION_INDEPENDENT_CODE ON)

target_link_libraries(libGDBMIParser PUBLIC omc::3rd::omantlr3)

target_include_directories(libGDBMIParser PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
## To pick up the generated header files.
target_include_directories(libGDBMIParser PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
