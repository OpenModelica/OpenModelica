//
// Copyright (c) 2003 Kresimir Fresl
// Copyright (c) 2010 Thomas Klimpel
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_COMPLEX_UTILS_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_COMPLEX_UTILS_HPP

#include <iterator>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/is_complex.hpp>
#include <Core/Utils/numeric/bindings/remove_imaginary.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <Core/Utils/numeric/bindings/vector_view.hpp>
#include <boost/utility/enable_if.hpp>

namespace boost {
namespace numeric {
namespace bindings {

namespace detail {

#ifdef BOOST_NUMERIC_BINDINGS_BY_THE_BOOK
template <typename It>
void inshuffle(It it, std::size_t n) {
  if (n==0) return;
  for (std::size_t i = 0; 2*i < n; ++i) {
    std::size_t k = 2*i + 1;
    while (2*k <= n) k *= 2;
    typename std::iterator_traits<It>::value_type tmp = it[n+i];
    it[n+i] = it[k-1];
    while (k % 2 == 0) {
      it[k-1] = it[(k/2)-1];
      k /= 2;
    }
    it[k-1] = tmp;
  }
  std::size_t kmin = 1;
  while (2*kmin <= n) kmin *= 2;
  for (std::size_t i = 0; 4*i+1 < n; ++i) {
    std::size_t k = 2*i + 1;
    while (2*k <= n) k *= 2;
    std::size_t k1 = 2*(i+1) + 1;
    while (2*k1 <= n) k1 *= 2;
    if (k > k1) {
      if (k1 < kmin) {
        kmin = k1;
        inshuffle(it+n, i+1);
      }
      else
        inshuffle(it+n+1, i);
    }
  }
  return inshuffle(it+n+(n%2), n/2);
}
#else
template <typename It>
void inshuffle(It it, std::size_t n) {
  while (n > 0) {
    std::size_t kmin = 1;
    while (kmin <= n)
      kmin *= 2;
    {
      std::size_t kk = kmin/2;
      It itn = it + n;
      for (std::size_t i = 0, s = (n+1)/2; i < s; ++i) {
        std::size_t k = (2*i+1)*kk;
        while (k > n) {
          k /= 2;
          kk /= 2;
        }
        // apply the cyclic permutation
        typename std::iterator_traits<It>::value_type tmp = itn[i];
        itn[i] = it[k-1];
        while (k % 2 == 0) {
          it[k-1] = it[(k/2)-1];
          k /= 2;
        }
        it[k-1] = tmp;
      }
    }
    // the optimized computation of k fails for n=2,
    // so skip the 'normalization' loop when possible
    if (n > 3) {
      std::size_t kk = kmin/4;
      for (std::size_t i = 1; 4*i < n+3; ++i) {
        std::size_t k = (2*i+1)*kk;
        if (k > n) {
          kk /= 2;
          if (k < kmin) {
            kmin = k;
            // if kmin is updated, do an in-shuffle
            inshuffle(it+n, i);
          }
          else
            // otherwise do an out-shuffle
            inshuffle(it+n+1, i-1);
        }
      }
    }
    // implement the tail recursion as an iteration
    it += n+(n%2);
    n /= 2;
  }
}
#endif

// Reorders a real array followed by an imaginary array to a true complex array
// where real and imaginary part of each number directly follow each other.
template <typename VectorW>
typename boost::enable_if< is_complex< typename bindings::value_type< VectorW >::type >, void >::type
interlace (VectorW& w) {
  typedef typename bindings::value_type< VectorW >::type value_type;
  typedef typename bindings::remove_imaginary< value_type >::type real_type;
  value_type* pw = bindings::begin_value(w);
  std::ptrdiff_t n = bindings::end_value(w) - pw;
  if (n < 2) return;
  inshuffle(reinterpret_cast<real_type*> (pw)+1, n-1);
}

} // namespace detail

namespace result_of {

template< typename VectorW >
struct real_part_view {
    typedef typename bindings::result_of::vector_view< typename
      bindings::remove_imaginary< typename
      bindings::value_type< VectorW >::type
      >::type >::type type;
};

template< typename VectorW >
struct imag_part_view {
    typedef typename bindings::result_of::vector_view< typename
      bindings::remove_imaginary< typename
      bindings::value_type< VectorW >::type
      >::type >::type type;
};

} // namespace result_of

namespace detail {

// Creates a real vector_view to the first half of the complex array,
// which is intended to be filled by the real part
template <typename VectorW>
typename boost::enable_if< is_complex< typename bindings::value_type< VectorW >::type >,
        typename result_of::real_part_view< VectorW >::type const >::type
real_part_view (VectorW& w) {
  typedef typename bindings::value_type< VectorW >::type value_type;
  typedef typename bindings::remove_imaginary< value_type >::type real_type;
  value_type* pw = bindings::begin_value(w);
  std::ptrdiff_t n = bindings::end_value(w) - pw;
  return bindings::vector_view(reinterpret_cast<real_type*> (pw), n);
}

// Creates a real vector_view to the second half of the complex array,
// which is intended to be filled by the imaginary part
template <typename VectorW>
typename boost::enable_if< is_complex< typename bindings::value_type< VectorW >::type >,
        typename result_of::imag_part_view< VectorW >::type const >::type
imag_part_view (VectorW& w) {
  typedef typename bindings::value_type< VectorW >::type value_type;
  typedef typename bindings::remove_imaginary< value_type >::type real_type;
  value_type* pw = bindings::begin_value(w);
  std::ptrdiff_t n = bindings::end_value(w) - pw;
  return bindings::vector_view(reinterpret_cast<real_type*> (pw)+n, n);
}

} // namespace detail

} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
