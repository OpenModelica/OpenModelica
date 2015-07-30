/*
 *
 * Copyright (c) Kresimir Fresl 2003
 *
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * Author acknowledges the support of the Faculty of Civil Engineering,
 * University of Zagreb, Croatia.
 *
 */

/* for UMFPACK Copyright, License and Availability see umfpack_inc.hpp */


#ifndef BOOST_NUMERIC_BINDINGS_UMFPACK_HPP
#define BOOST_NUMERIC_BINDINGS_UMFPACK_HPP


#include <boost/noncopyable.hpp>
#include <Core/Utils/numeric/bindings/umfpack/umfpack_overloads.hpp>
#include <Core/Utils/numeric/bindings/value_type.hpp>
#include <Core/Utils/numeric/bindings/begin.hpp>
#include <Core/Utils/numeric/bindings/end.hpp>
#include <Core/Utils/numeric/bindings/size.hpp>
#include <Core/Utils/numeric/bindings/data_order.hpp>
#include <Core/Utils/numeric/bindings/index_base.hpp>


namespace boost { namespace numeric { namespace bindings {  namespace umfpack {

  template <typename MatrA>
  void check_umfpack_structure()
  {
    BOOST_STATIC_ASSERT((boost::is_same<
      typename bindings::detail::property_at< MatrA, tag::matrix_type >::type,
      tag::general
    >::value));
    BOOST_STATIC_ASSERT((boost::is_same<
      typename bindings::result_of::data_order<MatrA>::type,
      tag::column_major
    >::value));
    typedef typename bindings::result_of::index_base<MatrA>::type index_b;
    BOOST_STATIC_ASSERT(index_b::value == 0);
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;
    BOOST_STATIC_ASSERT(
      (boost::is_same<storage_f, tag::compressed_sparse>::value ||
       boost::is_same<storage_f, tag::coordinate_sparse>::value ));
  }

  template <typename T = double>
  struct symbolic_type : private noncopyable {
    void *ptr;
    symbolic_type():ptr(0){}
    ~symbolic_type() {
      if (ptr)
        detail::free_symbolic (T(), 0, &ptr);
    }
    void free() {
      if (ptr)
        detail::free_symbolic (T(), 0, &ptr);
      ptr = 0;
    }
  };

  template <typename T>
  void free (symbolic_type<T>& s) { s.free(); }

  template <typename T = double>
  struct numeric_type : private noncopyable {
    void *ptr;
    numeric_type():ptr(0){}
    ~numeric_type() {
      if (ptr)
        detail::free_numeric (T(), 0, &ptr);
    }
    void free() {
      if (ptr)
        detail::free_numeric (T(), 0, &ptr);
      ptr = 0;
    }
  };

  template <typename T>
  void free (numeric_type<T>& n) { n.free(); }


  template <typename T = double>
  struct control_type : private noncopyable {
    double ptr[UMFPACK_CONTROL];
    control_type() { detail::defaults (T(), 0, ptr); }
    double operator[] (int i) const { return ptr[i]; }
    double& operator[] (int i) { return ptr[i]; }
    void defaults() { detail::defaults (T(), 0, ptr); }
  };

  template <typename T>
  void defaults (control_type<T>& c) { c.defaults(); }

  template <typename T = double>
  struct info_type : private noncopyable {
    double ptr[UMFPACK_INFO];
    double operator[] (int i) const { return ptr[i]; }
    double& operator[] (int i) { return ptr[i]; }
  };


  /////////////////////////////////////
  // solving system of linear equations
  /////////////////////////////////////


  // symbolic
  /*
   * Given nonzero pattern of a sparse matrix A in column-oriented form,
   * umfpack_*_symbolic performs a column pre-ordering to reduce fill-in
   * (using COLAMD or AMD) and a symbolic factorisation.  This is required
   * before the matrix can be numerically factorised with umfpack_*_numeric.
   */
  namespace detail {

    template <typename MatrA>
    inline
    int symbolic (tag::compressed_sparse,
                  MatrA const& A, void **Symbolic,
                  double const* Control = 0, double* Info = 0)
    {
      return detail::symbolic (bindings::size_row (A),
                               bindings::size_column (A),
                               bindings::begin_compressed_index_major (A),
                               bindings::begin_index_minor (A),
                               bindings::begin_value (A),
                               Symbolic, Control, Info);
    }

    template <typename MatrA, typename QVec>
    inline
    int symbolic (tag::compressed_sparse,
                  MatrA const& A, QVec const& Qinit, void **Symbolic,
                  double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
      return detail::qsymbolic (bindings::size_row (A),
                                bindings::size_column (A),
                                bindings::begin_compressed_index_major (A),
                                bindings::begin_index_minor (A),
                                bindings::begin_value (A),
                                bindings::begin_value (Qinit),
                                Symbolic, Control, Info);
    }

    template <typename MatrA>
    inline
    int symbolic (tag::coordinate_sparse,
                  MatrA const& A, void **Symbolic,
                  double const* Control = 0, double* Info = 0)
    {
      int n_row = bindings::size_row (A);
      int n_col = bindings::size_column (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n_col+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n_row, n_col, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      return detail::symbolic (n_row, n_col,
                               Ap.storage(), Ai.storage(),
                               bindings::begin_value (A),
                               Symbolic, Control, Info);
    }

    template <typename MatrA, typename QVec>
    inline
    int symbolic (tag::coordinate_sparse,
                  MatrA const& A, QVec const& Qinit, void **Symbolic,
                  double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
      int n_row = bindings::size_row (A);
      int n_col = bindings::size_column (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n_col+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n_row, n_col, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      return detail::qsymbolic (n_row, n_col,
                                Ap.storage(), Ai.storage(),
                                bindings::begin_value (A),
                                bindings::begin_value (Qinit),
                                Symbolic, Control, Info);
    }

  } // detail

  template <typename MatrA>
  inline
  int symbolic (MatrA const& A,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                double const* Control = 0, double* Info = 0)
  {
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    return detail::symbolic (storage_f(), A, &Symbolic.ptr, Control, Info);
  }

  template <typename MatrA>
  inline
  int symbolic (MatrA const& A,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                control_type<
                  typename bindings::value_type<MatrA>::type
                > const& Control,
                info_type<
                  typename bindings::value_type<MatrA>::type
                >& Info)
  {
    return symbolic (A, Symbolic, Control.ptr, Info.ptr);
  }

  template <typename MatrA>
  inline
  int symbolic (MatrA const& A,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                control_type<
                  typename bindings::value_type<MatrA>::type
                > const& Control)
  {
    return symbolic (A, Symbolic, Control.ptr);
  }

  template <typename MatrA, typename QVec>
  inline
  int symbolic (MatrA const& A, QVec const& Qinit,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                double const* Control = 0, double* Info = 0)
  {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    assert (bindings::size_column (A) == bindings::size (Qinit));

    return detail::symbolic (storage_f(), A, Qinit,
                             &Symbolic.ptr, Control, Info);
  }

  template <typename MatrA, typename QVec>
  inline
  int symbolic (MatrA const& A, QVec const& Qinit,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                control_type<
                  typename bindings::value_type<MatrA>::type
                > const& Control,
                info_type<
                  typename bindings::value_type<MatrA>::type
                >& Info)
  {
    return symbolic (A, Qinit, Symbolic, Control.ptr, Info.ptr);
  }

  template <typename MatrA, typename QVec>
  inline
  int symbolic (MatrA const& A, QVec const& Qinit,
                symbolic_type<
                  typename bindings::value_type<MatrA>::type
                >& Symbolic,
                control_type<
                  typename bindings::value_type<MatrA>::type
                > const& Control)
  {
    return symbolic (A, Qinit, Symbolic, Control.ptr);
  }


  // numeric
  /*
   * Given a sparse matrix A in column-oriented form, and a symbolic analysis
   * computed by umfpack_*_*symbolic, the umfpack_*_numeric routine performs
   * the numerical factorisation, PAQ=LU, PRAQ=LU, or P(R\A)Q=LU, where P
   * and Q are permutation matrices (represented as permutation vectors),
   * R is the row scaling, L is unit-lower triangular, and U is upper
   * triangular.  This is required before the system Ax=b (or other related
   * linear systems) can be solved.
   */
  namespace detail {

    template <typename MatrA>
    inline
    int numeric (tag::compressed_sparse, MatrA const& A,
                 void *Symbolic, void** Numeric,
                 double const* Control = 0, double* Info = 0)
    {
      return detail::numeric (bindings::size_row (A),
                              bindings::size_column (A),
                              bindings::begin_compressed_index_major (A),
                              bindings::begin_index_minor (A),
                              bindings::begin_value (A),
                              Symbolic, Numeric, Control, Info);
    }

    template <typename MatrA>
    inline
    int numeric (tag::coordinate_sparse, MatrA const& A,
                 void *Symbolic, void** Numeric,
                 double const* Control = 0, double* Info = 0)
    {
      int n_row = bindings::size_row (A);
      int n_col = bindings::size_column (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n_col+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n_row, n_col, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      return detail::numeric (n_row, n_col,
                              Ap.storage(), Ai.storage(),
                              bindings::begin_value (A),
                              Symbolic, Numeric, Control, Info);
    }

  } // detail

  template <typename MatrA>
  inline
  int numeric (MatrA const& A,
               symbolic_type<
                 typename bindings::value_type<MatrA>::type
               > const& Symbolic,
               numeric_type<
                 typename bindings::value_type<MatrA>::type
               >& Numeric,
               double const* Control = 0, double* Info = 0)
  {
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    return detail::numeric (storage_f(), A,
                            Symbolic.ptr, &Numeric.ptr, Control, Info);
  }

  template <typename MatrA>
  inline
  int numeric (MatrA const& A,
               symbolic_type<
                 typename bindings::value_type<MatrA>::type
               > const& Symbolic,
               numeric_type<
                 typename bindings::value_type<MatrA>::type
               >& Numeric,
               control_type<
                 typename bindings::value_type<MatrA>::type
               > const& Control,
               info_type<
                 typename bindings::value_type<MatrA>::type
               >& Info)

  {
    // g++ (3.2) is unable to distinguish
    //           function numeric() and namespace boost::numeric ;o)
    return umfpack::numeric (A, Symbolic, Numeric, Control.ptr, Info.ptr);
  }

  template <typename MatrA>
  inline
  int numeric (MatrA const& A,
               symbolic_type<
                 typename bindings::value_type<MatrA>::type
               > const& Symbolic,
               numeric_type<
                 typename bindings::value_type<MatrA>::type
               >& Numeric,
               control_type<
                 typename bindings::value_type<MatrA>::type
               > const& Control)
  {
    return umfpack::numeric (A, Symbolic, Numeric, Control.ptr);
  }


  // factor
  /*
   * symbolic and numeric
   */
  namespace detail {

    template <typename MatrA>
    inline
    int factor (tag::compressed_sparse, MatrA const& A,
                void** Numeric, double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
      symbolic_type<typename bindings::value_type<MatrA>::type>
        Symbolic;

      int status;
      status = detail::symbolic (bindings::size_row (A),
                                 bindings::size_column (A),
                                 bindings::begin_compressed_index_major (A),
                                 bindings::begin_index_minor (A),
                                 bindings::begin_value (A),
                                 &Symbolic.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      return detail::numeric (bindings::size_row (A),
                              bindings::size_column (A),
                              bindings::begin_compressed_index_major (A),
                              bindings::begin_index_minor (A),
                              bindings::begin_value (A),
                              Symbolic.ptr, Numeric, Control, Info);
    }

    template <typename MatrA>
    inline
    int factor (tag::coordinate_sparse, MatrA const& A,
                void** Numeric, double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
      int n_row = bindings::size_row (A);
      int n_col = bindings::size_column (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n_col+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n_row, n_col, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      symbolic_type<typename bindings::value_type<MatrA>::type>
        Symbolic;

      status = detail::symbolic (n_row, n_col,
                                 Ap.storage(), Ai.storage(),
                                 bindings::begin_value (A),
                                 &Symbolic.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      return detail::numeric (n_row, n_col,
                              Ap.storage(), Ai.storage(),
                              bindings::begin_value (A),
                              Symbolic.ptr, Numeric, Control, Info);
    }

  } // detail

  template <typename MatrA>
  inline
  int factor (MatrA const& A,
              numeric_type<
                typename bindings::value_type<MatrA>::type
              >& Numeric,
              double const* Control = 0, double* Info = 0)
  {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    return detail::factor (storage_f(), A, &Numeric.ptr, Control, Info);
  }

  template <typename MatrA>
  inline
  int factor (MatrA const& A,
              numeric_type<
                typename bindings::value_type<MatrA>::type
              >& Numeric,
              control_type<
                typename bindings::value_type<MatrA>::type
              > const& Control,
              info_type<
                typename bindings::value_type<MatrA>::type
              >& Info)
  {
    return factor (A, Numeric, Control.ptr, Info.ptr);
  }

  template <typename MatrA>
  inline
  int factor (MatrA const& A,
              numeric_type<
                typename bindings::value_type<MatrA>::type
              >& Numeric,
              control_type<
                typename bindings::value_type<MatrA>::type
              > const& Control)
  {
    return factor (A, Numeric, Control.ptr);
  }


  // solve
  /*
   * Given LU factors computed by umfpack_*_numeric and the right-hand-side,
   * B, solve a linear system for the solution X.  Iterative refinement is
   * optionally performed.  Only square systems are handled.
   */
  namespace detail {

    template <typename MatrA, typename VecX, typename VecB>
    inline
    int solve (tag::compressed_sparse, int sys,
               MatrA const& A, VecX& X, VecB const& B,
               void *Numeric, double const* Control = 0, double* Info = 0)
    {
      return detail::solve (sys, bindings::size_row (A),
                            bindings::begin_compressed_index_major (A),
                            bindings::begin_index_minor (A),
                            bindings::begin_value (A),
                            bindings::begin_value (X),
                            bindings::begin_value (B),
                            Numeric, Control, Info);
    }

    template <typename MatrA, typename VecX, typename VecB>
    inline
    int solve (tag::coordinate_sparse, int sys,
               MatrA const& A, VecX& X, VecB const& B,
               void *Numeric, double const* Control = 0, double* Info = 0)
    {

      int n = bindings::size_row (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n, n, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      return detail::solve (sys, n, Ap.storage(), Ai.storage(),
                            bindings::begin_value (A),
                            bindings::begin_value (X),
                            bindings::begin_value (B),
                            Numeric, Control, Info);
    }

  } // detail

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (int sys, MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             double const* Control = 0, double* Info = 0)
  {
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    assert (bindings::size_row (A) == bindings::size_row (A));
    assert (bindings::size_column (A) == bindings::size (X));
    assert (bindings::size_column (A) == bindings::size (B));

    return detail::solve (storage_f(), sys, A, X, B,
                          Numeric.ptr, Control, Info);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (int sys, MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             control_type<
               typename bindings::value_type<MatrA>::type
             > const& Control,
             info_type<
               typename bindings::value_type<MatrA>::type
             >& Info)
  {
    return solve (sys, A, X, B, Numeric, Control.ptr, Info.ptr);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (int sys, MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             control_type<
               typename bindings::value_type<MatrA>::type
             > const& Control)
  {
    return solve (sys, A, X, B, Numeric, Control.ptr);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             double const* Control = 0, double* Info = 0)
  {
    return solve (UMFPACK_A, A, X, B, Numeric, Control, Info);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             control_type<
               typename bindings::value_type<MatrA>::type
             > const& Control,
             info_type<
               typename bindings::value_type<MatrA>::type
             >& Info)
  {
    return solve (UMFPACK_A, A, X, B, Numeric,
                  Control.ptr, Info.ptr);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int solve (MatrA const& A, VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<MatrA>::type
             > const& Numeric,
             control_type<
               typename bindings::value_type<MatrA>::type
             > const& Control)
  {
    return solve (UMFPACK_A, A, X, B, Numeric, Control.ptr);
  }


  // umf_solve
  /*
   * symbolic, numeric and solve
   */
  namespace detail {

    template <typename MatrA, typename VecX, typename VecB>
    inline
    int umf_solve (tag::compressed_sparse,
                   MatrA const& A, VecX& X, VecB const& B,
                   double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
      symbolic_type<typename bindings::value_type<MatrA>::type>
        Symbolic;
      numeric_type<typename bindings::value_type<MatrA>::type>
        Numeric;

      int status;
      status = detail::symbolic (bindings::size_row (A),
                                 bindings::size_column (A),
                                 bindings::begin_compressed_index_major (A),
                                 bindings::begin_index_minor (A),
                                 bindings::begin_value (A),
                                 &Symbolic.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      status = detail::numeric (bindings::size_row (A),
                                bindings::size_column (A),
                                bindings::begin_compressed_index_major (A),
                                bindings::begin_index_minor (A),
                                bindings::begin_value (A),
                                Symbolic.ptr, &Numeric.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      return detail::solve (UMFPACK_A, bindings::size_row (A),
                            bindings::begin_compressed_index_major (A),
                            bindings::begin_index_minor (A),
                            bindings::begin_value (A),
                            bindings::begin_value (X),
                            bindings::begin_value (B),
                            Numeric.ptr, Control, Info);
    }

    template <typename MatrA, typename VecX, typename VecB>
    inline
    int umf_solve (tag::coordinate_sparse,
                   MatrA const& A, VecX& X, VecB const& B,
                   double const* Control = 0, double* Info = 0)
    {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrAA::not_yet_tested i_m_still_here;
#endif
      int n_row = bindings::size_row (A);
      int n_col = bindings::size_column (A);
      int nnz = bindings::end_value (A) - bindings::begin_value (A);

      typedef typename bindings::value_type<MatrA>::type val_t;

      int const* Ti = bindings::begin_index_minor (A);
      int const* Tj = bindings::begin_index_major (A);
      bindings::detail::array<int> Ap (n_col+1);
      if (!Ap.valid()) return UMFPACK_ERROR_out_of_memory;
      bindings::detail::array<int> Ai (nnz);
      if (!Ai.valid()) return UMFPACK_ERROR_out_of_memory;

      int status = detail::triplet_to_col (n_row, n_col, nnz,
                                           Ti, Tj, static_cast<val_t*> (0),
                                           Ap.storage(), Ai.storage(),
                                           static_cast<val_t*> (0), 0);
      if (status != UMFPACK_OK) return status;

      symbolic_type<typename bindings::value_type<MatrA>::type>
        Symbolic;
      numeric_type<typename bindings::value_type<MatrA>::type>
        Numeric;

      status = detail::symbolic (n_row, n_col,
                                 Ap.storage(), Ai.storage(),
                                 bindings::begin_value (A),
                                 &Symbolic.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      status = detail::numeric (n_row, n_col,
                                Ap.storage(), Ai.storage(),
                                bindings::begin_value (A),
                                Symbolic.ptr, &Numeric.ptr, Control, Info);
      if (status != UMFPACK_OK) return status;

      return detail::solve (UMFPACK_A, n_row, Ap.storage(), Ai.storage(),
                            bindings::begin_value (A),
                            bindings::begin_value (X),
                            bindings::begin_value (B),
                            Numeric.ptr, Control, Info);
    }

  } // detail

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int umf_solve (MatrA const& A, VecX& X, VecB const& B,
                 double const* Control = 0, double* Info = 0)
  {
#ifdef CHECK_TEST_COVERAGE
      typedef typename MatrA::not_yet_tested i_m_still_here;
#endif
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    assert (bindings::size_row (A) == bindings::size_row (A));
    assert (bindings::size_column (A) == bindings::size (X));
    assert (bindings::size_column (A) == bindings::size (B));

    return detail::umf_solve (storage_f(), A, X, B, Control, Info);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int umf_solve (MatrA const& A, VecX& X, VecB const& B,
                 control_type<
                   typename bindings::value_type<MatrA>::type
                 > const& Control,
                 info_type<
                   typename bindings::value_type<MatrA>::type
                 >& Info)
  {
    return umf_solve (A, X, B, Control.ptr, Info.ptr);
  }

  template <typename MatrA, typename VecX, typename VecB>
  inline
  int umf_solve (MatrA const& A, VecX& X, VecB const& B,
                 control_type<
                   typename bindings::value_type<MatrA>::type
                 > const& Control)
  {
    return umf_solve (A, X, B, Control.ptr);
  }


  ///////////////////////
  // matrix manipulations
  ///////////////////////


  // scale

  template <typename VecX, typename VecB>
  inline
  int scale (VecX& X, VecB const& B,
             numeric_type<
               typename bindings::value_type<VecB>::type
             > const& Numeric)
  {
    return detail::scale (bindings::size (B),
                          bindings::begin_value (X),
                          bindings::begin_value (B),
                          Numeric.ptr);
  }


  ////////////
  // reporting
  ////////////


  // report status

  template <typename T>
  inline
  void report_status (control_type<T> const& Control, int status) {
    detail::report_status (T(), 0, Control.ptr, status);
  }

#if 0
  template <typename T>
  inline
  void report_status (int printing_level, int status) {
    control_type<T> Control;
    Control[UMFPACK_PRL] = printing_level;
    detail::report_status (T(), 0, Control.ptr, status);
  }
  template <typename T>
  inline
  void report_status (int status) {
    control_type<T> Control;
    detail::report_status (T(), 0, Control.ptr, status);
  }
#endif


  // report control

  template <typename T>
  inline
  void report_control (control_type<T> const& Control) {
    detail::report_control (T(), 0, Control.ptr);
  }


  // report info

  template <typename T>
  inline
  void report_info (control_type<T> const& Control, info_type<T> const& Info) {
    detail::report_info (T(), 0, Control.ptr, Info.ptr);
  }

#if 0
  template <typename T>
  inline
  void report_info (int printing_level, info_type<T> const& Info) {
    control_type<T> Control;
    Control[UMFPACK_PRL] = printing_level;
    detail::report_info (T(), 0, Control.ptr, Info.ptr);
  }
  template <typename T>
  inline
  void report_info (info_type<T> const& Info) {
    control_type<T> Control;
    detail::report_info (T(), 0, Control.ptr, Info.ptr);
  }
#endif


  // report matrix (compressed column and coordinate)

  namespace detail {

    template <typename MatrA>
    inline
    int report_matrix (tag::compressed_sparse, MatrA const& A,
                       double const* Control)
    {
      return detail::report_matrix (bindings::size_row (A),
                                    bindings::size_column (A),
                                    bindings::begin_compressed_index_major (A),
                                    bindings::begin_index_minor (A),
                                    bindings::begin_value (A),
                                    1, Control);
    }

    template <typename MatrA>
    inline
    int report_matrix (tag::coordinate_sparse, MatrA const& A,
                       double const* Control)
    {
      return detail::report_triplet (bindings::size_row (A),
                                     bindings::size_column (A),
                                     bindings::end_value (A) - bindings::begin_value (A),
                                     bindings::begin_index_major (A),
                                     bindings::begin_index_minor (A),
                                     bindings::begin_value (A),
                                     Control);
    }

  } // detail

  template <typename MatrA>
  inline
  int report_matrix (MatrA const& A,
                     control_type<
                       typename bindings::value_type<MatrA>::type
                     > const& Control)
  {
#ifndef BOOST_NUMERIC_BINDINGS_NO_STRUCTURE_CHECK
    check_umfpack_structure<MatrA>();
#endif
    typedef typename bindings::detail::property_at<
      MatrA, tag::data_structure >::type storage_f;

    return detail::report_matrix (storage_f(), A, Control.ptr);
  }


  // report vector

  template <typename VecX>
  inline
  int report_vector (VecX const& X,
                     control_type<
                       typename bindings::value_type<VecX>::type
                     > const& Control)
  {
    return detail::report_vector (bindings::size (X),
                                  bindings::begin_value (X),
                                  Control.ptr);
  }


  // report numeric

  template <typename T>
  inline
  int report_numeric (numeric_type<T> const& Numeric,
                      control_type<T> const& Control)
  {
    return detail::report_numeric (T(), 0, Numeric.ptr, Control.ptr);
  }


  // report symbolic

  template <typename T>
  inline
  int report_symbolic (symbolic_type<T> const& Symbolic,
                       control_type<T> const& Control)
  {
    return detail::report_symbolic (T(), 0, Symbolic.ptr, Control.ptr);
  }


  // report permutation vector

  template <typename VecP, typename T>
  inline
  int report_permutation (VecP const& Perm, control_type<T> const& Control) {
#ifdef CHECK_TEST_COVERAGE
      typedef typename T::not_yet_tested i_m_still_here;
#endif
    return detail::report_perm (T(), 0,
                                bindings::begin_value (Perm),
                                Control.ptr);
  }


}}}}

#endif // BOOST_NUMERIC_BINDINGS_UMFPACK_HPP
