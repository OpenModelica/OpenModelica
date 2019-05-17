//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_BASIC_UNWRAPPER_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_BASIC_UNWRAPPER_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Id >
struct basic_unwrapper {

    static typename result_of::size1< T >::type size1( const Id& id ) {
        return bindings::size1( id.get() );
    }

    static typename result_of::size2< T >::type size2( const Id& id ) {
        return bindings::size2( id.get() );
    }

    static typename result_of::stride1< T >::type stride1( const Id& id ) {
        return bindings::stride1( id.get() );
    }

    static typename result_of::stride2< T >::type stride2( const Id& id ) {
        return bindings::stride2( id.get() );
    }

    static typename result_of::begin_value< T >::type begin_value( Id& id ) {
        return bindings::begin_value( id.get() );
    }

    static typename result_of::end_value< T >::type end_value( Id& id ) {
        return bindings::end_value( id.get() );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
