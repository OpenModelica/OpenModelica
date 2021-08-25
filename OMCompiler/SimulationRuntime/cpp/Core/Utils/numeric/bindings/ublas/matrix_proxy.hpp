//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_MATRIX_PROXY_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_MATRIX_PROXY_HPP

#include <Core/Utils/numeric/bindings/bandwidth.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/offset.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_range< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_map_of< adapted_type >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1(), id.start2() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1() + id.size1(), id.start2() + id.size2() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() );
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return bindings::stride2( id.data() );
    }

    static std::ptrdiff_t bandwidth1( const Id& id ) {
        return bindings::bandwidth1( id.data() );
    }

    static std::ptrdiff_t bandwidth2( const Id& id ) {
        return bindings::bandwidth2( id.data() );
    }

};


template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_slice< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_map_of< adapted_type >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1(), id.start2() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1() + id.size1(), id.start2() + id.size2() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.stride1();
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return id.stride2();
    }

    static std::ptrdiff_t bandwidth1( const Id& id ) {
        return bindings::bandwidth1( id.data() );
    }

    static std::ptrdiff_t bandwidth2( const Id& id ) {
        return bindings::bandwidth2( id.data() );
    }

};


template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_column< T >, Id, Enable > {

    typedef typename copy_const< Id, typename bindings::value_type< T>::type >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        // TODO in case of column major, this could be contiguous
        mpl::pair< tag::stride_type<1>, std::ptrdiff_t >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static value_type* begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), 0, id.index() );
    }

    static value_type* end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), bindings::size(id), id.index() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() );
    }

};


template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_row< T >, Id, Enable > {

    typedef typename copy_const< Id, typename bindings::value_type< T>::type >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        // TODO in case of row major, this could be contiguous
        mpl::pair< tag::stride_type<1>, std::ptrdiff_t >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static value_type* begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.index(), 0 );
    }

    static value_type* end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.index(), bindings::size(id) );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride2( id.data() );
    }

};

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_vector_range< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_insert< adapted_type,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::stride_type<1>, std::ptrdiff_t >
    >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1(), id.start2() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1() + id.size1(), id.start2() + id.size2() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() ) + bindings::stride2( id.data() );
    }

};

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::matrix_vector_slice< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_insert< adapted_type,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::stride_type<1>, std::ptrdiff_t >
    >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1(), id.start2() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id.data(), id.start1() + id.size(), id.start2() + id.size() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.stride1() * bindings::stride1( id.data() ) +
               id.stride2() * bindings::stride2( id.data() );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
