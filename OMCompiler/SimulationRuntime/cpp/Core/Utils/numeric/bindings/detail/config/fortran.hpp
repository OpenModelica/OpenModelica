//
//  Copyright (C) 2002, 2003 Si-Lab b.v.b.a., Toon Knapen and Kresimir Fresl
//                2010 Thomas Klimpel
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_CONFIG_FORTRAN_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_CONFIG_FORTRAN_HPP

#if defined(BIND_FORTRAN_LOWERCASE_UNDERSCORE) || defined(BIND_FORTRAN_LOWERCASE) || defined(BIND_FORTRAN_UPPERCASE_UNDERSCORE) || defined(BIND_FORTRAN_UPPERCASE)
// Allow manual override of the defaults, e.g. if you want to use a fortran
// lib compiled with gcc from MSVC
#else

// We have no chance of determining the conventions for linking C with Fortran
// here, because they only depend on the fortran compiler and it's command line
// switches, but not on the C++ compiler which compiles these lines.

// We default to lowercase underscore, because this is much more common than
// the other option. (The previous automatic configuration only selected the
// other option in case of "defined(__IBMCPP__) || defined(_MSC_VER)".)
#define BIND_FORTRAN_LOWERCASE_UNDERSCORE

#endif

// Next we define macro's to convert our symbols to
// the current convention
#if defined(BIND_FORTRAN_LOWERCASE_UNDERSCORE)
#define FORTRAN_ID( id ) id##_
#define FORTRAN_ID2( id, ID2 ) id##_
#elif defined(BIND_FORTRAN_LOWERCASE)
#define FORTRAN_ID( id ) id
#define FORTRAN_ID2( id, ID2 ) id
#elif defined(BIND_FORTRAN_UPPERCASE_UNDERSCORE)
#define FORTRAN_ID2( id, ID2 ) ID2##_
#elif defined(BIND_FORTRAN_UPPERCASE)
#define FORTRAN_ID2( id, ID2 ) ID2
#else
#error do not know how to bind to fortran calling convention
#endif


#ifdef BIND_FORTRAN_F2C_RETURN_CONVENTIONS
// "g77" or clapack or "gfortran -ff2c"
#define BIND_FORTRAN_RETURN_REAL_DOUBLE
#define BIND_FORTRAN_RETURN_COMPLEX_FIRST_ARG
#elif BIND_FORTRAN_MKL_RETURN_CONVENTIONS
// mkl
#define BIND_FORTRAN_RETURN_COMPLEX_FIRST_ARG
#elif BIND_FORTRAN_OSX_RETURN_CONVENTIONS
// OS X
#define BIND_FORTRAN_RETURN_COMPLEX_LAST_ARG
#else
// "g77 -fno-f2c" or "gfortran"
#endif


// "g77" or "gfortran" or mkl_intel_lp64
//#undef BIND_FORTRAN_INTEGER_8
// clapack or "gfortran -fdefault-integer-8" or mkl_intel_ilp64
//#define BIND_FORTRAN_INTEGER_8

// Most fortran compilers use fortran_int_t := int by default, so we follow
// this default, even so f2c (=clapack) uses "typedef long int integer;"
#ifndef BIND_FORTRAN_INTEGER_8
typedef int fortran_int_t;
#else
typedef std::ptrdiff_t fortran_int_t;
#endif

// Looks like fortran_int_t and fortran_bool_t should be identical, the unsigned is
// required so overloads can distinguish between fortran_bool_t and fortran_int_t.
#ifndef BIND_FORTRAN_INTEGER_8
typedef unsigned int fortran_bool_t;
#else
typedef std::size_t fortran_bool_t;
#endif

// This definition of external_fp is identical to the definition of L_fp from
// f2c, and it seems to work more or less. These functions return fortran_bool_t,
// but they don't all take the same type of arguments. A reinterpret_cast will
// probably work for most compilers to extend the allowed function signatures.
typedef fortran_bool_t (*external_fp)(...);

#endif // BOOST_NUMERIC_BINDINGS_TRAITS_FORTRAN_H
