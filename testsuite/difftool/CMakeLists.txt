

find_package(FLEX)

if(NOT FLEX_FOUND)
  message(WARNING "GNU Flex not found. You will not be able to use omc-diff to verify test results against expected results.")
else()
  FLEX_TARGET(omc_diff_lexer omc-diff.l ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.c)
  add_executable(omc-diff ${FLEX_omc_diff_lexer_OUTPUTS})

  install(TARGETS omc-diff)
endif()
