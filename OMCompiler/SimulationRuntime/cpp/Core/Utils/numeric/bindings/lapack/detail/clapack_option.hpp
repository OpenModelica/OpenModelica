//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_LAPACK_DETAIL_CLAPACK_OPTION_HPP
#define BOOST_NUMERIC_BINDINGS_LAPACK_DETAIL_CLAPACK_OPTION_HPP

#include <Core/Utils/numeric/bindings/blas/detail/cblas_option.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace lapack {
namespace detail {

template< typename Tag >
struct clapack_option: blas::detail::cblas_option< Tag > {};

} // namespace detail
} // namespace blas
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
