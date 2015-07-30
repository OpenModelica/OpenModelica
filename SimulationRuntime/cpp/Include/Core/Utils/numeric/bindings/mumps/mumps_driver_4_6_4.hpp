//
// Copyright Karl Meerbergen 2007
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE_1_0.txt or copy at
// http://www.boost.org/LICENSE_1_0.txt)
//

#ifndef BOOST_NUMERIC_BINDINGS_MUMPS_MUMPS_DRIVER_4_6_4_HPP
#define BOOST_NUMERIC_BINDINGS_MUMPS_MUMPS_DRIVER_4_6_4_HPP

#include <Core/Utils/numeric/bindings/mumps/4.6.4/smumps_c.hpp>
#include <Core/Utils/numeric/bindings/mumps/4.6.4/cmumps_c.hpp>
#include <Core/Utils/numeric/bindings/mumps/4.6.4/dmumps_c.hpp>
#include <Core/Utils/numeric/bindings/mumps/4.6.4/zmumps_c.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/data_order.hpp>
#include <Core/Utils/numeric/bindings/index_base.hpp>
#include <boost/static_assert.hpp>
#include <complex>
#include <cassert>

//
// This file contains a C++ driver for MUMPS
//
// The templated class mumps<M> is a wrapper for the corresponding C struct.
// The class contains constructor and destructor that call mumps with JOB=-1 and JOB=-2
// respectively.
//
// The function driver() calls MUMPS. The user must set the parameters of the data manually.
//
// The following functions are very helpful in this respect, since they extract pointer and size
// data using the Boost Bindings.
//
// void matrix_integer_data() : to set the integer data of the matrix.
// void matrix_value_data() : to set the values of the matrix.
// void rhs_sol_value_data() : to set the right-hand side and solution vectors in the case of a dense solution vector.
//

namespace boost { namespace numeric { namespace bindings { namespace mumps {

  namespace detail {
    //
    // Type and Driver
    //
    template <class T>
    struct mumps_type {
    } ;

    template <class T>
    struct mumps_call {
    } ;

    template <class T>
    struct mumps_internal_value_type {
      typedef T type ;
    } ;

    //
    // Specialization for float
    //

    template <>
    struct mumps_type< float > {
      typedef SMUMPS_STRUC_C type ;
    } ;

    template <>
    struct mumps_call< float > {
      void operator() ( SMUMPS_STRUC_C& struc ) const {
        smumps_c( &struc ) ;
      }
    } ;

    //
    // Specialization for double
    //

    template <>
    struct mumps_type< double > {
      typedef DMUMPS_STRUC_C type ;
    } ;

    template <>
    struct mumps_call< double > {
      void operator() ( DMUMPS_STRUC_C& struc ) const {
        dmumps_c( &struc ) ;
      }
    } ;

    //
    // Specialization for complex<float>
    //

    template <>
    struct mumps_type< std::complex< float > > {
      typedef CMUMPS_STRUC_C type ;
    } ;

    template <>
    struct mumps_call< std::complex< float > > {
      void operator() ( CMUMPS_STRUC_C& struc ) const {
        cmumps_c( &struc ) ;
      }
    } ;

    template <>
    struct mumps_internal_value_type< std::complex<float> > {
      typedef mumps_complex type ;
    } ;

    //
    // Specialization for complex<double>
    //

    template <>
    struct mumps_type< std::complex< double > > {
      typedef ZMUMPS_STRUC_C type ;
    } ;

    template <>
    struct mumps_call< std::complex< double > > {
      void operator() ( ZMUMPS_STRUC_C& struc ) const {
        zmumps_c( &struc ) ;
      }
    } ;

    template <>
    struct mumps_internal_value_type< std::complex<double> > {
      typedef mumps_double_complex type ;
    } ;

    //
    // Symmetry map
    //

    template <class T>
    struct mumps_sym {
    } ;

    template <>
    struct mumps_sym< bindings::tag::symmetric > {
      static int const value = 2 ;
    } ;

    template <>
    struct mumps_sym< bindings::tag::general > {
      static int const value = 0 ;
    } ;

    //
    // Get index pointers
    //
    template <typename M>
    void indices( bindings::tag::row_major, int*& rows, int*& cols, M const& m ) {
      rows = const_cast<int*>( bindings::begin_index_major( m ) ) ;
      cols = const_cast<int*>( bindings::begin_index_minor( m ) ) ;
    }

    template <typename M>
    void indices( bindings::tag::column_major, int*& rows, int*& cols, M const& m ) {
      cols = const_cast<int*>( bindings::begin_index_major( m ) ) ;
      rows = const_cast<int*>( bindings::begin_index_minor( m ) ) ;
    }

    // Pointer Cast
    float* cast_2_mumps( float* p ) { return p ; }
    double* cast_2_mumps( double* p ) { return p ; }
    mumps_double_complex* cast_2_mumps( std::complex<double>* p ) { return reinterpret_cast<mumps_double_complex*>( p ) ; }
    mumps_complex* cast_2_mumps( std::complex<float>* p ) { return reinterpret_cast<mumps_complex*>( p ) ; }
  } // namespace detail



  //
  // Generic MUMPS data for any value_type
  //
  template <typename M>
  struct mumps
  : detail::mumps_type< typename bindings::value_type<M>::type >::type
  {
    typedef typename bindings::value_type<M>::type                                      value_type ;
    typedef typename detail::mumps_type< typename bindings::value_type<M>::type >::type c_struct_type ;

    //
    // Initialize MUMPS solver
    // Pass a communicator (comm=-987654 means choose default)
    // Pass 'par': default = 1: host is involved in factorization
    //
    mumps( int comm_fortran=-987654, int par=1 )
    {
      this->job = -1 ;
      this->par = par ;
      this->comm_fortran = comm_fortran ;
      this->sym = detail::mumps_sym< typename bindings::detail::property_at<M, tag::matrix_type >::type >::value ;
      detail::mumps_call<value_type>() ( *this ) ;
    }

    // Destroy the solver
    ~mumps() {
      this->job = -2 ;
      detail::mumps_call<value_type>() ( *this ) ;
    }
  } ;


  //
  // Copy the matrix integer data (matrix order, structure) to the MUMPS struct
  //
  template <typename M>
  void matrix_integer_data( mumps<M>& data, M& m ) {
    typedef typename bindings::result_of::index_base<M>::type index_b ;
    BOOST_STATIC_ASSERT(index_b::value == 1) ;
    data.n = bindings::size_row( m ) ;
    assert( bindings::size_column( m ) == data.n ) ;

    data.nz = bindings::end_value( m ) - bindings::begin_value( m ) ;
    detail::indices( bindings::data_order(m), data.irn, data.jcn, m ) ;

    data.nz_loc = bindings::end_value( m ) - bindings::begin_value( m ) ;
    detail::indices( bindings::data_order(m), data.irn_loc, data.jcn_loc, m ) ;
  } // matrix_integer_data()


  //
  // Copy the values pointer to the MUMPS struct
  //
  template <typename M>
  void matrix_value_data( mumps<M>& data, M& m ) {
    data.a = detail::cast_2_mumps( bindings::begin_value( m ) ) ;
    data.a_loc = detail::cast_2_mumps( bindings::begin_value( m ) ) ;
  } // matrix_value_data()


  //
  // Copy the right-hand side / solution pointer to the MUMPS struct
  // in case of a dense undistributed right-hand side and solution.
  //
  template <typename M, typename X>
  void rhs_sol_value_data( mumps<M>& data, X& x ) {
    data.rhs = detail::cast_2_mumps( bindings::begin_value( x ) ) ;
    data.nrhs = bindings::size_column( x ) ;
    data.lrhs = bindings::stride_major( x ) ;
  } // matrix_rhs_sol_value_data()


  //
  // Call the MUMPS driver for the given MUMPS struct.
  //
  template <typename M>
  int driver( mumps<M>& data ) {
    assert( data.job>=1 ? data.irn!=0 : true ) ;
    assert( data.job>=1 ? data.jcn!=0 : true ) ;
    assert( data.job>=2 ? data.a!=0 : true ) ;
    assert( data.job>=3 ? data.rhs!=0 : true ) ;
    detail::mumps_call<typename M::value_type>() ( static_cast<typename mumps<M>::c_struct_type&>( data ) ) ;
    return data.info[0] ;
  } // driver()

} } } } // namespace boost::numeric::bindings::mumps

#endif
