//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_GLAS_DENSE_MATRIX_HPP
#define BOOST_NUMERIC_BINDINGS_GLAS_DENSE_MATRIX_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/if_row_major.hpp>
#include <Core/Utils/numeric/bindings/glas/detail/convert_to.hpp>
#include <glas/container/dense_matrix.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename O, typename Id, typename Enable >
struct adaptor< glas::dense_matrix< T, O >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename convert_to< tag::data_order, O >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::stride_type<1>,
            typename if_row_major< data_order, std::ptrdiff_t, tag::contiguous >::type >,
        mpl::pair< tag::stride_type<2>,
            typename if_row_major< data_order, tag::contiguous, std::ptrdiff_t >::type >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.num_rows();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.num_columns();
    }

    static value_type* begin_value( Id& id ) {
        return id.storage_ptr();
    }

    static value_type* end_value( Id& id ) {
        return id.storage_ptr() + id.num_rows() * id.num_columns();
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.num_columns();
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
