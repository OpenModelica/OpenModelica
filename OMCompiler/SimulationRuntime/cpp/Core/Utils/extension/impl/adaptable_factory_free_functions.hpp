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
template <class Interface, class Derived, class Info, class TypeInfo
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>
inline Interface* create_func(
    boost::extensions::basic_parameter_map<Info, TypeInfo>& map,
    const std::vector<Info>& names) {
#if N
  extensions::generic_parameter<TypeInfo>* gen;
#define BOOST_EXTENSION_GET_FROM_LIST(z, n, data) \
  gen = map.template get_first<BOOST_PP_CAT(Param, n)>(names[n]); \
  if (!gen) return 0; \
  BOOST_PP_CAT(Param, n) BOOST_PP_CAT(p, n) = \
     gen->template cast<BOOST_PP_CAT(Param, n)>();
  BOOST_PP_REPEAT(N, BOOST_EXTENSION_GET_FROM_LIST, )
#undef BOOST_EXTENSION_GET_FROM_LIST
#endif  // N
  return new Derived(BOOST_PP_ENUM_PARAMS(N, p));
}

template <class Interface, class Derived, class Info, class TypeInfo
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param)>
inline boost::function<Interface* ()> get_functor_func(
    boost::extensions::basic_parameter_map<Info, TypeInfo>& map,
    const std::vector<Info>& names) {
#if N
  extensions::generic_parameter<TypeInfo>* gen;
#define BOOST_EXTENSION_GET_FROM_LIST(z, n, data) \
  gen = map.template get_first<BOOST_PP_CAT(Param, n)>(names[n]); \
  if (!gen) return boost::function<Interface* ()>(); \
  BOOST_PP_CAT(Param, n) BOOST_PP_CAT(p, n) = \
     gen->template cast<BOOST_PP_CAT(Param, n)>();
  BOOST_PP_REPEAT(N, BOOST_EXTENSION_GET_FROM_LIST, )
#undef BOOST_EXTENSION_GET_FROM_LIST
#endif  // N
  Interface* (*f)(BOOST_PP_ENUM_PARAMS(N, Param)) =
    impl::create_derived<Interface, Derived BOOST_PP_COMMA_IF(N)
                         BOOST_PP_ENUM_PARAMS(N, Param)>;
  return bind(f
              BOOST_PP_COMMA_IF(N)
              BOOST_PP_ENUM_PARAMS(N, p));
}

template <class Info, class TypeInfo BOOST_PP_COMMA_IF(N)
          BOOST_PP_ENUM_PARAMS(N, class Param)>
inline std::vector<std::pair<TypeInfo, Info> > check_func(
    const boost::extensions::basic_parameter_map<Info, TypeInfo>& map,
    const std::vector<Info>& names) {
  std::vector<std::pair<TypeInfo, Info> > needed_parameters;
#define BOOST_EXTENSION_CHECK_IN_LIST(z, n, data) \
if (!map.template has<BOOST_PP_CAT(Param, n)>(names[n])) \
  needed_parameters.push_back(std::make_pair(\
    type_info_handler<TypeInfo, \
                      BOOST_PP_CAT(Param, n)>::template get_class_type(), \
    names[n]));
  BOOST_PP_REPEAT(N, BOOST_EXTENSION_CHECK_IN_LIST, )
#undef BOOST_EXTENSION_CHECK_IN_LIST
  return needed_parameters;
}
#undef N

