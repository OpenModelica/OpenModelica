/*
 * Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 * Note:
 * The code to determine whether or not function type syntax
 * is allowed in template declarations is based off of code
 * written for Boost.Function.
 */

#include <boost/config.hpp>

// The following is based on code from Boost.Function
#if defined (BOOST_NO_TEMPLATE_PARTIAL_SPECIALIZATION) \
   || defined(BOOST_BCB_PARTIAL_SPECIALIZATION_BUG) \
   || !(BOOST_STRICT_CONFIG || !defined(__SUNPRO_CC) || __SUNPRO_CC > 0x540)
#  define BOOST_EXTENSION_NO_FUNCTION_TYPE_SYNTAX
#endif
