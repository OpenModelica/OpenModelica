//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_GLAS_DENSE_VECTOR_COLLECTION_HPP
#define BOOST_NUMERIC_BINDINGS_GLAS_DENSE_VECTOR_COLLECTION_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/offset.hpp>
#include <glas/concept/dense_vector_collection.hpp>
#include <glas/concept/fixed_size_vector_expression.hpp>
#include <glas/concept/fixed_size.hpp>
#include <glas/concept/value_type.hpp>
#include <glas/concept/size.hpp>
#include <glas/concept/stride.hpp>
#include <glas/concept/storage_ptr.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

// Need a helper type here, because
// glas::fixed_size<T> doesn't work for any T
template< typename T, typename Enable = void >
struct glas_vector_size_type {
    typedef std::ptrdiff_t type;
};

template< typename T >
struct glas_vector_size_type<
            T, typename boost::enable_if< glas::FixedSizeVectorExpression<T> >::type > {
    typedef mpl::int_< glas::fixed_size<T>::value > type;
};

template< typename T, typename Id >
struct adaptor< T, Id, typename boost::enable_if< glas::DenseVectorCollection<T> >::type > {

    typedef typename copy_const< Id, typename glas::value_type<T>::type >::type value_type;
    typedef typename glas_vector_size_type< T >::type size_type1;
    typedef typename mpl::if_<
        glas::ContiguousDenseVectorCollection<T>,
        tag::contiguous,
        std::ptrdiff_t
    >::type stride_type1;

    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, size_type1 >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, stride_type1 >
    > property_map;

    // Only called in case of dynamic sizes
    static std::ptrdiff_t size1( const Id& id ) {
        return glas::size( id );
    }

    static value_type* begin_value( Id& id ) {
        return glas::storage_ptr( id );
    }

    static value_type* end_value( Id& id ) {
        return glas::storage_ptr( id ) + offset( id, bindings::size1( id ) );
    }

    // Only called in case of dynamic strides
    static std::ptrdiff_t stride1( const Id& id ) {
        return glas::stride( id );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
