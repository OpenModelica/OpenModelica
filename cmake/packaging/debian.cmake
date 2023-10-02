# Options and settings that are specific to Debian packages.
# https://cmake.org/cmake/help/latest/cpack_gen/deb.html
# usage: cpack -G DEB

set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "OpenModelica Build System <${CPACK_PACKAGE_CONTACT}>")

# Enable component based packaging (omc, omedit, omsimulator, fmu, simrtcpp ...)
# See the file common.cmake for a list of the components.
set(CPACK_DEB_COMPONENT_INSTALL ON)

# use dpkg-shlibdeps to generate better package dependency list.
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

# Allow setting our own inter-component dependencies
set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)

# Set the section control field
# https://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
set(CPACK_DEBIAN_PACKAGE_SECTION "math")
