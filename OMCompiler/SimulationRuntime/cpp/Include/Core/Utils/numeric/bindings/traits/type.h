/*
 * Copyright (C) 2000,2001,2002,2003 Si-Lab b.v.b.a. and Toon Knapen
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 */

#ifndef BOOST_NUMERIC_BINDINGS_TRAITS_TYPE_H
#define BOOST_NUMERIC_BINDINGS_TRAITS_TYPE_H

/*
 * This header defines the C types that will be mapped to
 * COMPLEX and COMPLEX*16 of Fortran
 */

#ifndef BOOST_NUMERIC_BINDINGS_USE_COMPLEX_STRUCT

#if defined(__GNUC__)
typedef _Complex float  fcomplex_t ;
typedef _Complex double dcomplex_t ;
#else
#include <complex>
typedef std::complex<float>  fcomplex_t ;
typedef std::complex<double> dcomplex_t ;
#endif

#else

typedef
union {
  float cmplx[2] ;
  double align_struct_ ;
} fcomplex_t ;

typedef
struct {
  double cmplx[2] ;
} dcomplex_t ;

#endif /* BOOST_NUMERIC_BINDINGS_USE_COMPLEX_STRUCT */

#endif /* BOOST_NUMERIC_BINDINGS_TRAITS_TYPE_H */
