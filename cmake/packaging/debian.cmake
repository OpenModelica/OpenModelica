# Options and settings that are specific to debian packages.

set(CPACK_DEBIAN_FILE_NAME DEB-DEFAULT)

set(CPACK_DEBIAN_PACKAGE_MAINTAINER "OpenModelica Build System <${CPACK_PACKAGE_CONTACT}>")

# Enable component based packaging (openmodelica-compiler, openmodelica-gui, ...)
set(CPACK_DEB_COMPONENT_INSTALL ON)

# use dpkg-shlibdeps to generate better package dependency list.
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)

# Allow setting our own inter-component dependencies
set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)

# Set the section control field
# https://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections
set(CPACK_DEBIAN_PACKAGE_SECTION "math")
