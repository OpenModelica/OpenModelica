#pragma once
/** @defgroup math Core.Math
 *  Module for array operations and math functions
 *  @{
 */
     
/**
* forward declaration
*/
template <class T> class DynArrayDim1;
template <class T> class DynArrayDim2;
template <class T> class DynArrayDim3;

/**
* Operator class to assign simvar memory to a reference array
*/
template<typename T>
struct CArray2RefArray
{
  T* operator()(T& val)
  {
    return &val;
  }
};

/**
* Operator class to assign simvar memory to a c array
* used in getDataCopy methods:
* double data[4];
* A.getDataCopy(data,4)
*/
template<typename T>
struct RefArray2CArray
{
  const T& operator()(const T* val) const
  {
    return *val;
  }
};
/**
* Operator class to copy an c -array  to a reference array
*/
template<typename T>
struct CopyCArray2RefArray
{
 /**
  assign value to simvar
  @param val simvar
  @param val2 value
  */
  T* operator()(T* val,const T& val2)
  {
    *val=val2;
    return val;
  }
};

/**
* Operator class to copy the values of a reference array to a reference array
*/
template<typename T>
struct CopyRefArray2RefArray
{
  T* operator()(T* val, const T* val2)
  {
    *val = *val2;
    return val;
  }
};

/**
* Base class for all dynamic and static arrays
*/
template<typename T> class BaseArray
{
public:
  BaseArray(bool isStatic, bool isRefArray)
    :_isStatic(isStatic)
    ,_isRefArray(isRefArray)
  {}

  virtual ~BaseArray() {};

 /**
  * Interface methods for all arrays
  */
  virtual const T& operator()(const vector<size_t>& idx) const = 0;
  virtual T& operator()(const vector<size_t>& idx) = 0;
  virtual void assign(const T* data) = 0;
  virtual void assign(const BaseArray<T>& b) = 0;
  virtual std::vector<size_t> getDims() const = 0;
  virtual int getDim(size_t dim) const = 0; // { (int)getDims()[dim - 1]; }

  virtual size_t getNumElems() const = 0;
  virtual size_t getNumDims() const = 0;
  virtual void setDims(const std::vector<size_t>& v) = 0;
  virtual void resize(const std::vector<size_t>& dims) = 0;
  virtual const T* getData() const = 0;
  virtual T* getData() = 0;
  virtual void getDataCopy(T data[], size_t n) const = 0;
  virtual const T* const* getDataRefs() const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array getDataRefs call");
  }

  virtual T& operator()(size_t i)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual const T& operator()(size_t i) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(size_t i, size_t j)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual const T& operator()(size_t i, size_t j) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(size_t i, size_t j, size_t k)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  bool isStatic() const
  {
    return _isStatic;
  }

  bool isRefArray() const
  {
    return _isRefArray;
  }

protected:
  bool _isStatic;
  bool _isRefArray;
};

/**
 * Wrapper to convert a string array to c_str array
 */
class CStrArray
{
 public:
  /**
   *  Constructor storing pointers
   */
  CStrArray(const BaseArray<string> &stringArray)
    :_c_str_array(stringArray.getNumElems())
  {
    const string *data = stringArray.getData();
    for(size_t i = 0; i < _c_str_array.size(); i++)
      _c_str_array[i] = data[i].c_str();
  }

  /**
   * Convert to c_str array
   */
  operator const char**()
  {
    return &_c_str_array[0];
  }

 private:
  vector<const char *> _c_str_array;
};

/**
 * Base class for array of references to externally stored elements
 * @param T type of the array
 * @param nelems number of elements of array
 */
template<typename T, std::size_t nelems>
class RefArray : public BaseArray<T>
{
public:
  /**
   * Constuctor for reference array
   * it uses data from simvars memory
   */
  RefArray(T* data)
    :BaseArray<T>(true, true)
  {
    std::transform(data, data + nelems,
                   _ref_array.c_array(), CArray2RefArray<T>());
  }

  /**
   * Constuctor for reference array
   * intialize array with reference data from simvars memory
   */
  RefArray(T* const* ref_data)
    :BaseArray<T>(true, true)
  {
    std::copy(ref_data, ref_data + nelems, _ref_array.c_array());
  }

  /**
   * Default constuctor for reference array
   * empty array
   */
  RefArray()
    :BaseArray<T>(true, true)
  {
  }

  virtual ~RefArray() {}

  /**
   * Assigns data to array
   * @param data  new array data
   * a.assign(data)
   */
  virtual void assign(const T* data)
  {
    T **refs = _ref_array.c_array();
    std::transform(refs, refs + nelems, data,
                   refs, CopyCArray2RefArray<T>());
  }

  /**
   * Assigns array data to array
   * @param b any array of type BaseArray
   * a.assign(b)
   */
  virtual void assign(const BaseArray<T>& b)
  {
    T **refs = _ref_array.c_array();
    if(b.isRefArray())
      std::transform(refs, refs + nelems, b.getDataRefs(),
                     refs, CopyRefArray2RefArray<T>());
    else
      std::transform(refs, refs + nelems, b.getData(),
                     refs, CopyCArray2RefArray<T>());
  }

  /**
   * Access to data (read-only)
   */
  virtual const T* getData() const
  {
    const T* const* refs  = _ref_array.begin();
    T* data  = _tmp_data.c_array();
    std::transform(refs, refs + nelems, data, RefArray2CArray<T>());
    return data;
  }

  /**
   * Access to c-array data
   */
  virtual T* getData()
  {
    throw std::runtime_error("Access data of reference array is not supported");
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    const T* const * simvars_data  = _ref_array.begin();
    std::transform(simvars_data, simvars_data + n, data, RefArray2CArray<T>());
  }

  /**
   * Access to data references (read-only)
   */
  virtual const T* const* getDataRefs() const
  {
    return _ref_array.data();
  }

  /**
   * Returns number of elements
   */
  virtual size_t getNumElems() const
  {
    return nelems;
  }

  virtual void setDims(const std::vector<size_t>& v) {  }

  /**
   * Resize array method
   * @param dims vector with new dimension sizes
   * static array could not be resized
   */
  virtual void resize(const std::vector<size_t>& dims)
  {
    throw std::runtime_error("Resize reference array is not supported");
  }

protected:
  //reference array data
  boost::array<T*, nelems> _ref_array;
  mutable boost::array<T, nelems> _tmp_data; // storage for const T* getData()
};

/**
 * One dimensional static reference array, specializes RefArray
 * @param T type of the array
 * @param size dimension of array
 */
template<typename T, std::size_t size>
class RefArrayDim1 : public RefArray<T, size>
{
public:
  /**
   * Constuctor for one dimensional reference array
   * it uses data from simvars memory
   */
  RefArrayDim1(T* data) : RefArray<T, size>(data) {}

  /**
   * Constuctor for one dimensional reference array
   * intialize array with reference data from simvars memory
   */
  RefArrayDim1(T* const* ref_data) : RefArray<T, size>(ref_data) {}

  /**
   * Default constuctor for one dimensional reference array
   */
  RefArrayDim1() : RefArray<T, size>() {}

  virtual ~RefArrayDim1() {}

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return *(RefArray<T, size>::_ref_array[idx[0]-1]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return *(RefArray<T, size>::_ref_array[idx[0]-1]);
  }

  /**
   * Index operator to access array element
   * @param index  index
   */
  inline virtual T& operator()(size_t index)
  {
    return *(RefArray<T, size>::_ref_array[index-1]);
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }

  /**
   * Return size of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    return (int)size;
  }

  /**
   * Returns number of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 1;
  }
};

/**
 * Two dimensional static reference array, specializes RefArray
 * @param T type of the array
 * @param size1  size of dimension one
 * @param size2  size of dimension two
 */
template<typename T, std::size_t size1, std::size_t size2>
class RefArrayDim2 : public RefArray<T, size1*size2>
{
public:
 /**
  * Constuctor for two dimensional reference array
  * it uses data from simvars memory
  */
  RefArrayDim2(T* data) : RefArray<T, size1*size2>(data) {}

 /**
  * Constuctor for two dimensional reference array
  * intialize array with reference data from simvars memory
  */
  RefArrayDim2(T* const* ref_data) : RefArray<T, size1*size2>(ref_data) {}

  virtual ~RefArrayDim2() {}

 /**
  * Default constuctor for two dimensional reference array
  */
  RefArrayDim2() : RefArray<T, size1*size2>() {}

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return *(RefArray<T, size1*size2>::
             _ref_array[(idx[0]-1)*size2 + (idx[1]-1)]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return *(RefArray<T, size1*size2>::
             _ref_array[(idx[0]-1)*size2 + (idx[1]-1)]);
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return *(RefArray<T, size1*size2>::
             _ref_array[(i-1)*size2 + (j-1)]);
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  /**
   * Return size of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 2;
  }
};

/**
 * Three dimensional static reference array, specializes RefArray
 * @param  T type of the array
 * @param size1  size of dimension one
 * @param size2  size of dimension two
 * @param size3  size of dimension two
 */
template<typename T, std::size_t size1, std::size_t size2, std::size_t size3>
class RefArrayDim3 : public RefArray<T, size1*size2*size3>
{
public:
 /**
  * Constuctor for three dimensional reference array
  * it uses data from simvars memory
  */
  RefArrayDim3(T* data) : RefArray<T, size1*size2*size3>(data) {}

 /**
  * Constuctor for three dimensional reference array
  * intialize array with reference data from simvars memory
  */
  RefArrayDim3(T* const* ref_data) : RefArray<T, size1*size2*size3>(ref_data) {}

 /**
  * Default constuctor for three dimensional reference array
  */
  RefArrayDim3() : RefArray<T, size1*size2*size3>() {}

  virtual ~RefArrayDim3() {}

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    return v;
  }

  /**
   * Return size of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    case 3:
      return (int)size3;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[size3*(idx[0]-1 + size2*(idx[1]-1)) + idx[2]-1]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[size3*(idx[0]-1 + size2*(idx[1]-1)) + idx[2]-1]);
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   * @param k  index 3
   */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[size3*(i-1 + size2*(j-1)) + (k-1)]);
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 3;
  }
};

/**
 * Static array, implements BaseArray interface methods
 * @param T type of the array
 * @param nelems number of elements of array
 */
template<typename T, std::size_t nelems>
class StatArray : public BaseArray<T>
{
 public:
  /**
   * Constuctor for static array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArray(const T* data)
    :BaseArray<T>(true, false)
  {
    std::copy(data, data + nelems, _array_data.begin());
  }

  /**
   * Constuctor for static array that
   * copies data from otherarray in array memory
   */
  StatArray(const StatArray<T, nelems>& otherarray)
    :BaseArray<T>(true, false)
  {
    _array_data = otherarray._array_data;
  }

  /**
   * Constuctor for static array that
   * lets otherarray copy data into array memory
   */
  StatArray(const BaseArray<T>& otherarray)
    :BaseArray<T>(true, false)
  {
    otherarray.getDataCopy(_array_data.begin(), nelems);
  }

  /**
   * Default constuctor for static array
   * empty array
   */
  StatArray()
    :BaseArray<T>(true,false)
  {
  }

  virtual ~StatArray() {}

  /**
   * Assignment operator to assign array of type base array to static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatArray<T, nelems>& operator=(BaseArray<T>& b)
  {
    if (this != &b)
    {
      b.getDataCopy(_array_data.begin(), nelems);
    }
    return *this;
  }

  /**
   * Resize array method
   * @param dims vector with new dimension sizes
   * static array could not be resized
   */
  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != this->getDims())
      throw std::runtime_error("Cannot resize static array!");
  }

  /**
   * Assigns data to array
   * @param data  new array data
   * a.assign(data)
   */
  virtual void assign(const T* data)
  {
    std::copy(data, data + nelems, _array_data.begin());
  }

  /**
   * Assigns array data to array
   * @param b any array of type BaseArray
   * a.assign(b)
   */
  virtual void assign(const BaseArray<T>& b)
  {
    b.getDataCopy(_array_data.begin(), nelems);
  }

  /**
   * Access to data
   */
  virtual T* getData()
  {
    return _array_data.c_array();
  }

  /**
   * Access to data (read-only)
   */
  virtual const T* getData() const
  {
    return _array_data.data();
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    const T *array_data = _array_data.data();
    std::copy(array_data, array_data + n, data);
  }

  /**
   * Returns number of elements
   */
  virtual size_t getNumElems() const
  {
    return nelems;
  }

  virtual void setDims(const std::vector<size_t>& v) {}

 protected:
  //static array data
  boost::array<T,nelems> _array_data;
};

/**
* One dimensional static array, specializes StatArray
* @param T type of the array
* @param size dimension of array
*/
template<typename T, std::size_t size>
class StatArrayDim1 : public StatArray<T, size>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim1(const T* data)
    :StatArray<T, size>(data) {}

  /**
   * Constuctor for one dimensional array
   * copies data from otherarray in array memory
   */
  StatArrayDim1(const StatArrayDim1<T,size>& otherarray)
    :StatArray<T, size>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim1(const BaseArray<T>& otherarray)
    :StatArray<T, size>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array
   * empty array
   */
  StatArrayDim1()
    :StatArray<T, size>() {}

  virtual ~StatArrayDim1() {}

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatArray<T, size>::_array_data[idx[0]-1];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size>::_array_data[idx[0]-1];
  }

  /**
   * Assignment operator to assign array of type base array to  two dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatArrayDim1<T, size>& operator=(BaseArray<T>& b)
  {
    StatArray<T, size>::operator=(b);
     return *this;
  }
  /**
   * Index operator to access array element
   * @param index  index
   */
  inline virtual T& operator()(size_t index)
  {
    return StatArray<T, size>::_array_data[index - 1];
  }

  /**
   * Index operator to read array element
   * @param index  index
   */
  inline virtual const T& operator()(size_t index) const
  {
    return StatArray<T, size>::_array_data[index - 1];
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }

  /**
   * Return sizes of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    return (int)size;
  }

  /**
   * Returns number of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 1;
  }

  void setDims(size_t size1)  { }

  typedef typename boost::array<T,size>::const_iterator const_iterator;
  typedef typename boost::array<T,size>::iterator iterator;

  iterator begin()
  {
    return StatArray<T, size>::_array_data.begin();
  }

  iterator end()
  {
    return StatArray<T, size>::_array_data.end();
  }
};

/**
 * Two dimensional static array, specializes StatArray
 * @param T type of the array
 * @param size1  size of dimension one
 * @param size2  size of dimension two
 */
template<typename T, std::size_t size1, std::size_t size2>
class StatArrayDim2 : public StatArray<T, size1*size2>
{
 public:
  /**
   * Constuctor for two dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim2(const T* data)
    :StatArray<T, size1*size2>(data) {}

  /**
   * Default constuctor for two dimensional array
   * empty array
   */
  StatArrayDim2()
    :StatArray<T, size1*size2>() {}

  /**
   * Constuctor for two dimensional array
   * copies data from otherarray in array memory
   */
  StatArrayDim2(const StatArrayDim2<T, size1, size2>& otherarray)
    :StatArray<T, size1*size2>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim2(const BaseArray<T>& otherarray)
    :StatArray<T, size1*size2>(otherarray)
  {
  }

  virtual ~StatArrayDim2(){}

  /**
   * Copies one dimensional array to row i
   * @param b array of type StatArrayDim1
   * @param i row number
   */
  void append(size_t i,const StatArrayDim1<T,size2>& b)
  {
    const T* data = b.getData();
    T *array_data = StatArray<T, size1*size2>::getData() + i-1;
    for (size_t j = 1; j <= size2; j++) {
      //(*this)(i, j) = b(j);
      *array_data = *data++;
      array_data += size1;
    }
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatArray<T, size1*size2>::_array_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size1*size2>::_array_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Assignment operator to assign array of type base array to  one dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatArrayDim2<T, size1,size2>& operator=(BaseArray<T>& b)
  {
    StatArray<T, size1*size2>::operator=(b);
    return *this;
  }
  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return StatArray<T, size1*size2>::_array_data[i-1 + size1*(j-1)];
  }

 /**
  * Index operator to read array element
  * @param index  index
  */
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    return StatArray<T, size1*size2>::_array_data[i-1 + size1*(j-1)];
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  /**
   * Return size of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 2;
  }

  void setDims(size_t i, size_t j) {}
};

/**
* Three dimensional static array, implements BaseArray interface methods
* @param  T type of the array
* @param size1  size of dimension one
* @param size2  size of dimension two
* @param size3  size of dimension two
*/
template<typename T, std::size_t size1, std::size_t size2, std::size_t size3>
class StatArrayDim3 : public StatArray<T, size1*size2*size3>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim3(const T* data)
    :StatArray<T, size1*size2*size3>(data) {}

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim3(const BaseArray<T>& otherarray)
    :StatArray<T, size1*size2>(otherarray)
  {
  }

  /**
   * Default constuctor for two dimensional array
   * empty array
   */
  StatArrayDim3()
    :StatArray<T, size1*size2*size3>() {}

  virtual ~StatArrayDim3() {}

  /**
   * Copies two dimensional array to row i
   * @param b array of type StatArrayDim2
   * @param i row number
   */
  void append(size_t i, const StatArrayDim2<T,size2,size3>& b)
  {
    const T* data = b.getData();
    T *array_data = StatArray<T, size1*size2*size3>::getData() + i-1;
    for (size_t k = 1; k <= size3; k++) {
      for (size_t j = 1; j <= size2; j++) {
        //(*this)(i, j, k) = b(j, k);
        *array_data = *data++;
        array_data += size1;
      }
    }
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    return v;
  }

  /**
   * Return sizes of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    case 3:
      return (int)size3;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatArray<T, size1*size2*size3>::
      _array_data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size1*size2*size3>::
      _array_data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Assignment operator to assign array of type base array to  three dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatArrayDim3<T, size1,size2,size3>& operator=(BaseArray<T>& b)
  {
     StatArray<T, size1*size2*size3>::operator=(b);
      return *this;
  }
  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   * @param k  index 3
   */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return StatArray<T, size1*size2*size3>::
      _array_data[i-1 + size1*(j-1 + size2*(k-1))];
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 3;
  }

  void setDims(size_t i, size_t j, size_t k) {}
};


/**
 * Static array that has no internal array storage, implements BaseArray interface methods
 * @param T type of the array
 * @param nelems number of elements of array
 */
template<typename T, std::size_t nelems>
class StatRefArray : public BaseArray<T>
{
 public:
  /**
   * Constructor for static array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatRefArray(T* data)
    : BaseArray<T>(true, false)
  {
    _array_data = data;
  }

  /**
   * Constuctor for static array that
   * copies data from otherarray in array memory
   */
  StatRefArray(const StatArray<T, nelems>& otherarray)
    : BaseArray<T>(true, false)
  {
    _array_data = otherarray._array_data;
  }

  /**
   * Constuctor for static array that
   * lets otherarray copy data into array memory
   */
  StatRefArray(const BaseArray<T>& otherarray)
    : BaseArray<T>(true, false)
  {
    _array_data = otherarray._array_data;
  }

  /**
   * Default constuctor for static array
   * empty array
   */
  StatRefArray()
    : BaseArray<T>(true,false)
  {
    _array_data = NULL;
  }

  virtual ~StatRefArray() {}

  /**
   * Assignment operator to assign array of type base array to static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatRefArray<T, nelems>& operator=(BaseArray<T>& b)
  {
    if (this != &b)
    {
      b.getDataCopy(_array_data, nelems);
    }
    return *this;
  }

  /**
   * Resize array method
   * @param dims vector with new dimension sizes
   * static array could not be resized
   */
  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != this->getDims())
      throw std::runtime_error("Cannot resize static array!");
  }

  /**
   * Assigns data to array
   * @param data  new array data
   * a.assign(data)
   */
  virtual void assign(const T* data)
  {
    std::copy(data, data + nelems, _array_data);
  }

  /**
   * Assigns array data to array
   * @param b any array of type BaseArray
   * a.assign(b)
   */
  virtual void assign(const BaseArray<T>& b)
  {
    b.getDataCopy(_array_data, nelems);
  }

  /**
   * Access to data
   */
  virtual T* getData()
  {
    return _array_data;
  }

  /**
   * Access to data (read-only)
   */
  virtual const T* getData() const
  {
    return _array_data;
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    std::copy(_array_data, _array_data + n, data);
  }

  /**
   * Returns number of elements
   */
  virtual size_t getNumElems() const
  {
    return nelems;
  }

  virtual void setDims(const std::vector<size_t>& v) {}

 protected:
  //static array data
  T* _array_data;
};

template<typename T, std::size_t size>
class StatRefArrayDim1 : public StatRefArray<T, size>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatRefArrayDim1(T* data)
    : StatRefArray<T, size>(data) {}

  /**
   * Constuctor for one dimensional array
   * copies data from otherarray in array memory
   */
  StatRefArrayDim1(const StatArrayDim1<T,size>& otherarray)
    : StatRefArray<T, size>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatRefArrayDim1(const BaseArray<T>& otherarray)
    : StatRefArray<T, size>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array
   * empty array
   */
  StatRefArrayDim1()
    :StatRefArray<T, size>() {}

  virtual ~StatRefArrayDim1() {}

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatRefArrayDim1<T, size>::_array_data[idx[0]-1];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatRefArrayDim1<T, size>::_array_data[idx[0]-1];
  }

  /**
   * Assignment operator to assign array of type base array to  two dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatRefArrayDim1<T, size>& operator=(BaseArray<T>& b)
  {
    StatRefArrayDim1<T, size>::operator=(b);
    return *this;
  }
  /**
   * Index operator to access array element
   * @param index  index
   */
  inline virtual T& operator()(size_t index)
  {
    return StatRefArrayDim1<T, size>::_array_data[index - 1];
  }

  /**
   * Index operator to read array element
   * @param index  index
   */
  inline virtual const T& operator()(size_t index) const
  {
    return StatRefArrayDim1<T, size>::_array_data[index - 1];
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }

  /**
   * Return sizes of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    return (int)size;
  }

  /**
   * Returns number of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 1;
  }

  void setDims(size_t size1)  { }
};

/**
 * Two dimensional static array, specializes StatArray
 * @param T type of the array
 * @param size1  size of dimension one
 * @param size2  size of dimension two
 */
template<typename T, std::size_t size1, std::size_t size2>
class StatRefArrayDim2 : public StatRefArray<T, size1*size2>
{
 public:
  /**
   * Constuctor for two dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatRefArrayDim2(T* data)
    : StatRefArray<T, size1*size2>(data) {}

  /**
   * Default constuctor for two dimensional array
   * empty array
   */
  StatRefArrayDim2()
    : StatRefArray<T, size1*size2>() {}

  /**
   * Constuctor for two dimensional array
   * copies data from otherarray in array memory
   */
  StatRefArrayDim2(const StatArrayDim2<T, size1, size2>& otherarray)
    : StatRefArray<T, size1*size2>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatRefArrayDim2(const BaseArray<T>& otherarray)
    : StatRefArray<T, size1*size2>(otherarray)
  {
  }

  virtual ~StatRefArrayDim2() {}

  /**
   * Copies one dimensional array to row i
   * @param b array of type StatArrayDim1
   * @param i row number
   */
  void append(size_t i,const StatArrayDim1<T,size2>& b)
  {
    const T* data = b.getData();
    T *array_data = StatRefArray<T, size1*size2>::getData() + i-1;
    for (size_t j = 1; j <= size2; j++) {
      //(*this)(i, j) = b(j);
      *array_data = *data++;
      array_data += size1;
    }
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatRefArray<T, size1*size2>::_array_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatRefArray<T, size1*size2>::_array_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Assignment operator to assign array of type base array to  one dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatRefArrayDim2<T, size1,size2>& operator=(BaseArray<T>& b)
  {
    StatRefArray<T, size1*size2>::operator=(b);
    return *this;
  }
  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return StatRefArray<T, size1*size2>::_array_data[i-1 + size1*(j-1)];
  }

 /**
  * Index operator to read array element
  * @param index  index
  */
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    return StatRefArray<T, size1*size2>::_array_data[i-1 + size1*(j-1)];
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  /**
   * Return size of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 2;
  }

  void setDims(size_t i, size_t j) {}
};

/**
* Three dimensional static array, implements BaseArray interface methods
* @param  T type of the array
* @param size1  size of dimension one
* @param size2  size of dimension two
* @param size3  size of dimension two
*/
template<typename T, std::size_t size1, std::size_t size2, std::size_t size3>
class StatRefArrayDim3 : public StatRefArray<T, size1*size2*size3>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatRefArrayDim3(T* data)
    : StatRefArray<T, size1*size2*size3>(data) {}

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatRefArrayDim3(const BaseArray<T>& otherarray)
    : StatRefArray<T, size1*size2>(otherarray)
  {
  }

  /**
   * Default constuctor for two dimensional array
   * empty array
   */
  StatRefArrayDim3()
    : StatRefArray<T, size1*size2*size3>() {}

  virtual ~StatRefArrayDim3() {}

  /**
   * Copies two dimensional array to row i
   * @param b array of type StatArrayDim2
   * @param i row number
   */
  void append(size_t i, const StatRefArrayDim2<T,size2,size3>& b)
  {
    const T* data = b.getData();
    T *array_data = StatRefArray<T, size1*size2*size3>::getData() + i-1;
    for (size_t k = 1; k <= size3; k++) {
      for (size_t j = 1; j <= size2; j++) {
        //(*this)(i, j, k) = b(j, k);
        *array_data = *data++;
        array_data += size1;
      }
    }
  }

  /**
   * Return sizes of dimensions
   */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    return v;
  }

  /**
   * Return sizes of one dimension
   */
  virtual int getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return (int)size1;
    case 2:
      return (int)size2;
    case 3:
      return (int)size3;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatRefArray<T, size1*size2*size3>::
      _array_data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatRefArray<T, size1*size2*size3>::
      _array_data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Assignment operator to assign array of type base array to  three dim static array
   * a=b
   * @param b any array of type BaseArray
   */
  virtual StatRefArrayDim3<T, size1,size2,size3>& operator=(BaseArray<T>& b)
  {
     StatRefArray<T, size1*size2*size3>::operator=(b);
     return *this;
  }
  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   * @param k  index 3
   */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return StatRefArray<T, size1*size2*size3>::
      _array_data[i-1 + size1*(j-1 + size2*(k-1))];
  }

  /**
   * Return sizes of dimensions
   */
  virtual size_t getNumDims() const
  {
    return 3;
  }

  void setDims(size_t i, size_t j, size_t k) {}
};

/**
 * Dynamically allocated array, implements BaseArray interface methods
 * @param T type of the array
 * @param ndims number of dimensions of array
 */
template<typename T, size_t ndims>
class DynArray : public BaseArray<T>
{
 public:
  /**
   * Constructor for given sizes
   */
  DynArray()
    :BaseArray<T>(false,false)
    ,_multi_array(vector<size_t>(ndims, 0), boost::fortran_storage_order())
  {
  }

  /**
   * Copy constructor for DynArray
   */
  DynArray(const DynArray<T,ndims>& dynarray)
    :BaseArray<T>(false,false)
    ,_multi_array(dynarray.getDims(), boost::fortran_storage_order())
  {
    _multi_array = dynarray._multi_array;
  }

  /**
   * Copy constructor for a general BaseArray
   */
  DynArray(const BaseArray<T>& b)
    :BaseArray<T>(false,false)
    ,_multi_array(b.getDims(), boost::fortran_storage_order())
  {
    b.getDataCopy(_multi_array.data(), _multi_array.num_elements());
  }

  virtual ~DynArray() {}

  virtual void assign(const BaseArray<T>& b)
  {
    _multi_array.resize(b.getDims());
    b.getDataCopy(_multi_array.data(), _multi_array.num_elements());
  }

  virtual void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements());
  }

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
    {
      _multi_array.resize(dims);
    }
  }

  virtual void setDims(const std::vector<size_t>& dims)
  {
    _multi_array.resize(dims);
  }

  virtual std::vector<size_t> getDims() const
  {
    const size_t* shape = _multi_array.shape();
    std::vector<size_t> dims;
    dims.assign(shape, shape + ndims);
    return dims;
  }

  virtual int getDim(size_t dim) const
  {
    return (int)_multi_array.shape()[dim - 1];
  }

  /**
   * access to array data
   */
  virtual T* getData()
  {
    return _multi_array.data();
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    const T *array_data = _multi_array.data();
    std::copy(array_data, array_data + n, data);
  }

  /**
   * access to data (read-only)
   */
  virtual const T* getData() const
  {
    return _multi_array.data();
  }

  virtual size_t getNumElems() const
  {
    return _multi_array.num_elements();
  }

  virtual size_t getNumDims() const
  {
    return ndims;
  }

 protected:
  boost::multi_array<T, ndims> _multi_array;
};

/**
 * Dynamically allocated one dimensional array, specializes DynArray
 * @param T type of the array
 */
template<typename T>
class DynArrayDim1 : public DynArray<T, 1>
{
  friend class DynArrayDim2<T>;
 public:
  DynArrayDim1()
    :DynArray<T, 1>()
    ,_multi_array(DynArray<T, 1>::_multi_array)
  {
  }

  DynArrayDim1(const DynArrayDim1<T>& dynarray)
    :DynArray<T, 1>(dynarray)
    ,_multi_array(DynArray<T, 1>::_multi_array)
  {
  }

  DynArrayDim1(const BaseArray<T>& b)
    :DynArray<T, 1>(b)
    ,_multi_array(DynArray<T, 1>::_multi_array)
  {
  }

  DynArrayDim1(size_t size1)
    :DynArray<T, 1>()
    ,_multi_array(DynArray<T, 1>::_multi_array)
  {
    _multi_array.resize(boost::extents[size1]);
  }

  virtual ~DynArrayDim1()
  {
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1];
    return _multi_array.data()[idx[0]-1];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1];
    return _multi_array.data()[idx[0]-1];
  }

  inline virtual T& operator()(size_t index)
  {
    //return _multi_array[index-1];
    return _multi_array.data()[index-1];
  }

  inline virtual const T& operator()(size_t index) const
  {
    //return _multi_array[index-1];
    return _multi_array.data()[index-1];
  }

  DynArrayDim1<T>& operator=(const DynArrayDim1<T>& b)
  {
    if (this != &b)
    {
      _multi_array.resize(b.getDims());
      _multi_array = b._multi_array;
    }
    return *this;
  }

  void setDims(size_t size1)
  {
    _multi_array.resize(boost::extents[size1]);
  }

  typedef typename boost::multi_array<T, 1>::const_iterator const_iterator;
  typedef typename boost::multi_array<T, 1>::iterator iterator;

  iterator begin()
  {
    return _multi_array.begin();
  }

  iterator end()
  {
    return _multi_array.end();
  }

 private:
  boost::multi_array<T, 1> &_multi_array; // refers to base class
};

/**
 * Dynamically allocated two dimensional array, specializes DynArray
 * @param T type of the array
 */
template<typename T>
class DynArrayDim2 : public DynArray<T, 2>
{
 public:
  DynArrayDim2()
    :DynArray<T, 2>()
    ,_multi_array(DynArray<T, 2>::_multi_array)
  {
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
    :DynArray<T, 2>(dynarray)
    ,_multi_array(DynArray<T, 2>::_multi_array)
  {
  }

  DynArrayDim2(const BaseArray<T>& b)
    :DynArray<T, 2>(b)
    ,_multi_array(DynArray<T, 2>::_multi_array)
  {
  }

  DynArrayDim2(size_t size1, size_t size2)
    :DynArray<T, 2>()
    ,_multi_array(DynArray<T, 2>::_multi_array)
  {
    _multi_array.resize(boost::extents[size1][size2]);
  }

  virtual ~DynArrayDim2() {}

  void append(size_t i, const DynArrayDim1<T>& b)
  {
    _multi_array[i-1] = b._multi_array;
  }

  DynArrayDim2<T>& operator=(const DynArrayDim2<T>& b)
  {
    if (this != &b)
    {
      _multi_array.resize(b.getDims());
      _multi_array = b._multi_array;
    }
    return *this;
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1][idx[1]-1];
    return _multi_array.data()[idx[0]-1 + _multi_array.shape()[0]*(idx[1]-1)];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1][idx[1]-1];
    return _multi_array.data()[idx[0]-1 + _multi_array.shape()[0]*(idx[1]-1)];
  }

  inline virtual T& operator()(size_t i, size_t j)
  {
    //return _multi_array[i-1][j-1];
    return _multi_array.data()[i-1 + _multi_array.shape()[0]*(j-1)];
  }

  inline virtual const T& operator()(size_t i, size_t j) const
  {
    //return _multi_array[i-1][j-1];
    return _multi_array.data()[i-1 + _multi_array.shape()[0]*(j-1)];
  }

  void setDims(size_t size1, size_t size2)
  {
    _multi_array.resize(boost::extents[size1][size2]);
  }

 private:
  boost::multi_array<T, 2> &_multi_array; // refers to base class
};

/**
 * Dynamically allocated three dimensional array, specializes DynArray
 * @param T type of the array
 */
template<typename T>
class DynArrayDim3 : public DynArray<T, 3>
{
public:
  DynArrayDim3()
    :DynArray<T, 3>(boost::extents[0][0][0])
    ,_multi_array(DynArray<T, 3>::_multi_array)
  {
  }

  DynArrayDim3(const BaseArray<T>& b)
    :DynArray<T, 3>(b)
    ,_multi_array(DynArray<T, 3>::_multi_array)
  {
  }

  DynArrayDim3(size_t size1, size_t size2, size_t size3)
    :DynArray<T, 3>()
    ,_multi_array(DynArray<T, 3>::_multi_array)
  {
    _multi_array.resize(boost::extents[size1][size2][size3]);
  }

  virtual ~DynArrayDim3(){}

  DynArrayDim3<T>& operator=(const DynArrayDim3<T>& b)
  {
    if (this != &b)
    {
      _multi_array.resize(b.getDims());
      _multi_array = b._multi_array;
    }
    return *this;
  }
 
  void setDims(size_t size1, size_t size2, size_t size3)
  {
    _multi_array.resize(boost::extents[size1][size2][size3]);
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1][idx[1]-1][idx[2]-1];
    const size_t *shape = _multi_array.shape();
    return _multi_array.data()[idx[0]-1 + shape[0]*(idx[1]-1 + shape[1]*(idx[2]-1))];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1][idx[1]-1][idx[2]-1];
    const size_t *shape = _multi_array.shape();
    return _multi_array.data()[idx[0]-1 + shape[0]*(idx[1]-1 + shape[1]*(idx[2]-1))];
  }

  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    //return _multi_array[i-1][j-1][k-1];
    const size_t *shape = _multi_array.shape();
    return _multi_array.data()[i-1 + shape[0]*(j-1 + shape[1]*(k-1))];
  }

 private:
  boost::multi_array<T, 3> &_multi_array; // refers to base class
};
/** @} */ // end of math

