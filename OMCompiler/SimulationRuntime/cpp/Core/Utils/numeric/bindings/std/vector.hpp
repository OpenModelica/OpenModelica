//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_STD_VECTOR_HPP
#define BOOST_NUMERIC_BINDINGS_STD_VECTOR_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <vector>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Alloc, typename Id, typename Enable >
struct adaptor< std::vector< T, Alloc >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, tag::contiguous >
    > property_map;

    static std::ptrdiff_t size1( const Id& t ) {
        return t.size();
    }

    static value_type* begin_value( Id& t ) {
        return &t.front();
    }

    static value_type* end_value( Id& t ) {
        return &t.front() + t.size();
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
