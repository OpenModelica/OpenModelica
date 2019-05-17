/*
 * Boost.Extension / convenience functions:
 *         for now only one to load a library and register it in the factory
 *         map.
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_CONVENIENCE_HPP
#define BOOST_EXTENSION_CONVENIENCE_HPP

#include <Core/Utils/extension/factory_map.hpp>
#include <Core/Utils/extension/type_map.hpp>

namespace boost {
namespace extensions {
/** \brief Load factories from the given library and function.
  *
  * Add any exported factories from the given library with the
  * given function name. This uses shared_library::get internally.
  * The function must have the signature void (factory_map&).
  * For more general loading of shared libraries, use the shared_library
  * class directly.
  * If the function is not found, false is returned.
  *
  * \param current_factory_map The factory map to load classes into. It is
  *        not required to be empty.
  * \param library_path The relative or absolute path to the library to load.
  * \param external_function_name The name of an exported function in the library
  *        with the signature void (factory_map&).
  * \return True on success.
  * \pre None.
  * \post None.
  */
inline bool load_single_library(factory_map& current_factory_map,
                                const std::string& library_path,
                                const std::string& external_function_name) {
    shared_library lib(library_path);
    if (!lib.open()) {
      return false;
    }
    void (*func)(factory_map&) =
      lib.shared_library::get<void, factory_map &>(external_function_name);
    if (!func) {
      return false;
    }
    (*func)(current_factory_map);
    return true;
}

inline bool load_single_library(factory_map& current_factory_map,
                                const std::string& library_path,
                                const std::string& external_function_name,
								shared_library& lib) {
    lib = shared_library(library_path);
    if (!lib.open()) {
      return false;
    }
    void (*func)(factory_map&) =
      lib.shared_library::get<void, factory_map &>(external_function_name);
    if (!func) {
      return false;
    }
    (*func)(current_factory_map);
    return true;
}


inline bool load_single_library(type_map& current_type_map,
                                const std::string& library_path,
                                shared_library& lib
                                ) {
    lib = shared_library(library_path);
    if (!lib.open()) {
      return false;
    }
	void (*func)(type_map&) =
      lib.shared_library::get<void, type_map&>
      ("boost_extension_exported_type_map_function");
    if (!func) {
         return false;
    }
	(*func)(current_type_map);

    return true;
}
}  // namespace extensions
}  // namespace boost



#endif
