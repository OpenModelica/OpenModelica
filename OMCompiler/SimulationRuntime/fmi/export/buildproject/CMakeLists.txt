
# Install the CMakeLists.txt.in template used to (re)build source-code FMUs.
# This is the only build system supported for source-code FMUs.
set(OM_FMU_CMAKELISTS_TEMPLATE ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt.in)

# A coverage build instruments the FMU export sources of every FMU it exports
# (-DOM_ENABLE_COVERAGE=ON, see cmake/modules/OpenModelicaCoverage.cmake): the
# installed template gets Coverage.cmake.in appended. The template itself is
# not configured: its @...@ placeholders are omc's to fill in, per FMU.
if(OM_ENABLE_COVERAGE)
  string(REPLACE ";" " " OM_COVERAGE_COMPILE_FLAGS "${OM_COVERAGE_COMPILE_OPTIONS}")
  configure_file(Coverage.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/Coverage.cmake @ONLY)

  file(READ ${OM_FMU_CMAKELISTS_TEMPLATE} _template)
  file(READ ${CMAKE_CURRENT_BINARY_DIR}/Coverage.cmake _coverage)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt.in.tmp "${_template}${_coverage}")
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS CMakeLists.txt.in)
  # COPYONLY only touches the result when it changed, so it is not reinstalled
  # on every configure.
  set(OM_FMU_CMAKELISTS_TEMPLATE ${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt.in)
  configure_file(${CMAKE_CURRENT_BINARY_DIR}/CMakeLists.txt.in.tmp ${OM_FMU_CMAKELISTS_TEMPLATE} COPYONLY)
endif()

install(FILES ${OM_FMU_CMAKELISTS_TEMPLATE}
        ## This should not be omc/runtime/c/fmi but rather omc/fmi. It is inconsistent
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/runtime/c/fmi/buildproject
)
