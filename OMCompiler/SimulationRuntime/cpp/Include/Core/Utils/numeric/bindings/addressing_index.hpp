//
// Copyright (c) 2009 by Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_INDEX_HPP
#define BOOST_NUMERIC_BINDINGS_INDEX_HPP

#include <boost/mpl/if.hpp>
#include <boost/mpl/max.hpp>
#include <Core/Utils/numeric/bindings/rank.hpp>
#include <Core/Utils/numeric/bindings/is_column_major.hpp>

namespace boost {
namespace numeric {
namespace bindings {

template< typename T >
struct addressing_index_minor {
    typedef typename mpl::if_<
        is_column_major< T >,
        tag::addressing_index<1>,
        tag::addressing_index<
            mpl::max< tag::matrix, rank< T > >::type::value
        >
    >::type type;
};

template< typename T >
struct addressing_index_major {
    typedef typename mpl::if_<
        is_column_major< T >,
        tag::addressing_index<
            mpl::max< tag::matrix, rank< T > >::type::value
        >,
        tag::addressing_index<1>
    >::type type;
};


template< typename AddressingIndex, typename TransTag >
struct addressing_index_trans {
    typedef AddressingIndex type;
};

template<>
struct addressing_index_trans< tag::addressing_index<1>, tag::transpose > {
    typedef tag::addressing_index<2> type;
};

template<>
struct addressing_index_trans< tag::addressing_index<1>, tag::conjugate > {
    typedef tag::addressing_index<2> type;
};

template<>
struct addressing_index_trans< tag::addressing_index<2>, tag::transpose > {
    typedef tag::addressing_index<1> type;
};

template<>
struct addressing_index_trans< tag::addressing_index<2>, tag::conjugate > {
    typedef tag::addressing_index<1> type;
};


} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
