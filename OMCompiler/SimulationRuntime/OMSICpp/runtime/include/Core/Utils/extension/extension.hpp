/*
 * Boost.Extension / main header:
 *         main header for extensions
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_EXTENSION_HPP
#define BOOST_EXTENSION_EXTENSION_HPP
#ifdef BOOST_EXTENSION_DOXYGEN_INVOKED
/** Macro to place in a function definition to cause it
  * to be exported, if necessary on the given platform and
  * with the current compiler settings. This is always required
  * for MSVC and other compilers, but only required depending on
  * compiler settings for GCC and other compilers.
  */
#define BOOST_EXTENSION_EXPORT_DECL
#else
#include <Core/Utils/extension/impl/decl.hpp>
#define BOOST_EXTENSION_TYPE_MAP_FUNCTION \
extern "C" \
void BOOST_EXTENSION_EXPORT_DECL \
boost_extension_exported_type_map_function \
  (boost::extensions::type_map& types)
#endif  // BOOST_EXTENSION_EXPORT_DECL
#endif  // BOOST_EXTENSION_EXTENSION_HPP
