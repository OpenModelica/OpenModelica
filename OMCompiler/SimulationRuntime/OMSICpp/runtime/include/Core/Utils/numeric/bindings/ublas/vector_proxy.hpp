//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_PROXY_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_PROXY_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/offset.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>
#include <boost/numeric/ublas/vector_proxy.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::vector_range< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_map_of< adapted_type >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) + id.start() * stride1( id );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) + id.size() * stride1( id );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() );
    }

};

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::vector_slice< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_map_of< adapted_type >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id, id.start() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::begin_value( id.data() ) +
               offset( id, id.start() + id.size() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
