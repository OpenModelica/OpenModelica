#pragma once
//#define BOOST_ENABLE_ASSERT_HANDLER
#include <boost/assert.hpp>
#include <boost/algorithm/minmax_element.hpp>

/*****************************************************************************/
/**

Auxillary Array operations for OpenModelica.


\date     September, 1st, 2010
\author

*/
/*****************************************************************************
Copyright (c) 2010, OSMC
*****************************************************************************/


/**
Assertion function
*/
//void boost::assertion_failed(char const * expr, char const * function,
//                             char const * file, long line);
#include <boost/multi_array.hpp>
#include <functional>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
using namespace boost::numeric;
using boost::multi_array;
using boost::const_multi_array_ref;
using boost::multi_array_ref;



/**
Operation class which performs the array operation *,/
*/
template< typename T1, typename T2, class F >
struct Operation
{
  Operation( F op ): _op(op) {}
  T1 &operator()( T1 &x, const T2 &y ) const
  { x = _op( y ); return x; }
  F _op;
};

/**
Operation class which performs the array operation +,-
*/
template< typename T, class F >
struct Operation2
{
  Operation2( F op ): _op(op) {}
  T &operator()( T &x, const T &y, const T &z ) const
  { x = _op( y, z ); return x; }
  F _op;
};


/**
Helper function for multiply_array,divide_array copies array a used as return value and performs operation
*/
template < typename T, size_t NumDims, class F >
boost::multi_array< T, NumDims > op_cp_array( boost::multi_array_ref< T, NumDims > a, F f )
{
  boost::multi_array< T, NumDims > retVal(a);
  Operation< T, T, F > opis( f );
  return array_operation( retVal, a, opis );
}
/**
Helper function for subtract_array,add_array, copies array a used as return value and performs operation
*/
template<
  typename T,size_t NumDims, class F
 >
boost::multi_array< T, NumDims > op_cp_array
( boost::multi_array_ref< T, NumDims > a, boost::multi_array_ref< T, NumDims > b, F f )
{
  boost::multi_array< T, NumDims > retVal( a );
  return array_operation( retVal, a, b, Operation2< T, F >( f ) );
}

/**
Multiplies an array with a scalar value (a type as template parameter)
*/
template < typename T, size_t NumDims >
boost::multi_array< T, NumDims > multiply_array( boost::multi_array_ref< T, NumDims > a,  const T &b )
{
  return  op_cp_array<T>( a, std::bind2nd( std::multiplies< T >(), b ) );
};


/**
Divides an array with a scalar value (a type as template parameter)
*/
template < typename T, size_t NumDims >
boost::multi_array< T, NumDims > divide_array( boost::multi_array_ref< T, NumDims > &a,  const T &b )
{
    return  op_cp_array<T>( a, std::bind2nd( std::divides< T >(), b ) );
};

/**
Subtracts two arrays (a,b type as template parameter)
*/
template < typename T, size_t dims >
boost::multi_array< T, dims > subtract_array( boost::multi_array_ref< T, dims > a ,  boost::multi_array_ref< T, dims > b  )
{
    return op_cp_array< T >( a, b, std::minus< T >() );
};

/**
Adds two arrays (a,b type as template parameter)
*/
template < typename T, size_t dims >
boost::multi_array< T, dims > add_array( boost::multi_array_ref< T, dims > a ,  boost::multi_array_ref< T, dims > b  )
{
  return op_cp_array< T >( a, b, std::plus< T >() );
};

/**
scalar product of two arrays (a,b type as template parameter)
*/
template < typename T >
T dot_array( boost::multi_array_ref< T, 1 > a ,  boost::multi_array_ref< T, 1 > b  )
{
  T tmp = 0;
  typename boost::multi_array< T, 1 >::const_iterator j = b.begin();
  for ( typename boost::multi_array< T, 1 >::iterator i = a.begin();  i != a.end(); i++, j++ )
    tmp += (*i) * (*j);

  return tmp;
};

/**
cross product of two arrays (a,b type as template parameter)
*/
template < typename T >
boost::multi_array< T, 1 > cross_array( boost::multi_array_ref< T, 1 > a ,  boost::multi_array_ref< T, 1 > b  )
{
  typename boost::multi_array<T, 1> res(boost::extents[3]);
  res.reindex(1);
  res[1] = (a[2] * b[3]) - (a[3] * b[2]);
  res[2] = (a[3] * b[1]) - (a[1] * b[3]);
  res[3] = (a[1] * b[2]) - (a[2] * b[1]);
  return res;
};

/**
- array (a)
*/
template < typename T, size_t dims >
void usub_array(boost::multi_array_ref< T, dims > &a)
{
  for ( typename boost::multi_array< T, dims >::iterator i = a.begin();  i != a.end(); i++)
    (*i) = -(*i);
}

/**
Applies array operation F (*,/) on array
*/

template< typename T1, typename T2, size_t dims, class F >
boost::multi_array_ref< T1, dims >  array_operation( boost::multi_array< T1, dims > a, const boost::multi_array_ref< T2, dims > b, F& op )
{
  typename boost::multi_array_ref< T2, dims >::const_iterator j = b.begin();
  for ( typename boost::multi_array< T1, dims >::iterator i = a.begin();
        i != a.end(); i++, j++ )
        array_operation( *i, *j, op );
  return a;
}


/**
Applies array operation F  (*,/) on one dimensional array
*/
template<
  typename T1, typename T2, class F
>
boost::multi_array_ref< T1, 1 > array_operation( boost::multi_array< T1, 1 > a, boost::multi_array_ref< T2, 1 > b, F& op )
{
  typename boost::multi_array_ref< T2, 1 >::const_iterator j = b.begin();
  for ( typename boost::multi_array< T1, 1 >::iterator i = a.begin();
        i != a.end(); i++, j++ )
    op( *i, *j );
  return a;
}

/**
Applies array operation F  (*,/) on  sub array a[i]
*/
template<typename T1, typename T2, size_t NumDims, class F >

boost::detail::multi_array::sub_array< T1, NumDims > array_operation( boost::detail::multi_array::sub_array< T1, NumDims > a, const boost::multi_array_ref< T2, NumDims > &b, F op )
{
  typename boost::multi_array_ref< T2, NumDims >::const_iterator j = b.begin();
  for ( typename boost::detail::multi_array::sub_array< T1, NumDims >::iterator i = a.begin();
        i != a.end(); i++, j++ )
    array_operation( *i, *j, op );
  return a;
}

/**
Applies array operation F  (*,/) on one dimensial sub array a[i]
*/
template< typename T1, typename T2, class F >
boost::detail::multi_array::sub_array< T1, 1 > array_operation( boost::detail::multi_array::sub_array< T1, 1 > a, boost::multi_array_ref< T2, 1 > &b,  F op )
{
  typename boost::multi_array_ref< T2, 1 >::const_iterator j = b.begin();
  for ( typename boost::detail::multi_array::sub_array< T1, 1 >::iterator i = a.begin();
        i != a.end(); i++, j++ )
    op( *i, *j );
  return a;
}


/**
Applies array operation F (+,-) on  on dimensional  subarray
*/

template<
  typename T1, typename T2, typename T3, class F >
boost::detail::multi_array::sub_array< T1, 1 > array_operation( boost::detail::multi_array::sub_array< T1, 1 > a,  boost::multi_array_ref< T2, 1 > &b, boost::multi_array_ref< T3, 1 > &c, F op )
{
  typename boost::multi_array_ref< T2, 1 >::const_iterator j = b.begin();
  typename boost::multi_array_ref< T3, 1 >::const_iterator k = c.begin();
  for ( typename boost::detail::multi_array::sub_array< T1, 1 >::iterator i = a.begin();
        i != a.end(); i++, j++, k++ )
   op( *i, *j, *k );
  return a;
}


/**
Applies array operation F (+,-) on array
*/

template<
  typename T1, typename T2, typename T3, class F >
boost::multi_array< T1, 1 > &array_operation( boost::multi_array< T1, 1 > &a,  boost::multi_array_ref< T2, 1 > &b,  boost::multi_array_ref< T3, 1 > &c, F op )
{
 typename boost::multi_array_ref< T2, 1 >::const_iterator j = b.begin();
 typename boost::multi_array_ref< T3, 1 >::const_iterator k = c.begin();
  for ( typename boost::multi_array< T1, 1 >::iterator i = a.begin();
        i != a.end(); i++, j++, k++ )
    op( *i, *j, *k );
  return a;
}

/**
Applies array operation F (+,-) on subarray
*/

template<
  typename T1, typename T2, typename T3, size_t dims, class F >
boost::detail::multi_array::sub_array< T1, dims > array_operation( boost::detail::multi_array::sub_array< T1, dims > a, boost::multi_array_ref< T2, dims > &b, boost::multi_array_ref< T3, dims > &c,  F op )
{
  typename boost::multi_array_ref< T2, dims >::const_iterator j = b.begin();
  typename boost::multi_array_ref< T3, dims >::const_iterator k = c.begin();
  for ( typename boost::detail::multi_array::sub_array< T1, dims >::iterator i = a.begin();
        i != a.end(); i++, j++, k++ )    array_operation( *i, *j, *k, op );
  return a;
}
/**
Applies array operation F (+,-) on array
*/

template<
  typename T1, typename T2, typename T3, size_t dims, class F >
boost::multi_array< T1, dims > &array_operation( boost::multi_array< T1, dims > &a,  boost::multi_array_ref< T2, dims > b,  boost::multi_array_ref< T3, dims > c, F op )
{
  typename boost::multi_array_ref< T2, dims >::const_iterator j = b.begin();
  typename boost::multi_array_ref< T3, dims >::const_iterator k = c.begin();
  for (typename boost::multi_array< T1, dims >::iterator i = a.begin();
        i != a.end(); i++, j++, k++ )
    array_operation( *i, *j, *k, op );
  return a;
}



/**
Copies a array
*/
template<
  typename T1, typename T2, size_t dims,
  template< typename, size_t > class MultiArray
>
boost::multi_array< T1, dims > empty_clone
( MultiArray< T2, dims > x )
{
  boost::array< size_t, dims > shape;
  std::copy( x.shape(), x.shape() + dims, shape.begin() );
  boost::multi_array< T1, dims > retVal( shape );
  return retVal;
}


/**
fills a array with an value val
*/
template < typename T, size_t NumDims >
void
 fill_array (boost::multi_array_ref< T, NumDims > x, T val )
{

 // std::fill( x.shape(), x.shape() + NumDims, val );
   std::fill( x.data(), x.data() + x.num_elements(), val);
}
template < typename T, size_t NumDims >
void assign_array(boost::multi_array<T, NumDims> &A,boost::multi_array_ref<T, NumDims> B) {
    std::vector<size_t> ex;
    const size_t* shape = B.shape();
    ex.assign( shape, shape+B.num_dimensions() );
    A.resize( ex );
    A.reindex(1);
    A = B;
}



/**
finds min/max elements of an array
template < typename T, size_t NumDims >
std::pair <T,T>
min_max (boost::multi_array_ref< T, NumDims > x, T val )
{

  boost::minmax_element(x.data(), x.data() + x.num_elements());

}
*/


/**
finds min/max elements of an array */
template < typename T, size_t NumDims >
std::pair <T,T>
min_max (boost::multi_array_ref< int, 1 > x)
{

  boost::minmax_element(x.data(), x.data() + x.num_elements());

}






template <class LAYOUT, class T>
ublas::matrix<const T, LAYOUT, ublas::shallow_array_adaptor<T> >
toMatrix(const size_t size1, const size_t size2,  T * data)
{
    typedef ublas::shallow_array_adaptor<T> a_t;
    typedef ublas::matrix<const T, LAYOUT, a_t>      m_t;
    return m_t(size1, size2, a_t(size1*size2, data));
}
// default layout: row_major
template <class T>
ublas::matrix<const T, ublas::row_major, ublas::shallow_array_adaptor<T> >
toMatrix(const size_t size1, const size_t size2,  T * data)
{
    return toMatrix<ublas::row_major>(size1,size2, data);
}


template <class T>
ublas::vector<T,ublas::shallow_array_adaptor<T> >
toVector(const size_t size, T * data)
{
    ublas::vector<T,ublas::shallow_array_adaptor<T> >
    v(size,ublas::shallow_array_adaptor<T>(size,data));
    return v;
}
