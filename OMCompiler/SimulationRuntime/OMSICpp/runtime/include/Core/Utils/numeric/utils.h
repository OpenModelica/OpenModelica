
#ifndef F_UTILS_H
#define F_UTILS_H

#include <stddef.h>
#include <iostream>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>


///////////////////////////////
// vectors

// element access:
template <typename V>
struct vct_access_traits {
  typedef typename
  boost::numeric::bindings::value_type<V>::type val_t;
  typedef val_t& ref_t;
  static ref_t elem (V& v, size_t i) { return v[i]; }
};

template <typename V>
struct vct_access_traits<V const> {
  typedef typename
  boost::numeric::bindings::value_type<V>::type val_t;
  typedef val_t ref_t;
  static ref_t elem (V const& v, size_t i) { return v[i]; }
};

template <typename V>
inline
typename vct_access_traits<V>::ref_t elem_v (V& v, size_t i) {
  return vct_access_traits<V>::elem (v, i);
}

// initialization:
struct ident {
  size_t operator() (size_t i) const { return i; }
};
struct iplus1 {
  size_t operator() (size_t i) const { return i + 1; }
};
template <typename T>
struct const_val {
  T val;
  const_val (T v = T()) : val (v) {}
  T operator() (size_t) const { return val; }
  T operator() (size_t, size_t) const { return val; }
};
struct kpp {
  size_t val;
  kpp (size_t v = 0) : val (v) {}
  size_t operator() (size_t) {
    size_t tmp = val;
    ++val;
    return tmp;
  }
  size_t operator() (size_t, size_t) {
    size_t tmp = val;
    ++val;
    return tmp;
  }
};
template <typename T>
struct times_plus {
  T s, a, b;
  times_plus (T ss, T aa = T(), T bb = T()) : s (ss), a (aa), b (bb) {}
  T operator() (size_t i) const {
    return s * (T) i + a;
  }
  T operator() (size_t i, size_t j) const {
    return s * ((T) i + a) + (T) j + b;
  }
};

template <typename F, typename V>
void init_v (V& v, F f = F()) {
  size_t sz
    = boost::numeric::bindings::size( v );
  for (std::size_t i = 0; i < sz; ++i)
    elem_v (v, i) = f (i);
}

// printing:
template <typename V>
void print_v (V const& v, char const* ch = 0) {
  if (ch)
    std::cout << ch << ": ";
  size_t sz
    = boost::numeric::bindings::size( v );
  for (std::size_t i = 0; i < sz; ++i)
    std::cout << elem_v (v, i) << " ";
  std::cout << std::endl;
}


/////////////////////////////////////
// matrices

// element access:
template <typename M>
struct matr_access_traits {
  typedef M mat_t;
  typedef typename boost::numeric::bindings::value_type<mat_t>::type val_t;
  typedef typename mat_t::reference ref_t;
  static ref_t elem (mat_t& m, size_t i, size_t j) { return m (i, j); }
};

#ifdef EIGEN_FORWARDDECLARATIONS_H
template<typename _Scalar, int _Rows, int _Cols, int _Options, int _MaxRows, int _MaxCols>
struct matr_access_traits<Eigen::Matrix<_Scalar, _Rows, _Cols, _Options, _MaxRows, _MaxCols> > {
  typedef Eigen::Matrix<_Scalar, _Rows, _Cols, _Options, _MaxRows, _MaxCols> mat_t;
  typedef typename boost::numeric::bindings::value_type<mat_t>::type val_t;
  typedef val_t& ref_t;
  static ref_t elem (mat_t& m, size_t i, size_t j) { return m (i, j); }
};
#endif

template <typename M>
struct matr_access_traits<M const> {
  typedef M const mat_t;
  typedef typename boost::numeric::bindings::value_type<mat_t>::type val_t;
  typedef val_t ref_t;
  static ref_t elem (mat_t& m, size_t i, size_t j) { return m (i, j); }
};

template <typename M>
inline
typename matr_access_traits<M>::ref_t elem_m (M& m, size_t i, size_t j) {
  return matr_access_traits<M>::elem (m, i, j);
}

// initialization:
struct rws {
  size_t operator() (size_t i, size_t) const { return i; }
};
struct rws1 {
  size_t operator() (size_t i, size_t) const { return i + 1; }
};
struct cls {
  size_t operator() (size_t, size_t j) const { return j; }
};
struct cls1 {
  size_t operator() (size_t, size_t j) const { return j + 1; }
};

template <typename F, typename M>
void init_m (M& m, F f = F()) {
  size_t sz1
    = boost::numeric::bindings::size_row( m );
  size_t sz2
    = boost::numeric::bindings::size_column( m );
  for (std::size_t i = 0; i < sz1; ++i)
    for (std::size_t j = 0; j < sz2; ++j)
      elem_m (m, i, j) = f (i, j);
}

template <typename M>
void init_symm (M& m, char uplo = 'f') {
  size_t n
    = boost::numeric::bindings::size_row( m );
  for (size_t i = 0; i < n; ++i) {
    elem_m (m, i, i) = n;
    for (size_t j = i + 1; j < n; ++j) {
      if (uplo == 'u' || uplo == 'U')
        elem_m (m, i, j) = n - (j - i);
      else if (uplo == 'l' || uplo == 'L')
        elem_m (m, j, i) = n - (j - i);
      else
        elem_m (m, i, j) = elem_m (m, j, i) = n - (j - i);
    }
  }
}

// printing:
template <typename M>
void print_m (M const& m, char const* ch = 0) {
  if (ch)
    std::cout << ch << ":\n";
  size_t sz1
    = boost::numeric::bindings::size_row( m );
  size_t sz2
    = boost::numeric::bindings::size_column( m );
  for (std::size_t i = 0 ; i < sz1 ; ++i) {
    for (std::size_t j = 0 ; j < sz2 ; ++j)
      std::cout << elem_m (m, i, j) << " ";
    std::cout << std::endl;
  }
  //  std::cout << std::endl;
}

template <typename M>
void print_m_data (M const& m, char const* ch = 0) {
  if (ch)
    std::cout << ch << " data:\n";
  using namespace boost::numeric::bindings;
  std::copy( begin_value( m ), end_value( m ), std::ostream_iterator
        < typename value_type< const M >::type >( std::cout, " " ) );
  std::cout << std::endl;
}

#endif
