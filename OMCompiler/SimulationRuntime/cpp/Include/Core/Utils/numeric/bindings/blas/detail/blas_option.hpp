//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BLAS_DETAIL_BLAS_OPTION_HPP
#define BOOST_NUMERIC_BINDINGS_BLAS_DETAIL_BLAS_OPTION_HPP

#include <boost/mpl/char.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace blas {
namespace detail {

template< typename Tag >
struct blas_option {};

template<>
struct blas_option< tag::transpose >: mpl::char_< 'T' > {};

template<>
struct blas_option< tag::no_transpose >: mpl::char_< 'N' > {};

template<>
struct blas_option< tag::conjugate >: mpl::char_< 'C' > {};

template<>
struct blas_option< tag::upper >: mpl::char_< 'U' > {};

template<>
struct blas_option< tag::lower >: mpl::char_< 'L' > {};

template<>
struct blas_option< tag::unit >: mpl::char_< 'U' > {};

template<>
struct blas_option< tag::non_unit >: mpl::char_< 'N' > {};

template<>
struct blas_option< tag::left >: mpl::char_< 'L' > {};

template<>
struct blas_option< tag::right >: mpl::char_< 'R' > {};

} // namespace detail
} // namespace blas
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
