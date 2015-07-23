//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_MTL_DETAIL_CONVERT_TO_HPP
#define BOOST_NUMERIC_BINDINGS_MTL_DETAIL_CONVERT_TO_HPP

#include <Core/Utils/numeric/bindings/detail/convert_to.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>
#include <boost/numeric/mtl/utility/tag.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template<>
struct convert_to< bindings::tag::data_order, mtl::tag::row_major > {
    typedef bindings::tag::row_major type;
};

template<>
struct convert_to< bindings::tag::data_order, mtl::tag::col_major > {
    typedef bindings::tag::column_major type;
};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
