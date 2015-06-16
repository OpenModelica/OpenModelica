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
 * Defined by start:stop or start:step:stop, start = 0 or stop = 0 meaning end,
 * or by an index vector if step = 0.
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

  // one index
  Slice(int index) {
    start = index;
    step = 1;
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

  size_t start;
  size_t step;
  size_t stop;
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
    , _isets(slice.size())
    , _idxs(slice.size())
    , _baseIdx(slice.size()) {

    if (baseArray.getNumDims() != slice.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions for ArraySlice");
    // create an explicit index set per dimension,
    // except for all indices that are indicated with an empty index set
    size_t dim;
    vector<Slice>::const_iterator sit;
    vector< vector<size_t> >::iterator dit = _idxs.begin();
    for (dim = 1, sit = slice.begin(); sit != slice.end(); dim++, sit++) {
      if (sit->step == 0)
        _isets[dim - 1] = sit->iset;
      else {
        _isets[dim - 1] = NULL;
        size_t maxIndex = baseArray.getDim(dim);
        size_t start = sit->start > 0? sit->start: maxIndex;
        size_t stop = sit->stop > 0? sit->stop: maxIndex;
        if (start > maxIndex || stop > maxIndex)
          throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                        "Wrong slice exceeding array size");
        if (start > 1 || sit->step > 1 || stop < maxIndex)
          for (size_t i = start; i <= stop; i += sit->step)
            dit->push_back(i);
      }
      if (dit->size() == 1)
        // prefill constant _baseIdx in case of reduction
        _baseIdx[dim - 1] = (*dit)[0];
      else
        // store dimension of array slice
        _dims.push_back(dit->size() != 0? dit->size(): _baseArray.getDim(dim));
      dit++;
    }
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
    getDataDim(_idxs.size(), data);
  }

  virtual const T* getData() const {
    if (_tmp_data.num_elements() == 0)
      // allocate on first use
      _tmp_data.resize(boost::extents[getNumElems()]);
    getDataDim(_idxs.size(), _tmp_data.data());
    return _tmp_data.data();
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
  mutable boost::multi_array<T, 1> _tmp_data; // storage for const T* getData()

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

  virtual T& operator()(const vector<size_t> &idx) {
    return _baseArray(ArraySliceConst<T>::baseIdx(idx.size(), &idx[0]));
  }

  virtual void assign(const T* data) {
    setDataDim(_idxs.size(), data);
  }

  virtual void assign(const BaseArray<T>& otherArray) {
    setDataDim(_idxs.size(), otherArray.getData());
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
};
/** @} */ // end of math