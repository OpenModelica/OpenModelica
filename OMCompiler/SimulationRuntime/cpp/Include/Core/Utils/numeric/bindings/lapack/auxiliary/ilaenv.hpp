/*
 *
 * Copyright (c) Toon Knapen, Kresimir Fresl and Matthias Troyer 2003
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * KF acknowledges the support of the Faculty of Civil Engineering,
 * University of Zagreb, Croatia.
 *
 */

#ifndef BOOST_NUMERIC_BINDINGS_LAPACK_ILAENV_HPP
#define BOOST_NUMERIC_BINDINGS_LAPACK_ILAENV_HPP

#include <cstring>
#include <Core/Utils/numeric/bindings/lapack/detail/lapack.h>

namespace boost { namespace numeric { namespace bindings { namespace lapack {

//
// ilaenv() is called from the LAPACK routines to choose
// problem-dependent parameters such as the block sizes
// for the local environment.
//

inline std::ptrdiff_t ilaenv( const fortran_int_t ispec, const char* name,
        const char* opts, const fortran_int_t n1 = -1, const fortran_int_t n2 = -1,
        const fortran_int_t n3 = -1, const fortran_int_t n4 = -1) {
    return LAPACK_ILAENV( &ispec, name, opts, &n1, &n2, &n3, &n4,
                          std::strlen (name), std::strlen (opts) );
}

}}}}

#endif

