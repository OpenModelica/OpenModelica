//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_DETAIL_CONVERT_TO_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_DETAIL_CONVERT_TO_HPP

#include <Core/Utils/numeric/bindings/detail/convert_to.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>
#include <boost/numeric/ublas/fwd.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template<>
struct convert_to< tag::data_order, ublas::row_major > {
    typedef tag::row_major type;
};

template<>
struct convert_to< tag::data_order, ublas::column_major > {
    typedef tag::column_major type;
};

template<>
struct convert_to< tag::matrix_type, ublas::lower > {
    typedef tag::triangular type;
};

template<>
struct convert_to< tag::matrix_type, ublas::upper > {
    typedef tag::triangular type;
};

template<>
struct convert_to< tag::matrix_type, ublas::unit_lower > {
    typedef tag::unit_triangular type;
};

template<>
struct convert_to< tag::matrix_type, ublas::unit_upper > {
    typedef tag::unit_triangular type;
};

template<>
struct convert_to< tag::data_side, ublas::lower > {
    typedef tag::lower type;
};

template<>
struct convert_to< tag::data_side, ublas::upper > {
    typedef tag::upper type;
};

template<>
struct convert_to< tag::data_side, ublas::unit_lower > {
    typedef tag::lower type;
};

template<>
struct convert_to< tag::data_side, ublas::unit_upper > {
    typedef tag::upper type;
};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
