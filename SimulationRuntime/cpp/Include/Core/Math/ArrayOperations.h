#pragma once
//#define BOOST_ENABLE_ASSERT_HANDLER

/*****************************************************************************/
/**

Auxillary Array operations for OpenModelica.


\date     September, 1st, 2010
\author

*/
/*****************************************************************************
Copyright (c) 2010, OSMC
*****************************************************************************/

/*index type for multi array, first shape, second indeces*/
typedef std::vector<std::vector<size_t> > idx_type;
typedef std::pair<vector<size_t>,idx_type >  spec_type;


size_t getNextIndex(vector<size_t> idx,size_t k);


/**
Concatenates n real arrays along the k:th dimension.
*/
template < typename T >
void cat_array (int k,BaseArray<T>& a, vector<BaseArray<T>* >& x );


template < typename T >
void transpose_array (BaseArray< T >& a, BaseArray< T >&  x );

/*
creates an array (d) for passed multi array  shape (sp) and initialized it with elements from passed source array (s)
s source array
d destination array
sp (shape,indices) of source array
*/

template < typename T >
void create_array_from_shape(const spec_type& sp,BaseArray<T>& s,BaseArray<T>& d);



template < typename T >
void promote_array(unsigned int n,BaseArray<T>& s,BaseArray<T>& d);



template < typename T>
void multiply_array( BaseArray<T> & inputArray ,const T &b, BaseArray<T> & outputArray  );


template < typename T>
void divide_array( BaseArray<T> & inputArray ,const T &b, BaseArray<T> & outputArray  );


template < typename T >
void fill_array( BaseArray<T> & inputArray , T b);

template < typename T >
void subtract_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  );

template < typename T >
void add_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  );

template < typename T >
void usub_array(BaseArray<T> & a , BaseArray<T> & b);

template < typename T >
T sum_array ( BaseArray<T> & leftArray );


/**
finds min/max elements of an array */
template < typename T >
std::pair <T,T>
min_max (BaseArray<T>& x);



/**
scalar product of two arrays (a,b type as template parameter)
*/
template < typename T >
T dot_array( BaseArray<T> & a , BaseArray<T> & b  );
/**
cross product of two arrays (a,b type as template parameter)
*/
template < typename T >
void cross_array( BaseArray<T> & a ,BaseArray<T> & b, BaseArray<T> & res );
