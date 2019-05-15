//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_EXPRESSION_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_EXPRESSION_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/property_map.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/stride.hpp>
#include <boost/numeric/ublas/vector_expression.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Id, typename Enable >
struct adaptor< ublas::vector_reference< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type adapted_type;
    typedef typename property_map_of< adapted_type >::type property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static typename result_of::begin_value< adapted_type >::type begin_value( Id& id ) {
        return bindings::begin_value( id.expression() );
    }

    static typename result_of::end_value< adapted_type >::type end_value( Id& id ) {
        return bindings::end_value( id.expression() );
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return bindings::stride1( id.expression() );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
