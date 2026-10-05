# Reads <DEPENDS_DIR>/<pkg>.depends for every package in SOURCE_LIST and writes
# <DEPENDS_DIR>/<pkg>.rev_depends: the packages that depend on <pkg>.

file(STRINGS ${SOURCE_LIST} _sources)
set(_packages ${_sources})

foreach(_src IN LISTS _sources)
  file(STRINGS ${DEPENDS_DIR}/${_src}.depends _line LIMIT_COUNT 1)
  separate_arguments(_deps UNIX_COMMAND "${_line}")
  foreach(_dep IN LISTS _deps)
    list(APPEND _rev_${_dep} ${_src})
    list(APPEND _packages ${_dep})
  endforeach()
endforeach()

list(REMOVE_DUPLICATES _packages)
foreach(_pkg IN LISTS _packages)
  set(_rev ${_rev_${_pkg}})
  list(REMOVE_DUPLICATES _rev)
  list(SORT _rev)
  set(_content "")
  foreach(_r IN LISTS _rev)
    string(APPEND _content "${_r};")
  endforeach()
  file(WRITE ${DEPENDS_DIR}/${_pkg}.rev_depends "${_content}")
endforeach()
