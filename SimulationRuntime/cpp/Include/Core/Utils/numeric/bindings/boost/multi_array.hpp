//
// Copyright (c) 2010 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_BOOST_MULTI_ARRAY_HPP
#define BOOST_NUMERIC_BINDINGS_BOOST_MULTI_ARRAY_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <boost/multi_array.hpp>
#include <boost/mpl/range_c.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Map, typename AddressingIndex >
struct multi_array_dim_inserter {

    typedef typename mpl::insert<
        typename mpl::insert<
            Map,
            mpl::pair< tag::size_type< AddressingIndex::value >, std::ptrdiff_t >
        >::type,
        mpl::pair< tag::stride_type< AddressingIndex::value >, std::ptrdiff_t >
    >::type type;

};

template< typename T, std::size_t Dim, typename Alloc, typename Id, typename Enable >
struct adaptor< boost::multi_array<T,Dim,Alloc>, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::tensor< Dim > >,
        mpl::pair< tag::data_order, tag::row_major >,
        mpl::pair< tag::data_structure, tag::linear_array >
    >  basic_map;
    typedef typename mpl::fold<
        mpl::range_c< std::size_t, 1, Dim+1 >,
        basic_map,
        multi_array_dim_inserter<
            mpl::_1,
            mpl::_2
        >
    >::type property_map;

    // Sizes are only reachable if Addressing Index <= Dim, otherwise
    // the default (1) will be returned
    static std::ptrdiff_t size1( const Id& id ) {
        return id.shape()[0];
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.shape()[1];
    }

    static std::ptrdiff_t stride1( const Id& id ) {
        return id.strides()[0];
    }

    // Only reachable if dimension D is sufficient
    static std::ptrdiff_t stride2( const Id& id ) {
        return id.strides()[1];
    }

    static value_type* begin_value( Id& id ) {
        return id.data();
    }

    static value_type* end_value( Id& id ) {
        return id.data()+id.num_elements();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
