/*
 * Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */


// No header guard - this file is intended to be included multiple times.

# define N BOOST_PP_ITERATION()
template <
  class T,
  class D
  BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)
>
struct create_function<
  T,
  D
  BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param)
> {
  static T * create(BOOST_PP_ENUM_BINARY_PARAMS(N, Param, p) ) {
    return new D(BOOST_PP_ENUM_PARAMS(N, p));
  }
};

template <
  class T,
  class D
  BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)
>
static T* create_derived(BOOST_PP_ENUM_BINARY_PARAMS(N, Param, p)) {
    return new D(BOOST_PP_ENUM_PARAMS(N, p));
}
#undef N

