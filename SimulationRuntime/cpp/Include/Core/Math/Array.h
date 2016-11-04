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
 * Add a const qualifier to force use of const methods
 */
template <typename T>
const T& ConstArray(T& arr)
{
  return arr;
}

/**
 * Wrapper to convert a string array to c_str array
 */
class CStrArray
{
 public:
  /**
   *  Constructor storing pointers
   */
  CStrArray(const BaseArray<string>& stringArray)
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

  /**
   * Write back to string array and free c strings if allocated
   */
  void writeBack(BaseArray<string>& stringArray)
  {
    string *data = stringArray.getData();
    for(size_t i = 0; i < _c_str_array.size(); i++) {
      data[i] = _c_str_array[i];
      _ModelicaFreeStringIfAllocated(_c_str_array[i]);
    }
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
                   _ref_array, CArray2RefArray<T>());
  }

  /**
   * Constuctor for reference array
   * intialize array with reference data from simvars memory
   */
  RefArray(T* const* ref_data)
    :BaseArray<T>(true, true)
  {
    if (nelems > 0)
      std::copy(ref_data, ref_data + nelems, _ref_array);
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
    std::transform(_ref_array, _ref_array + nelems, data,
                   _ref_array, CopyCArray2RefArray<T>());
  }

  /**
   * Assigns array data to array
   * @param b any array of type BaseArray
   * a.assign(b)
   */
  virtual void assign(const BaseArray<T>& b)
  {
    if(b.isRefArray())
      std::transform(_ref_array, _ref_array + nelems, b.getDataRefs(),
                     _ref_array, CopyRefArray2RefArray<T>());
    else
      std::transform(_ref_array, _ref_array + nelems, b.getData(),
                     _ref_array, CopyCArray2RefArray<T>());
  }

  /**
   * Access to data (read-only)
   */
  virtual const T* getData() const
  {
    std::transform(_ref_array, _ref_array + nelems, _tmp_data, RefArray2CArray<T>());
    return _tmp_data;
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
    assert(n <= nelems);
    std::transform(_ref_array, _ref_array + n, data, RefArray2CArray<T>());
  }

  /**
   * Access to data references (read-only)
   */
  virtual const T* const* getDataRefs() const
  {
    return _ref_array;
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
  T* _ref_array[nelems == 0? 1: nelems];
  mutable T _tmp_data[nelems == 0? 1: nelems]; // storage for const T* getData()
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
    assert(size > (idx[0] - 1));
    return *(RefArray<T, size>::_ref_array[idx[0]-1]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    assert(size > (idx[0] - 1));
    return *(RefArray<T, size>::_ref_array[idx[0]-1]);
  }

  /**
   * Index operator to access array element
   * @param index  index
   */
  inline virtual T& operator()(size_t index)
  {
    assert(size > (index - 1));
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
    assert((size1*size2) > ((idx[0]-1) + size1*(idx[1]-1)));
    return *(RefArray<T, size1*size2>::
             _ref_array[(idx[0]-1) + size1*(idx[1]-1)]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    assert((size1*size2) > ((idx[0]-1) + size1*(idx[1]-1)));
    return *(RefArray<T, size1*size2>::
             _ref_array[(idx[0]-1) + size1*(idx[1]-1)]);
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    assert((size1*size2) > ((i-1) + size1*(j-1)));
    return *(RefArray<T, size1*size2>::
             _ref_array[(i-1) + size1*(j-1)]);
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
    assert(size1*size2*size3 > idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1)));
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))]);
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    assert(size1*size2*size3 > idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1)));
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))]);
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   * @param k  index 3
   */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    assert(size1*size2*size3 > i-1 + size1*(j-1 + size2*(k-1)));
    return *(RefArray<T, size1*size2*size3>::
             _ref_array[i-1 + size1*(j-1 + size2*(k-1))]);
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
 * @param external indicates if the memory is provided externally
 */
template<typename T, std::size_t nelems, bool external = false>
class StatArray : public BaseArray<T>
{
 public:
  /**
   * Constuctor for static array
   * if external it just stores a pointer
   * else it copies data into array memory
   */
  StatArray(T* data)
    :BaseArray<T>(true, false)
  {
    if (external)
      _data = data;
    else {
      _data = _array;
      if (nelems > 0)
        std::copy(data, data + nelems, _data);
    }
  }

  /**
   * Constuctor for static array that
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArray(const StatArray<T, nelems, true>& otherarray)
    :BaseArray<T>(true, false)
  {
    if (external)
      _data = otherarray._data;
    else {
      _data = _array;
      otherarray.getDataCopy(_data, nelems);
    }
  }

  /**
   * Constuctor for static array that
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArray(const StatArray<T, nelems, false>& otherarray)
    :BaseArray<T>(true, false)
  {
    if (external)
      _data = otherarray._data;
    else {
      _data = _array;
      _array = otherarray._array;
    }
  }

  /**
   * Constuctor for static array that
   * lets otherarray copy data into array memory
   */
  StatArray(const BaseArray<T>& otherarray)
    :BaseArray<T>(true, false)
  {
    if (external)
      throw std::runtime_error("Unsupported copy constructor of static array with external storage!");
    _data = _array;
    otherarray.getDataCopy(_data, nelems);
  }

  /**
   * Default constuctor for static array
   */
  StatArray()
    :BaseArray<T>(true, false)
  {
    if (external)
      _data = NULL; // no data assigned yet
    else
      _data = _array;
  }

  virtual ~StatArray() {}

  /**
   * Assign static array with external storage to static array.
   * a = b
   * Just copy the data pointer if this array has external storage as well.
   * @param b any array of type StatArray
   */
  StatArray<T, nelems, external>&
  operator=(const StatArray<T, nelems, true>& b)
  {
    if (external)
      _data = b._data;
    else if (nelems > 0) {
      if (_data == NULL)
        throw std::runtime_error("Invalid assign operation from StatArray to uninitialized StatArray!");
      b.getDataCopy(_data, nelems);
    }
    return *this;
  }

  /**
   * Assign static array with internal storage to static array.
   * a = b
   * @param b any array of type StatArray
   */
  StatArray<T, nelems, external>&
  operator=(const StatArray<T, nelems, false>& b)
  {
    if (nelems > 0) {
      if (_data == NULL)
        throw std::runtime_error("Invalid assign operation from StatArray to uninitialized StatArray!");
      b.getDataCopy(_data, nelems);
    }
    return *this;
  }

  /**
   * Assignment operator to assign array of type base array to static array
   * a = b
   * @param b any array of type BaseArray
   */
  StatArray<T, nelems, external>& operator=(const BaseArray<T>& b)
  {
    if (nelems > 0) {
      if (_data == NULL)
        throw std::runtime_error("Invalid assign operation to uninitialized StatArray!");
      assert(b.getNumElems() == nelems);
      b.getDataCopy(_data, nelems);
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
    if (nelems > 0) {
      if (_data == NULL)
        throw std::runtime_error("Cannot assign data to uninitialized StatArray!");
      std::copy(data, data + nelems, _data);
    }
  }

  /**
   * Assigns array data to array
   * @param b any array of type BaseArray
   * a.assign(b)
   */
  virtual void assign(const BaseArray<T>& b)
  {
    if (nelems > 0) {
      if (_data == NULL)
        throw std::runtime_error("Cannot assign to uninitialized StatArray!");
      assert(b.getNumElems() == nelems);
      b.getDataCopy(_data, nelems);
    }
  }

  /**
   * Access to data
   */
  virtual T* getData()
  {
    return _data;
  }

  /**
   * Access to data (read-only)
   */
  virtual const T* getData() const
  {
    return _data;
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    if (n > 0)
      std::copy(_data, _data + n, data);
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
  T _array[external || nelems == 0? 1: nelems]; // static array
  T *_data; // array data
};

/**
 * One dimensional static array, specializes StatArray
 * @param T type of the array
 * @param size dimension of array
 * @param external indicates if the memory is provided externally
 */
template<typename T, std::size_t size, bool external = false>
class StatArrayDim1 : public StatArray<T, size, external>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim1(T* data)
    :StatArray<T, size, external>(data) {}

  /**
   * Constuctor for one dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim1(const StatArrayDim1<T, size, true>& otherarray)
    :StatArray<T, size, external>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim1(const StatArrayDim1<T, size, false>& otherarray)
    :StatArray<T, size, external>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim1(const BaseArray<T>& otherarray)
    :StatArray<T, size, external>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array
   * empty array
   */
  StatArrayDim1()
    :StatArray<T, size, external>() {}

  virtual ~StatArrayDim1() {}

  /**
   * Assign static array with external storage to static array.
   * a = b
   * Just copy the data pointer if this array has external storage as well.
   * @param b any array of type StatArray
   */
  StatArrayDim1<T, size, external>&
  operator=(const StatArrayDim1<T, size, true>& b)
  {
    StatArray<T, size, external>::operator=(b);
    return *this;
  }

  /**
   * Assign static array with internal storage to static array.
   * a = b
   * @param b any array of type StatArray
   */
  StatArrayDim1<T, size, external>&
  operator=(const StatArrayDim1<T, size, false>& b)
  {
    StatArray<T, size, external>::operator=(b);
    return *this;
  }

  /**
   * Assign array of type base array to one dim static array
   * a = b
   * @param b any array of type BaseArray
   */
  StatArrayDim1<T, size, external>& operator=(const BaseArray<T>& b)
  {
    StatArray<T, size, external>::operator=(b);
    return *this;
  }

  /**
   * Index operator to read array element
   * @param idx  vector of indices
   */
  virtual const T& operator()(const vector<size_t>& idx) const
  {
    return StatArray<T, size, external>::_data[idx[0]-1];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size, external>::_data[idx[0]-1];
  }

  /**
   * Index operator to access array element
   * @param index  index
   */
  inline virtual T& operator()(size_t index)
  {
    return StatArray<T, size, external>::_data[index - 1];
  }

  /**
   * Index operator to read array element
   * @param index  index
   */
  inline virtual const T& operator()(size_t index) const
  {
    return StatArray<T, size, external>::_data[index - 1];
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

  typedef const T* const_iterator;
  typedef T* iterator;

  iterator begin()
  {
    return StatArray<T, size, external>::_data;
  }

  iterator end()
  {
    return StatArray<T, size, external>::_data + size;
  }
};

/**
 * Two dimensional static array, specializes StatArray
 * @param T type of the array
 * @param size1  size of dimension one
 * @param size2  size of dimension two
 * @param external indicates if the memory is provided externally
 */
template<typename T, std::size_t size1, std::size_t size2, bool external = false>
class StatArrayDim2 : public StatArray<T, size1*size2, external>
{
 public:
  /**
   * Constuctor for two dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim2(T* data)
    :StatArray<T, size1*size2, external>(data) {}

  /**
   * Constuctor for two dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim2(const StatArrayDim2<T, size1, size2, true>& otherarray)
    :StatArray<T, size1*size2, external>(otherarray)
  {
  }

  /**
   * Constuctor for two dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim2(const StatArrayDim2<T, size1, size2, false>& otherarray)
    :StatArray<T, size1*size2, external>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim2(const BaseArray<T>& otherarray)
    :StatArray<T, size1*size2, external>(otherarray)
  {
  }

  /**
   * Default constuctor for two dimensional array
   */
  StatArrayDim2()
    :StatArray<T, size1*size2, external>() {}

  virtual ~StatArrayDim2(){}

  /**
   * Assign static array with external storage to static array.
   * a = b
   * Just copy the data pointer if this array has external storage as well.
   * @param b any array of type StatArray
   */
  StatArrayDim2<T, size1, size2, external>&
  operator=(const StatArrayDim2<T, size1, size2, true>& b)
  {
    StatArray<T, size1*size2, external>::operator=(b);
    return *this;
  }

  /**
   * Assign static array with internal storage to static array.
   * a = b
   * @param b any array of type StatArray
   */
  StatArrayDim2<T, size1, size2, external>&
  operator=(const StatArrayDim2<T, size1, size2, false>& b)
  {
    StatArray<T, size1*size2, external>::operator=(b);
    return *this;
  }

  /**
   * Assign array of type base array to two dim static array
   * a = b
   * @param b any array of type BaseArray
   */
  StatArrayDim2<T, size1, size2, external>& operator=(const BaseArray<T>& b)
  {
    StatArray<T, size1*size2, external>::operator=(b);
    return *this;
  }

  /**
   * Copies one dimensional array to row i
   * @param b array of type StatArrayDim1
   * @param i row number
   * @param n optional number of rows not needed for static arrays
   */
  void append(size_t i, const StatArrayDim1<T, size2, external>& b, size_t n = 0)
  {
    const T* data = b.getData();
    T *array_data = StatArray<T, size1*size2, external>::getData() + i-1;
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
    return StatArray<T, size1*size2, external>::_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size1*size2, external>::_data[idx[0]-1 + size1*(idx[1]-1)];
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return StatArray<T, size1*size2, external>::_data[i-1 + size1*(j-1)];
  }

 /**
  * Index operator to read array element
  * @param index  index
  */
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    return StatArray<T, size1*size2, external>::_data[i-1 + size1*(j-1)];
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
 * @param external indicates if the memory is provided externally
 */
template<typename T, std::size_t size1, std::size_t size2, std::size_t size3, bool external = false>
class StatArrayDim3 : public StatArray<T, size1*size2*size3, external>
{
 public:
  /**
   * Constuctor for one dimensional array
   * if reference array it uses data from simvars memory
   * else it copies data  in array memory
   */
  StatArrayDim3(T* data)
    :StatArray<T, size1*size2*size3, external>(data) {}

  /**
   * Constuctor for three dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim3(const StatArrayDim3<T, size1, size2, size3, true>& otherarray)
    :StatArray<T, size1*size2*size3, external>(otherarray)
  {
  }

  /**
   * Constuctor for three dimensional array
   * copies data from otherarray in array memory
   * or holds a pointer to otherarray's data
   */
  StatArrayDim3(const StatArrayDim3<T, size1, size2, size3, false>& otherarray)
    :StatArray<T, size1*size2*size3, external>(otherarray)
  {
  }

  /**
   * Constuctor for one dimensional array that
   * lets otherarray copy data into array memory
   */
  StatArrayDim3(const BaseArray<T>& otherarray)
    :StatArray<T, size1*size2*size3, external>(otherarray)
  {
  }

  /**
   * Default constuctor for three dimensional array
   */
  StatArrayDim3()
    :StatArray<T, size1*size2*size3, external>() {}

  virtual ~StatArrayDim3() {}

  /**
   * Assign static array with external storage to static array.
   * a = b
   * Just copy the data pointer if this array has external storage as well.
   * @param b any array of type StatArray
   */
  StatArrayDim3<T, size1, size2, size3, external>&
  operator=(const StatArrayDim3<T, size1, size2, size3, true>& b)
  {
    StatArray<T, size1*size2*size3, external>::operator=(b);
    return *this;
  }

  /**
   * Assign static array with internal storage to static array.
   * a = b
   * @param b any array of type StatArray
   */
  StatArrayDim3<T, size1, size2, size3, external>&
  operator=(const StatArrayDim3<T, size1, size2, size3, false>& b)
  {
    StatArray<T, size1*size2*size3, external>::operator=(b);
    return *this;
  }

  /**
   * Assign array of type base array to three dim static array
   * a = b
   * @param b any array of type BaseArray
   */
  StatArrayDim3<T, size1, size2, size3, external>&
  operator=(const BaseArray<T>& b)
  {
    StatArray<T, size1*size2*size3, external>::operator=(b);
    return *this;
  }

  /**
   * Copies two dimensional array to row i
   * @param b array of type StatArrayDim2
   * @param i row number
   * @param n optional number of rows not needed for static arrays
   */
  void append(size_t i, const StatArrayDim2<T,size2,size3>& b, size_t n = 0)
  {
    const T* data = b.getData();
    T *array_data = StatArray<T, size1*size2*size3, external>::getData() + i-1;
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
    return StatArray<T, size1*size2*size3, external>::
      _data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Index operator to write array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return StatArray<T, size1*size2*size3, external>::
      _data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   * @param k  index 3
   */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return StatArray<T, size1*size2*size3, external>::
      _data[i-1 + size1*(j-1 + size2*(k-1))];
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
    ,_dims(ndims)
  {
    _array_data = NULL;
    _nelems = 0;
  }

  /**
   * Copy constructor for DynArray
   */
  DynArray(const DynArray<T, ndims>& dynarray)
    :BaseArray<T>(false,false)
    ,_dims(ndims)
  {
    _array_data = NULL;
    _nelems = 0;
    assign(dynarray);
  }

  /**
   * Copy constructor for a general BaseArray
   */
  DynArray(const BaseArray<T>& b)
    :BaseArray<T>(false,false)
    ,_dims(ndims)
  {
    _array_data = NULL;
    _nelems = 0;
    assign(b);
  }

  virtual ~DynArray()
  {
    if (_array_data != NULL)
      delete [] _array_data;
  }

  virtual void assign(const BaseArray<T>& b)
  {
    resize(b.getDims());
    b.getDataCopy(_array_data, _nelems);
  }

  virtual void assign(const T* data)
  {
    if (_nelems > 0)
      std::copy(data, data + _nelems, _array_data);
  }

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims.size() != ndims)
      throw std::runtime_error("Can't change dimensionality of DynArray");
    if (dims != _dims) {
      size_t nelems = 0;
      if (dims.size() > 0)
        nelems = std::accumulate(dims.begin(), dims.end(),
                                 1, std::multiplies<size_t>());
      if (nelems != _nelems) {
        if (_array_data != NULL)
          delete [] _array_data;
        if (nelems > 0)
          _array_data = new T[nelems];
        else
          _array_data = NULL;
        _nelems = nelems;
      }
      _dims = dims;
    }
  }

  virtual void setDims(const std::vector<size_t>& dims)
  {
    resize(dims);
  }

  virtual std::vector<size_t> getDims() const
  {
    return _dims;
  }

  virtual int getDim(size_t dim) const
  {
    return (int)_dims[dim - 1];
  }

  /**
   * access to array data
   */
  virtual T* getData()
  {
    return _array_data;
  }

  /**
   * Copies the array data of size n in the data array
   * data has to be allocated before getDataCopy is called
   */
  virtual void getDataCopy(T data[], size_t n) const
  {
    if (n > 0)
       std::copy(_array_data, _array_data + n, data);
  }

  /**
   * access to data (read-only)
   */
  virtual const T* getData() const
  {
    return _array_data;
  }

  virtual size_t getNumElems() const
  {
    return _nelems;
  }

  virtual size_t getNumDims() const
  {
    return ndims;
  }

 protected:
  T *_array_data;
  size_t _nelems;
  std::vector<size_t> _dims;
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
  {
  }

  DynArrayDim1(const DynArrayDim1<T>& dynarray)
    :DynArray<T, 1>(dynarray)
  {
  }

  DynArrayDim1(const BaseArray<T>& b)
    :DynArray<T, 1>(b)
  {
  }

  DynArrayDim1(size_t size1)
    :DynArray<T, 1>()
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    this->resize(dims);
  }

  DynArrayDim1(size_t size1, const T *data)
    :DynArray<T, 1>()
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    this->resize(dims);
    if (size1 > 0)
      std::copy(data, data + size1, this->_array_data);
  }

  virtual ~DynArrayDim1()
  {
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1];
    return this->_array_data[idx[0]-1];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1];
    return this->_array_data[idx[0]-1];
  }

  inline virtual T& operator()(size_t index)
  {
    //return _multi_array[index-1];
    return this->_array_data[index-1];
  }

  inline virtual const T& operator()(size_t index) const
  {
    //return _multi_array[index-1];
    return this->_array_data[index-1];
  }

  DynArrayDim1<T>& operator=(const DynArrayDim1<T>& b)
  {
    this->assign(b);
    return *this;
  }

  void setDims(size_t size1)
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    this->resize(dims);
  }

  virtual void setDims(const std::vector<size_t>& dims)
  {
    this->resize(dims);
  }


  typedef const T* const_iterator;
  typedef T* iterator;

  iterator begin()
  {
    return this->_array_data;
  }

  iterator end()
  {
    return this->_array_data + this->_nelems;
  }
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
  {
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
    :DynArray<T, 2>(dynarray)
  {
  }

  DynArrayDim2(const BaseArray<T>& b)
    :DynArray<T, 2>(b)
  {
  }

  DynArrayDim2(size_t size1, size_t size2)
    :DynArray<T, 2>()
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    dims.push_back(size2);
    this->resize(dims);
  }

  virtual ~DynArrayDim2() {}

  /**
   * Copies one dimensional array to row i
   * @param b array of type DynArrayDim1
   * @param i row number
   * @param n number of rows
   */
  void append(size_t i, const DynArrayDim1<T>& b, size_t n)
  {
    //if the dynamic array was not allocate before
    if(this->_dims[0]==0 )
    {
        size_t m = b.getDim(1);
        if(n > 0 && m > 0)
          setDims(n,m);
        else
          throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Could not append array, wrong array dimensions");

    }
    const T* data = b.getData();
    T *array_data = this->_array_data + i-1;
    size_t size1 = this->_dims[0];
    size_t size2 = this->_dims[1];
    for (size_t j = 1; j <= size2; j++) {
      //(*this)(i, j) = b(j);
      *array_data = *data++;
      array_data += size1;
    }
  }

  DynArrayDim2<T>& operator=(const DynArrayDim2<T>& b)
  {
    this->assign(b);
    return *this;
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1][idx[1]-1];
    return this->_array_data[idx[0]-1 + this->_dims[0]*(idx[1]-1)];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1][idx[1]-1];
    return this->_array_data[idx[0]-1 + this->_dims[0]*(idx[1]-1)];
  }

  inline virtual T& operator()(size_t i, size_t j)
  {
    //return _multi_array[i-1][j-1];
    return this->_array_data[i-1 + this->_dims[0]*(j-1)];
  }

  inline virtual const T& operator()(size_t i, size_t j) const
  {
    //return _multi_array[i-1][j-1];
    return this->_array_data[i-1 + this->_dims[0]*(j-1)];
  }

  void setDims(size_t size1, size_t size2)
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    dims.push_back(size2);
    this->resize(dims);
  }
  virtual void setDims(const std::vector<size_t>& dims)
  {
      this->resize(dims);
  }
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
    :DynArray<T, 3>()
  {
  }

  DynArrayDim3(const BaseArray<T>& b)
    :DynArray<T, 3>(b)
  {
  }

  DynArrayDim3(size_t size1, size_t size2, size_t size3)
    :DynArray<T, 3>()
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    dims.push_back(size2);
    dims.push_back(size3);
    this->resize(dims);
  }

  virtual ~DynArrayDim3() {}

  DynArrayDim3<T>& operator=(const DynArrayDim3<T>& b)
  {
    this->assign(b);
    return *this;
  }

  void setDims(size_t size1, size_t size2, size_t size3)
  {
    std::vector<size_t> dims;
    dims.push_back(size1);
    dims.push_back(size2);
    dims.push_back(size3);
    this->resize(dims);
  }
  virtual void setDims(const std::vector<size_t>& dims)
  {
      this->resize(dims);
  }

  virtual const T& operator()(const vector<size_t>& idx) const
  {
    //return _multi_array[idx[0]-1][idx[1]-1][idx[2]-1];
    const std::vector<size_t>& shape = this->_dims;
    return this->_array_data[idx[0]-1 + shape[0]*(idx[1]-1 + shape[1]*(idx[2]-1))];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]-1][idx[1]-1][idx[2]-1];
    const std::vector<size_t>& shape = this->_dims;
    return this->_array_data[idx[0]-1 + shape[0]*(idx[1]-1 + shape[1]*(idx[2]-1))];
  }

  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    //return _multi_array[i-1][j-1][k-1];
    const std::vector<size_t>& shape = this->_dims;
    return this->_array_data[i-1 + shape[0]*(j-1 + shape[1]*(k-1))];
  }
};
/** @} */ // end of math
