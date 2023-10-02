# Options and settings that are specific to RPM packages.
# https://cmake.org/cmake/help/latest/cpack_gen/rpm.html
# usage: cpack -G RPM

# Enable component based packaging (omc, omedit, omsimulator, fmu, simrtcpp ...)
# See the file common.cmake for a list of the components.
set(CPACK_RPM_COMPONENT_INSTALL ON)

set(CPACK_RPM_PACKAGE_LICENSE "${PROJECT_SOURCE_DIR}/OSMC-License.txt")
