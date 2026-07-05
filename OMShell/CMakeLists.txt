cmake_minimum_required (VERSION 3.14)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omshell' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omshell)


project(OMShell)

## mosh needs GNU readline. Native Windows (MinGW/MSYS2) has it, but the xwin
## cross sysroot does not, so default OFF only when cross-compiling.
if(CMAKE_CROSSCOMPILING)
  set(_om_omshell_terminal_default OFF)
else()
  set(_om_omshell_terminal_default ON)
endif()
option(OM_OMSHELL_ENABLE_TERMINAL "Enable building the OMShell REPL terminal (in addition to the OMSell GUI)" ${_om_omshell_terminal_default})

omc_add_subdirectory(OMShell/OMShellGUI)

if(OM_OMSHELL_ENABLE_TERMINAL)
  omc_add_subdirectory(mosh)
endif()
