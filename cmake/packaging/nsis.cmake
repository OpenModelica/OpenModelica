# Options and settings that are specific to Windows NSIS packages.
# https://cmake.org/cmake/help/latest/cpack_gen/nsis.html
# usage: cpack -G NSIS64

# set(CPACK_PACKAGING_INSTALL_PREFIX ".")

# This assumes the images are in the root OpenModelica directory for now.
set(CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}\\OpenModelica.ico")
set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${CMAKE_SOURCE_DIR}\\openmodelica.bmp")
set(CPACK_NSIS_MUI_UNWELCOMEFINISHPAGE_BITMAP "${CMAKE_SOURCE_DIR}\\openmodelica.bmp")

SET (CPACK_NSIS_HELP_LINK      "https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/")
SET (CPACK_NSIS_URL_INFO_ABOUT "http://openmodelica.org")
SET (CPACK_NSIS_CONTACT        "openmodelica@ida.liu.se")

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
