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

template <class T, class D, class... Params>
struct create_function {
  static T* create(Params... p) { return new D(p...); }
};

}  // namespace impl
}  // namespace extensions
}  // namespace boost

#endif  // BOOST_EXTENSION_IMPL_CREATE_HPP
