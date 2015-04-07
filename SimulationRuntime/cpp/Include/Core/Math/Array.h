#pragma once

//forward declaration
template <class T> class DynArrayDim1;
template <class T> class DynArrayDim2;
template <class T> class DynArrayDim3;

template<class T>class BaseArray
{
public:
  BaseArray(bool is_static)
  :_static(is_static)
  {};

  //interface methods for all arrays

  virtual T& operator()(const vector<size_t>& idx) = 0;
  virtual void assign(const T* data) = 0;
  virtual void assign(const BaseArray<T>& otherArray) = 0;
  virtual std::vector<size_t> getDims() const = 0;
  virtual T* getData() = 0;
  virtual const T* getData() const = 0;
  virtual unsigned int getNumElems() const = 0;
  virtual unsigned int getNumDims() const = 0;
  virtual void setDims(std::vector<size_t> v) = 0;
  virtual void resize(std::vector<size_t> dims) = 0;
  virtual const char** getCStrData()
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array getCStrData call");
  }
  virtual T& operator()(unsigned int i)
  {
     throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual const T& operator()(unsigned int i) const
  {
     throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(const unsigned int  i, const unsigned int j)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l, unsigned int m)
  {
    throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong virtual Array operator call");
  };

  bool isStatic()
  {
     return _static;
  }

protected:
  bool _static;
};

template<typename T, std::size_t size>class StatArrayDim1 : public BaseArray<T>
{

public:
  StatArrayDim1(const T* data)
  :BaseArray<T>(true)
  {
    //std::copy(data,data+size,_array_data.begin());
    memcpy( _array_data.begin(), data, size * sizeof( T ) );
  }

  StatArrayDim1(const StatArrayDim1<T,size>& otherarray)
  :BaseArray<T>(true)
  {
     _array_data = otherarray._array_data;
  }
  StatArrayDim1(const DynArrayDim1<T>& otherarray)
  :BaseArray<T>(true)
  {
     const T* data_otherarray = otherarray.getData();
    //std::copy(data_otherarray,data_otherarray+size,_array_data.begin());
    memcpy( _array_data.begin(), data_otherarray, size * sizeof( T ) );
  }

  StatArrayDim1()
  :BaseArray<T>(true)
  {
  }

  ~StatArrayDim1() {}

  //void assign(StatArrayDim1<T,size> otherArray)
  //{
  //  _array_data = otherArray._array_data;
  //}


  StatArrayDim1<T,size>& operator=(BaseArray<T>& rhs)
 {
  if (this != &rhs)
  {

      try
      {
         if(rhs.isStatic())
         {
            StatArrayDim1<T,size>&  a = dynamic_cast<StatArrayDim1<T,size>&  >(rhs);
            _array_data = a._array_data;
         }
         else
         {
             DynArrayDim1<T>&  a = dynamic_cast<DynArrayDim1<T>&  >(rhs);
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
 StatArrayDim1<T,size>& operator=(const StatArrayDim1<T,size>& rhs)
 {
  if (this != &rhs)
  {
      _array_data= rhs._array_data;
  }
  return *this;
 }

 virtual void resize(std::vector<size_t> dims)
 {
     if (dims != getDims())
         std::runtime_error("Cannot resize static array!");
 }

   virtual void assign(const T* data)
  {
      //std::copy(data,data+size,_array_data.begin());
      memcpy( _array_data.begin(), data, size * sizeof( T ) );
  }


   virtual void assign(const BaseArray<T>& otherArray)
  {
    //std::vector<size_t> v;
    //v = otherArray.getDims();
    const T* data_otherarray = otherArray.getData();
    //std::copy(data_otherarray,data_otherarray+size,_array_data.begin());
    memcpy( _array_data.begin(), data_otherarray, size * sizeof( T ) );
    /*for(unsigned int i = 1; i <= min(v[0],size); i++)
    {
      _array_data[i-1] = otherArray(i);
    }*/
  }
  virtual T& operator()(const vector<size_t>& idx)
  {
     return _array_data[idx[0]-1];
  };


  inline virtual T& operator()(unsigned int index)
  {
      return _array_data[index - 1];
  }
  inline virtual const T& operator()(unsigned int index) const
  {

    return _array_data[index - 1];
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }
 /*
  access to data
  */
  virtual T* getData()
  {
    return _array_data.c_array();
  }
  /*
  access to data (read-only)
  */
  virtual const T* getData() const
  {
     return _array_data.data();
  }
  virtual unsigned int getNumElems() const
  {
    return size;
  }
  virtual unsigned int getNumDims() const
  {
     return 1;
  }

  virtual void setDims(std::vector<size_t> v) {  }
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
    boost::array<T,size> _array_data;
};

/*Specialization for string 1-dim arrays*/


template<std::size_t size>class StatArrayDim1<string,size> : public BaseArray<string>
{

public:
  StatArrayDim1(const string data[])
  :BaseArray<string>(true)
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
  :BaseArray<string>(true)
  {
     _array_data = otherarray._array_data;
     for(int i=0;i<size;i++)
    {
      _c_array_data[i]=_array_data[i].c_str();
    }
  }
  StatArrayDim1(const DynArrayDim1<string>& otherarray)
  :BaseArray<string>(true)
  {

  }

  StatArrayDim1()
  :BaseArray<string>(true)
  {
  }

  ~StatArrayDim1() {}

  //void assign(StatArrayDim1<T,size> otherArray)
  //{
  //  _array_data = otherArray._array_data;
  //}

 virtual void resize(std::vector<size_t> dims)
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
             for(unsigned int i=0;i<size;i++)
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


  inline virtual string& operator()(unsigned int index)
  {
    return _array_data[index - 1];
  }
  inline virtual const string& operator()(unsigned int index) const
  {
    return _array_data[index - 1];
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
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


  virtual unsigned int getNumElems() const
  {
    return size;
  }
  virtual unsigned int getNumDims() const
  {
     return 1;
  }

  virtual void setDims(std::vector<size_t> v) {  }
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


template<typename T ,std::size_t size1,std::size_t size2,bool fotran = false>class StatArrayDim2 : public BaseArray<T>
{

public:
  StatArrayDim2(const T* data) //const T (&data)     const T (&data)[size1*size2]
  :BaseArray<T>(true)
  {
    //std::copy(data,data+size1*size2,_array_data.begin());
    memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );

  }

  StatArrayDim2()
  :BaseArray<T>(true)
  {
  }

  StatArrayDim2(const StatArrayDim2<T,size1,size2>& otherarray)
  :BaseArray<T>(true)
  {
     _array_data = otherarray._array_data;
  }
 StatArrayDim2<T,size1,size2>& operator=(const StatArrayDim2<T,size1,size2>& rhs)
 {
  if (this != &rhs)
  {
     _array_data = rhs._array_data;
  }
  return *this;
 }

  StatArrayDim2<T,size1,size2>& operator=(BaseArray<T>& rhs)
 {
  if (this != &rhs)
  {
      try
      {
         StatArrayDim2<T,size1,size2>& a = dynamic_cast<StatArrayDim2<T,size1,size2>& >(rhs);
         _array_data = a._array_data;
      }
      catch(std::bad_exception & be)
      {
        throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong array type assign");
      }
  }
  return *this;
 }

  ~StatArrayDim2(){}

  void append(size_t i,const StatArrayDim1<T,size2>& rhs)
  {
    const T* data = rhs.getData();
    // std::copy(data,data+size2,data0+(size1));
    memcpy( _array_data.begin()+(i-1)*size2, data, size2 * sizeof( T ) );


  }

  virtual void resize(std::vector<size_t> dims)
  {
      if (dims != getDims())
          std::runtime_error("Cannot resize static array!");
  }

  virtual void assign(const BaseArray<T>& otherArray)
  {

    std::vector<size_t> v;
    v = otherArray.getDims();
    const T* data_otherarray = otherArray.getData();
     //std::copy(data_otherarray,data_otherarray+size1*size2,_array_data.begin());
    memcpy( _array_data.begin(), data_otherarray, size1*size2 * sizeof( T ) );


  }

  virtual void assign(const T* data)//)const T (&data) [size1*size2]
  {
    //std::copy(data,data+size1*size2,_array_data.begin());
    memcpy( _array_data.begin(), data, size1*size2 * sizeof( T ) );


  }
  virtual T& operator()(const vector<size_t>& idx)
  {
     return _array_data[size2*(idx[0] - 1) + idx[1] - 1]; //row wise order
  };

  inline virtual T& operator()(const unsigned int i, const unsigned  int j)
  {
    if(fotran)
       return _array_data[size1*(j - 1) + i - 1]; //column wise order
     else
       return _array_data[size2*(i - 1) + j - 1]; //row wise order
  }
  inline virtual const T& operator()(const unsigned int i, const unsigned  int j) const
  {
    if(fotran)
     return _array_data[size1*(j - 1) + i - 1];//column wise order
    else
     return _array_data[size2*(i - 1) + j - 1];//row wise order
  }


  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  virtual unsigned int getNumElems() const
  {
    return size1 * size2;
  }

    virtual unsigned int getNumDims() const
  {
     return 2;
  }
   /*
  access to data
  */
  virtual T* getData()
  {
    return _array_data. c_array();
  }
  /*
  access to data (read-only)
  */
  virtual const T* getData() const
  {
     return _array_data.data();
  }

  virtual void setDims(std::vector<size_t> v) {  }
  void setDims(size_t i,size_t j)  {  }
private:
  //boost::array< boost::array<T, size2>, size1> _array_data;
  boost::array<T, size2 * size1> _array_data;

  //T _array_data[size2*size1];
};


/*Specialization for string 2-dim arrays*/


template<std::size_t size1,std::size_t size2>
class StatArrayDim2<string,size1,size2> : public BaseArray<string>
{

public:
  StatArrayDim2(const string data[]) //const T (&data)     const T (&data)[size1*size2]
  :BaseArray<string>(true)
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
  :BaseArray<string>(true)
  {

  }

  StatArrayDim2(const StatArrayDim2<string,size1,size2>& otherarray)
  :BaseArray<string>(true)
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

  virtual void resize(std::vector<size_t> dims)
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

  inline virtual string& operator()(const unsigned int i, const unsigned  int j)
  {
      return _array_data[size2*(i - 1) + j - 1]; //row wise order
  }
  inline virtual const string& operator()(const unsigned int i, const unsigned  int j) const
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

  virtual unsigned int getNumElems() const
  {
    return size1 * size2;
  }

    virtual unsigned int getNumDims() const
  {
     return 2;
  }
  /*
  access to data
  */
  virtual string* getData()
  {
    return _array_data. c_array();
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

  virtual void setDims(std::vector<size_t> v) {  }
  void setDims(size_t i,size_t j)  {  }
private:
  //boost::array< boost::array<T, size2>, size1> _array_data;
  boost::array<string, size2 * size1> _array_data;
  boost::array<const char*,size2 * size1> _c_array_data;
  //T _array_data[size2*size1];
};













template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3> class StatArrayDim3 : public BaseArray<T>
{
  //friend class ArrayDim3<T, size1, size2, size3>;
public:
  StatArrayDim3(const T data[])
  :BaseArray<T>(true)
  {
    //std::copy(data,data+size1*size2*size3,_array_data.begin());
     memcpy( _array_data.begin(), data, size1*size2*size3 * sizeof( T ) );
  }

  StatArrayDim3()
  :BaseArray<T>(true)
  {
  }

  ~StatArrayDim3()
  {}

  /*void assign(StatArrayDim3<T,size1,size2,size3> otherArray)
  {
    _array_data = otherArray._array_data;
  }
  */
  virtual  void assign(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v;
    v = otherArray.getDims();
     const T* data_otherarray = otherArray.getData();
     //std::copy(data_otherarray,data_otherarray+size1*size2*size3,_array_data.begin());
      memcpy( _array_data.begin(), data_otherarray, size1*size2*size3 * sizeof( T ) );

  }
  void append(size_t i,const StatArrayDim2<T,size2,size3>& rhs)
  {

        const T* data = rhs.getData();
        // std::copy(data,data+size2,data0+(size1));
        memcpy( _array_data.begin()+(i-1)*size2*size3, data, size2 *size3*sizeof( T ) );


  }
  virtual void assign(const T* data)
  {
     //std::copy(data,data+size1*size2*size3,_array_data.begin());
     memcpy( _array_data.begin(), data, size1*size2*size3 * sizeof( T ) );
  }

  virtual void resize(std::vector<size_t> dims)
  {
      if (dims != getDims())
          std::runtime_error("Cannot resize static array!");
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    return v;
  }
 StatArrayDim3<T,size1,size2,size3>& operator=(const StatArrayDim3<T,size1,size2,size3>& rhs)
 {
  if (this != &rhs)
  {
      _array_data = rhs._array_data;
  }
  return *this;
 }
  virtual T& operator()(const vector<size_t>& idx)
  {
    //row-major order
   return _array_data[(idx[2] - 1) + size3*((idx[1]-1)+size2*(idx[0]-1))];
     //column-major order
    //return _array_data[(idx[2] - 1)*size2*size1 +   (idx[1] - 1)*size1 + (idx[0] - 1)];
  };
 inline virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    //row-major order
    return _array_data[(k - 1) + size3*((j-1)+size2*(i-1))];
    //column-major order
    //return _array_data[(k - 1)*size2*size1 +   (j - 1)*size1 + (i - 1)];
  }

  virtual unsigned int getNumElems() const
  {
    return size1 * size2 * size3;
  }

   virtual unsigned int getNumDims() const
  {
     return 3;
  }

  virtual void setDims(std::vector<size_t> v) { }
  void setDims(size_t i,size_t j,size_t k)  { }
   /*
  access to data
  */
  virtual T* getData()
  {
    return _array_data.c_array();
  }
   /*
  access to data (read-only)
  */
  virtual const T* getData() const
  {
     return _array_data.data();
  }
private:
    boost::array<T, size2 * size1*size3> _array_data;
 // boost::array< boost::array< boost::array<T,size3> ,size2>,size1> _array_data;
};



/*

template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3, std::size_t size4>
class StatArrayDim4 : public BaseArray<T>
{
  //friend class ArrayDim4<T, size1, size2, size3, size4>;
public:
  StatArrayDim4(const T* data)
  {
    for(int i = 0; i < size1; i++)
    {
      for(int j = 0; j < size2; j++)
      {
        for(int k = 0; k < size3; k++)
        {
          for(int l = 0; l < size4; l++)
          {
            _array_data[i][j][k][l] = data[i * size2 * size3 * size4 + j * size3 * size4 + k * size4 + l];//TODO
          }
        }
      }
    }
  }

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


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l)
  {
    return _array_data[i - 1][j - 1][k - 1][l - 1];
  }

  virtual unsigned int getNumElems() const
  {
    return size1 + size2 + size3 + size4;
  }
  virtual void setDims(std::vector<size_t> v)
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


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l, unsigned int m)
  {
    return _array_data[i - 1][j - 1][k - 1][l - 1][m - 1];
  }
  virtual unsigned int getNumElems() const
  {
    return size1 + size2 + size3 + size4 + size5;
  }
  virtual void setDims(std::vector<size_t> v)
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
  :BaseArray<T>(false)
  {
    _multi_array.reindex(1);
  }

  DynArrayDim1(const DynArrayDim1<T>& dynarray)
  :BaseArray<T>(false)
  {
    //assign(dynarray);
    setDims(dynarray.getDims()[0]);
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

  DynArrayDim1(unsigned int size1)
  :BaseArray<T>(false)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }

  DynArrayDim1(const BaseArray<T>& otherArray)
  :BaseArray<T>(false)
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

  virtual void resize(std::vector<size_t> dims)
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
  inline virtual T& operator()(unsigned int index)
  {
    //double tmp = _multi_array[index];
    return _multi_array[index];
  }
  inline virtual const T& operator()(unsigned int index) const
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
  void setDims(unsigned int size1)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(std::vector<size_t> v)
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
  /*
  access to data (read-only)
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
  virtual unsigned int getNumElems() const
  {
    return _multi_array.num_elements();
  }
 virtual unsigned int getNumDims() const
  {
     return 1;
  }
  private:
    boost::multi_array<T, 1> _multi_array;
};


template<typename T >class DynArrayDim2 : public BaseArray<T>
{

public:
  DynArrayDim2()
  :BaseArray<T>(false)
  {
    _multi_array.reindex(1);
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
  :BaseArray<T>(false)
  {
    //assign(dynarray);
    setDims(dynarray.getDims()[0],dynarray.getDims()[1]);
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

   DynArrayDim2(const BaseArray<T>& otherArray)
   :BaseArray<T>(false)
   {
    std::vector<size_t> v = otherArray.getDims();
    if(v.size()!=2)
      throw ModelicaSimulationError(MODEL_ARRAY_FUNCTION,"Wrong number of dimensions in DynArrayDim2");
    _multi_array.resize(v);
    _multi_array.reindex(1);
    const T* data_otherarray = otherArray.getData();
    _multi_array.assign(data_otherarray,data_otherarray+v[0]*v[1]);
   }

  DynArrayDim2(unsigned int size1, unsigned int size2)
  :BaseArray<T>(false)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }
  ~DynArrayDim2(){}

  virtual void resize(std::vector<size_t> dims)
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
     const T* data = otherArray.getData();
    _multi_array.assign(data, data + v[0]*v[1]);
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
  inline virtual T& operator()(const unsigned  int i, const unsigned  int j)
  {
    return _multi_array[i][j];
  }

  void setDims(unsigned int size1, unsigned int size2)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(std::vector<size_t> v)
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

  virtual unsigned int getNumElems() const
  {
    return _multi_array.num_elements();
  }
   virtual unsigned int getNumDims() const
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
private:
  boost::multi_array<T, 2> _multi_array;
};


template<typename T> class DynArrayDim3 : public BaseArray<T>
{
  //friend class ArrayDim3<T, size1, size2, size3>;
public:
  DynArrayDim3()
  :BaseArray<T>(false)
  {
    _multi_array.reindex(1);
  }

  DynArrayDim3(unsigned int size1, unsigned int size2, unsigned int size3)
  :BaseArray<T>(false)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }
  DynArrayDim3(const BaseArray<T>& otherArray)
  :BaseArray<T>(false)
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

  virtual void resize(std::vector<size_t> dims)
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


  void setDims(unsigned int size1, unsigned int size2, unsigned int size3)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(std::vector<size_t> v)
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
  virtual T& operator()(const vector<size_t>& idx)
  {
     return _multi_array[idx[0]][idx[1]][idx[2]];
  };
  inline virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    return _multi_array[i][j][k];
  }

  virtual unsigned int getNumElems() const
  {
    return _multi_array.num_elements();
  }
   virtual unsigned int getNumDims() const
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

  DynArrayDim4(unsigned int size1, unsigned int size2, unsigned int size3, unsigned int size4)
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

  void setDims(unsigned int size1, unsigned int size2, unsigned int size3, unsigned int size4)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    v.push_back(size4);
    _multi_array.resize(v);
    _multi_array.reindex(1);
  }

  virtual void setDims(std::vector<size_t> v)
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


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l)
  {
    return _multi_array[i][j][k][l];
  }

  virtual unsigned int getNumElems() const
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

  DynArrayDim5(unsigned int size1, unsigned int size2, unsigned int size3, unsigned int size4, unsigned int size5)
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

  void setDims(unsigned int size1, unsigned int size2, unsigned int size3, unsigned int size4, unsigned int size5)
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

  virtual void setDims(std::vector<size_t> v)
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


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l, unsigned int m)
  {
    return _multi_array[i][j][k][l][m];
  }

  virtual unsigned int getNumElems() const
  {
    return _multi_array.num_elements();
  }

private:
  boost::multi_array<T,5> _multi_array;
};

*/

