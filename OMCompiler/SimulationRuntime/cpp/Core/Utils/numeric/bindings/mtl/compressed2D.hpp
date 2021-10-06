//
// Copyright (c) 2009--2010
// Thomas Klimpel and Rutger ter Borg
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_MTL_COMPRESSED2D_HPP
#define BOOST_NUMERIC_BINDINGS_MTL_COMPRESSED2D_HPP

#include <Core/Utils/numeric/bindings/detail/adaptor.hpp>
#include <Core/Utils/numeric/bindings/detail/copy_const.hpp>
#include <Core/Utils/numeric/bindings/mtl/detail/convert_to.hpp>
#include <boost/numeric/mtl/matrix/compressed2D.hpp>

namespace boost {
namespace numeric {
namespace bindings {
namespace detail {

template< typename T, typename Parameters, typename Id, typename Enable >
struct adaptor< mtl::compressed2D< T, Parameters >, Id, Enable > {

    typedef typename copy_const< Id, T >::type value_type;
    typedef typename copy_const<
        Id,
        //typename Id::index_type
        //typename Id::size_type // (Seems to be the actually used index_type)
        std::ptrdiff_t // (Seems to be an actual usable type for bindings purposes)
    >::type index_type;
    typedef typename convert_to<
        tag::data_order,
        typename Parameters::orientation
    >::type data_order;
    typedef mpl::map<
        mpl::pair< tag::value_type, value_type >,
        mpl::pair< tag::index_type, index_type >,
        mpl::pair< tag::entity, tag::matrix >,
        mpl::pair< tag::size_type<1>, std::ptrdiff_t >,
        mpl::pair< tag::size_type<2>, std::ptrdiff_t >,
        mpl::pair< tag::matrix_type, tag::general >,
        mpl::pair< tag::data_structure, tag::compressed_sparse >,
        mpl::pair< tag::data_order, data_order >,
        mpl::pair< tag::index_base, mpl::int_<0> >
    > property_map;

    static std::ptrdiff_t size1( const Id& id ) {
        return id.num_rows();
    }

    static std::ptrdiff_t size2( const Id& id ) {
        return id.num_cols();
    }

    static value_type* begin_value( Id& id ) {
        return id.address_data();
    }

    static value_type* end_value( Id& id ) {
        return id.address_data() + id.nnz();
    }

    static index_type* begin_compressed_index_major( Id& id ) {
        return reinterpret_cast<index_type*>(id.address_major());
    }

    static index_type* end_compressed_index_major( Id& id ) {
        return reinterpret_cast<index_type*>(id.address_major() + id.dim1() + 1);
    }

    static index_type* begin_index_minor( Id& id ) {
        return reinterpret_cast<index_type*>(id.address_minor());
    }

    static index_type* end_index_minor( Id& id ) {
        return reinterpret_cast<index_type*>(id.address_minor() + id.nnz());
    }

};

} // namespace detail
} // namespace bindings
} // namespace numeric
} // namespace boost

#endif
