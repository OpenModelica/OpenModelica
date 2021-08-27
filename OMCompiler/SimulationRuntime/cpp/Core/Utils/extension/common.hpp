/*
 * Boost.Extension / common:
 *         common include files
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_COMMON_HPP
#define BOOST_EXTENSION_COMMON_HPP

#include <boost/preprocessor/arithmetic/inc.hpp>
#include <boost/preprocessor/if.hpp>
#include <boost/preprocessor/punctuation/comma_if.hpp>
#include <boost/preprocessor/repetition.hpp>
#include <boost/preprocessor/iteration/iterate.hpp>
#include <boost/concept_check.hpp>
/** This determines the maximum number of parameters that a constructor
  * or exported shared library function can have. 10 is the same default
  * as Boost.Function.
  */
#ifndef BOOST_EXTENSION_MAX_FUNCTOR_PARAMS
#define BOOST_EXTENSION_MAX_FUNCTOR_PARAMS 10
#endif

#endif  // BOOST_EXTENSION_COMMON_HPP
