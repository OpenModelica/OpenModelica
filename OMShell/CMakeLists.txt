cmake_minimum_required (VERSION 3.14)

project(OMShell)

## The autotools/Makefiles based OpenModelica build skips omshell-terminal on Windows.
## So we make it default-enabled optional component here as well. In case it needs to be disabled in some cases.
option(OM_OMSHELL_ENABLE_TERMINAL "Enable building the OMShell REPL terminal (in addition to the OMSell GUI)" ON)

omc_add_subdirectory(OMShell/OMShellGUI)

if(OM_OMSHELL_ENABLE_TERMINAL)
  omc_add_subdirectory(mosh)
endif()
