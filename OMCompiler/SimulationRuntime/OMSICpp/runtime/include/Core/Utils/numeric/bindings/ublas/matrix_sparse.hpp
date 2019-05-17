//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_MATRIX_SPARSE_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_MATRIX_SPARSE_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/copy_const.hpp>
#include <Core/Utils/numeric/bindings/ublas/detail/convert_to.hpp>
#include <Core/Utils/numeric/bindings/ublas/matrix_expression.hpp>
#include <Core/Utils/numeric/bindings/ublas/storage.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename F, std::size_t IB, typename IA, typename TA, typename Id, typename Enable >
struct adaptor< ublas::compressed_matrix< T, F, IB, IA, TA >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename copy_const< Id, typename bindings::value_type<IA>::type >::type index_type;
    typedef typename convert_to< tag::data_order, F >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::index_type, index_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::matrix_type, tag::general >,
        mpl::pair< tag::data_structure, tag::compressed_sparse >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::index_base, mpl::int_<IB> >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static value_type* begin_value( Id& id ) {
        return bindings::begin_value( id.value_data() );
    }

    static value_type* end_value( Id& id ) {
        return bindings::begin_value( id.value_data() ) + id.nnz();
    }

    static index_type* begin_compressed_index_major( Id& id ) {
        return bindings::begin_value( id.index1_data() );
    }

    static index_type* end_compressed_index_major( Id& id ) {
        return bindings::end_value( id.index1_data() );
    }

    static index_type* begin_index_minor( Id& id ) {
        return bindings::begin_value( id.index2_data() );
    }

    static index_type* end_index_minor( Id& id ) {
        return bindings::begin_value( id.index2_data() ) + id.nnz();
    }

};

template< typename T, typename F, std::size_t IB, typename IA, typename TA, typename Id, typename Enable >
struct adaptor< ublas::coordinate_matrix< T, F, IB, IA, TA >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename copy_const< Id, typename bindings::value_type<IA>::type >::type index_type;
    typedef typename convert_to< tag::data_order, F >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::index_type, index_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::matrix_type, tag::general >,
        mpl::pair< tag::data_structure, tag::coordinate_sparse >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::index_base, mpl::int_<IB> >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static value_type* begin_value( Id& id ) {
        return bindings::begin_value( id.value_data() );
    }

    static value_type* end_value( Id& id ) {
        return bindings::begin_value( id.value_data() ) + id.nnz();
    }

    static index_type* begin_index_major( Id& id ) {
        return bindings::begin_value( id.index1_data() );
    }

    static index_type* end_index_major( Id& id ) {
        return bindings::begin_value( id.index1_data() ) + id.nnz();
    }

    static index_type* begin_index_minor( Id& id ) {
        return bindings::begin_value( id.index2_data() );
    }

    static index_type* end_index_minor( Id& id ) {
        return bindings::begin_value( id.index2_data() ) + id.nnz();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
