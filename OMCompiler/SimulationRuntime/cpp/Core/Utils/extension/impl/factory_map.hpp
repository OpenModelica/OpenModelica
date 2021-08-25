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

template <class Interface, class Info
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param) >
std::map<
  Info,
  factory<Interface  BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param) >
  > &
get() {
  typedef Interface* (* func_ptr_type )(BOOST_PP_ENUM_PARAMS(N, Param));
  typedef type_info_handler<TypeInfo, func_ptr_type> handler_type;

  TypeInfo t = handler_type::get_class_type();

  typename std::map<TypeInfo, generic_map_holder*>::iterator
  it = maps_.find(t);

  typedef factory<
    Interface
    BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param)
  > factory_type;
  typedef std::map<Info, factory_type> map_type;

  map_holder<map_type>* holder;
  if (it == maps_.end())
  {
    holder = new map_holder<map_type>;
    it = maps_.insert(std::make_pair(t, holder)).first;
  }
  else {
    holder = static_cast<map_holder<map_type>* > (it->second);
  }

  return *(static_cast<map_type* >(holder));
}

template <class Interface, class Info
          BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, class Param) >
operator
  std::map<
    Info,
    factory<Interface BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param) >
  >&
  ()
{
  return get< Interface, Info
             BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N, Param)>();
}

#undef N
