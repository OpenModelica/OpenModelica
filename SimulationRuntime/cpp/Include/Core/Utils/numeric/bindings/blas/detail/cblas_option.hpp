//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BLAS_DETAIL_CBLAS_OPTION_HPP
#define BOOST_NUMERIC_BINDINGS_BLAS_DETAIL_CBLAS_OPTION_HPP

#include <Core/Utils/numeric/bindings/blas/detail/cblas.h>
#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace blas {
namespace detail {

template< typename Tag >
struct cblas_option {};

template<>
struct cblas_option< tag::row_major > {
    static const CBLAS_ORDER value = CblasRowMajor;
};

template<>
struct cblas_option< tag::column_major > {
    static const CBLAS_ORDER value = CblasColMajor;
};

template<>
struct cblas_option< tag::transpose > {
    static const CBLAS_TRANSPOSE value = CblasTrans;
};

template<>
struct cblas_option< tag::no_transpose > {
    static const CBLAS_TRANSPOSE value = CblasNoTrans;
};

template<>
struct cblas_option< tag::conjugate > {
    static const CBLAS_TRANSPOSE value = CblasConjTrans;
};

template<>
struct cblas_option< tag::upper > {
    static const CBLAS_UPLO value = CblasUpper;
};

template<>
struct cblas_option< tag::lower > {
    static const CBLAS_UPLO value = CblasLower;
};

template<>
struct cblas_option< tag::unit > {
    static const CBLAS_DIAG value = CblasUnit;
};

template<>
struct cblas_option< tag::non_unit > {
    static const CBLAS_DIAG value = CblasNonUnit;
};

template<>
struct cblas_option< tag::left > {
    static const CBLAS_SIDE value = CblasLeft;
};

template<>
struct cblas_option< tag::right > {
    static const CBLAS_SIDE value = CblasRight;
};

} // namespace detail
} // namespace blas
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
