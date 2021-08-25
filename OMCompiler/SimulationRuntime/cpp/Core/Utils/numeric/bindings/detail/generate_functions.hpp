//
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_GENERATE_FUNCTIONS_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_GENERATE_FUNCTIONS_HPP

#include <boost/preprocessor/repetition.hpp>
#include <boost/preprocessor/cat.hpp>

//
// Macro used to generate convenience functions
//

#define GENERATE_FUNCTIONS( function_name, suffix, tag ) \
\
namespace result_of {\
\
template< typename T > \
struct BOOST_PP_CAT( function_name, suffix ) { \
    typedef typename detail::\
    BOOST_PP_CAT( function_name, _impl ) \
    <T, tag >::result_type type; \
}; \
\
}\
\
template< typename T >\
typename result_of:: BOOST_PP_CAT( function_name, suffix )<T>::type \
BOOST_PP_CAT( function_name, suffix )( T& t ) {\
    return detail:: \
        BOOST_PP_CAT( function_name, _impl ) \
        <T, tag >::invoke( t );\
}\
\
template< typename T >\
typename result_of:: BOOST_PP_CAT( function_name, suffix )<const T>::type \
BOOST_PP_CAT( function_name, suffix )( const T& t ) {\
    return detail:: \
        BOOST_PP_CAT( function_name, _impl ) \
        <const T, tag >::invoke( t );\
}

#endif
