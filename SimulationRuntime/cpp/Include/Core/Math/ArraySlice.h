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
    indices = NULL;
    nindices = 0;
  }

  // one index
  Slice(int index) {
    start = index;
    step = 1;
    stop = index;
    indices = NULL;
    nindices = 0;
  }

  Slice(int start, int stop) {
    this->start = start;
    step = 1;
    this->stop = stop;
    indices = NULL;
    nindices = 0;
  }

  Slice(int start, int step, int stop) {
    this->start = start;
    this->step = step;
    this->stop = stop;
    indices = NULL;
    nindices = 0;
  }

  Slice(const BaseArray<int> &ivec) {
    start = 0;
    step = 0;
    stop = 0;
    if (ivec.getNumDims() != 1)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Slice requires an index vector");
    // make shallow copy as ivec should live long enough in a Modelica model
    indices = ivec.getData();
    nindices = ivec.getNumElems();
  }

  size_t start;
  size_t step;
  size_t stop;
  const int *indices;
  int nindices;
};

// Multi-dimensional array slice holding a reference to a BaseArray.
template<class T>
class ArraySlice : public BaseArray<T> {
 public:
  ArraySlice(BaseArray<T> &baseArray, const vector<Slice> &slice)
    : BaseArray<T>(baseArray.isStatic())
    , _baseArray(baseArray)
    , _idxs(slice.size())
    , _baseIdx(slice.size()) {

    if (baseArray.getNumDims() != slice.size())
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                    "Wrong dimensions for ArraySlice");
    // create an explicit index set per dimension,
    // except for all indices that are indicated with an empty index set
    vector<Slice>::const_iterator sit;
    size_t dim;
    for (dim = 1, sit = slice.begin(); sit != slice.end(); dim++, sit++) {
      if (sit->step == 0)
        _idxs[dim - 1].assign(sit->indices, sit->indices + sit->nindices);
      else {
        size_t maxIndex = baseArray.getDims()[dim - 1];
        size_t start = sit->start > 0? sit->start: maxIndex;
        size_t stop = sit->stop > 0? sit->stop: maxIndex;
        if (start > maxIndex || stop > maxIndex)
          throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                        "Wrong slice exceeding array size");
        if (start > 1 || sit->step > 1 || stop < maxIndex)
          for (size_t i = start; i <= stop; i += sit->step)
            _idxs[dim - 1].push_back(i);
      }
    }
  }

  virtual T& operator()(const vector<size_t> &idx) {
    vector<size_t>::const_iterator it = idx.begin();
    vector< vector<size_t> >::const_iterator dit;
    size_t i, dim;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      switch (dit->size()) {
      case 0:
        // all indices
        i = *it++;
        break;
      case 1:
        // reduction
        i = (*dit)[0];
        break;
      default:
        // regular index mapping
        i = (*dit)[*it++ - 1];
      }
      _baseIdx[dim - 1] = i;
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
    size_t dim;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      switch (dit->size()) {
      case 0:
        // all indices
        dims.push_back(_baseArray.getDims()[dim - 1]);
        break;
      case 1:
        // reduction
        break;
      default:
        // regular index mapping
        dims.push_back(dit->size());
      }
    }
    return dims;
  }

  virtual size_t getDim(size_t reducedDim) const {
    size_t dim, rdim = 1;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++) {
      switch (dit->size()) {
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
          return dit->size();
      }
    }
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDim out of range");
  }

  virtual T* getData() {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't get data pointer of ArraySlice");
  }

  virtual const T* getData() const {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't get const data pointer of ArraySlice");
  }

  virtual size_t getNumElems() const {
    size_t nelems = 1;
    size_t dim;
    vector< vector<size_t> >::const_iterator dit;
    for (dim = 1, dit = _idxs.begin(); dit != _idxs.end(); dim++, dit++)
      nelems *= dit->size() != 0? dit->size(): _baseArray.getDims()[dim - 1];
    return nelems;
  }

  virtual size_t getNumDims() const {
    int ndims = 0;
    vector< vector<size_t> >::const_iterator dit;
    for (dit = _idxs.begin(); dit != _idxs.end(); dit++)
      ndims += dit->size() == 1? 0: 1;
    return ndims;
  }

  virtual void setDims(const std::vector<size_t> &v) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't set dims of ArraySlice");
  }

  virtual void resize(const std::vector<size_t> &dims) {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,
                                  "Can't resize ArraySlice");
  }

 protected:
  BaseArray<T> &_baseArray;
  vector< vector<size_t> > _idxs;
  vector<size_t> _baseIdx;

  // recursive method for muli-dimensional assignment of raw data
  size_t setDataDim(size_t dim, const T* data) {
    size_t processed = 0;
    size_t size = _idxs[dim - 1].size();
    if (size == 0)
      size = _baseArray.getDims()[dim - 1];
    for (size_t i = 1; i <= size; i++) {
      _baseIdx[dim - 1] = _idxs[dim - 1].size() > 0? _idxs[dim - 1][i - 1]: i;
      if (dim < _idxs.size())
        processed += setDataDim(dim + 1, data + processed);
      else
        _baseArray(_baseIdx) = data[processed++];
    }
    return processed;
  }
};
