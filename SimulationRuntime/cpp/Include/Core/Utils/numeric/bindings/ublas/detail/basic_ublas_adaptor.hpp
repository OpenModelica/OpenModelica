//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_DETAIL_BASIC_UBLAS_ADAPTOR_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_DETAIL_BASIC_UBLAS_ADAPTOR_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Id, typename P1 = mpl::void_,
          typename P2 = mpl::void_, typename P3 = mpl::void_ >
struct basic_ublas_adaptor {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_insert< adapted_type, P1, P2, P3 >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.data() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::end_value( id.data() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.data() );
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return bindings::stride2( id.data() );
    }

};

} // detail
} // bindings
} // numeric
} // boost

#endif
