//
// Copyright (c) 2002--2010
// Toon Knapen, Karl Meerbergen, Kresimir Fresl,
// Thomas Klimpel and Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BLAS_LEVEL1_DOTU_HPP
#define BOOST_NUMERIC_BINDINGS_BLAS_LEVEL1_DOTU_HPP

#include <Core/Utils/numeric/bindings/blas/level1/dot.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace blas {

//
// dotu is a synonym for dot
//
// Functions for direct use. These functions are overloaded for temporaries,
// so that wrapped types can still be passed and used for write-access.
//

//
// Overloaded function for dotu.
//
template< typename VectorX, typename VectorY >
inline typename dot_impl< typename bindings::value_type< VectorX >::type >::result_type
dotu( const VectorX& x, const VectorY& y ) {
    return dot_impl< typename bindings::value_type< VectorX >::type >::invoke( x, y );
}

} // namespace blas
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
