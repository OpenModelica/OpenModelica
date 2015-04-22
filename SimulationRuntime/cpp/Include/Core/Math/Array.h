#pragma once

/**
* forward declaration
*/
template <class T> class DynArrayDim1;
template <class T> class DynArrayDim2;
template <class T> class DynArrayDim3;

/**
* Operator class to assign simvar memory to a reference array
*/
template<class T>
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
template<class T>
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
template<class T>
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
* Operator class to assign a reference array  to a reference array
*/
template<class T>
struct RefArray2RefArray
{
    T* operator()(T* val,T* val2)
    {
        return val;
    }
};

/**
* Operator class to copy the values of a reference array to a reference array
*/
template<class T>
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
template<class T>class BaseArray
{
public:
  BaseArray(bool is_static,bool isReference)
    :_static(is_static)
    ,_isReference(isReference)
  {}

 /**
  * Interface methods for all arrays
  */
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
  virtual const T* const* getDataReferences() const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array getDataReferences call");
  }
  virtual const char** getCStrData()
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array getCStrData call");
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
    return _static;
  }

  bool isReference() const
  {
    return _isReference;
  }

protected:
  bool _static;
  bool _isReference;
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
  RefArray(T** ref_data)
    :BaseArray<T>(true, true)
  {
    T **refs = _ref_array.c_array();
    std::transform(refs, refs + nelems, ref_data,
                   refs, RefArray2RefArray<T>());
  }

  /**
   * Default constuctor for reference array
   * empty array
   */
  RefArray()
    :BaseArray<T>(true, true)
  {
  }

  ~RefArray() {}

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
    if(b.isReference())
      std::transform(refs, refs + nelems, b.getDataReferences(),
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
    std::runtime_error("Access const data of reference array is not supported");
  }

  /**
   * Access to c-array data
   */
  virtual T* getData()
  {
    std::runtime_error("Access data of reference array is not supported");
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
  virtual const T* const* getDataReferences() const
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
    std::runtime_error("Resize reference array is not supported");
  }

protected:
  //reference array data
  boost::array<T*, nelems> _ref_array;
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
  RefArrayDim1(T* data) : RefArray<T,size>(data) { }

  /**
   * Constuctor for one dimensional reference array
   * intialize array with reference data from simvars memory
   */
  RefArrayDim1(T** ref_data) : RefArray<T,size>(ref_data) { }

  /**
   * Index operator to access array element
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
  RefArrayDim2(T* data) : RefArray<T,size1*size2>(data) { }

 /**
  * Constuctor for two dimensional reference array
  * intialize array with reference data from simvars memory
  */
  RefArrayDim2(T** ref_data) : RefArray<T,size1*size2>(ref_data) { }

  /**
   * Index operator to access array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return *(RefArray<T, size1*size2>::
             _ref_array[idx[0]-1 + size1*(idx[1]-1)]);
  }

  /**
   * Index operator to access array element
   * @param i  index 1
   * @param j  index 2
   */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return *(RefArray<T, size1*size2>::
             _ref_array[i-1 + size1*(j-1)]);
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
  RefArrayDim3(T* data) : RefArray<T,size1*size2*size3>(data) { }

 /**
  * Constuctor for three dimensional reference array
  * intialize array with reference data from simvars memory
  */
  RefArrayDim3(T** ref_data) : RefArray<T,size1*size2*size3>(ref_data) { }

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
   * Index operator to access array element
   * @param idx  vector of indices
   */
  virtual T& operator()(const vector<size_t>& idx)
  {
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
* One dimensional static array, implements BaseArray interface methods
* @param T type of the array
* @param size dimension of array
*/
template<typename T, std::size_t size>
class StatArrayDim1 : public BaseArray<T>
{
public:
 /**
  * Constuctor for one dimensional array
  * if reference array it uses data from simvars memory
  * else it copies data  in array memory
  */
  StatArrayDim1(T* data)
    :BaseArray<T>(true, false)
  {
    memcpy( _array_data.begin(), data, size * sizeof( T ) );
  }

 /**
  * Constuctor for one dimensional array
  * copies data from otherarray in array memory
  */
  StatArrayDim1(const StatArrayDim1<T,size>& otherarray)
    :BaseArray<T>(true, false)
  {
    _array_data = otherarray._array_data;
  }

 /**
  * Constuctor for one dimensional array
  * copies data  from dynamic array in array memory
  */
  StatArrayDim1(const DynArrayDim1<T>& otherarray)
    :BaseArray<T>(true, false)
  {
    memcpy( _array_data.begin(), otherarray.getData(), size * sizeof( T ) );
  }

 /**
  * Constuctor for one dimensional array
  * empty array
  */
  StatArrayDim1()
    :BaseArray<T>(true,false)
  {
  }

  ~StatArrayDim1() {}

   /**
    * Assignment operator to assign array of type base array to static array
    * a=b
    * @param b any array of type BaseArray
    */
    StatArrayDim1<T,size>& operator=(BaseArray<T>& b)
    {
        if (this != &b)
        {
          b.getDataCopy(_array_data.begin(), size);
        }
        return *this;
    }

   /**
    *Resize array method
    *@param dims vector with new dimension sizes
    *static array could not be resized
    */
    virtual void resize(const std::vector<size_t>& dims)
    {
        if (dims != getDims())
            std::runtime_error("Cannot resize static array!");
    }

   /**
    * Assigns data to array
    * @param data  new array data
    * a.assign(data)
    */
    virtual void assign(const T* data)
    {
      memcpy( _array_data.begin(), data, size * sizeof( T ) );
    }

   /**
    * Assigns array data to array
    * @param b any array of type BaseArray
    * a.assign(b)
    */
    virtual void assign(const BaseArray<T>& b)
    {
      b.getDataCopy(_array_data.begin(), size);
    }

 /**
  * Index operator to access array element
  * @param idx  vector of indices
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return _array_data[idx[0]-1];
  }

 /**
  * Index operator to access array element
  * @param index  index
  */
  inline virtual T& operator()(size_t index)
  {
    return _array_data[index - 1];
  }

 /**
  * Index operator to read array element
  * @param index  index
  */
  inline virtual const T& operator()(unsigned int index) const
  {
    return _array_data[index - 1];
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


  virtual int getDim(size_t dim) const
  {
    return (int)size;
  }

 /**
  * Access to c-array data
  */
  virtual T* getData()
  {
    return _array_data.c_array();
  }

 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    memcpy(data,  _array_data.begin(), n * sizeof( T ) );
  }

 /**
  * Access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _array_data.data();
  }

 /**
  * Returns number of elements
  */

  virtual size_t getNumElems() const
  {
    return size;
  }

 /**
  * Returns number of dimensions
  */

  virtual size_t getNumDims() const
  {
    return 1;
  }

  virtual void setDims(const std::vector<size_t>& v) {  }
  void setDims(size_t size1)  { }

  typedef typename boost::array<T,size>::const_iterator                              const_iterator;
  typedef typename  boost::array<T,size>::iterator                                   iterator;
  iterator begin()
  {
    return   _array_data.begin();
  }
  iterator end()
  {
    return   _array_data.end();
  }

private:
  //static array data
  boost::array<T,size> _array_data;
};

/**
* Specialization for string 1-dim arrays, implements BaseArray interface methods
*/
template<std::size_t size>class StatArrayDim1<string,size> : public BaseArray<string>
{

public:
  StatArrayDim1(const string data[])
    :BaseArray<string>(true,false)
  {
    for(int i=0;i<size;i++)
    {
      _array_data[i]=data[i];
    }

    for(int i=0;i<size;i++)
    {
      _c_array_data[i]=_array_data[i].c_str();
    }

  }

  StatArrayDim1(const StatArrayDim1<string,size>& otherarray)
    :BaseArray<string>(true,false)
  {
    _array_data = otherarray._array_data;
    for(int i=0;i<size;i++)
    {
      _c_array_data[i]=_array_data[i].c_str();
    }
  }
  StatArrayDim1(const DynArrayDim1<string>& otherarray)
    :BaseArray<string>(true,false)
  {

  }

  StatArrayDim1()
    :BaseArray<string>(true,false)
  {
  }

  ~StatArrayDim1() {}



  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }

    StatArrayDim1<string,size>& operator=(BaseArray<string>& b)
    {
        if (this != &b)
        {

            try
            {
                if(b.isStatic())
                {
                    StatArrayDim1<string,size>&  a = dynamic_cast<StatArrayDim1<string,size>&  >(b);
                    _array_data = a._array_data;
                    for(int i=0;i<size;i++)
                    {
                        _c_array_data[i]=_array_data[i].c_str();
                    }
                }
                else
                {
                    for(size_t i=0;i<size;i++)
                    {
                        _array_data[i]=b(i);
                        _c_array_data[i]=_array_data[i].c_str();
                    }
                }
            }
            catch(std::bad_exception & be)
            {
                throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong array type assign");

            }

        }
        return *this;
    }
    StatArrayDim1<string,size>& operator=(const StatArrayDim1<string,size>& b)
    {
        if (this != &b)
        {
            _array_data= b._array_data;
            for(int i=0;i<size;i++)
            {
                _c_array_data[i]=_array_data[i].c_str();
            }
        }
        return *this;
    }

  virtual void assign(const string data[])
  {
    for(int i=0;i<size;i++)
    {
      _array_data[i]=data[i];
      _c_array_data[i]=_array_data[i].c_str();
    }

  }


    virtual void assign(const BaseArray<string>& b)
    {
        for(int i=0;i<size;i++)
        {
            _array_data[i]=b(i);
            _c_array_data[i]=_array_data[i].c_str();
        }

  }
  virtual string& operator()(const vector<size_t>& idx)
  {
    return _array_data[idx[0]-1];
  };


  inline virtual string& operator()(size_t index)
  {
    return _array_data[index - 1];
  }
  inline virtual const string& operator()(size_t index) const
  {
    return _array_data[index - 1];
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }


  virtual int getDim(size_t dim) const
  {
    return (int)size;
  }

 /**
  * access to data
  */
  virtual string* getData()
  {
    return _array_data.c_array();
  }

 /**
  * access to data (read-only)
  */
  virtual const string* getData() const
  {
    return _array_data.data();
  }
  virtual const char** getCStrData()
  {
    return _c_array_data.c_array();
  }
 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(string data[], size_t n) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDataCopy for one dim string array not supported");
  }

  virtual size_t getNumElems() const
  {
    return size;
  }
  virtual size_t getNumDims() const
  {
    return 1;
  }

  virtual void setDims(const std::vector<size_t>& v) {  }
  void setDims(size_t size1)  { }

  typedef typename boost::array<string,size>::const_iterator                              const_iterator;
  typedef typename  boost::array<string,size>::iterator                                   iterator;
  iterator begin()
  {
    return   _array_data.begin();
  }
  iterator end()
  {
    return   _array_data.end();
  }

private:
  boost::array<string,size> _array_data;
  boost::array<const char*, size> _c_array_data;
};


/**
* Two dimensional static array, implements BaseArray interface methods
* @param T type of the array
* @param size1  size of dimension one
* @param size2  size of dimension two
*/
template<typename T, std::size_t size1, std::size_t size2>
class StatArrayDim2 : public BaseArray<T>
{
public:
 /**
  * Constuctor for two dimensional array
  * if reference array it uses data from simvars memory
  * else it copies data  in array memory
  */
  StatArrayDim2(T* data)
    :BaseArray<T>(true, false)
  {
    memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );
  }

  /**
  * Constuctor for two dimensional array
  * empty array
  */
  StatArrayDim2()
    :BaseArray<T>(true, false)
  {
  }

 /**
  * Constuctor for two dimensional array
  * copies data from otherarray in array memory
  */
  StatArrayDim2(const StatArrayDim2<T,size1,size2>& otherarray)
    :BaseArray<T>(true, false)
  {
    _array_data = otherarray._array_data;
  }

   /**
    * Assignment operator to assign array of type base array to static array
    * a=b
    * @param b any array of type BaseArray
    */
    StatArrayDim2<T,size1,size2>& operator=(BaseArray<T>& b)
    {

        if (this != &b)
        {
            b.getDataCopy(_array_data.begin(), size1*size2);
        }
        return *this;
    }

    ~StatArrayDim2(){}

   /**
    * Copies one dimensional array to row i
    * \@param b array of type StatArrayDim1
    * \@param i row number
    */
    void append(size_t i,const StatArrayDim1<T,size2>& b)
    {
        const T* data = b.getData();
        T *array_data = _array_data.c_array() + i-1;
        for (size_t j = 1; j <= size2; j++) {
          //(*this)(i, j) = b(j);
          *array_data = *data++;
          array_data += size1;
        }
    }

   /**
    * Resize array method
    * static array could not be resized
    * @param dims vector with new dimension sizes
    */
    virtual void resize(const std::vector<size_t>& dims)
    {
        if (dims != getDims())
            std::runtime_error("Cannot resize static array!");
    }

   /**
    * Assigns array data to array
    * @param b any array of type BaseArray
    * a.assign(b)
    */
    virtual void assign(const BaseArray<T>& b)
    {
      b.getDataCopy(_array_data.begin(), size1*size2);
    }

   /**
    * Assigns array data to array
    * @param dims vector with new dimension sizes data array data
    * a.assign(data)
    */
    virtual void assign(const T* data)
    {
      memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );
    }

 /**
  * Index operator to access array element
  * @param idx  vector of indices
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return _array_data[idx[0]-1 + size1*(idx[1]-1)];
  }

 /**
  * Index operator to access array element
  * @param i  index 1
  * @param j  index 2
  */
  inline virtual T& operator()(size_t i, size_t j)
  {
    return _array_data[i-1 + size1*(j-1)];
  }

 /**
  * Index operator to read array element
  * @param index  index
  */
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    return _array_data[i-1 + size1*(j-1)];
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
  * Returns number of elements
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

  virtual size_t getNumElems() const
  {
    return size1 * size2;
  }

 /**
  * Return sizes of dimensions
  */
  virtual size_t getNumDims() const
  {
    return 2;
  }

 /**
  * Access to data
  */
  virtual T* getData()
  {
    return _array_data.c_array();
  }

 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    memcpy(data,  _array_data.begin(), n * sizeof( T ) );
  }

 /**
  * Access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _array_data.data();
  }

  virtual void setDims(const std::vector<size_t>& v) {  }
  void setDims(size_t i,size_t j)  {  }
private:
  //static array data
  boost::array<T, size2 * size1> _array_data;
};


/**
* Specialization for string 2-dim arrays, implements BaseArray interface methods
*/
template<std::size_t size1,std::size_t size2>
class StatArrayDim2<string,size1,size2> : public BaseArray<string>
{

public:
  StatArrayDim2(const string data[])
    :BaseArray<string>(true,false)
  {

    std::copy(data,data+size1*size2,_array_data.begin());
    for(int i=0;i<size1;i++)
    {
      for(int j=0;j<size2;j++)
      {
        _c_array_data[i + size1*j] = _array_data[i + size1*j].c_str();
      }
    }
  }

  StatArrayDim2()
    :BaseArray<string>(true,false)
  {

  }

  StatArrayDim2(const StatArrayDim2<string,size1,size2>& otherarray)
    :BaseArray<string>(true,false)
  {
    _array_data = otherarray._array_data;

        for(int i=0;i<size1;i++)
        {
            for(int j=0;j<size2;j++)
            {
                _c_array_data[i + size1*j] = _array_data[i + size1*j].c_str();
            }
        }
    }
    StatArrayDim2<string,size1,size2>& operator=(const StatArrayDim2<string,size1,size2>& b)
    {
        if (this != &b)
        {
            _array_data = b._array_data;
            for(int i=0;i<size1;i++)
            {
                for(int j=0;j<size2;j++)
                {
                    _c_array_data[i + size1*j] = _array_data[i + size1*j].c_str();
                }
            }
        }
        return *this;
    }

    StatArrayDim2<string,size1,size2>& operator=(BaseArray<string>& b)
    {
        if (this != &b)
        {
            try
            {
                StatArrayDim2<string,size1,size2>& a = dynamic_cast<StatArrayDim2<string,size1,size2>& >(b);
                _array_data = a._array_data;
                for(int i=0;i<size1;i++)
                {
                    for(int j=0;j<size2;j++)
                    {
                        _c_array_data[i + size1*j] = _array_data[i + size1*j].c_str();
                    }
                }
            }
            catch(std::bad_exception & be)
            {
                throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong array type assign");
            }
        }
        return *this;
    }

  ~StatArrayDim2(){}

    void append(size_t i,const StatArrayDim1<string,size2>& b)
    {

    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"append not supported for 2-dim string array");
  }

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }

    virtual void assign(const BaseArray<string>& b)
    {
        std::vector<size_t> v;
        v = b.getDims();
        const string* data_otherarray = b.getData();
        std::copy(data_otherarray,data_otherarray+size1*size2,_array_data.begin());
        for(int i=0;i<size1;i++)
        {
            for(int j=0;j<size2;j++)
            {
                const char* c_str_data = _array_data[i + size1*j].c_str();
                _c_array_data[i + size1*j] = c_str_data;
            }
        }
    }

  virtual void assign(const string data[])//)const T (&data) [size1*size2]
  {
    std::copy(data,data+size1*size2,_array_data.begin());
    for(int i=0;i<size1;i++)
    {
      for(int j=0;j<size2;j++)
      {
        const char* c_str_data = _array_data[i + size1*j].c_str();
        _c_array_data[i + size1*j] = c_str_data;
      }
    }
  }
  virtual string& operator()(const vector<size_t>& idx)
  {
    return _array_data[idx[0]-1 + size1*(idx[1]-1)];
  };

  inline virtual string& operator()(size_t i, size_t j)
  {
    return _array_data[i-1 + size1*(j-1)];
  }
  inline virtual const string& operator()(size_t i, size_t j) const
  {
    return _array_data[i-1 + size1*(j-1)];
  }


  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

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

  virtual size_t getNumElems() const
  {
    return size1 * size2;
  }

  virtual size_t getNumDims() const
  {
    return 2;
  }
 /**
  * Access to data
  */
  virtual string* getData()
  {
    return _array_data. c_array();
  }
 /**
  * Access to data (read-only)
  */
  virtual const string* getData() const
  {
    return _array_data.data();
  }
 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(string data[], size_t n) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDataCopy for one dim string array not supported");
  }
  virtual const char** getCStrData()
  {

    return _c_array_data.c_array();
  }

  virtual void setDims(const std::vector<size_t>& v) {  }
  void setDims(size_t i,size_t j)  {  }
private:

  boost::array<string, size2 * size1> _array_data;
  boost::array<const char*,size2 * size1> _c_array_data;

};

/**
* Three dimensional static array, implements BaseArray interface methods
* @param  T type of the array
* @param size1  size of dimension one
* @param size2  size of dimension two
* @param size3  size of dimension two
*/
template<typename T, std::size_t size1, std::size_t size2, std::size_t size3>
class StatArrayDim3 : public BaseArray<T>
{
public:
 /**
  * Constuctor for one dimensional array
  * if reference array it uses data from simvars memory
  * else it copies data  in array memory
  */
  StatArrayDim3(T* data)
    :BaseArray<T>(true, false)
  {
    memcpy( _array_data.begin(), data, size1*size2*size3 * sizeof( T ) );
  }

 /**
  * Constuctor for two dimensional array
  * empty array
  */
  StatArrayDim3()
    :BaseArray<T>(true, false)
  {
  }

  ~StatArrayDim3()
  {}

   /**
    * Assigns array data to array
    * @param b any array of type BaseArray
    * a.assign(b)
    */
    virtual  void assign(const BaseArray<T>& b)
    {
      b.getDataCopy(_array_data.begin(), size1*size2*size3);
    }

   /**
    * Assigns array data to array
    * @param data array data
    * a.assign(data)
    */
    virtual void assign(const T* data)
    {
      memcpy( _array_data.begin(), data, size1*size2*size3*sizeof( T ) );
    }

   /**
    * Copies two dimensional array to row i
    * @param b array of type StatArrayDim2
    * @param i row number
    */
    void append(size_t i,const StatArrayDim2<T,size2,size3>& b)
    {
        const T* data = b.getData();
        T *array_data = _array_data.c_array() + i-1;
        for (size_t k = 1; k <= size3; k++) {
          for (size_t j = 1; j <= size2; j++) {
            //(*this)(i, j, k) = b(j, k);
            *array_data = *data++;
            array_data += size1;
          }
        }
    }

 /**
  * Resize array method
  * @param dims vector with new dimension sizes
  * static array could not be resized
  */
  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
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
  * Assignment operator to assign static array
  * @param rhs array of type StatArrayDim3
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
    * Assignment operator to assign static array
    * @param b array of type StatArrayDim3
    * a=b
    */
    StatArrayDim3<T,size1,size2,size3>& operator=(const BaseArray<T>& b)
    {
        if (this != &b)
        {
          b.getDataCopy(_array_data.begin(), size1*size2*size3);
        }
        return *this;
    }

 /**
  * Index operator to access array element
  * @param idx  vector of indices
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    return _array_data[idx[0]-1 + size1*(idx[1]-1 + size2*(idx[2]-1))];
  }

 /**
  * Index operator to access array element
  * @param i  index 1
  * @param j  index 2
  * @param k  index 3
  */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return _array_data[i-1 + size1*(j-1 + size2*(k-1))];
  }

 /**
  * Returns number of elements
  */
  virtual size_t getNumElems() const
  {
    return size1 * size2 * size3;
  }

 /**
  * Return sizes of dimensions
  */
  virtual size_t getNumDims() const
  {
    return 3;
  }

  virtual void setDims(const std::vector<size_t>& v) { }
  void setDims(size_t i,size_t j,size_t k)  { }

 /**
  * Access to data
  */
  virtual T* getData()
  {
    return _array_data.c_array();
  }

 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    memcpy(data,  _array_data.begin(), n * sizeof( T ) );
  }

 /**
  * Access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _array_data.data();
  }

private:
  //static array data
  boost::array<T, size2 * size1*size3> _array_data;
};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




template<typename T>class DynArrayDim1 : public BaseArray<T>
{
  friend class DynArrayDim2<T>;
public:


  DynArrayDim1()
    :BaseArray<T>(false,false)
  {
    _multi_array.reindex(1);
  }

  DynArrayDim1(const DynArrayDim1<T>& dynarray)
    :BaseArray<T>(false,false)
  {
    //assign(dynarray);
    setDims(dynarray.getDim(1));
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

  DynArrayDim1(size_t size1)
    :BaseArray<T>(false,false)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }

    DynArrayDim1(const BaseArray<T>& b)
        :BaseArray<T>(false,false)
    {
        std::vector<size_t> v = b.getDims();
        if(v.size()!=1)
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim1");
        _multi_array.resize(v);
        _multi_array.reindex(1);
        const T* data_otherarray = b.getData();
        _multi_array.assign(data_otherarray,data_otherarray+v[0]);
    }


  ~DynArrayDim1()
  {
  }



  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
    {
      _multi_array.resize(dims);
      _multi_array.reindex(1);
    }
  }

    virtual  void assign(const BaseArray<T>& b)
    {
        std::vector<size_t> v = b.getDims();

        resize(v);
        const T* data_otherarray = b.getData();
        _multi_array.assign(data_otherarray,data_otherarray+ v[0]);


  }

  virtual void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }


  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]];
    return _multi_array.data()[idx[0]-1];
  }
  inline virtual T& operator()(size_t index)
  {
    //return _multi_array[index];
    return _multi_array.data()[index-1];
  }
  inline virtual const T& operator()(size_t index) const
  {
    //return _multi_array[index];
    return _multi_array.data()[index-1];
  }
    DynArrayDim1<T>& operator=(const DynArrayDim1<T>& b)
    {
        if (this != &b)
        {
            std::vector<size_t> v = b.getDims();
            _multi_array.resize(v);
            _multi_array.reindex(1);
            _multi_array = b._multi_array;

        }
        return *this;
    }
  void setDims(size_t size1)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(const std::vector<size_t>& v)
  {
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual std::vector<size_t> getDims() const
  {
    const size_t* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 1 );
    return ex;
  }

  virtual int getDim(size_t dim) const
  {
    return (int)_multi_array.shape()[dim - 1];
  }
 /**
  * access to data (read-only)
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
     const T* array_data = _multi_array.data();
    memcpy(data, array_data, n * sizeof( T ) );
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
    return 1;
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
  boost::multi_array<T, 1> _multi_array;
};


template<typename T >class DynArrayDim2 : public BaseArray<T>
{

public:
  DynArrayDim2()
    :BaseArray<T>(false,false)
    ,_multi_array(boost::extents[0][0], boost::fortran_storage_order())
  {
    _multi_array.reindex(1);
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
    :BaseArray<T>(false,false)
    ,_multi_array(boost::extents[0][0], boost::fortran_storage_order())
  {
    //assign(dynarray);
    setDims(dynarray.getDim(1), dynarray.getDim(2));
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

    DynArrayDim2(const BaseArray<T>& b)
        :BaseArray<T>(false,false)
        ,_multi_array(boost::extents[0][0], boost::fortran_storage_order())
    {
        std::vector<size_t> v = b.getDims();
        if(v.size()!=2)
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim2");
        _multi_array.resize(v);
        _multi_array.reindex(1);
        b.getDataCopy(_multi_array.data(), v[0]*v[1]);

  }

  DynArrayDim2(size_t size1, size_t size2)
    :BaseArray<T>(false,false)
    ,_multi_array(boost::extents[size1][size2], boost::fortran_storage_order())
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }
  ~DynArrayDim2(){}

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
    {
      _multi_array.resize(dims);
      _multi_array.reindex(1);
    }
  }
    virtual  void assign(const BaseArray<T>& b)
    {
        std::vector<size_t> v = b.getDims();
        resize(v);
        b.getDataCopy(_multi_array.data(), v[0]*v[1]);

    }
    void append(size_t i, const DynArrayDim1<T>& b)
    {
        _multi_array[i] = b._multi_array;
    }
    DynArrayDim2<T>& operator=(const DynArrayDim2<T>& b)
    {
        if (this != &b)  //oder if (*this != b)
        {
            std::vector<size_t> v = b.getDims();
            _multi_array.resize(v);
            _multi_array.reindex(1);
            _multi_array = b._multi_array;

    }
    return *this;
  }
  virtual void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }
  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]][idx[1]];
    return _multi_array.data()[idx[0]-1 + _multi_array.shape()[0]*(idx[1]-1)];
  }
  inline virtual T& operator()(size_t i, size_t j)
  {
    //return _multi_array[i][j];
    return _multi_array.data()[i-1 + _multi_array.shape()[0]*(j-1)];
  }
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    //return _multi_array[i][j];
    return _multi_array.data()[i-1 + _multi_array.shape()[0]*(j-1)];
  }

  void setDims(size_t size1, size_t size2)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(const std::vector<size_t>& v)
  {
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual std::vector<size_t> getDims() const
  {
    const size_t* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 2 );
    return ex;
  }

  virtual int getDim(size_t dim) const
  {
    return (int)_multi_array.shape()[dim - 1];
  }

  virtual size_t getNumElems() const
  {
    return _multi_array.num_elements();
  }
  virtual size_t getNumDims() const
  {
    return 2;
  }

 /**
  * access to data
  */
  virtual T* getData()
  {
    return _multi_array.data();
  }
 /**
  * access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _multi_array.data();
  }
 /**
  * Copies the array data of size n in the data array
  * data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    const T* array_data = _multi_array.data();
    memcpy(data, array_data, n * sizeof( T ) );
  }

private:
  boost::multi_array<T, 2> _multi_array;
};


template<typename T> class DynArrayDim3 : public BaseArray<T>
{
  //friend class ArrayDim3<T, size1, size2, size3>;
public:
  DynArrayDim3()
    :BaseArray<T>(false,false)
    ,_multi_array(boost::extents[0][0][0], boost::fortran_storage_order())
  {
    _multi_array.reindex(1);
  }

    DynArrayDim3(size_t size1, size_t size2, size_t size3)
        :BaseArray<T>(false,false)
        ,_multi_array(boost::extents[size1][size2][size3],
                      boost::fortran_storage_order())
    {
        std::vector<size_t> v;
        v.push_back(size1);
        v.push_back(size2);
        v.push_back(size3);
        _multi_array.resize(v);//
        _multi_array.reindex(1);
    }
    DynArrayDim3(const BaseArray<T>& b)
        :BaseArray<T>(false,false)
        ,_multi_array(boost::extents[0][0][0], boost::fortran_storage_order())
    {
        std::vector<size_t> v = b.getDims();
        if(v.size()!=3)
            throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim3");
        _multi_array.resize(v);
        _multi_array.reindex(1);
        const T* data_otherarray = b.getData();
        _multi_array.assign(data_otherarray,data_otherarray+v[0]*v[1]*v[3]);
    }
    ~DynArrayDim3(){}
   /**
    void assign(DynArrayDim3<T> b)
    {
    std::vector<size_t> v = b.getDims();
    _multi_array.resize(v);
    _multi_array.reindex(1);
    T* data = b._multi_array.data();
    _multi_array.assign(data, data + v[0]*v[1]*v[2]);
    }
    */

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
    {
      _multi_array.resize(dims);
      _multi_array.reindex(1);
    }
  }

    virtual void assign(const T* data)
    {
        _multi_array.assign(data, data + _multi_array.num_elements() );
    }
    virtual  void assign(const BaseArray<T>& b)
    {
        std::vector<size_t> v = b.getDims();
        resize(v);
        const T* data = b.getData();
        _multi_array.assign(data, data + v[0]*v[1]*v[2]);
    }
    DynArrayDim3<T>& operator=(const DynArrayDim3<T>& b)
    {
        if (this != &b)
        {
            std::vector<size_t> v = b.getDims();
            _multi_array.resize(v);
            _multi_array.reindex(1);
            _multi_array = b._multi_array;

    }
    return *this;
  }


  void setDims(size_t size1, size_t size2, size_t size3)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(const std::vector<size_t>& v)
  {
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual std::vector<size_t> getDims() const
  {
    const size_t* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 3 );
    return ex;
  }

  virtual int getDim(size_t dim) const
  {
    return (int)_multi_array.shape()[dim - 1];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    //return _multi_array[idx[0]][idx[1]][idx[2]];
    const size_t *shape = _multi_array.shape();
    return _multi_array.data()[idx[0]-1 + shape[0]*(idx[1]-1 + shape[1]*(idx[2]-1))];
  }
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    //return _multi_array[i][j][k];
    const size_t *shape = _multi_array.shape();
    return _multi_array.data()[i-1 + shape[0]*(j-1 + shape[1]*(k-1))];
  }

  virtual size_t getNumElems() const
  {
    return _multi_array.num_elements();
  }
  virtual size_t getNumDims() const
  {
    return 3;
  }

 /**
  * access to data
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
     const T* array_data = _multi_array.data();
    memcpy(data, array_data, n * sizeof( T ) );
  }
 /**
  * access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _multi_array.data();
  }

private:
  boost::multi_array<T, 3> _multi_array;
};
