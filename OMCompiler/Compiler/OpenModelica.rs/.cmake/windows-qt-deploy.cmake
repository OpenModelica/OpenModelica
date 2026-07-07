# Install-time PE DLL-closure deploy for cross (clang-cl) Windows builds, where
# windeployqt (a Windows binary) cannot run. BFS the import table with objdump and
# copy each dependency found under OMDEPLOY_DIRS next to the executable. Expects:
#   OMDEPLOY_EXE OMDEPLOY_DIRS OMDEPLOY_OBJDUMP OMDEPLOY_DEST
# (set via a preceding install(CODE) in the same cmake_install.cmake scope).

function(_om_pe_imports out_var file)
  execute_process(COMMAND "${OMDEPLOY_OBJDUMP}" -p "${file}"
                  OUTPUT_VARIABLE _out ERROR_QUIET RESULT_VARIABLE _rc)
  set(_names "")
  if(NOT _rc)
    string(REGEX MATCHALL "DLL Name: *[^\r\n]+" _lines "${_out}")
    foreach(_l IN LISTS _lines)
      string(REGEX REPLACE "DLL Name: *" "" _n "${_l}")
      string(STRIP "${_n}" _n)
      list(APPEND _names "${_n}")
    endforeach()
  endif()
  set(${out_var} "${_names}" PARENT_SCOPE)
endfunction()

set(_om_seen "")
set(_om_queue "${OMDEPLOY_EXE}")
while(_om_queue)
  list(POP_FRONT _om_queue _cur)
  _om_pe_imports(_deps "${_cur}")
  foreach(_d IN LISTS _deps)
    string(TOLOWER "${_d}" _dl)
    if(_dl MATCHES "^(api-ms-|ext-ms-)" OR _dl IN_LIST _om_seen)
      continue()
    endif()
    set(_resolved "")
    foreach(_dir IN LISTS OMDEPLOY_DIRS)
      if(EXISTS "${_dir}/${_d}")
        set(_resolved "${_dir}/${_d}")
        break()
      endif()
    endforeach()
    list(APPEND _om_seen "${_dl}")
    if(_resolved)
      file(INSTALL DESTINATION "${OMDEPLOY_DEST}"
           TYPE SHARED_LIBRARY FOLLOW_SYMLINK_CHAIN FILES "${_resolved}")
      list(APPEND _om_queue "${_resolved}")
    endif()
  endforeach()
endwhile()
