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
#include <stdarg.h>

// Modelica slice
// Defined by start:stop or start:step:stop, start = 0 or stop = 0 meaning end,
// or by an index vector if step = 0.
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

// Multi-dimensional array slice holding a reference to a BaseArray.
template<class T>
class ArraySlice: public BaseArray<T> {
 public:
  ArraySlice(BaseArray<T> &baseArray, const vector<Slice> &slice)
    : BaseArray<T>(baseArray.isStatic())
    , _baseArray(baseArray)
    , _isets(slice.size())
    , _idxs(slice.size())
    , _baseIdx(slice.size()) {

    if (baseArray.getNumDims() != slice.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions for ArraySlice");
    // create an explicit index set per dimension,
    // except for all indices that are indicated with an empty index set
    _ndims = 0;
    _nelems = 1;
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
      _ndims += dit->size() == 1? 0: 1;
      _nelems *= dit->size() != 0? dit->size(): _baseArray.getDim(dim);
      dit++;
    }
  }

  virtual T& operator()(const vector<size_t> &idx) {
    vector<size_t>::const_iterator it = idx.begin();
    size_t dim, size;
    const BaseArray<int> *iset;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      iset = _isets[dim - 1];
      size = iset? iset->getNumElems(): dit->size();
      switch (size) {
      case 0:
        // all indices
        _baseIdx[dim - 1] = *it++;
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        _baseIdx[dim - 1] = iset? (*iset)(*it++): (*dit)[*it++ - 1];
      }
    }
    return _baseArray(_baseIdx);
  }

  virtual void assign(const T* data) {
    setDataDim(1, data);
  }

  virtual void assign(const BaseArray<T>& otherArray) {
    setDataDim(1, otherArray.getData());
  }

  virtual std::vector<size_t> getDims() const {
    vector<size_t> dims;
    size_t dim, size;
    const BaseArray<int> *iset;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      iset = _isets[dim - 1];
      size = iset? iset->getNumElems(): dit->size();
      switch (size) {
      case 0:
        // all indices
        dims.push_back(_baseArray.getDim(dim));
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        dims.push_back(size);
      }
    }
    return dims;
  }

  virtual size_t getDim(size_t reducedDim) const {
    size_t dim, size, rdim = 1;
    const BaseArray<int> *iset;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      iset = _isets[dim - 1];
      size = iset? iset->getNumElems(): dit->size();
      switch (size) {
      case 0:
        // all indices
        if (reducedDim == rdim++)
          return _baseArray.getDim(dim);
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        if (reducedDim == rdim++)
          return size;
      }
    }
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDim out of range");
  }

  virtual T* getData() {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't get pointer to write to ArraySlice");
  }

  virtual const T* getData() const {
    if (_tmp_data.size() == 0)
      // allocate on first use
      _tmp_data.resize(_nelems);
    getDataDim(1, &_tmp_data[0]);
    return &_tmp_data[0];
  }

  virtual size_t getNumElems() const {
    return _nelems;
  }

  virtual size_t getNumDims() const {
    return _ndims;
  }

  virtual void setDims(const std::vector<size_t> &v) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't set dims of ArraySlice");
  }

  virtual void resize(const std::vector<size_t> &dims) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't resize ArraySlice");
  }

  virtual T& operator()(size_t i) {
    accessElement(1, i);
  }

  virtual const T& operator()(size_t i) const {
    accessElement(1, i);
  }

  virtual T& operator()(size_t  i, size_t j) {
    accessElement(2, i, j);
  }

  virtual T& operator()(size_t i, size_t j, size_t k) {
    accessElement(3, i, j, k);
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l) {
    accessElement(4, i, j, k, l);
  }

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m) {
    accessElement(5, i, j, k, l, m);
  }

 protected:
  BaseArray<T> &_baseArray;        // underlying array
  vector<const BaseArray<int>*> _isets; // given index sets per dimension
  vector< vector<size_t> > _idxs;  // created index sets per dimension
  size_t _ndims;                   // number of reduced dimensions
  size_t _nelems;                  // number of elements
  mutable vector<size_t> _baseIdx; // idx into underlying array
  mutable vector<T> _tmp_data;     // contiguous storage for const T* getData()

  // recursive method for muli-dimensional assignment of raw data
  size_t setDataDim(size_t dim, const T* data) {
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
      if (dim < _idxs.size())
        processed += setDataDim(dim + 1, data + processed);
      else
        _baseArray(_baseIdx) = data[processed++];
    }
    return processed;
  }

  // recursive method for reading raw data
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
      if (dim < _idxs.size())
        processed += getDataDim(dim + 1, data + processed);
      else
        data[processed++] = _baseArray(_baseIdx);
    }
    return processed;
  }

  T& accessElement(size_t ndims, ...) const {
    if (ndims != _ndims)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions accessing ArraySlice");
    size_t dim, size, i;
    const BaseArray<int> *iset;
    va_list args;
    va_start(args, ndims);
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      iset = _isets[dim - 1];
      size = iset? iset->getNumElems(): dit->size();
      switch (size) {
      case 0:
        // all indices
        i = va_arg(args, size_t);
        _baseIdx[dim - 1] = i;
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        i = va_arg(args, size_t);
        _baseIdx[dim - 1] = iset? (*iset)(i): (*dit)[i - 1];
      }
    }
    va_end(args);
    return _baseArray(_baseIdx);
  }
};
