/*
 * Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

// No header guard - this file is intended to be included multiple times.

#define N BOOST_PP_ITERATION()
template <class Derived
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>
void set(BOOST_PP_ENUM_PARAMS(N, Info i)) {
  parameter_names_.resize(N);
#define BOOST_EXTENSION_ADD_TO_LIST(z, n, data) \
  parameter_names_[n] = BOOST_PP_CAT(i, n);
  BOOST_PP_REPEAT(N, BOOST_EXTENSION_ADD_TO_LIST, );
#undef BOOST_EXTENSION_ADD_TO_LIST
  func_ = &impl::create_func
    <Interface, Derived, Info, TypeInfo
     BOOST_PP_COMMA_IF(N)
     BOOST_PP_ENUM_PARAMS(N, Param)>;
  functor_func_ = &impl::get_functor_func
    <Interface, Derived, Info, TypeInfo
     BOOST_PP_COMMA_IF(N)
     BOOST_PP_ENUM_PARAMS(N, Param)>;
  check_func_ = &impl::check_func
    <Info, TypeInfo BOOST_PP_COMMA_IF(N)
     BOOST_PP_ENUM_PARAMS(N, Param)>;
}
#undef N

