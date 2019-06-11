#pragma once
/*
 * Implement Modelica array slices.
 *
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "Array.h"
/** @addtogroup math
 *   @{
*/

/**
 * Modelica slice.
 * Defined by an index vector iset != NULL or by start:stop or start:step:stop,
 * start == stop and step == 0 meaning reduction of dimension,
 * start == 0 or stop == 0 meaning end.
 */
class Slice {
 public:
  // all indices
  Slice() {
    start = 1;
    step = 1;
    stop = 0;
    iset = NULL;
  }

  // one index (reduction)
  Slice(int index) {
    start = index;
    step = 0;
    stop = index;
    iset = NULL;
  }

  Slice(int start, int stop) {
    this->start = start;
    step = 1;
    this->stop = stop;
    iset = NULL;
  }

  Slice(int start, int step, int stop) {
    this->start = start;
    this->step = step;
    this->stop = stop;
    iset = NULL;
  }

  // index set, reduction if size(indices) == 1
  Slice(const BaseArray<int> &indices) {
    start = 0;
    step = 0;
    stop = 0;
    if (indices.getNumDims() != 1)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Slice requires an index vector");
    // store pointer as indices should live long enough in a Modelica model
    iset = &indices;
  }

  int start;
  int step;
  int stop;
  const BaseArray<int> *iset;
};

/**
 * Multi-dimensional array slice holding a const reference to a BaseArray.
 */
template<class T>
class ArraySliceConst: public BaseArray<T> {
 public:
  ArraySliceConst(const BaseArray<T> &baseArray, const vector<Slice> &slice)
    : BaseArray<T>(baseArray.isStatic(), false)
    , _baseArray(baseArray)
    , _isets(baseArray.getNumDims())
    , _idxs(baseArray.getNumDims())
    , _baseIdx(baseArray.getNumDims())
    , _tmp_data(NULL) {

    if (baseArray.getNumDims() < slice.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong slices exceeding array dimensions");
    // create an explicit index set per dimension,
    // except for all indices that are indicated with an empty index set
    size_t dim, size;
    vector<Slice>::const_iterator sit;
    vector< vector<size_t> >::iterator dit = _idxs.begin();
    for (dim = 1, sit = slice.begin(); sit != slice.end(); dim++, sit++) {
      if (sit->iset != NULL) {
        _isets[dim - 1] = sit->iset;
        size = sit->iset->getNumElems();
      }
      else {
        _isets[dim - 1] = NULL;
        int maxIndex = baseArray.getDim(dim);
        int start = sit->start > 0? sit->start: maxIndex;
        int stop = sit->stop > 0? sit->stop: maxIndex;
        int step = sit->step;
        if (start > maxIndex || stop > maxIndex)
          throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                        "Wrong slice exceeding array size");
        if (start == 1 && step == 1 && stop == maxIndex)
          // all indices; avoid trivial fill of _idxs
          size = _baseArray.getDim(dim);
        else {
          size = step == 0? 1: std::max(0, (stop - start) / step + 1);
          for (int i = 0; i < size; i++)
            dit->push_back(start + i * step);
        }
      }
      if (size == 1 && sit->step == 0)
        // preset constant _baseIdx in case of reduction
        _baseIdx[dim - 1] = sit->iset != NULL? (*_isets[dim - 1])(1): (*dit)[0];
      else
        // store dimension of array slice
        _dims.push_back(size);
      dit++;
    }
    // use all indices of remaining dims
    for (; dim <= baseArray.getNumDims(); dim++) {
      _isets[dim - 1] = NULL;
      _dims.push_back(_baseArray.getDim(dim));
    }
  }

  virtual ~ArraySliceConst() {
    if (_tmp_data != NULL)
      delete [] _tmp_data;
  }

  virtual const T& operator()(const vector<size_t> &idx) const {
    return _baseArray(baseIdx(idx.size(), &idx[0]));
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
    return _dims;
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
        getDataDim(_idxs.size(), data);
    }
  }

  virtual const T* getData() const {
    if (_tmp_data == NULL)
      // allocate on first use
      _tmp_data = new T [getNumElems()];
    getDataDim(_idxs.size(), _tmp_data);
    return _tmp_data;
  }

  virtual size_t getNumElems() const {
    return std::accumulate(_dims.begin(), _dims.end(),
                           1, std::multiplies<size_t>());
  }

  virtual size_t getNumDims() const {
    return _dims.size();
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
    return _baseArray(baseIdx(1, &i));
  }

  virtual const T& operator()(size_t i, size_t j) const {
    size_t idx[] = {i, j};
    return _baseArray(baseIdx(2, idx));
  }

 protected:
  const BaseArray<T> &_baseArray;  // underlying array
  vector<const BaseArray<int>*> _isets; // given index sets per dimension
  vector< vector<size_t> > _idxs;  // created index sets per dimension
  vector<size_t> _dims;            // dimensions of array slice
  mutable vector<size_t> _baseIdx; // idx into underlying array
  mutable T *_tmp_data;            // storage for const T* getData()

  /**
   * returns idx vector to access an element
   */
  const vector<size_t> &baseIdx(size_t ndims, const size_t idx[]) const {
    if (ndims != _dims.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions accessing ArraySlice");
    size_t dim, size;
    const BaseArray<int> *iset;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      iset = _isets[dim - 1];
      size = iset? iset->getNumElems(): dit->size();
      switch (size) {
      case 0:
        // all indices
        _baseIdx[dim - 1] = *idx++;
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        _baseIdx[dim - 1] = iset? (*iset)(*idx++): (*dit)[*idx++ - 1];
      }
    }
    return _baseIdx;
  }

  /**
   * recursive method for reading raw data
   */
  size_t getDataDim(size_t dim, T* data) const {
    size_t processed = 0;
    const BaseArray<int> *iset = _isets[dim - 1];
    size_t size = iset? iset->getNumElems(): _idxs[dim - 1].size();
    if (size == 0)
      size = _baseArray.getDim(dim);
    for (size_t i = 1; i <= size; i++) {
      if (iset)
        _baseIdx[dim - 1] = iset->getNumElems() > 0? (*iset)(i): i;
      else
        _baseIdx[dim - 1] = _idxs[dim - 1].size() > 0? _idxs[dim - 1][i - 1]: i;
      if (dim > 1)
        processed += getDataDim(dim - 1, data + processed);
      else
        data[processed++] = _baseArray(_baseIdx);
    }
    return processed;
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
    , _baseArray(baseArray)
    , _idxs(ArraySliceConst<T>::_idxs)
    , _baseIdx(ArraySliceConst<T>::_baseIdx) {
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
    return _baseArray(ArraySliceConst<T>::baseIdx(idx.size(), &idx[0]));
  }

  virtual void assign(const T* data) {
    setDataDim(_idxs.size(), data);
  }

  virtual void assign(const BaseArray<T>& otherArray) {
    setDataDim(_idxs.size(), otherArray.getData());
  }

  virtual void assign(const T& value) {
    setEachDim(_idxs.size(), value);
  }

  virtual T& operator()(size_t i) {
    return _baseArray(ArraySliceConst<T>::baseIdx(1, &i));
  }

  virtual T& operator()(size_t i, size_t j) {
    size_t idx[] = {i, j};
    return _baseArray(ArraySliceConst<T>::baseIdx(2, idx));
  }

  virtual T& operator()(size_t i, size_t j, size_t k) {
    size_t idx[] = {i, j, k};
    return _baseArray(ArraySliceConst<T>::baseIdx(3, idx));
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l) {
    size_t idx[] = {i, j, k, l};
    return _baseArray(ArraySliceConst<T>::baseIdx(4, idx));
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m) {
    size_t idx[] = {i, j, k, l, m};
    return _baseArray(ArraySliceConst<T>::baseIdx(5, idx));
  }

 protected:
  BaseArray<T> &_baseArray;        // underlying array
  vector< vector<size_t> > &_idxs; // reference to index set of ArraySliceConst
  vector<size_t> &_baseIdx;        // reference to idx into underlying array

  /**
   * recursive method for muli-dimensional assignment of raw data
   */
  size_t setDataDim(size_t dim, const T* data) {
    size_t processed = 0;
    const BaseArray<int> *iset = ArraySliceConst<T>::_isets[dim - 1];
    size_t size = iset? iset->getNumElems(): _idxs[dim - 1].size();
    if (size == 0)
      size = _baseArray.getDim(dim);
    for (size_t i = 1; i <= size; i++) {
      if (iset)
        _baseIdx[dim - 1] = iset->getNumElems() > 0? (*iset)(i): i;
      else
        _baseIdx[dim - 1] = _idxs[dim - 1].size() > 0? _idxs[dim - 1][i - 1]: i;
      if (dim > 1)
        processed += setDataDim(dim - 1, data + processed);
      else
        _baseArray(_baseIdx) = data[processed++];
    }
    return processed;
  }

  /**
   * recursive method for muli-dimensional fill of each element
   */
  void setEachDim(size_t dim, const T& value) {
    const BaseArray<int> *iset = ArraySliceConst<T>::_isets[dim - 1];
    size_t size = iset? iset->getNumElems(): _idxs[dim - 1].size();
    if (size == 0)
      size = _baseArray.getDim(dim);
    for (size_t i = 1; i <= size; i++) {
      if (iset)
        _baseIdx[dim - 1] = iset->getNumElems() > 0? (*iset)(i): i;
      else
        _baseIdx[dim - 1] = _idxs[dim - 1].size() > 0? _idxs[dim - 1][i - 1]: i;
      if (dim > 1)
        setEachDim(dim - 1, value);
      else
        _baseArray(_baseIdx) = value;
    }
  }
};
/** @} */ // end of math
