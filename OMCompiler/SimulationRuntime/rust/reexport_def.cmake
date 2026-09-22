# Writes a linker response file re-exporting every external symbol of a static
# library, so a cdylib that absorbs it hands them on. Script mode: -DLIB= -DOUT=
# -DNM=. /EXPORT: switches rather than a .def, because rustc writes the cdylib's
# own .def and a second /DEF: would replace it instead of adding to it.
if(NOT LIB OR NOT OUT OR NOT NM)
  message(FATAL_ERROR "reexport_def.cmake needs -DLIB= -DOUT= -DNM=")
endif()

execute_process(COMMAND ${NM} --defined-only ${LIB}
                OUTPUT_VARIABLE _nm RESULT_VARIABLE _rc)
if(_rc)
  message(FATAL_ERROR "${NM} --defined-only ${LIB} failed (${_rc}).")
endif()

string(REPLACE "\n" ";" _lines "${_nm}")
set(_out "")
foreach(_line IN LISTS _lines)
  # "<address> <class> <name>", upper-case class being external. The name
  # pattern drops the COMDAT constants sharing those classes: string literals
  # (?_C@...) and the SSE pool (__xmm@...).
  if(_line MATCHES "^[0-9a-fA-F]+ ([TRDB]) ([A-Za-z_][A-Za-z0-9_]*)$")
    if(CMAKE_MATCH_1 STREQUAL "T")
      string(APPEND _out "/EXPORT:${CMAKE_MATCH_2}\n")
    else()
      string(APPEND _out "/EXPORT:${CMAKE_MATCH_2},DATA\n")
    endif()
  endif()
endforeach()
file(WRITE ${OUT} "${_out}")
