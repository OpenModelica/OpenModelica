/*
 * Boost.Extension / libraries management:
 *         low-level platform specific dynamic library management
 *
 * (C) Copyright Jeremy Pack 2007
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */


#ifndef BOOST_EXTENSION_LIBRARY_IMPL_HPP
#define BOOST_EXTENSION_LIBRARY_IMPL_HPP

#include <iostream>


#include <cstring>

#if (defined(_WIN32) || defined(__WIN32__) || defined(WIN32)) \
    && !defined(BOOST_DISABLE_WIN32) && (!defined(__GNUC__) ||  defined(__MINGW32__))

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501
#endif
#ifndef BOOST_EXTENSION_NO_LEAN_WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#endif

#include <windows.h>
namespace boost {
namespace extensions {
namespace impl {
  typedef HMODULE library_handle;
  typedef FARPROC generic_function_ptr;
  inline library_handle load_shared_library(const char* library_name) {
    return LoadLibraryA(library_name);
  }
  inline generic_function_ptr get_function(library_handle handle,
                                           const char* function_name) {
    return GetProcAddress(handle, function_name);
  }
  inline bool close_shared_library(library_handle handle) {
    return FreeLibrary(handle) != 0;
  }
}  // namespace impl
}  // namespace extensions
}  // namespace boost

#   pragma comment(lib, "kernel32.lib")
#else
#include <dlfcn.h>
namespace boost {
namespace extensions {
namespace impl {
  typedef void * library_handle;
  typedef void * generic_function_ptr;
  inline library_handle load_shared_library(const char* library_name) {
  	library_handle  handle = dlopen(library_name, RTLD_LAZY);
	if (!handle) {
        std::cout << "Cannot open library: " << dlerror() << std::endl;
        return NULL;
    }
	return handle;

  }
  inline generic_function_ptr get_function(library_handle handle,
                                           const char* function_name) {
    return dlsym(handle, function_name);
  }
  inline bool close_shared_library(library_handle handle) {
    return dlclose(handle)==0;
  }
}  // namespace impl
}  // namespace extensions
}  // namespace boost

#endif

#endif
