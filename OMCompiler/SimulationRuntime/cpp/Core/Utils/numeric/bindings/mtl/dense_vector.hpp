//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_MTL_DENSE_VECTOR_HPP
#define BOOST_NUMERIC_BINDINGS_MTL_DENSE_VECTOR_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/mtl/detail/convert_to.hpp>
#include <boost/numeric/mtl/vector/dense_vector.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename Dimension >
struct mtl_vector_size_type {
    typedef std::ptrdiff_t type;
};

template< std::size_t Size >
struct mtl_vector_size_type< mtl::vector::fixed::dimension< Size > > {
    typedef mpl::int_< Size > type;
};

template< typename T, typename Parameters, typename Id, typename Enable >
struct adaptor< mtl::dense_vector< T, Parameters >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename convert_to<
            tag::data_order,
            typename Parameters::orientation
    >::type data_order;
    typedef typename mtl_vector_size_type<
        typename Parameters::dimension
    >::type size_type1;

    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, size_type1 >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::stride_type<1>, tag::contiguous >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size();
    }

    static value_type* begin_value( Id& id ) {
        return id.begin();
    }

    static value_type* end_value( Id& id ) {
        return id.end();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
