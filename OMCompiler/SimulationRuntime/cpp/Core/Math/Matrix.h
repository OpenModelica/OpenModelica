/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


#pragma once
/** @addtogroup coreMath
 *
 *  @{
 */

#include <algorithm>
#include <cstddef>
#include <vector>

/**
 * Dense and compressed matrix types for the Jacobians and linear systems.
 *
 * Core/Modelica.h aliases this namespace to `ublas`, so generated code keeps
 * the uBLAS spelling. Only the operations OpenModelica uses are provided.
 */
namespace omcpp { namespace linalg {

struct row_major {
  static constexpr std::size_t element(std::size_t i, std::size_t j, std::size_t, std::size_t n2)
  { return i * n2 + j; }
};

struct column_major {
  static constexpr std::size_t element(std::size_t i, std::size_t j, std::size_t n1, std::size_t)
  { return i + j * n1; }
};

/** Storage with the subset of the uBLAS array interface that is used. */
template <class T>
class unbounded_array {
 public:
  typedef T value_type;
  typedef T* iterator;
  typedef const T* const_iterator;

  unbounded_array() {}
  explicit unbounded_array(std::size_t n) : _data(n, T()) {}
  unbounded_array(std::size_t n, const T& init) : _data(n, init) {}

  T* begin() { return _data.empty() ? 0 : &_data[0]; }
  const T* begin() const { return _data.empty() ? 0 : &_data[0]; }
  T* end() { return begin() + _data.size(); }
  const T* end() const { return begin() + _data.size(); }

  T& operator[](std::size_t i) { return _data[i]; }
  const T& operator[](std::size_t i) const { return _data[i]; }

  std::size_t size() const { return _data.size(); }
  void resize(std::size_t n) { _data.resize(n, T()); }
  void clear() { std::fill(_data.begin(), _data.end(), T()); }
  void insert(std::size_t pos, const T& v) { _data.insert(_data.begin() + pos, v); }

 private:
  std::vector<T> _data;
};

template <class T>
class zero_vector {
 public:
  explicit zero_vector(std::size_t n) : size(n) {}
  std::size_t size;
};

template <class T>
class zero_matrix {
 public:
  zero_matrix(std::size_t n1, std::size_t n2) : size1(n1), size2(n2) {}
  std::size_t size1, size2;
};

template <class T, class A = unbounded_array<T> >
class vector {
 public:
  typedef T value_type;
  typedef std::size_t size_type;

  vector() {}
  explicit vector(std::size_t n) : _data(n) {}
  vector(const zero_vector<T>& z) : _data(z.size) {}

  T& operator()(std::size_t i) { return _data[i]; }
  const T& operator()(std::size_t i) const { return _data[i]; }
  T& operator[](std::size_t i) { return _data[i]; }
  const T& operator[](std::size_t i) const { return _data[i]; }

  std::size_t size() const { return _data.size(); }
  /** uBLAS semantics: assign zero to every element, keeping the size. */
  void clear() { _data.clear(); }
  void resize(std::size_t n, bool preserve = true) { (void)preserve; _data.resize(n); }

  A& data() { return _data; }
  const A& data() const { return _data; }

 private:
  A _data;
};

template <class T, class L = row_major, class A = unbounded_array<T> >
class matrix {
 public:
  typedef T value_type;
  typedef std::size_t size_type;

  matrix() : _size1(0), _size2(0) {}
  matrix(std::size_t n1, std::size_t n2) : _data(n1 * n2), _size1(n1), _size2(n2) {}
  matrix(const zero_matrix<T>& z)
    : _data(z.size1 * z.size2), _size1(z.size1), _size2(z.size2) {}

  T& operator()(std::size_t i, std::size_t j)
  { return _data[L::element(i, j, _size1, _size2)]; }
  const T& operator()(std::size_t i, std::size_t j) const
  { return _data[L::element(i, j, _size1, _size2)]; }

  std::size_t size1() const { return _size1; }
  std::size_t size2() const { return _size2; }
  void clear() { _data.clear(); }

  void resize(std::size_t n1, std::size_t n2, bool preserve = true) {
    (void)preserve;
    _data.resize(n1 * n2);
    _size1 = n1;
    _size2 = n2;
  }

  A& data() { return _data; }
  const A& data() const { return _data; }

 private:
  A _data;
  std::size_t _size1, _size2;
};

/**
 * Compressed storage, major direction chosen by L. Entries are kept sorted
 * because the code generator emits `A(row, col) = ...` once per entry and then
 * addresses those same entries as `A.value_data()[n]`, in that order.
 */
template <class T, class L = row_major, std::size_t IB = 0,
          class IA = unbounded_array<int>, class TA = unbounded_array<T> >
class compressed_matrix {
 public:
  typedef T value_type;
  typedef std::size_t size_type;

  compressed_matrix() : _size1(0), _size2(0) { init(); }
  compressed_matrix(std::size_t n1, std::size_t n2) : _size1(n1), _size2(n2) { init(); }
  compressed_matrix(std::size_t n1, std::size_t n2, std::size_t nnz)
    : _size1(n1), _size2(n2) { init(); (void)nnz; }

  T& operator()(std::size_t i, std::size_t j) {
    std::size_t major = is_column_major() ? j : i;
    std::size_t minor = is_column_major() ? i : j;
    std::size_t lo = (std::size_t)_index1[major];
    std::size_t hi = (std::size_t)_index1[major + 1];
    for (std::size_t n = lo; n < hi; ++n) {
      if ((std::size_t)_index2[n] == minor + IB)
        return _value[n];
      if ((std::size_t)_index2[n] > minor + IB)
        return insert(n, major, minor);
    }
    return insert(hi, major, minor);
  }

  const T& operator()(std::size_t i, std::size_t j) const {
    std::size_t major = is_column_major() ? j : i;
    std::size_t minor = is_column_major() ? i : j;
    for (std::size_t n = (std::size_t)_index1[major]; n < (std::size_t)_index1[major + 1]; ++n)
      if ((std::size_t)_index2[n] == minor + IB)
        return _value[n];
    return _zero;
  }

  std::size_t size1() const { return _size1; }
  std::size_t size2() const { return _size2; }
  std::size_t nnz() const { return _nnz; }

  TA& value_data() { return _value; }
  const TA& value_data() const { return _value; }
  IA& index1_data() { return _index1; }
  const IA& index1_data() const { return _index1; }
  IA& index2_data() { return _index2; }
  const IA& index2_data() const { return _index2; }

  /** uBLAS semantics: drop every entry, keeping the dimensions. */
  void clear() { init(); }

  void resize(std::size_t n1, std::size_t n2, bool preserve = false) {
    (void)preserve;
    _size1 = n1;
    _size2 = n2;
    init();
  }

 private:
  static constexpr bool is_column_major() { return L::element(0, 1, 2, 2) == 2; }
  std::size_t majors() const { return is_column_major() ? _size2 : _size1; }

  void init() {
    _nnz = 0;
    _value = TA();
    _index2 = IA();
    _index1 = IA(majors() + 1, (int)IB);
  }

  T& insert(std::size_t n, std::size_t major, std::size_t minor) {
    _value.insert(n, T());
    _index2.insert(n, (int)(minor + IB));
    for (std::size_t m = major + 1; m <= majors(); ++m)
      ++_index1[m];
    ++_nnz;
    return _value[n];
  }

  TA _value;
  IA _index1, _index2;
  std::size_t _size1, _size2, _nnz;
  T _zero = T();
};

} }  // namespace omcpp::linalg
/** @} */
