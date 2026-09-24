# The system documentation that is shipped as-is.
#
# These four are the current form of their respective documents; the .doc files
# next to them are the sources they were written from and are not installed.
install(FILES
          ModelicaTutorialFritzson.pdf
          OpenModelicaMetaProgramming.pdf
          OpenModelicaSystem.pdf
          OpenModelicaTemplateProgramming.pdf
        DESTINATION ${CMAKE_INSTALL_DOCDIR}
        COMPONENT doc)

if(OM_ENABLE_DOCS)
  omc_add_subdirectory(UsersGuide)
endif()

## Man pages ##########################################################################################
# Each page is installed into the package that ships its binary, and only when that binary is
# built: an install rule naming a component registers that component with CPack, so an unguarded
# page would create a package containing nothing but the page.
# Pages are compressed with gzip -9n (Debian policy, reproducible); rpm accepts the .gz as well.
#
# Entries are page:target:component, where target is the one that must exist for the page to be
# installed. OMSimulator is an ExternalProject without a target, so OM_ENABLE_OMSIMULATOR guards it.
set(OM_MANPAGES
    omc:omc:omc
    omc-diff:omc-diff:omc
    OMPlot:OMPlot:omplot
    OMEdit:OMEdit:omedit
    OMShell:OMShell:omshell
    OMShell-terminal:OMShell-terminal:omshellterminal
    OMNotebook:OMNotebook:omnotebook
    OMCppOSUSimulation:OMCppOSUSimulation:simrt)
if(OM_ENABLE_OMSIMULATOR)
  list(APPEND OM_MANPAGES OMSimulator:omc:omsimulator)
endif()

# Version substituted for @OM_MANPAGE_VERSION@ in each page's .TH line. CPACK_PACKAGE_VERSION is
# not set yet at this point, so use OM_PACKAGE_VERSION and fall back to the project() version.
if(OM_PACKAGE_VERSION)
  set(OM_MANPAGE_VERSION "${OM_PACKAGE_VERSION}")
else()
  set(OM_MANPAGE_VERSION "${PROJECT_VERSION}")
endif()

# The User's Guide release the pages link to (@OM_MANPAGE_DOC_VERSION@), e.g. 1.28.
if(OM_PACKAGE_VERSION)
  set(OM_MANPAGE_DOC_VERSION "${OM_PACKAGE_VERSION_MAJOR}.${OM_PACKAGE_VERSION_MINOR}")
else()
  set(OM_MANPAGE_DOC_VERSION "latest")
endif()

find_program(OM_GZIP_EXECUTABLE gzip)
foreach(_man_entry IN LISTS OM_MANPAGES)
  string(REPLACE ":" ";" _man_parts "${_man_entry}")
  list(GET _man_parts 0 _man_page)
  list(GET _man_parts 1 _man_target)
  list(GET _man_parts 2 _man_component)
  if(NOT TARGET ${_man_target})
    continue()
  endif()
  set(_man_input "${CMAKE_CURRENT_SOURCE_DIR}/manpages/${_man_page}.1")
  if(NOT EXISTS "${_man_input}")
    message(WARNING "No man page ${_man_input} for the ${_man_component} package.")
    continue()
  endif()
  set(_man_source "${CMAKE_CURRENT_BINARY_DIR}/manpages/${_man_page}.1")
  configure_file("${_man_input}" "${_man_source}" @ONLY)
  if(OM_GZIP_EXECUTABLE)
    set(_man_gz "${CMAKE_CURRENT_BINARY_DIR}/manpages/${_man_page}.1.gz")
    add_custom_command(
      OUTPUT "${_man_gz}"
      COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/manpages"
      COMMAND ${CMAKE_COMMAND} -E env "${OM_GZIP_EXECUTABLE}" -9 -n -c "${_man_source}" > "${_man_gz}"
      DEPENDS "${_man_source}"
      COMMENT "Compressing the ${_man_page} man page"
      VERBATIM)
    list(APPEND OM_MANPAGE_OUTPUTS "${_man_gz}")
    install(FILES "${_man_gz}"
            DESTINATION "${CMAKE_INSTALL_MANDIR}/man1"
            COMPONENT ${_man_component})
  else()
    install(FILES "${_man_source}"
            DESTINATION "${CMAKE_INSTALL_MANDIR}/man1"
            COMPONENT ${_man_component})
  endif()
endforeach()

# Build the compressed pages so the install rules above find them.
if(OM_MANPAGE_OUTPUTS)
  add_custom_target(om-manpages ALL DEPENDS ${OM_MANPAGE_OUTPUTS})
endif()
