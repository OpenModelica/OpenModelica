## What each component's binary package is called ##################################################
# Needed in two places that run at different times, which is why it lives in a file of its own:
#
#   * configure time, by components.cmake, to install each package's copyright and changelog into
#     share/doc/<package>/ -- Debian policy names that directory after the *binary package*, not
#     after the component, so lintian reports no-copyright-file if the two differ.
#   * cpack time, by OpenModelicaCPackOptions.in.cmake, to set CPACK_DEBIAN_<C>_PACKAGE_NAME and
#     CPACK_RPM_<C>_PACKAGE_NAME.
#
# The top-level CMakeLists.txt includes this before it configures the options file, so the
# overrides below can be substituted into it and there is one list rather than two that drift.
#
# Almost every component is packaged under its own name -- omc, omedit, omplot and the rest, the
# names the Autoconf packaging used rather than the openmodelica-<component> CPack would derive
# from the project name. Only these three differ:
#   * meta, whose package is openmodelica: what the install instructions tell people to ask for,
#     not the "openmodelica-meta" its component name would give.
#   * omshellterminal, whose package has always been omshell-terminal.
#   * doc, which components.cmake does not currently pack. A bare "doc" is far too general a name
#     to let a loop invent, and openmodelica-doc is what its source package was called.
set(OM_PACKAGE_NAME_OVERRIDES
    meta            openmodelica
    omshellterminal omshell-terminal
    doc             openmodelica-doc)

# The package name for <component>, into <out_var>. Defaults to the component's own name.
function(om_package_name component out_var)
  list(LENGTH OM_PACKAGE_NAME_OVERRIDES _n)
  math(EXPR _last "${_n} - 1")
  foreach(_i RANGE 0 ${_last} 2)
    list(GET OM_PACKAGE_NAME_OVERRIDES ${_i} _comp)
    if(_comp STREQUAL component)
      math(EXPR _j "${_i} + 1")
      list(GET OM_PACKAGE_NAME_OVERRIDES ${_j} _name)
      set(${out_var} "${_name}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
  set(${out_var} "${component}" PARENT_SCOPE)
endfunction()
