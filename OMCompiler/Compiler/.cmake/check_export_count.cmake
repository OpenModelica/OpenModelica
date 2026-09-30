# Counts the symbols a shared library exports and fails when a Windows DLL could
# not hold them (its export ordinals are 16 bit).
#
# cmake -DNM=<nm> -DLIBRARY=<libOpenModelicaCompiler.so> -P check_export_count.cmake

set(MAX_EXPORTS 65535)

execute_process(
  COMMAND ${NM} -D --defined-only ${LIBRARY}
  OUTPUT_VARIABLE symbols
  RESULT_VARIABLE result)
if(NOT result EQUAL 0)
  message(FATAL_ERROR "${NM} -D --defined-only ${LIBRARY} failed")
endif()

# One symbol per line.
string(REGEX REPLACE "[^\n]" "" newlines "${symbols}")
string(LENGTH "${newlines}" count)

if(count GREATER MAX_EXPORTS)
  message(FATAL_ERROR "${LIBRARY} exports ${count} symbols; a Windows DLL can export at most ${MAX_EXPORTS}.")
endif()
message(STATUS "${LIBRARY} exports ${count} of at most ${MAX_EXPORTS} symbols.")
