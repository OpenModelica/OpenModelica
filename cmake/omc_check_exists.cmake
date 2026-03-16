include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckIncludeFile)
include(CheckTypeSize)


# Checks if a sub-standard function exists.
# e.g checks "ctime_s" and defines HAVE_CTIME_S to 1 or 0
macro(omc_check_function_exists_and_define func_name)
  string(TOUPPER ${func_name} DEFINE_SUFFIX)
  check_function_exists(${func_name} HAVE_${DEFINE_SUFFIX})
endmacro(omc_check_function_exists_and_define)


# Checks a list of sub-standard functions and defines HAVE_* for each one.
macro(omc_check_functions_exist_and_define_each func_names)
  foreach(func_name ${func_names})
    string(TOUPPER ${func_name} DEFINE_SUFFIX)
    check_function_exists(${func_name} HAVE_${DEFINE_SUFFIX})
  endforeach()
endmacro(omc_check_functions_exist_and_define_each)


# Checks if a sub-standard header file exists.
# e.g checks "unistd.h" and defines HAVE_UNISTD_H to 1 or 0
# "." and "/" in input names are changed to underscore
# e.g check(sys/socket.h) -> HAVE_SYS_SOCKET_H
macro(omc_check_header_exists_and_define header_name)
  string(TOUPPER ${header_name} DEFINE_SUFFIX)
  string(REPLACE "." "_" DEFINE_SUFFIX ${DEFINE_SUFFIX})
  string(REPLACE "/" "_" DEFINE_SUFFIX ${DEFINE_SUFFIX})
  check_include_file(${header_name} HAVE_${DEFINE_SUFFIX})
endmacro(omc_check_header_exists_and_define)


# Checks a list of sub-standard header files and defines HAVE_* for each one.
macro(omc_check_headers_exist_and_define_each header_names)
  foreach(header_name ${header_names})
    omc_check_header_exists_and_define(${header_name})
  endforeach()
endmacro(omc_check_headers_exist_and_define_each)
