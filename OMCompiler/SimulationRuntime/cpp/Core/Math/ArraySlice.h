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

/* Implement Modelica array slices. */

#include "Array.h"
/** @addtogroup math
 *   @{
*/

/**
 * Modelica slice.
 * Defined by an index vector iset != NULL or by start:stop or start:step:stop,
 * start == stop and step == 0 meaning reduction of dimension,
 * is_stop_end marking stop == end.
 */
class Slice {
 public:
  // all indices
  Slice() {
    start = 1;
    step = 1;
    stop = 0;
    is_stop_end = true;
    iset = NULL;
  }

  // one index (reduction)
  Slice(int index) {
    start = index;
    step = 0;
    stop = index;
    is_stop_end = false;
    iset = NULL;
  }

  Slice(int start, int stop) {
    this->start = start;
    step = 1;
    this->stop = stop;
    is_stop_end = false;
    iset = NULL;
  }

  Slice(int start, int step, int stop) {
    this->start = start;
    this->step = step;
    this->stop = stop;
    is_stop_end = false;
    iset = NULL;
  }

  // index set
  Slice(const BaseArray<int> &indices) {
    start = 0;
    step = 0;
    stop = 0;
    is_stop_end = false;
    if (indices.getNumDims() != 1)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Slice requires an index vector");
    // store pointer as indices should live long enough in a Modelica model
    iset = &indices;
  }

  int start;
  int step;
  int stop;
  bool is_stop_end;
  const BaseArray<int> *iset;
};

/**
 * Multi-dimensional array slice holding a const reference to a BaseArray.
 * Slices are typically created for single elements of arrays of records in
 * loops, e.g. v[i, j, :], so they don't allocate memory unless they have
 * many elements or many dimensions, and they access the elements of
 * contiguous arrays directly.
 */
template<class T>
class ArraySliceConst: public BaseArray<T> {
 public:
  ArraySliceConst(const BaseArray<T> &baseArray, const vector<Slice> &slice)
    : BaseArray<T>(baseArray.isStatic(), false)
    , _baseArray(baseArray)
    , _nBaseDims(baseArray.getNumDims())
    , _nDims(0)
    , _contiguous(baseArray.isContiguous())
    , _tmp_data(NULL) {

    if (_nBaseDims < slice.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong slices exceeding array dimensions");
    if (_nBaseDims > MAX_DIMS)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Too many dimensions for ArraySlice");
    // map each dimension of the base array to an index set, a range or a
    // reduction; dimensions without slice keep all indices
    size_t stride = 1;
    for (size_t dim = 0; dim < _nBaseDims; dim++) {
      DimSlice &ds = _dimSlices[dim];
      int maxIndex = baseArray.getDim(dim + 1);
      ds.stride = stride;
      stride *= maxIndex;
      ds.iset = NULL;
      ds.start = 1;
      ds.step = 1;
      ds.size = maxIndex;
      ds.reduction = false;
      if (dim < slice.size()) {
        const Slice &s = slice[dim];
        if (s.iset != NULL) {
          ds.iset = s.iset;
          ds.size = s.iset->getNumElems();
        }
        else {
          int stop = s.is_stop_end? maxIndex: s.stop;
          int size = s.step == 0? 1: std::max(0, (stop - s.start) / s.step + 1);
          if (size > 0 && (s.start > maxIndex || stop > maxIndex))
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                          "Wrong slice exceeding array size");
          ds.start = s.start;
          ds.step = s.step;
          ds.size = size;
          ds.reduction = s.step == 0;
        }
      }
      // the index of a reduced dimension is constant
      _baseIdx[dim] = ds.reduction? ds.start: 1;
      if (!ds.reduction)
        _dims[_nDims++] = ds.size;
    }
  }

  virtual ~ArraySliceConst() {
    if (_tmp_data != NULL)
      delete [] _tmp_data;
  }

  virtual const T& operator()(const vector<size_t> &idx) const {
    mapIndex(idx.size(), &idx[0]);
    return baseElement();
  }

  virtual T& operator()(const vector<size_t> &idx) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't write to ArraySliceConst");
  }

  virtual void assign(const T* data) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't assign data to ArraySliceConst");
  }

  virtual void assign(const BaseArray<T>& otherArray) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't assign array to ArraySliceConst");
  }

  virtual void assign(const T& value) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't assign value to ArraySliceConst");
  }

  virtual std::vector<size_t> getDims() const {
    return std::vector<size_t>(_dims, _dims + _nDims);
  }

  virtual int getDim(size_t sliceDim) const {
    return (int)_dims[sliceDim - 1];
  }

  virtual T* getData() {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't get pointer to write to ArraySlice");
  }

  virtual void getDataCopy(T data[], size_t n) const {
    if (n != getNumElems())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong number of elements in getDataCopy");
    if (n > 0) {
      const T* base_data = _baseArray.getData();
      if (base_data <= data && data < base_data + n) {
        // in-situ access requires an internal copy to avoid side effects,
        // e.g. v = v[n:-1:1]
        const T* slice_data = getData();
        std::copy(slice_data, slice_data + n, data);
      }
      else
        // direct access
        getDataDim(data);
    }
  }

  virtual const T* getData() const {
    size_t n = getNumElems();
    T* data = _inline_data;
    if (n > INLINE_ELEMS) {
      if (_tmp_data == NULL)
        // allocate on first use
        _tmp_data = new T [n];
      data = _tmp_data;
    }
    getDataDim(data);
    return data;
  }

  virtual size_t getNumElems() const {
    size_t n = 1;
    for (size_t dim = 0; dim < _nDims; dim++)
      n *= _dims[dim];
    return n;
  }

  virtual size_t getNumDims() const {
    return _nDims;
  }

  virtual bool isContiguous() const {
    return false;
  }

  virtual void setDims(const std::vector<size_t> &v) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't set dims of ArraySlice");
  }

  virtual void resize(const std::vector<size_t> &dims) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't resize ArraySlice");
  }

  virtual const T& operator()(size_t i) const {
    mapIndex(1, &i);
    return baseElement();
  }

  virtual const T& operator()(size_t i, size_t j) const {
    size_t idx[] = {i, j};
    mapIndex(2, idx);
    return baseElement();
  }

  virtual const T& operator()(size_t i, size_t j, size_t k) const {
    size_t idx[] = {i, j, k};
    mapIndex(3, idx);
    return baseElement();
  }

  virtual const T& operator()(size_t i, size_t j, size_t k, size_t l) const {
    size_t idx[] = {i, j, k, l};
    mapIndex(4, idx);
    return baseElement();
  }

  virtual const T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m) const {
    size_t idx[] = {i, j, k, l, m};
    mapIndex(5, idx);
    return baseElement();
  }

  virtual const T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m, size_t n) const {
    size_t idx[] = {i, j, k, l, m, n};
    mapIndex(6, idx);
    return baseElement();
  }

 protected:
  static const size_t MAX_DIMS = 16;    // maximum number of dimensions of the base array
  static const size_t INLINE_ELEMS = 8; // slices up to this size need no allocation

  // mapping of one dimension of the base array
  struct DimSlice {
    const BaseArray<int> *iset; // given index set
    int start;                  // range start:step:..., if no index set
    int step;
    size_t size;                // number of indices
    bool reduction;             // dimension reduced to the index start
    size_t stride;              // distance of elements in contiguous storage
  };

  const BaseArray<T> &_baseArray;  // underlying array
  size_t _nBaseDims;               // dimensions of underlying array
  size_t _nDims;                   // dimensions of array slice
  bool _contiguous;                // elements of underlying array are accessed directly
  DimSlice _dimSlices[MAX_DIMS];   // mapping per dimension of underlying array
  size_t _dims[MAX_DIMS];          // dimensions of array slice
  mutable size_t _baseIdx[MAX_DIMS];    // idx into underlying array
  mutable vector<size_t> _baseIdxVec;   // idx for arrays that aren't contiguous
  mutable T _inline_data[INLINE_ELEMS]; // storage for const T* getData() of small slices
  mutable T *_tmp_data;                 // storage for const T* getData() of large slices

  /**
   * index into the underlying array of the index i (one based) of a dimension
   */
  static size_t baseIndex(const DimSlice &ds, size_t i) {
    return ds.iset? (*ds.iset)(i): ds.start + (i - 1) * ds.step;
  }

  /**
   * set _baseIdx to the element idx of the slice
   */
  void mapIndex(size_t ndims, const size_t idx[]) const {
    if (ndims != _nDims)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions accessing ArraySlice");
    for (size_t dim = 0; dim < _nBaseDims; dim++) {
      if (!_dimSlices[dim].reduction)
        _baseIdx[dim] = baseIndex(_dimSlices[dim], *idx++);
    }
  }

  /**
   * offset of the element _baseIdx in contiguous storage
   */
  size_t baseOffset() const {
    size_t offset = 0;
    for (size_t dim = 0; dim < _nBaseDims; dim++)
      offset += (_baseIdx[dim] - 1) * _dimSlices[dim].stride;
    return offset;
  }

  /**
   * _baseIdx for the operators of underlying arrays that aren't contiguous
   */
  const vector<size_t> &baseIdxVec() const {
    _baseIdxVec.assign(_baseIdx, _baseIdx + _nBaseDims);
    return _baseIdxVec;
  }

  const T& baseElement() const {
    if (_contiguous)
      return _baseArray.getData()[baseOffset()];
    return _baseArray(baseIdxVec());
  }

  /**
   * set _baseIdx to the first element of the slice; false if it is empty
   */
  bool firstIndex(size_t counter[]) const {
    for (size_t dim = 0; dim < _nBaseDims; dim++) {
      const DimSlice &ds = _dimSlices[dim];
      if (ds.reduction)
        continue;
      if (ds.size == 0)
        return false;
      counter[dim] = 1;
      _baseIdx[dim] = baseIndex(ds, 1);
    }
    return true;
  }

  /**
   * advance _baseIdx to the next element of the slice in column major order
   */
  void nextIndex(size_t counter[]) const {
    for (size_t dim = 0; dim < _nBaseDims; dim++) {
      const DimSlice &ds = _dimSlices[dim];
      if (ds.reduction)
        continue;
      if (++counter[dim] <= ds.size) {
        _baseIdx[dim] = baseIndex(ds, counter[dim]);
        return;
      }
      counter[dim] = 1;
      _baseIdx[dim] = baseIndex(ds, 1);
    }
  }

  /**
   * read all elements in column major order
   */
  size_t getDataDim(T* data) const {
    size_t counter[MAX_DIMS];
    size_t n = getNumElems();
    if (n == 0 || !firstIndex(counter))
      return 0;
    const T* base_data = _contiguous? _baseArray.getData(): NULL;
    for (size_t i = 0; i < n; i++) {
      data[i] = base_data? base_data[baseOffset()]: _baseArray(baseIdxVec());
      nextIndex(counter);
    }
    return n;
  }
};

/**
 * Multi-dimensional array slice extending ArraySliceConst with write access
 */
template<class T>
class ArraySlice: public ArraySliceConst<T> {
 public:
  ArraySlice(BaseArray<T> &baseArray, const vector<Slice> &slice)
    : ArraySliceConst<T>(baseArray, slice)
    , _baseArray(baseArray) {
  }

  ArraySlice<T>& operator=(const ArraySlice<T>& b)
  {
    this->assign(b);
    return *this;
  }

  ArraySlice<T>& operator=(const BaseArray<T>& b)
  {
    this->assign(b);
    return *this;
  }

  virtual T& operator()(const vector<size_t> &idx) {
    this->mapIndex(idx.size(), &idx[0]);
    return baseElement();
  }

  virtual void assign(const T* data) {
    setDataDim(data);
  }

  virtual void assign(const BaseArray<T>& otherArray) {
    setDataDim(otherArray.getData());
  }

  virtual void assign(const T& value) {
    setEachDim(value);
  }

  virtual T& operator()(size_t i) {
    this->mapIndex(1, &i);
    return baseElement();
  }

  virtual T& operator()(size_t i, size_t j) {
    size_t idx[] = {i, j};
    this->mapIndex(2, idx);
    return baseElement();
  }

  virtual T& operator()(size_t i, size_t j, size_t k) {
    size_t idx[] = {i, j, k};
    this->mapIndex(3, idx);
    return baseElement();
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l) {
    size_t idx[] = {i, j, k, l};
    this->mapIndex(4, idx);
    return baseElement();
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m) {
    size_t idx[] = {i, j, k, l, m};
    this->mapIndex(5, idx);
    return baseElement();
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m, size_t n) {
    size_t idx[] = {i, j, k, l, m, n};
    this->mapIndex(6, idx);
    return baseElement();
  }

 protected:
  BaseArray<T> &_baseArray;        // underlying array

  T& baseElement() {
    if (this->_contiguous)
      return _baseArray.getData()[this->baseOffset()];
    return _baseArray(this->baseIdxVec());
  }

  /**
   * write all elements in column major order
   */
  size_t setDataDim(const T* data) {
    size_t counter[ArraySliceConst<T>::MAX_DIMS];
    size_t n = this->getNumElems();
    if (n == 0 || !this->firstIndex(counter))
      return 0;
    for (size_t i = 0; i < n; i++) {
      baseElement() = data[i];
      this->nextIndex(counter);
    }
    return n;
  }

  /**
   * fill each element
   */
  void setEachDim(const T& value) {
    size_t counter[ArraySliceConst<T>::MAX_DIMS];
    size_t n = this->getNumElems();
    if (n == 0 || !this->firstIndex(counter))
      return;
    for (size_t i = 0; i < n; i++) {
      baseElement() = value;
      this->nextIndex(counter);
    }
  }
};
/** @} */ // end of math
