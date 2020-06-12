/*
 * Boost.Extension / main header:
 *         main header for extensions
 *
 * (C) Copyright Jeremy Pack 2007
 * Copyrignt 2008 Stjepan Rajko
 *
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#if (__GNUC__ >= 4) && !defined(__MINGW32__)

#  define BOOST_EXTENSION_EXPORT_DECL __attribute__((visibility("default")))
/* adrpo: this doesn't seem to work yet.
 * #  define BOOST_EXTENSION_IMPORT_DECL __attribute__((visibility("hidden")))
 */
#  define BOOST_EXTENSION_IMPORT_DECL __attribute__((visibility("default")))

#elif defined(_WIN32) || defined(__WIN32__) || defined(WIN32) || defined(MSC_VER)

#  define BOOST_EXTENSION_EXPORT_DECL __declspec(dllexport)
#  define BOOST_EXTENSION_IMPORT_DECL __declspec(dllimport)

#else

#  define BOOST_EXTENSION_EXPORT_DECL
#  define BOOST_EXTENSION_IMPORT_DECL

#endif
