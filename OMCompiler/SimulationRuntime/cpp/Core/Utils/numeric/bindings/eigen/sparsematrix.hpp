//
// Copyright (c) 2009--2010
// Thomas Klimpel and Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_EIGEN_SPARSEMATRIX_HPP
#define BOOST_NUMERIC_BINDINGS_EIGEN_SPARSEMATRIX_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/copy_const.hpp>
#include <Eigen/Sparse>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< int Value >
struct eigen_data_order {
    typedef typename mpl::if_<
        mpl::bool_< Value & Eigen::RowMajorBit >,
        tag::row_major,
        tag::column_major
    >::type type;
};

template< typename T, int Flags, typename Id, typename Enable >
struct adaptor< Eigen::SparseMatrix< T, Flags >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename copy_const<
        Id,
        //??? (Sorry, couldn't find it. Maybe fix it later.)
        std::ptrdiff_t
    >::type index_type;
    typedef typename eigen_data_order< Flags >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::index_type, index_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::matrix_type, tag::general >,
        mpl::pair< tag::data_structure, tag::compressed_sparse >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::index_base, mpl::int_<0> >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.rows();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.cols();
    }

    static value_type* begin_value( Id& id ) {
        return id._valuePtr();
    }

    static value_type* end_value( Id& id ) {
        return id._valuePtr() + id.nonZeros();
    }

    static index_type* begin_compressed_index_major( Id& id ) {
        return id._outerIndexPtr();
    }

    static index_type* end_compressed_index_major( Id& id ) {
        return id._outerIndexPtr() + id.outerSize() + 1;
    }

    static index_type* begin_index_minor( Id& id ) {
        return id._innerIndexPtr();
    }

    static index_type* end_index_minor( Id& id ) {
        return id._innerIndexPtr() + id.nonZeros();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
