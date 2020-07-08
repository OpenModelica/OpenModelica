/*
 * Boost.Extension / factory:
 *         factory to register the implementations and create them
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_IMPL_CREATE_HPP
#define BOOST_EXTENSION_IMPL_CREATE_HPP
namespace boost {
namespace extensions {
namespace impl {

#define N BOOST_EXTENSION_MAX_FUNCTOR_PARAMS
template <class T, class D
          BOOST_PP_COMMA_IF(N)
          BOOST_PP_ENUM_PARAMS_WITH_A_DEFAULT( \
            BOOST_PP_INC(N), class Param, void) >
struct create_function;
#undef N

// generate specializations of create_func
# define BOOST_PP_ITERATION_LIMITS \
  (0, BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
# define BOOST_PP_FILENAME_1 "Core/Utils/extension/impl/create_func.hpp"
# include BOOST_PP_ITERATE()
}  // namespace impl
}  // namespace extensions
}  // namespace boost

#endif  // BOOST_EXTENSION_IMPL_CREATE_HPP
