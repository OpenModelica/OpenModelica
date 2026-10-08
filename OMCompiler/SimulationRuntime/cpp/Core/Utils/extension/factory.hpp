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
#include <type_traits>

namespace boost {
namespace extensions {

/** Function object returning new instances of T, built from Params. */
template <class T, class... Params>
class factory {
public:
  static_assert(std::is_class<T>::value, "factory<T>: T must be a class");
  static_assert(!std::is_const<T>::value, "factory<T>: T must not be const");

  /** Set the factory function to the constructor of D. */
  template <class D>
  void set() {
    static_assert(std::is_base_of<T, D>::value,
                  "factory<T>::set<D>(): D must inherit from T");
    static_assert(!std::is_const<D>::value,
                  "factory<T>::set<D>(): D must not be const");
    this->func = &impl::create_function<T, D, Params...>::create;
  }

  factory() : func(0) {}

  bool is_valid() const { return this->func != 0; }

  T* create(Params... p) const {
    return this->func ? this->func(p...) : 0;
  }

private:
  typedef T* (*func_ptr_type)(Params...);
  func_ptr_type func;
};

}  // namespace extensions
}  // namespace boost

#endif  // BOOST_EXTENSION_FACTORY_HPP
