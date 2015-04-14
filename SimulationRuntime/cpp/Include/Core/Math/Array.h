#pragma once

//forward declaration
template <class T> class DynArrayDim1;
template <class T> class DynArrayDim2;
template <class T> class DynArrayDim3;

/*
Operator class to assign simvar memory to a reference array
*/
template<class T>
struct CArray2RefArray
{
  T* operator()(T& val)
  {
    return &val;
  }
};

/*
Operator class to assign simvar memory to a c array
used in getDataCopy methods:
double data[4];
A.getDataCopy(data,4)
*/
template<class T>
struct RefArray2CArray
{
  const T& operator()(const T* val) const
  {
    return *val;
  }
};
/*
Operator class to copy an c -array  to a reference array
*/
template<class T>
struct CopyCArray2RefArray
{
  /*
  assign value to simvar
  \param val simvar
  \param val2 value
  */
  T* operator()(T* val,const T& val2)
  {
    *val=val2;
    return val;
  }
};


/*
Base class for all dynamic and static arrays
*/
template<class T>class BaseArray
{
public:
  BaseArray(bool is_static,bool isReference)
    :_static(is_static)
    ,_isReference(isReference)
  {}

  /*
  Interface methods for all arrays
  */
  virtual T& operator()(const vector<size_t>& idx) = 0;
  virtual void assign(const T* data) = 0;
  virtual void assign(const BaseArray<T>& otherArray) = 0;
  virtual std::vector<size_t> getDims() const = 0;
  virtual size_t getDim(size_t dim) const = 0; // { getDims()[dim - 1]; }

  virtual size_t getNumElems() const = 0;
  virtual size_t getNumDims() const = 0;
  virtual void setDims(const std::vector<size_t>& v) = 0;
  virtual void resize(const std::vector<size_t>& dims) = 0;
  virtual const T* getData() const = 0;
  virtual T* getData() = 0;
  virtual void getDataCopy(T data[], size_t n) const = 0;
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
/*
One dimensional static array, implements BaseArray interface methods
@ T type of the array
@size dimension of array
@isRef if true the array data points to the simvar memory
*/
template<typename T, std::size_t size,bool isRef = false>class StatArrayDim1 : public BaseArray<T>
{

public:
  /*
  Constuctor for one dimensional array
  if reference array it uses data from simvars memory
  else it copies data  in array memory
  */
  StatArrayDim1(T* data)
    :BaseArray<T>(true,isRef)
  {
    if(isRef)
    {
      std::transform(data,data +size,_ref_array_data.c_array(),CArray2RefArray<T>());
      _ref_init =true;
    }
    else
    {
      memcpy( _array_data.begin(), data, size * sizeof( T ) );
      _ref_init = false;
    }
  }

  /*
  Constuctor for one dimensional array
  copies data from otherarray in array memory
  */
  StatArrayDim1(const StatArrayDim1<T,size>& otherarray)
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
    checkArray("assign data to reference array is not supported");
    _array_data = otherarray._array_data;
  }
  /*
  Constuctor for one dimensional array
  copies data  from dynamic array in array memory
  */
  StatArrayDim1(const DynArrayDim1<T>& otherarray)
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
    checkArray("assign data to reference array is not supported");
    const T* data_otherarray = otherarray.getData();
    memcpy( _array_data.begin(), data_otherarray, size * sizeof( T ) );
  }


  /*
  Constuctor for one dimensional array
  empty array
  */
  StatArrayDim1()
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
  }

  ~StatArrayDim1() {}

  /*
  Assignment operator to assign arry of type base array to static array
  \@rhs any array of type BaseArray
  */
  StatArrayDim1<T,size>& operator=(BaseArray<T>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    if (this != &rhs)
    {

      try
      {
        if(rhs.isStatic())
        {
          if(rhs.isReference())
            {
              rhs.getDataCopy(_array_data.begin(), size);
            }
            else
            {

            StatArrayDim1<T,size>&  a = dynamic_cast<StatArrayDim1<T,size>&  >(rhs);
            _array_data = a._array_data;
          }
        }
        else
        {
          const T* data = rhs.getData();
          memcpy( _array_data.begin(), data, size * sizeof( T ) );
        }
      }
      catch(std::bad_exception & be)
      {
        throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong array type assign");

      }

    }
    return *this;
  }
  /*
  Assignment operator to assign static array
  \@rhs array of type StatArrayDim1
  */
  StatArrayDim1<T,size>& operator=(const StatArrayDim1<T,size>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    if (this != &rhs)
    {
      _array_data= rhs._array_data;
    }
    return *this;
  }
  /*
  Resize array method
  \@dims vector with new dimension sizes
  static array could not be resized
  */
  virtual void resize(const std::vector<size_t>& dims)
  {
    checkArray("resize  reference array is not supported");
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }
  /*
  Assigns data to array
  \@data  new array data
  */
  virtual void assign(const T* data)
  {
    checkArray("assign data to reference array is not supported");
    memcpy( _array_data.begin(), data, size * sizeof( T ) );
  }

  /*
  Assigns array data to array
  \@otherArray any array of type BaseArray
  */
  virtual void assign(const BaseArray<T>& otherArray)
  {
    checkArray("assign data to reference array is not supported");
    const T* data_otherarray = otherArray.getData();

    memcpy( _array_data.begin(), data_otherarray, size * sizeof( T ) );

  }

  /*
  Index operator to access array element
  \@idx  vector of indeces
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    if(isRef)
      return *(_ref_array_data[idx[0]-1]);
    else
      return _array_data[idx[0]-1];
  };

  /*
  Index operator to access array element
  \@index  index
  */
  inline virtual T& operator()(size_t index)
  {
    if(isRef)
    {
      T& var( *(_ref_array_data[index - 1]));
      return var;
    }
    else
      return _array_data[index - 1];
  }

  /*
  Index operator to read array element
  \@index  index
  */
  inline virtual const T& operator()(unsigned int index) const
  {

    if(isRef)
      return *(_ref_array_data[index - 1]);
    else
      return _array_data[index - 1];
  }
  /*
  Return sizes of dimensions
  */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }


  virtual size_t getDim(size_t dim) const
  {
    return size;
  }

  /*
  Access to c-array data
  */
  virtual T* getData()
  {
    checkArray("access data for reference array is not supported");
    return _array_data.c_array();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    if(isRef)
    {
      const T* const * simvars_data  = _ref_array_data.begin();
      std::transform(simvars_data,simvars_data +n,data,RefArray2CArray<T>());

    }
    else
    {
      memcpy(data,  _array_data.begin(), n * sizeof( T ) );

    }
  }
  /*
  Access to data (read-only)
  */
  virtual const T* getData() const
  {
    checkArray("assign data to reference array is not supported");
    return _array_data.data();
  }


  /*
  Returns number of elements
  */

  virtual size_t getNumElems() const
  {
    return size;
  }

  /*
  Returns number of dimensions
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
  /*
  Checks if array is a reference array and throws exception
  some array array operations are not possible for reference arrays
  */
  void checkArray(string error_msg) const
  {
    if(isRef)
    {
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,error_msg);
    }
  }
  //static array data
  boost::array<T,size> _array_data;
  //reference array data, only used if isRef = true
  boost::array<T*,size> _ref_array_data;
  bool _ref_init;
};

/*
Specialization for string 1-dim arrays, implements BaseArray interface methods
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

  StatArrayDim1<string,size>& operator=(BaseArray<string>& rhs)
  {
    if (this != &rhs)
    {

      try
      {
        if(rhs.isStatic())
        {
          StatArrayDim1<string,size>&  a = dynamic_cast<StatArrayDim1<string,size>&  >(rhs);
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
            _array_data[i]=rhs(i);
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
  StatArrayDim1<string,size>& operator=(const StatArrayDim1<string,size>& rhs)
  {
    if (this != &rhs)
    {
      _array_data= rhs._array_data;
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


  virtual void assign(const BaseArray<string>& otherArray)
  {
    for(int i=0;i<size;i++)
    {
      _array_data[i]=otherArray(i);
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


  virtual size_t getDim(size_t dim) const
  {
    return size;
  }

  /*
  access to data
  */
  virtual string* getData()
  {
    return _array_data.c_array();
  }

  /*
  access to data (read-only)
  */
  virtual const string* getData() const
  {
    return _array_data.data();
  }
  virtual const char** getCStrData()
  {
    return _c_array_data.c_array();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
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


/*
Two dimensional static array, implements BaseArray interface methods
@ T type of the array
@size1  size of dimension one
@size2  size of dimension two
@fortran use of column wise order (fortran style) or row wise order for array data
@isRef if true the array data points to the simvar memory
*/
template<typename T ,std::size_t size1,std::size_t size2,bool fortran=false,bool isRef = false>
class StatArrayDim2 : public BaseArray<T>
{

public:


  /*
  Constuctor for two dimensional array
  if reference array it uses data from simvars memory
  else it copies data  in array memory
  */
  StatArrayDim2(T* data)
    :BaseArray<T>(true,isRef)
  {
    if(isRef)
    {
      std::transform(data,data +size1*size2,_ref_array_data.c_array(),CArray2RefArray<T>());
      _ref_init =true;
    }
    else
    {
      memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );
      _ref_init = false;
    }
  }
  /*
  Constuctor for two dimensional array
  empty array
  */
  StatArrayDim2()
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
  }
  /*
  Constuctor for two dimensional array
  copies data from otherarray in array memory
  */
  StatArrayDim2(const StatArrayDim2<T,size1,size2,fortran,isRef>& otherarray)
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
    checkArray("assign data to reference array is not supported");
    _array_data = otherarray._array_data;
  }
  /*
  Assignment operator to assign static array to static array
  \@rhs  array of type StatArrayDim2
  */
  StatArrayDim2<T,size1,size2,fortran,isRef>& operator=(const StatArrayDim2<T,size1,size2,fortran,isRef>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    if (this != &rhs)
    {
      _array_data = rhs._array_data;
    }
    return *this;
  }
  /*
  Assignment operator to assign array of type base array to static array
  \@rhs any array of type BaseArray
  */
  StatArrayDim2<T,size1,size2,fortran,isRef>& operator=(BaseArray<T>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    if (this != &rhs)
    {
      try
      {
        if(rhs.isReference())
        {
          rhs.getDataCopy(_array_data.begin(), size1*size2);
        }
        else
        {
          StatArrayDim2<T,size1,size2,fortran,isRef>& a = dynamic_cast<StatArrayDim2<T,size1,size2,fortran,isRef>& >(rhs);
          _array_data = a._array_data;
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
  /*
  Appends one dimensional array in column i
  \@rhs array of type StatArrayDim1
  \@i column number
  */
  void append(size_t i,const StatArrayDim1<T,size2>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    const T* data = rhs.getData();
    memcpy( _array_data.begin()+(i-1)*size2, data, size2 * sizeof( T ) );


  }
  /*
  Resize array method
  \@dims vector with new dimension sizes
  static array could not be resized
  */
  virtual void resize(const std::vector<size_t>& dims)
  {
    checkArray("resize  reference array is not supported");
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }
  /*
  Assigns array data to array
  \@otherArray any array of type BaseArray
  */
  virtual void assign(const BaseArray<T>& otherArray)
  {

    if(isRef)
    {
      if(otherArray.isReference())
        throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"array assign from reference array not supported");
      const T* data = otherArray.getData();
      std::transform(_ref_array_data.c_array(),_ref_array_data.c_array() +size1*size2,data,_ref_array_data.c_array(),CopyCArray2RefArray<T>());
    }
    else
    {

      const T* data_otherarray = otherArray.getData();
      memcpy( _array_data.begin(), data_otherarray, size1*size2 * sizeof( T ) );
    }





  }
  /*
  Assigns array data to array
  \@data array data
  */
  virtual void assign(const T* data)
  {

    if(isRef)
    {
      std::transform(_ref_array_data.c_array(),_ref_array_data.c_array() +size1*size2,data,_ref_array_data.c_array(),CopyCArray2RefArray<T>());
    }
    else
    {
      memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );
    }

  }

  /*
  Index operator to access array element
  \@idx  vector of indices
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    if(isRef)
      return *(_ref_array_data[size2*(idx[0] - 1) + idx[1] - 1]); //row wise order
    else
      return _array_data[size2*(idx[0] - 1) + idx[1] - 1]; //row wise order
  };
  /*
  Index operator to access array element
  \@i  index 1
  \@j  index 2
  */
  inline virtual T& operator()(size_t i, size_t j)
  {

    if(fortran)
    {
      if(isRef)
        return *(_ref_array_data[size1*(j - 1) + i - 1]); //column wise order
      else
        return _array_data[size1*(j - 1) + i - 1]; //column wise order
    }
    else
    {
      if(isRef)
        return *(_ref_array_data[size2*(i - 1) + j - 1]); //row wise order
      else
        return _array_data[size2*(i - 1) + j - 1]; //row wise order
    }
  }

  /*
  Index operator to read array element
  \@index  index
  */
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    if (fortran)
      return _array_data[size1*(j - 1) + i - 1]; //column wise order
    else
      return _array_data[size2*(i - 1) + j - 1]; //row wise order
  }

  /*
  Return sizes of dimensions
  */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }
  /*
  Returns number of elements
  */
  virtual size_t getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return size1;
    case 2:
      return size2;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }

  virtual size_t getNumElems() const
  {
    return size1 * size2;
  }

  /*
  Return sizes of dimensions
  */
  virtual size_t getNumDims() const
  {
    return 2;
  }
  /*
  Access to data
  */
  virtual T* getData()
  {
    checkArray("access data for reference array is not supported");
    return _array_data. c_array();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    if(isRef)
    {
      const T* const * simvars_data  = _ref_array_data.begin();
      std::transform(simvars_data,simvars_data +n,data,RefArray2CArray<T>());
    }
    else
    {
      memcpy(data,  _array_data.begin(), n * sizeof( T ) );
    }
  }
  /*
  Access to data (read-only)
  */
  virtual const T* getData() const
  {
    checkArray("access data for reference array is not supported");
    return _array_data.data();
  }

  virtual void setDims(const std::vector<size_t>& v) {  }
  void setDims(size_t i,size_t j)  {  }
private:
  /*
  Checks if array is a reference array and throws exception
  some array array operations are not possible for reference arrays
  */
  void checkArray(string error_msg) const
  {
    if(isRef)
    {
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,error_msg);
    }
  }

  //static array data
  boost::array<T, size2 * size1> _array_data;
  //reference array data, only used if isRef = true
  boost::array<T*, size2 * size1> _ref_array_data;
  bool _ref_init;
};


/*
Specialization for string 2-dim arrays, implements BaseArray interface methods
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
        _c_array_data[size2*i + j ] = _array_data[size2*i + j].c_str();
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
        _c_array_data[size2*i + j ] = _array_data[size2*i + j].c_str();
      }
    }
  }
  StatArrayDim2<string,size1,size2>& operator=(const StatArrayDim2<string,size1,size2>& rhs)
  {
    if (this != &rhs)
    {
      _array_data = rhs._array_data;
      for(int i=0;i<size1;i++)
      {
        for(int j=0;j<size2;j++)
        {
          _c_array_data[size2*i + j ] = _array_data[size2*i + j].c_str();
        }
      }
    }
    return *this;
  }

  StatArrayDim2<string,size1,size2>& operator=(BaseArray<string>& rhs)
  {
    if (this != &rhs)
    {
      try
      {
        StatArrayDim2<string,size1,size2>& a = dynamic_cast<StatArrayDim2<string,size1,size2>& >(rhs);
        _array_data = a._array_data;
        for(int i=0;i<size1;i++)
        {
          for(int j=0;j<size2;j++)
          {
            _c_array_data[size2*i + j ] = _array_data[size2*i + j].c_str();
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

  void append(size_t i,const StatArrayDim1<string,size2>& rhs)
  {

    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"append not supported for 2-dim string array");
  }

  virtual void resize(const std::vector<size_t>& dims)
  {
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }

  virtual void assign(const BaseArray<string>& otherArray)
  {
    std::vector<size_t> v;
    v = otherArray.getDims();
    const string* data_otherarray = otherArray.getData();
    std::copy(data_otherarray,data_otherarray+size1*size2,_array_data.begin());
    for(int i=0;i<size1;i++)
    {
      for(int j=0;j<size2;j++)
      {
        const char* c_str_data = _array_data[size2*i + j].c_str();
        _c_array_data[size2*i + j ] = c_str_data;
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
        const char* c_str_data = _array_data[size2*i + j].c_str();
        _c_array_data[size2*i + j ] = c_str_data;
      }
    }
  }
  virtual string& operator()(const vector<size_t>& idx)
  {
    return _array_data[size2*(idx[0] - 1) + idx[1] - 1]; //row wise order
  };

  inline virtual string& operator()(size_t i, size_t j)
  {
    return _array_data[size2*(i - 1) + j - 1]; //row wise order
  }
  inline virtual const string& operator()(size_t i, size_t j) const
  {
    return _array_data[size2*(i - 1) + j - 1];//row wise order
  }


  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  virtual size_t getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return size1;
    case 2:
      return size2;
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
  /*
  Access to data
  */
  virtual string* getData()
  {
    return _array_data. c_array();
  }
  /*
  Access to data (read-only)
  */
  virtual const string* getData() const
  {
    return _array_data.data();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
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










/*
Three dimensional static array, implements BaseArray interface methods
@ T type of the array
@size1  size of dimension one
@size2  size of dimension two
@size3  size of dimension two
@isRef if true the array data points to the simvar memory
*/
template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3,bool isRef = false> class StatArrayDim3 : public BaseArray<T>
{

public:

  /*
  Constuctor for one dimensional array
  if reference array it uses data from simvars memory
  else it copies data  in array memory
  */
  StatArrayDim3(T* data)
    :BaseArray<T>(true,isRef)
  {
    if(isRef)
    {
      std::transform(data,data +size1*size2*size3,_ref_array_data.c_array(),CArray2RefArray<T>());
      _ref_init =true;
    }
    else
    {
      memcpy( _array_data.begin(), data, size1*size2*size3 * sizeof( T ) );
      _ref_init = false;
    }
  }

  /*
  Constuctor for two dimensional array
  empty array
  */
  StatArrayDim3()
    :BaseArray<T>(true,isRef)
    ,_ref_init(false)
  {
  }

  ~StatArrayDim3()
  {}

  /*
  Assigns array data to array
  \@otherArray any array of type BaseArray
  */
  virtual  void assign(const BaseArray<T>& otherArray)
  {
    checkArray("assign data to reference array is not supported");
    std::vector<size_t> v;
    v = otherArray.getDims();
    const T* data_otherarray = otherArray.getData();
    memcpy( _array_data.begin(), data_otherarray, size1*size2*size3 * sizeof( T ) );

  }
  /*
  Assigns array data to array
  \@data array data
  */
  virtual void assign(const T* data)
  {
    checkArray("assign data to reference array is not supported");
    memcpy( _array_data.begin(), data, size1*size2*size3 * sizeof( T ) );
  }
  /*
  Appends two dimensional array in column i
  \@rhs array of type StatArrayDim2
  \@i column number
  */
  void append(size_t i,const StatArrayDim2<T,size2,size3>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    const T* data = rhs.getData();
    memcpy( _array_data.begin()+(i-1)*size2*size3, data, size2 *size3*sizeof( T ) );
  }

  /*
  Resize array method
  \@dims vector with new dimension sizes
  static array could not be resized
  */
  virtual void resize(const std::vector<size_t>& dims)
  {
    checkArray("resize  reference array is not supported");
    if (dims != getDims())
      std::runtime_error("Cannot resize static array!");
  }
  /*
  Return sizes of dimensions
  */
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    return v;
  }

  /*
  Assignment operator to assign static array
  \@rhs array of type StatArrayDim3
  */
  virtual size_t getDim(size_t dim) const
  {
    switch (dim) {
    case 1:
      return size1;
    case 2:
      return size2;
    case 3:
      return size3;
    default:
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "Wrong getDim");
    }
  }


  StatArrayDim3<T,size1,size2,size3>& operator=(const StatArrayDim3<T,size1,size2,size3>& rhs)
  {
    checkArray("assign data to reference array is not supported");
    if (this != &rhs)
    {
      _array_data = rhs._array_data;
    }
    return *this;
  }

  /*
  Index operator to access array element
  \@idx  vector of indices
  */
  virtual T& operator()(const vector<size_t>& idx)
  {
    //row-major order
    if(isRef)
      return *(_ref_array_data[(idx[2] - 1) + size3*((idx[1]-1)+size2*(idx[0]-1))]);
    else
      return _array_data[(idx[2] - 1) + size3*((idx[1]-1)+size2*(idx[0]-1))];
    //column-major order
    //return _array_data[(idx[2] - 1)*size2*size1 +   (idx[1] - 1)*size1 + (idx[0] - 1)];
  };

  /*
  Index operator to access array element
  \@i  index 1
  \@j  index 2
  \@k  index 3
  */
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    //row-major order
    if(isRef)
      return *(_ref_array_data[(k - 1) + size3*((j-1)+size2*(i-1))]);
    else
      return _array_data[(k - 1) + size3*((j-1)+size2*(i-1))];
    //column-major order
    //return _array_data[(k - 1)*size2*size1 +   (j - 1)*size1 + (i - 1)];
  }
  /*
  Returns number of elements
  */
  virtual size_t getNumElems() const
  {
    return size1 * size2 * size3;
  }

  /*
  Return sizes of dimensions
  */
  virtual size_t getNumDims() const
  {
    return 3;
  }

  virtual void setDims(const std::vector<size_t>& v) { }
  void setDims(size_t i,size_t j,size_t k)  { }
  /*
  Access to data
  */
  virtual T* getData()
  {
    checkArray("access data for reference array is not supported");
    return _array_data.c_array();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    if(isRef)
    {
      const T* const * simvars_data  = _ref_array_data.begin();
      std::transform(simvars_data,simvars_data +n,data,RefArray2CArray<T>());
    }
    else
    {
      memcpy(data,  _array_data.begin(), n * sizeof( T ) );
    }
  }
  /*
  Access to data (read-only)
  */
  virtual const T* getData() const
  {
    checkArray("access data for reference array is not supported");
    return _array_data.data();
  }

private:
  /*
  Checks if array is a reference array and throws exception
  some array array operations are not possible for reference arrays
  */
  void checkArray(string error_msg) const
  {
    if(isRef)
    {
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,error_msg);
    }
  }

  //static array data
  boost::array<T, size2 * size1*size3> _array_data;
  //reference array data, only used if isRef = true
  boost::array<T*, size2 * size1*size3> _ref_array_data;
  bool _ref_init;

};
/*
template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3, std::size_t size4>
class StatArrayDim4 : public BaseArray<T>
StatArrayDim4()
{
}

~StatArrayDim4(){}

void assign(StatArrayDim4<T,size1,size2,size3,size4> otherArray)
{
for(int i = 0; i < size1; i++)
{
for(int j = 0; j < size2; j++)
{
for(int k = 0; k < size3; k++)
{
for(int l = 0; l < size4; l++)
{
_array_data[i][j][k][l] = otherArray._array_data[i][j][k][l];
}
}
}
}
}

void assign( BaseArray<T>& otherArray)
{
std::vector<size_t> v;
v = otherArray.getDims();
for(int i = 1; i <= min(v[0],size1); i++)
{
for(int j = 1; j <= min(v[1],size2); j++)
{
for(int k = 1; k <= min(v[2],size3); k++)
{
for(int l = 1; l <= min(v[3],size4); l++)
{
_array_data[i - 1][j - 1][k - 1][l - 1] = otherArray(i,j,k,l);
}
}
}
}
}

void assign(const T* data)
{
for(int i = 1; i <= size1; i++)
{
for(int j = 1; j <= size2; j++)
{
for(int k = 1; k <= size3; k++)
{
for(int l = 1; l <= size4; l++)
{
_array_data[i][j][k][l] = data[i * size2 * size3 * size4 + j * size3 * size4 + k * size4 + l];
}
}
}
}
}

virtual std::vector<size_t> getDims() const
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
return v;
}


virtual T& operator()(size_t i, size_t j, size_t k, size_t l)
{
return _array_data[i - 1][j - 1][k - 1][l - 1];
}

virtual size_t getNumElems() const
{
return size1 + size2 + size3 + size4;
}
virtual void setDims(const std::vector<size_t>& v)
{

}
private:
boost::array< boost::array< boost::array<boost::array<T,size4>,size3>,size2>,size1> _array_data;

};


template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3, std::size_t size4, std::size_t size5>
class StatArrayDim5 : public BaseArray<T>
{
//friend class ArrayDim5<T, size1, size2, size3, size4, size5>;
public:
StatArrayDim5(const T* data)
{
for(int i = 0; i < size1; i++)
{
for(int j = 0; j < size2; j++)
{
for(int k = 0; k < size3; k++)
{
for(int l = 0; l < size4; l++)
{
for(int m = 0; m < size5; m++)
{
_array_data[i][j][k][l][m] = data[i * size2 * size3 * size4 *size5 + j * size3 * size4 * size5 + k * size4 * size5 + l * size5 + m];
}
}
}
}
}
}

StatArrayDim5()
{
}

~StatArrayDim5(){}

void assign(StatArrayDim5<T,size1,size2,size3,size4,size5> otherArray)
{
for(int i = 0; i < size1; i++)
{
for(int j = 0; j < size2; j++)
{
for(int k = 0; k < size3; k++)
{
for(int l = 0; l < size4; l++)
{
for(int m = 0; m < size5; m++)
{
_array_data[i][j][k][l][m] = otherArray._array_data[i][j][k][l][m];
}
}
}
}
}
}

void assign( BaseArray<T>& otherArray)
{
std::vector<size_t> v;
v = otherArray.getDims();
for(int i = 1; i <= min(v[0],size1); i++)
{
for(int j = 1; j <= min(v[1],size2); j++)
{
for(int k = 1; k <= min(v[2],size3); k++)
{
for(int l = 1; l <= min(v[3],size4); l++)
{
for(int m = 1; m <= min(v[4],size5); m++)
{
_array_data[i - 1][j - 1][k - 1][l - 1][m - 1] = otherArray(i,j,k,l,m);
}
}
}
}
}
}


void assign(const T& data)
{
for(int i = 0; i < size1; i++)
{
for(int j = 0; j < size2; j++)
{
for(int k = 0; k < size3; k++)
{
for(int l = 0; l < size4; l++)
{
for(int m = 0; m < size5; m++)
{
_array_data[i][j][k][l][m] = data[i * size2 * size3 * size4 *size5 + j * size3 * size4 * size5 + k * size4 * size5 + l * size5 + m];
}
}
}
}
}
}

virtual std::vector<size_t> getDims() const
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
v.push_back(size5);
return v;
}


virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m)
{
return _array_data[i - 1][j - 1][k - 1][l - 1][m - 1];
}
virtual size_t getNumElems() const
{
return size1 + size2 + size3 + size4 + size5;
}
virtual void setDims(const std::vector<size_t>& v)
{

}
private:
boost::array< boost::array< boost::array< boost::array<boost::array<T,size5>,size4>,size3>,size2>,size1> _array_data;
};

*/



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




template<typename T>class DynArrayDim1 : public BaseArray<T>
{

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

  DynArrayDim1(const BaseArray<T>& otherArray)
    :BaseArray<T>(false,false)
  {
    std::vector<size_t> v = otherArray.getDims();
    if(v.size()!=1)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim1");
    _multi_array.resize(v);
    _multi_array.reindex(1);
    const T* data_otherarray = otherArray.getData();
    _multi_array.assign(data_otherarray,data_otherarray+v[0]);
  }


  ~DynArrayDim1()
  {
  }

  /*///anschauen!!!
  void assign(DynArrayDim1<T>& otherArray)
  {
  _multi_array.resize(otherArray.getDims());
  T* data = otherArray._multi_array.data();
  _multi_array.assign(data, data + otherArray._multi_array.num_elements());
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

  virtual  void assign(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v = otherArray.getDims();

    resize(v);
    const T* data_otherarray = otherArray.getData();
    _multi_array.assign(data_otherarray,data_otherarray+ v[0]);
    /*for (int i = 1; i <= v[0]; i++)
    {
    //double tmp =  otherArray(i);
    _multi_array[i] = otherArray(i);
    }
    */

  }

  virtual void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }


  virtual T& operator()(const vector<size_t>& idx)
  {
    return _multi_array[idx[0]];
  };
  inline virtual T& operator()(size_t index)
  {
    //double tmp = _multi_array[index];
    return _multi_array[index];
  }
  inline virtual const T& operator()(size_t index) const
  {
    //double tmp = _multi_array[index];
    return _multi_array[index];
  }
  DynArrayDim1<T>& operator=(const DynArrayDim1<T>& rhs)
  {
    if (this != &rhs)
    {
      std::vector<size_t> v = rhs.getDims();
      _multi_array.resize(v);
      _multi_array.reindex(1);
      _multi_array = rhs._multi_array;

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

  virtual size_t getDim(size_t dim) const
  {
    return _multi_array.shape()[dim - 1];
  }
  /*
  access to data (read-only)
  */
  virtual T* getData()
  {
    return _multi_array.data();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDataCopy for one dim dynamic array not supported");
  }
  /*
  access to data (read-only)
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
  {
    _multi_array.reindex(1);
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
    :BaseArray<T>(false,false)
  {
    //assign(dynarray);
    setDims(dynarray.getDim(1), dynarray.getDim(2));
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

  DynArrayDim2(const BaseArray<T>& otherArray)
    :BaseArray<T>(false,false)
  {
    std::vector<size_t> v = otherArray.getDims();
    if(v.size()!=2)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim2");
    _multi_array.resize(v);
    _multi_array.reindex(1);
    otherArray.getDataCopy(_multi_array.data(), v[0]*v[1]);

  }

  DynArrayDim2(size_t size1, size_t size2)
    :BaseArray<T>(false,false)
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

  /*void assign(DynArrayDim2<T> otherArray)
  {
  _multi_array.resize(otherArray.getDims());
  _multi_array.reindex(1);
  const T* data = otherArray._multi_array.data();
  _multi_array.assign(data, data + otherArray._multi_array.num_elements());
  }
  */
  virtual  void assign(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v = otherArray.getDims();
    resize(v);
    otherArray.getDataCopy(_multi_array.data(), v[0]*v[1]);

  }
  void append(size_t i,const DynArrayDim1<T>& rhs)
  {

    const T* data = rhs.getData();
    boost::multi_array<T, 1>  a;
    std::vector<size_t> v = rhs.getDims();
    a.resize(v);
    a.reindex(1);
    _multi_array[i]=a;
  }
  DynArrayDim2<T>& operator=(const DynArrayDim2<T>& rhs)
  {
    if (this != &rhs)  //oder if (*this != rhs)
    {
      std::vector<size_t> v = rhs.getDims();
      _multi_array.resize(v);
      _multi_array.reindex(1);
      _multi_array = rhs._multi_array;

    }
    return *this;
  }
  virtual void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }
  virtual T& operator()(const vector<size_t>& idx)
  {
    return _multi_array[idx[0]][idx[1]];
  };
  inline virtual T& operator()(size_t i, size_t j)
  {
    return _multi_array[i][j];
  }
  inline virtual const T& operator()(size_t i, size_t j) const
  {
    return _multi_array[i][j];
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

  virtual size_t getDim(size_t dim) const
  {
    return _multi_array.shape()[dim - 1];
  }

  virtual size_t getNumElems() const
  {
    return _multi_array.num_elements();
  }
  virtual size_t getNumDims() const
  {
    return 2;
  }

  /*
  access to data
  */
  virtual T* getData()
  {
    return _multi_array.data();
  }
  /*
  access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _multi_array.data();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDataCopy for one dim dynamic array not supported");
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
  {
    _multi_array.reindex(1);
  }

  DynArrayDim3(size_t size1, size_t size2, size_t size3)
    :BaseArray<T>(false,false)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }
  DynArrayDim3(const BaseArray<T>& otherArray)
    :BaseArray<T>(false,false)
  {
    std::vector<size_t> v = otherArray.getDims();
    if(v.size()!=3)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim3");
    _multi_array.resize(v);
    _multi_array.reindex(1);
    const T* data_otherarray = otherArray.getData();
    _multi_array.assign(data_otherarray,data_otherarray+v[0]*v[1]*v[3]);
  }
  ~DynArrayDim3(){}
  /*
  void assign(DynArrayDim3<T> otherArray)
  {
  std::vector<size_t> v = otherArray.getDims();
  _multi_array.resize(v);
  _multi_array.reindex(1);
  T* data = otherArray._multi_array.data();
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
  virtual  void assign(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v = otherArray.getDims();
    resize(v);
    const T* data = otherArray.getData();
    _multi_array.assign(data, data + v[0]*v[1]*v[2]);
  }
  DynArrayDim3<T>& operator=(const DynArrayDim3<T>& rhs)
  {
    if (this != &rhs)
    {
      std::vector<size_t> v = rhs.getDims();
      _multi_array.resize(v);
      _multi_array.reindex(1);
      _multi_array = rhs._multi_array;

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

  virtual size_t getDim(size_t dim) const
  {
    return _multi_array.shape()[dim - 1];
  }

  virtual T& operator()(const vector<size_t>& idx)
  {
    return _multi_array[idx[0]][idx[1]][idx[2]];
  };
  inline virtual T& operator()(size_t i, size_t j, size_t k)
  {
    return _multi_array[i][j][k];
  }

  virtual size_t getNumElems() const
  {
    return _multi_array.num_elements();
  }
  virtual size_t getNumDims() const
  {
    return 3;
  }

  /*
  access to data
  */
  virtual T* getData()
  {
    return _multi_array.data();
  }
  /*
  Copies the array data of size n in the data array
  data has to be allocated before getDataCopy is called
  */
  virtual void getDataCopy(T data[], size_t n) const
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "getDataCopy for one dim dynamic array not supported");
  }
  /*
  access to data (read-only)
  */
  virtual const T* getData() const
  {
    return _multi_array.data();
  }

private:
  boost::multi_array<T, 3> _multi_array;
};



/*cd

template<typename T> class DynArrayDim4 : public BaseArray<T>
{
//friend class ArrayDim4<T, size1, size2, size3, size4>;
public:
DynArrayDim4()
{
_multi_array.reindex(1);
}

DynArrayDim4(size_t size1, size_t size2, size_t size3, size_t size4)
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
_multi_array.resize(v);//
_multi_array.reindex(1);
}

~DynArrayDim4(){}

void assign(DynArrayDim4<T> otherArray)
{
_multi_array.resize(otherArray.getDims());
_multi_array.reindex(1);
T* data = otherArray._multi_array.data();
_multi_array.assign(data, data + otherArray._multi_array.num_elements());
}

void assign(BaseArray<T>& otherArray)
{
std::vector<size_t> v = otherArray.getDims();
_multi_array.resize(v);
_multi_array.reindex(1);

for (int i = 1; i <= v[0]; i++)
{
for (int j = 1; j <= v[1]; j++)
{
for (int k = 1; k <= v[1]; k++)
{
for (int l = 1; l <= v[1]; l++)
{
_multi_array[i][j][k][l] = otherArray(i,j,k,l);
}
}
}
}
}

void assign(const T& data)
{
_multi_array.assign(data, data + _multi_array.num_elements() );
}

void setDims(size_t size1, size_t size2, size_t size3, size_t size4)
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
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
ex.assign( shape, shape + 4 );
return ex;
}

virtual size_t getDim(size_t dim) const
{
return _multi_array.shape()[dim - 1];
}

virtual T& operator()(size_t i, size_t j, size_t k, size_t l)
{
return _multi_array[i][j][k][l];
}

virtual size_t getNumElems() const
{
return _multi_array.num_elements();
}

private:
boost::multi_array<T, 4> _multi_array;
};




template<typename T>
class DynArrayDim5 : public BaseArray<T>
{
//friend class ArrayDim5<T, size1, size2, size3, size4, size5>;
public:

DynArrayDim5()
{
_multi_array.reindex(1);
}

DynArrayDim5(size_t size1, size_t size2, size_t size3, size_t size4, size_t size5)
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
v.push_back(size5);
_multi_array.resize(v);//
_multi_array.reindex(1);
}

~DynArrayDim5(){}

void assign(DynArrayDim5<T> otherArray)
{
_multi_array.resize(otherArray.getDims());
_multi_array.reindex(1);
T* data = otherArray._multi_array.data();
_multi_array.assign(data, data + otherArray._multi_array.num_elements());
}

void assign(BaseArray<T>& otherArray)
{
std::vector<size_t> v = otherArray.getDims();
_multi_array.resize(v);
_multi_array.reindex(1);

for (int i = 1; i <= v[0]; i++)
{
for (int j = 1; j <= v[1]; j++)
{
for (int k = 1; k <= v[2]; k++)
{
for (int l = 1; l <= v[3]; l++)
{
for (int m = 1; m <= v[4]; m++)
{
_multi_array[i][j][k][l][m] = otherArray(i,j,k,l,m);
}
}
}
}
}
}

void assign(const T& data)
{
_multi_array.assign(data, data + _multi_array.num_elements() );
}

void setDims(size_t size1, size_t size2, size_t size3, size_t size4, size_t size5)
{
std::vector<size_t> v;
v.push_back(size1);
v.push_back(size2);
v.push_back(size3);
v.push_back(size4);
v.push_back(size5);
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
ex.assign( shape, shape + 5 );
return ex;
}

virtual size_t getDim(size_t dim) const
{
return _multi_array.shape()[dim - 1];
}

virtual T& operator()(size_t i, size_t j, size_t k, size_t l, size_t m)
{
return _multi_array[i][j][k][l][m];
}

virtual size_t getNumElems() const
{
return _multi_array.num_elements();
}

private:
boost::multi_array<T,5> _multi_array;
};

*/
/* assign simvar region to simvar memory

std::vector<size_t> v;
if(otherArray.getNumDims()!=2)
throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "error in assing array: Dimensions did not match");
size_t n1 = otherArray.getDim(1);
size_t n2 = otherArray.getDim(2);
if(n1=size1 || n2 != size2)
throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION, "error in assing array: Array Sizes did not match");
std::transform(otherArray._ref_array_data.c_array(),otherArray._ref_array_data.c_array() +size1*size2,_ref_array_data.c_array(),AssignArrayVarToArrayVar<T>());

*/