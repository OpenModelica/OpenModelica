//
// Copyright (c) 2002--2010
// Toon Knapen, Karl Meerbergen, Kresimir Fresl,
// Thomas Klimpel and Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BLAS_LEVEL1_SET_HPP
#define BOOST_NUMERIC_BINDINGS_BLAS_LEVEL1_SET_HPP

#include <boost/assert.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/is_mutable.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <boost/static_assert.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace blas {

//
// set is an extension, not part of the BLAS API.
//
// TODO implement ATLAS backend call(s)
//
// Functions for direct use. These functions are overloaded for temporaries,
// so that wrapped types can still be passed and used for write-access.
//

//
// Overloaded function for set. Its overload differs for
// * VectorX&
//
template< typename VectorX >
inline void
set( const typename bindings::value_type< VectorX >::type a, VectorX& x ) {
    BOOST_STATIC_ASSERT( (bindings::is_mutable< VectorX >::value) );
    std::fill( bindings::begin(x), bindings::end(x), a );
}

//
// Overloaded function for set. Its overload differs for
// * const VectorX&
//
template< typename VectorX >
inline void
set( const typename bindings::value_type< const VectorX >::type a,  const VectorX& x ) {
    BOOST_STATIC_ASSERT( (bindings::is_mutable< const VectorX >::value) );
    std::fill( bindings::begin(x), bindings::end(x), a );
}

} // namespace blas
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
