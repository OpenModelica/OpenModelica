//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_SPARSE_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_VECTOR_SPARSE_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/ublas/vector_expression.hpp>
#include <boost/numeric/ublas/vector_sparse.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, std::size_t IB, typename IA, typename TA, typename Id, typename Enable >
struct adaptor< ublas::compressed_vector< T, IB, IA, TA >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::compressed_sparse >
    > property_map;

    static std::ptrdiff_t size1( const Id& t ) {
        return t.size();
    }

//     static void index_data( Id& t ) {
//       //  t.index_data();
//     }
//

    static value_type* begin_value( Id& t ) {
        return bindings::begin_value( t.value_data() );
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
