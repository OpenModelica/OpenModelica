//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_IO_HPP
#define BOOST_NUMERIC_BINDINGS_IO_HPP

#include <iostream>
#include <boost/utility/enable_if.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptable_type.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Stream, typename T >
Stream& pretty_print( Stream& os, const T& t ) {
    namespace bindings = ::boost::numeric::bindings;
    os << "[" << size1(t) << "] ";
    typename bindings::result_of::begin< const T >::type i = bindings::begin(t);
    if ( i != bindings::end(t) ) {
        os << *i;
        ++i;
    }
    for( ; i != bindings::end(t); ++i ) {
        os << " " << *i;
    }
    return os;
}

} // detail
} // bindings
} // numeric
} // boost


template< typename T >
std::ostream& operator<<( std::ostream& os,
        const boost::numeric::bindings::detail::adaptable_type<T>& object ) {
    return boost::numeric::bindings::detail::pretty_print( os, object.derived() );
}


#endif
