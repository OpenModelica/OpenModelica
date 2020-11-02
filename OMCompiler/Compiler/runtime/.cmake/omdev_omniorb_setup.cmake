
# this file sets up omniorb support for corba on Windows MinGW using
# libraries and executable provided in OMDev.

# It sets up libomniORB420_rt and omnithread40_rt. They are made avaiable as
# omdev::omniORB::omniORB420_rt and omdev::omniORB::omnithread40_rt respectively.

# It also defines OMNIIDL_EXE to be used for compilation of idl sources.


if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR
    "OMDev environment variable not defined. If you are using Windows MinGW version of OpenModelica and need corba support, you have to define the environment variable so that omniORB setup can be done.")
endif()


# Add libomniORB420_rt from OMDev as an imported library so that CMake knows it.
add_library(omdev::omniORB::omniORB420_rt STATIC IMPORTED)

set_target_properties(omdev::omniORB::omniORB420_rt PROPERTIES
    IMPORTED_LOCATION_DEBUG  $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/lib/x86_win32/libomniORB420_rtd.a
    IMPORTED_LOCATION_RELEASE  $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/lib/x86_win32/libomniORB420_rt.a
    INTERFACE_INCLUDE_DIRECTORIES $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/include/
    INTERFACE_COMPILE_DEFINITIONS __x86__ __NT__ __OSVERSION__=4 _WIN64 MS_WIN64
)


# Add omnithread40_rt from OMDev as an imported library so that CMake knows it.
add_library(omdev::omniORB::omnithread40_rt STATIC IMPORTED)

set_target_properties(omdev::omniORB::omnithread40_rt PROPERTIES
    IMPORTED_LOCATION_DEBUG  $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/lib/x86_win32/libomnithread40_rtd.a
    IMPORTED_LOCATION_RELEASE  $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/lib/x86_win32/libomnithread40_rt.a
    INTERFACE_INCLUDE_DIRECTORIES $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/include/
    INTERFACE_COMPILE_DEFINITIONS __x86__ __NT__ __OSVERSION__=4 _WIN64 MS_WIN64
)

# define OMNIIDL_EXE to point to the idl compiler.
set(OMNIIDL_EXE $ENV{OMDEV}/lib/omniORB-4.2.0-mingw64/bin/x86_win32/omniidl)

