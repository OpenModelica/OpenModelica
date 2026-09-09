cmake_minimum_required (VERSION 3.14)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omshell' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omshell)


project(OMShell)

# MSVC: this client only consumes the shared MetaModelica runtime, so its
# DLLDirection-annotated data symbols must come in as __declspec(dllimport).
if(MSVC)
  add_compile_definitions(IMPORT_INTO=1)
endif()

## mosh needs GNU readline. Native Windows (MinGW/MSYS2) has it, but the xwin
## cross sysroot does not, and vcpkg does not provide it for the native MSVC
## build either, so default OFF for both of those.
if(CMAKE_CROSSCOMPILING OR MSVC)
  set(_om_omshell_terminal_default OFF)
else()
  set(_om_omshell_terminal_default ON)
endif()
option(OM_OMSHELL_ENABLE_TERMINAL "Enable building the OMShell REPL terminal (in addition to the OMSell GUI)" ${_om_omshell_terminal_default})

omc_add_subdirectory(OMShell/OMShellGUI)

if(OM_OMSHELL_ENABLE_TERMINAL)
  omc_add_subdirectory(mosh)
endif()
