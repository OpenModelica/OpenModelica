/*
 * Boost.Extension / factory map:
 *         map of factories (for the implementations)
 *
 * (C) Copyright Jeremy Pack 2008
 * Distributed under the Boost Software License, Version 1.0. (See
 * accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See http://www.boost.org/ for latest version.
 */

#ifndef BOOST_EXTENSION_FACTORY_MAP_HPP
#define BOOST_EXTENSION_FACTORY_MAP_HPP

#include <map>
#include <Core/Utils/extension/factory.hpp>
#include <Core/Utils/extension/impl/typeinfo.hpp>

namespace boost {
namespace extensions {

/** \brief A collection of factories of various types.
  * \tparam TypeInfo The type used for TypeInfo. By default,
  *         RTTI is used, but users can define their own TypeInfo.
  *         See impl/typeinfo.hpp.
  */
template <class TypeInfo>
class basic_factory_map {
public:
  ~basic_factory_map() {
    for (typename std::map<TypeInfo, generic_map_holder*>::iterator
         it =maps_.begin(); it != maps_.end(); ++it) {
      delete it->second;
    }
  }

/* Include simplified versions of the get and conversion member
 * functions for Doxygen, and to make it easier for readers of
 * this file.
 */
#ifdef BOOST_EXTENSION_DOXYGEN_INVOKED
  /** \brief Return a map of the factories that match the given interface.
    * \tparam Interface The type of the interface returned by factories in
    *         the requested map.
    * \tparam Info An arbitrary type that is stored with each factory,
    *         to differentiate them. By default, strings are used.
    * \tparam Params The constructor params for the requested factories.
    * \return A map of the requested factory type.
    *
    * This returns a map of the given type of factories. It can return
    * an empty map if no such factories are found.
    */
  template <class Interface, class Info, class Params...>
  std::map<Info, factory<Interface, Params...> >& get() {
    // EMPTY - THIS IS ONLY HERE FOR DOXYGEN.
  }

  /** \brief A conversion operator that calls get().
    *
    * A conversion operator for convenience in calling functions
    * that take a map of factories.
    * This is identical to the get() function.
    */
  template <class Interface, class Info, class Params...>
  operator
  std::map<
    Info,
    factory<Interface, Params...>
  >&
  () {
    // EMPTY - THIS IS ONLY HERE FOR DOXYGEN.
  }

#else
  // generate get and conversion template member functions from the
  // specification in impl/
# define BOOST_PP_ITERATION_LIMITS (0, \
    BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
# define BOOST_PP_FILENAME_1 "Core/Utils/extension/impl/factory_map.hpp"
# include BOOST_PP_ITERATE()

private:

  struct generic_map_holder {
    virtual ~generic_map_holder() {}
  };

  template <class T>
  struct map_holder : generic_map_holder, T {};

  std::map<TypeInfo, generic_map_holder*> maps_;
#endif
};
/** A typedef for convenience - provides the most common
  * type of basic_factory_map.
  */
typedef basic_factory_map<default_type_info> factory_map;

} // namespace extensions
} // namespace boost

#endif  // BOOST_EXTENSION_FACTORY_MAP_HPP
