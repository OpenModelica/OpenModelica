//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_SCALAR_VECTOR_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_SCALAR_VECTOR_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <boost/numeric/ublas/vector.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Alloc, typename Id, typename Enable >
struct adaptor< ublas::scalar_vector< T, Alloc >, Id, Enable > {

    typedef typename add_const< T >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, mpl::int_<0> >
    > property_map;

    static std::ptrdiff_t size1( const Id& t ) {
        return t.size();
    }

    static value_type* begin_value( Id& t ) {
        return t.find_element( 0 );
    }

    static value_type* end_value( Id& t ) {
        return t.find_element( 0 ) + 1;
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
