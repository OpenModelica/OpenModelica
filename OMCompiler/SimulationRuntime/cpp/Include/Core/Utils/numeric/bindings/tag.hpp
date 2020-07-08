//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_TAG_HPP
#define BOOST_NUMERIC_BINDINGS_TAG_HPP

#include <boost/mpl/bool.hpp>
#include <boost/mpl/int.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct is_tag: mpl::bool_<false> {};

#define ADD_TAG( tag_name ) \
\
namespace tag { \
struct tag_name {}; \
} \
\
template<> \
struct is_tag< tag::tag_name >: \
    mpl::bool_< true > {};


#define ADD_INT_TEMPLATE_TAG( tag_name ) \
\
namespace tag { \
template< int N >\
struct tag_name: mpl::int_< N > {}; \
} \
template< int N > \
struct is_tag< tag::tag_name<N> >: mpl::bool_< true > {};


#define ADD_TAG_ALIAS( tag_name, other_tag_name ) \
\
namespace tag { \
struct tag_name: other_tag_name {}; \
} \
\
template<> \
struct is_tag< tag::tag_name >: \
    mpl::bool_< true > {};

ADD_TAG( index_type )
ADD_TAG( value_type )
ADD_TAG( value )
ADD_TAG( value_transform )

ADD_TAG( entity )
ADD_TAG( matrix_type )

ADD_TAG( data_structure )
ADD_TAG( data_order )
ADD_TAG( data_side )

ADD_INT_TEMPLATE_TAG( tensor )
ADD_INT_TEMPLATE_TAG( size_type )
ADD_INT_TEMPLATE_TAG( stride_type )
ADD_INT_TEMPLATE_TAG( bandwidth_type )
ADD_INT_TEMPLATE_TAG( addressing_index )

// Supported data structures
ADD_TAG( linear_array )
ADD_TAG( triangular_array )
ADD_TAG( band_array )
ADD_TAG( compressed_sparse )
ADD_TAG( coordinate_sparse )

ADD_TAG( structure )
ADD_TAG( general )
ADD_TAG( triangular )
ADD_TAG( unit_triangular )
ADD_TAG( symmetric )
ADD_TAG( hermitian )
ADD_TAG( band )

ADD_TAG( num_strides )

ADD_TAG( row_major )
ADD_TAG( column_major )

ADD_TAG( upper )
ADD_TAG( lower )
ADD_TAG( unit_upper )
ADD_TAG( unit_lower )

// BLAS Options
ADD_TAG( no_transpose )
ADD_TAG( transpose )
ADD_TAG( conjugate )

ADD_TAG( unit )
ADD_TAG( non_unit )
ADD_TAG( left )
ADD_TAG( right )
ADD_TAG( both )

// Sparse matrix
ADD_TAG( index_major )
ADD_TAG( compressed_index_major )
ADD_TAG( index_minor )
ADD_TAG( index_base )

namespace tag {

typedef tensor<0> scalar;
typedef tensor<1> vector;
typedef tensor<2> matrix;
typedef mpl::int_<1> contiguous;

}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
