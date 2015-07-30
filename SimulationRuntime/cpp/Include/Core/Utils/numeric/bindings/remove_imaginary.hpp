//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_REMOVE_IMAGINARY_HPP
#define BOOST_NUMERIC_BINDINGS_REMOVE_IMAGINARY_HPP

#include <complex>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct remove_imaginary {
    typedef T type;
};

template< typename T >
struct remove_imaginary< std::complex<T> > {
    typedef T type;
};

template< typename T >
struct remove_imaginary< const std::complex<T> > {
    typedef const T type;
};

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
