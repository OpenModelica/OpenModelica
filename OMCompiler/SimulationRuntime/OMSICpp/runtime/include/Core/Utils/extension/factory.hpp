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

#ifndef BOOST_EXTENSION_FACTORY_HPP
#define BOOST_EXTENSION_FACTORY_HPP

#include <Core/Utils/extension/common.hpp>
#include <Core/Utils/extension/impl/create.hpp>
#include <boost/static_assert.hpp>
#include <boost/type_traits/is_base_of.hpp>
#include <boost/type_traits/is_class.hpp>
#include <boost/type_traits/is_const.hpp>

namespace boost {
namespace extensions {
/* For Doxygen, and for easier readability by users, a
 * simplified version of this class is provided, but never
 * compiled. The actual class definition is in impl/factory.hpp.
 */
#ifdef BOOST_EXTENSION_DOXYGEN_INVOKED
/** This class is a function object that returns
  * new instances of type T, using factories that
  * take parameters described in the variable length
  * list Params...
  */
template <class T, class Params... >
class factory {
public:
  /** \brief Set the factory function for this factory.
    *
    * This sets the factory function
    * to the constructor for type D.
    * Example: factory<Base, int, int> f; f.set<Derived>();
    */
  template <class D>
  void set() {
    this->func = &impl::create_function<
        T, D BOOST_PP_COMMA_IF(N) BOOST_PP_ENUM_PARAMS(N,Param)
      >::create;
  }

  /** \brief Default constructor.
    * On creation, this factory is empty.
    */
  factory() : func(0) {}

  /** \brief Standard copy constructor.
    */
  factory(factory<T> const& first) : func(first.func) {}

  /** \brief Standard assignment operator.
    */
  factory& operator=(factory<T> const& first) {
    this->func = first->func;
    return *this;
  }

  /** \brief Returns true if set has been called.
    *
    * Until set is called, a factory cannot be used. This
    * function can be used to determine if set has been called.
    * \pre None.
    * \post None.
    * \return True if the factory is initialized (ie, set has been called).
    */
  bool is_valid() const { return this->func != 0; }

  /** Returns an instance of T (but does NOT retain ownership of the instance).
    * \param Params... The parameters described in the type of this factory.
    * \return An instance of T.
    * \pre is_valid() == true.
    * \post None.
    */
  T* create(Params...) const {
    if (this->func) {
      return this->func(BOOST_PP_ENUM_PARAMS(N, p));
    }
    else {
      return 0;
    }
  }
};

#else

#define N BOOST_EXTENSION_MAX_FUNCTOR_PARAMS

template <class T
          BOOST_PP_COMMA_IF(N)
          BOOST_PP_ENUM_PARAMS_WITH_A_DEFAULT(
              BOOST_PP_INC(N), class Param, void) >
class factory;

#undef N

// generate specializations of factory
# define BOOST_PP_ITERATION_LIMITS \
  (0, BOOST_PP_INC(BOOST_EXTENSION_MAX_FUNCTOR_PARAMS) - 1)
# define BOOST_PP_FILENAME_1 "Core/Utils/extension/impl/factory.hpp"
# include BOOST_PP_ITERATE()
#endif
}  // namespace extensions
}  // namespace boost

#endif  // BOOST_EXTENSION_FACTORY_HPP
