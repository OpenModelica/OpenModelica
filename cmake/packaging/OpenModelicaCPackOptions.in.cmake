
set(CPACK_VERBATIM_VARIABLES ON)

# Common variables for most package generators.
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VENDOR "Open Source Modelica Consoritum")
set(CPACK_PACKAGE_VERSION ${SOURCE_REVISION})
set(CPACK_PACKAGE_CONTACT "build@openmodelica.org")
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/OSMC-License.txt")
# set(CPACK_RESOURCE_FILE_README "${PROJECT_SOURCE_DIR}/README.md")

set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_BINARY_DIR}/_packages")


## Package Generator specific variables. ##########################################################################################

if(CPACK_GENERATOR STREQUAL "DEB")
  # Options and settings that are specific to Debian packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/deb.html
  # usage: cpack -G DEB

  set(CPACK_PACKAGING_INSTALL_PREFIX "/usr/local")

  set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

  set(CPACK_DEBIAN_PACKAGE_MAINTAINER "OpenModelica Build System <${CPACK_PACKAGE_CONTACT}>")

  # Enable component based packaging (omc, omedit, omsimulator, fmu, simrtcpp ...)
  # See the file common.cmake for a list of the components.
  set(CPACK_DEB_COMPONENT_INSTALL ON)

  # use dpkg-shlibdeps to generate better package dependency list.
  # set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

  # Allow setting our own inter-component dependencies
  set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)

  # Set the section control field
  # https://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
  set(CPACK_DEBIAN_PACKAGE_SECTION "math")

elseif(CPACK_GENERATOR STREQUAL "RPM")
  # Options and settings that are specific to RPM packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/rpm.html
  # usage: cpack -G RPM

  # Enable component based packaging (omc, omedit, omsimulator, fmu, simrtcpp ...)
  # See the file common.cmake for a list of the components.
  set(CPACK_RPM_COMPONENT_INSTALL ON)

  set(CPACK_RPM_PACKAGE_LICENSE ${CPACK_RESOURCE_FILE_LICENSE})


elseif(CPACK_GENERATOR STREQUAL "productbuild")
  # Options and settings that are specific to macOS productbuild packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/productbuild.html
  # usage: cpack -G productbuild

  set(CPACK_PRODUCTBUILD_IDENTIFIER "org.openmodelica")

elseif(CPACK_GENERATOR STREQUAL "NSIS")
  # Options and settings that are specific to Windows NSIS packages.
  # https://cmake.org/cmake/help/latest/cpack_gen/nsis.html
  # usage: cpack -G NSIS64

  set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}\\OpenModelica.ico")
  set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${CMAKE_SOURCE_DIR}\\openmodelica.bmp")
  set(CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP "${CMAKE_SOURCE_DIR}\\openmodelica.bmp")

  set(CPACK_NSIS_HELP_LINK      "https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/")
  set(CPACK_NSIS_URL_INFO_ABOUT "http://openmodelica.org")
  set(CPACK_NSIS_CONTACT        "openmodelica@ida.liu.se")

  # These need a bit more testing and work. The shortcuts do not work yet.
  set(CPACK_CREATE_DESKTOP_LINKS OMEdit)
  set(CPACK_CREATE_DESKTOP_LINKS OMNotebook)
  set(CPACK_CREATE_DESKTOP_LINKS OMShell)

  # Ask to modify path during installation
  set(CPACK_NSIS_MODIFY_PATH ON)

  # Ask to uninstall previous installation if the same version is installed.
  set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

  # Ask to start OMEdit after installation. right now this says 'Start OpenModelica'.
  # The text at the second command below seems to be ignored for some reason.
  set(CPACK_NSIS_MUI_FINISHPAGE_RUN "OMEdit.exe")
  set(CPACK_NSIS_MUI_FINISHPAGE_RUN_TEXT "Start OpenModelica Connection Editor (OMEdit)")


endif()
