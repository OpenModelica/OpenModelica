//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_TRANS_HPP
#define BOOST_NUMERIC_BINDINGS_TRANS_HPP

#include <boost/mpl/fold.hpp>
#include <boost/mpl/insert.hpp>
#include <boost/mpl/max.hpp>
#include <boost/mpl/vector.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/is_column_major.hpp>
#include <Core/Utils/numeric/bindings/rank.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/bandwidth.hpp>
#include <Core/Utils/numeric/bindings/tag.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <Core/Utils/numeric/bindings/has_band_array.hpp>
#include <Core/Utils/numeric/bindings/has_linear_array.hpp>
#include <boost/ref.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Conj >
struct trans_wrapper: reference_wrapper<T> {
    trans_wrapper( T& t ): reference_wrapper<T>( t ) {}
};

//
// In case of linear storage
//
template< typename T, typename Conj, typename Id, typename Enable >
struct adaptor< trans_wrapper<T, Conj>, Id, Enable > {

    typedef typename property_map_of< T >::type prop_of_T;
    typedef typename property_insert< T,

        // upgrade to at least a matrix
        mpl::pair<
            tag::entity,
            tag::tensor< mpl::max< tag::matrix, rank< T > >::type::value >
        >,

        // size1 <-> size2
        mpl::pair< tag::size_type<1>, typename result_of::size2< T >::type >,
        mpl::pair< tag::size_type<2>, typename result_of::size1< T >::type >,

        // row_major <-> column_major
        mpl::pair<
            tag::data_order,
            typename mpl::if_<
                is_column_major< T >,
                tag::row_major,
                tag::column_major >::type
        >,

        // Conjugate transform (if passed by template argument)
        Conj,

        // If T has a linear array, or has a band array
        // flip strides, stride1 <-> stride2
        typename mpl::if_< mpl::or_< has_linear_array< T >, has_band_array< T > >,
            mpl::pair< tag::stride_type<1>, typename result_of::stride2< T >::type >,
            mpl::void_
        >::type,
        typename mpl::if_< mpl::or_< has_linear_array< T >, has_band_array< T > >,
            mpl::pair< tag::stride_type<2>, typename result_of::stride1< T >::type >,
            mpl::void_
        >::type,

        // If T has a band array
        // flip bandwidths, bandwidth1 <-> bandwidth2
        typename mpl::if_< has_band_array< T >,
            mpl::pair< tag::bandwidth_type<1>, typename result_of::bandwidth2< T >::type >,
            mpl::void_
        >::type,
        typename mpl::if_< has_band_array< T >,
            mpl::pair< tag::bandwidth_type<2>, typename result_of::bandwidth1< T >::type >,
            mpl::void_
        >::type,

        // If a data_side tag is present:
        // upper <-> lower
        typename mpl::if_<
            mpl::has_key< prop_of_T, tag::data_side >,
            typename mpl::if_<
                is_same<
                    typename mpl::at< prop_of_T, tag::data_side >::type,
                    tag::upper
                >,
                mpl::pair< tag::data_side, tag::lower >,
                mpl::pair< tag::data_side, tag::upper >
            >::type,
            mpl::void_
        >::type

    >::type property_map;

    // Flip size1/size2
    static typename result_of::size2< T >::type size1( const Id& id ) {
        return bindings::size2( id.get() );
    }

    static typename result_of::size1< T >::type size2( const Id& id ) {
        return bindings::size1( id.get() );
    }

    // Value array access
    static typename result_of::begin_value< T >::type begin_value( Id& id ) {
        return bindings::begin_value( id.get() );
    }

    static typename result_of::end_value< T >::type end_value( Id& id ) {
        return bindings::end_value( id.get() );
    }

    // Linear array storage transpose
    // Flip stride1/stride2
    static typename result_of::stride2< T >::type stride1( const Id& id ) {
        return bindings::stride2( id.get() );
    }

    static typename result_of::stride1< T >::type stride2( const Id& id ) {
        return bindings::stride1( id.get() );
    }

    // Banded matrix transpose
    // Flip bandwidth1/bandwidth2
    static typename result_of::bandwidth2< T >::type bandwidth1( const Id& id ) {
        return bindings::bandwidth2( id.get() );
    }

    static typename result_of::bandwidth1< T >::type bandwidth2( const Id& id ) {
        return bindings::bandwidth1( id.get() );
    }

};

} // namespace detail

namespace result_of {

template< typename T >
struct trans {
    typedef detail::trans_wrapper<T, mpl::void_> type;
};

}

template< typename T >
typename result_of::trans<T>::type const trans( T& underlying ) {
    return detail::trans_wrapper<T, mpl::void_>( underlying );
}

template< typename T >
typename result_of::trans<const T>::type const trans( const T& underlying ) {
    return detail::trans_wrapper<const T, mpl::void_>( underlying );
}

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
