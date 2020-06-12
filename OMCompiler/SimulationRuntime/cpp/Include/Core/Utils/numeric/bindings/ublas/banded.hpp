//
// Copyright (c) 2002 Kresimir Fresl
// Copyright (c) 2010 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_UBLAS_BANDED_HPP
#define BOOST_NUMERIC_BINDINGS_UBLAS_BANDED_HPP

#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/if_row_major.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/ublas/detail/basic_ublas_adaptor.hpp>
#include <Core/Utils/numeric/bindings/ublas/detail/convert_to.hpp>
#include <Core/Utils/numeric/bindings/ublas/matrix_expression.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <boost/numeric/ublas/banded.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename F, typename A, typename Id, typename Enable >
struct adaptor< ublas::banded_matrix< T, F, A >, Id, Enable > {

    // The ublas banded row_major format corresponds to the LAPACK band format.
    // LAPACK is column_major; so we flip the data order reported by uBLAS.
    typedef typename copy_const< Id, T >::type value_type;
    typedef typename if_row_major<
                typename convert_to< tag::data_order, F >::type,
                tag::column_major,
                tag::row_major
            >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::matrix_type, tag::band >,
        mpl::pair< tag::data_structure, tag::band_array >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::bandwidth_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::bandwidth_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::stride_type<1>,
            typename if_row_major< data_order, std::ptrdiff_t, tag::contiguous >::type >,
        mpl::pair< tag::stride_type<2>,
            typename if_row_major< data_order, tag::contiguous, std::ptrdiff_t >::type >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.size1();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.size2();
    }

    static value_type* begin_value( Id& id ) {
        return bindings::begin_value( id.data() );
    }

    static value_type* end_value( Id& id ) {
        return bindings::end_value( id.data() );
    }

    // A.k.a. left half-bandwidth
    static std::ptrdiff_t bandwidth1( const Id& id ) {
        return id.lower();
    }

    // A.k.a. right half-bandwidth
    static std::ptrdiff_t bandwidth2( const Id& id ) {
        return id.upper();
    }

    // These strides are over the band array structure; not over
    // the band matrix representation of this structure
    static std::ptrdiff_t stride1( const Id& id ) {
        return id.lower() + id.upper() + 1;
    }

    static std::ptrdiff_t stride2( const Id& id ) {
        return id.lower() + id.upper() + 1;
    }

};


template< typename T, typename Id, typename Enable >
struct adaptor< ublas::banded_adaptor< T >, Id, Enable >:
    basic_ublas_adaptor<
        T,
        Id,
        mpl::pair< tag::matrix_type, tag::band >,
        mpl::pair< tag::bandwidth_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::bandwidth_type<2>, std::ptrdiff_t >
    > {

    // A.k.a. left half-bandwidth
    static std::ptrdiff_t bandwidth1( const Id& id ) {
        return id.lower();
    }

    // A.k.a. right half-bandwidth
    static std::ptrdiff_t bandwidth2( const Id& id ) {
        return id.upper();
    }

};

} // detail
} // bindings
} // numeric
} // boost

#endif
