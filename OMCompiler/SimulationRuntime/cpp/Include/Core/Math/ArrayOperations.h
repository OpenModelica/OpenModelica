#pragma once
/** @addtogroup math
 *  @{
 */


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
Concatenates n real arrays along the k:th dimension.
*/
template <typename T>
void cat_array(int k, const vector<const BaseArray<T>*>& x, BaseArray<T>& a);

template <typename T>
void transpose_array(const BaseArray<T>& x, BaseArray<T>& a);

void BOOST_EXTENSION_EXPORT_DECL identity_alloc(size_t n, DynArrayDim2<int>& I);

template <typename T>
void diagonal_alloc(const BaseArray<T>& v, BaseArray<T>& D);

template <typename T>
void promote_array(size_t n, const BaseArray<T>& s, BaseArray<T>& d);

template <typename T>
void multiply_array(const BaseArray<T>& inputArray, const T &b, BaseArray<T>& outputArray);

template <typename T>
void multiply_array(const BaseArray<T> &leftArray, const BaseArray<T> &rightArray, BaseArray<T> &resultArray);

template <typename T>
void multiply_array_elem_wise(const BaseArray<T> &leftArray, const BaseArray<T> &rightArray, BaseArray<T> &resultArray);

template <typename T>
void divide_array(const BaseArray<T>& inputArray, const T &b, BaseArray<T>& outputArray);

template <typename T>
void divide_array(const T &b, const BaseArray<T>& inputArray, BaseArray<T>& outputArray);

template <typename T>
void divide_array_elem_wise(const BaseArray<T> &leftArray, const BaseArray<T> &rightArray, BaseArray<T> &resultArray);

template <typename T>
void fill_array(BaseArray<T>& inputArray, T b);

/**
 * Element wise exponentiation
 */
template <typename T>
void pow_array_scalar(const BaseArray<double> &inputArray, T exponent, BaseArray<double> &outputArray);

template <typename T>
void subtract_array(const BaseArray<T>& leftArray, const BaseArray<T>& rightArray, BaseArray<T>& resultArray);

template <typename T>
void subtract_array_scalar(const BaseArray<T>& inputArray, T b, BaseArray<T>& outputArray);

template <typename T>
void add_array(const BaseArray<T>& leftArray, const BaseArray<T>& rightArray, BaseArray<T>& resultArray);

template <typename T>
void add_array_scalar(const BaseArray<T>& inputArray, T b, BaseArray<T>& outputArray);

template <typename T>
void usub_array(const BaseArray<T>& a , BaseArray<T>& b);

template < typename T >
T sum_array(const BaseArray<T>& x);

template < typename T >
T product_array(const BaseArray<T>& x);

/**
finds min/max elements of an array */
template <typename T>
std::pair<T, T> min_max(const BaseArray<T>& x);

/**
scalar product of two arrays (a,b type as template parameter)
*/
template <typename T>
T dot_array(const BaseArray<T> & a, const BaseArray<T>& b);

/**
cross product of two arrays (a,b type as template parameter)
*/
template <typename T>
void cross_array(const BaseArray<T>& a, const BaseArray<T>& b, BaseArray<T>& res);

/**
cast type of array elements
*/
template <typename S, typename T>
void cast_array(const BaseArray<S> &a, BaseArray<T> &b);

/**
 * Permutes dims between row and column major storage layout,
 * including optional type conversion if supported in assignment from S to T
 */
template <typename S, typename T>
void convertArrayLayout(const BaseArray<S> &s, BaseArray<T> &d);

/**
 * Assign data with row major order to BaseArray with arbitrary storage layout
 */
template <typename T>
void assignRowMajorData(const T *data, BaseArray<T>& array);
/** @} */ // end of math
