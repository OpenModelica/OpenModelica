//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_MTL_DENSE2D_HPP
#define BOOST_NUMERIC_BINDINGS_MTL_DENSE2D_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/if_row_major.hpp>
#include <Core/Utils/numeric/bindings/mtl/detail/convert_to.hpp>
#include <boost/numeric/mtl/matrix/dense2D.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Dimensions, int N >
struct mtl_matrix_size_type {
    typedef std::ptrdiff_t type;
};

template< std::size_t Rows, std::size_t Cols >
struct mtl_matrix_size_type< mtl::fixed::dimensions< Rows, Cols >, 1 > {
    typedef mpl::int_< Rows > type;
};

template< std::size_t Rows, std::size_t Cols >
struct mtl_matrix_size_type< mtl::fixed::dimensions< Rows, Cols >, 2 > {
    typedef mpl::int_< Cols > type;
};

template< typename T, typename Parameters, typename Id, typename Enable >
struct adaptor< mtl::dense2D< T, Parameters >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename convert_to<
        tag::data_order,
        typename Parameters::orientation
    >::type data_order;
    typedef typename mtl_matrix_size_type<
        typename Parameters::dimensions,
        1
    >::type size_type1;
    typedef typename mtl_matrix_size_type<
        typename Parameters::dimensions,
        2
    >::type size_type2;

    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, size_type1 >,
        mpl::pair< tag::size_type<2>, size_type2 >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::stride_type<1>,
            typename if_row_major< data_order, size_type2, tag::contiguous >::type >,
        mpl::pair< tag::stride_type<2>,
            typename if_row_major< data_order, tag::contiguous, size_type1 >::type >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.num_rows();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.num_cols();
    }

    static value_type* begin_value( Id& id ) {
        return id.elements();
    }

    static value_type* end_value( Id& id ) {
        return id.elements() + id.used_memory();
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.num_cols();
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return id.num_rows();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
