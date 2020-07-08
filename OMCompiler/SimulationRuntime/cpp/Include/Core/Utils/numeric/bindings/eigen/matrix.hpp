//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_EIGEN_MATRIX_HPP
#define BOOST_NUMERIC_BINDINGS_EIGEN_MATRIX_HPP

#include <boost/mpl/equal.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/if_row_major.hpp>
#include <Eigen/Core>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< int Value >
struct eigen_size_type {
    typedef typename mpl::if_<
        mpl::bool_< Value == Eigen::Dynamic >,
        std::ptrdiff_t,
        mpl::int_<Value>
    >::type type;
};

template< int Value >
struct eigen_data_order {
    typedef typename mpl::if_<
        mpl::bool_< Value & Eigen::RowMajorBit >,
        tag::row_major,
        tag::column_major
    >::type type;
};

template< typename T, int Rows, int Cols, int Options,
          typename Id, typename Enable >
struct adaptor< Eigen::Matrix< T, Rows, Cols, Options >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename eigen_size_type< Rows >::type size_type1;
    typedef typename eigen_size_type< Cols >::type size_type2;
    typedef typename eigen_data_order< Options >::type data_order;
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
        return id.rows();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.cols();
    }

    static value_type* begin_value( Id& id ) {
        return id.data();
    }

    static value_type* end_value( Id& id ) {
        return id.data() + id.size();
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.cols();
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return id.rows();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
