//
// Copyright (c) 2003 Kresimir Fresl
// Copyright (c) 2009 Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_DETAIL_ARRAY_HPP
#define BOOST_NUMERIC_BINDINGS_DETAIL_ARRAY_HPP

#include <new>
#include <boost/noncopyable.hpp>
#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>


/*
 very simple dynamic array class which is used in `higher level'
 bindings functions for pivot and work arrays

 Namely, there are (at least) two versions of all bindings functions
 where called LAPACK function expects work and/or pivot array, e.g.

      `lower' level (user should provide work and pivot arrays):
           int sysv (SymmA& a, IVec& i, MatrB& b, Work& w);

      `higher' level (with `internal' work and pivot arrays):
           int sysv (SymmA& a, MatrB& b);

 Probably you ask why I didn't use std::vector. There are two reasons.
 First is efficiency -- std::vector's constructor initialises vector
 elements. Second is consistency. LAPACK functions use `info' parameter
 as an error indicator. On the other hand, std::vector's allocator can
 throw an exception if memory allocation fails. detail::array's
 constructor uses `new (nothrow)' which returns 0 if allocation fails.
 So I can check whether array::storage == 0 and return appropriate error
 in `info'.*/

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template <typename T>
class array : private noncopyable {
public:
    typedef std::ptrdiff_t size_type ;

    array (size_type n) {
        stg = new (std::nothrow) T[n];
        sz = (stg != 0) ? n : 0;
    }

    ~array() {
        delete[] stg;
    }

    size_type size() const {
        return sz;
    }

    bool valid() const {
        return stg != 0;
    }

    void resize (int n) {
        delete[] stg;
        stg = new (std::nothrow) T[n];
        sz = (stg != 0) ? n : 0;
    }

    T* storage() {
        return stg;
    }

    T const* storage() const {
        return stg;
    }

    T& operator[] (int i) {
        return stg[i];
    }

    T const& operator[] (int i) const {
        return stg[i];
    }

private:
    size_type sz;
    T*        stg;
};


template< typename T, typename Id, typename Enable >
struct adaptor< array< T >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::entity, tag::vector >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::data_structure, tag::linear_array >,
        mpl::pair< tag::stride_type<1>, tag::contiguous >
    > property_map;

    static std::ptrdiff_t size1( const Id& t ) {
        return t.size();
    }

    static value_type* begin_value( Id& t ) {
        return t.storage();
    }

    static value_type* end_value( Id& t ) {
        return t.storage() + t.size();
    }

};


} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
