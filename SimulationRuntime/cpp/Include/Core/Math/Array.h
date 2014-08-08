#pragma once



template<class T>class BaseArray
{
public:
  BaseArray(){};

  virtual T& operator()(unsigned int i)
  {
    T a;
    return a;
  };
  virtual const T& operator()(unsigned int i) const
  {
    T a;
    return a;
  };
  virtual T& operator()(const unsigned int  i, const unsigned int j)
  {
    T a;
    return a;
  };
  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    T a;
    return a;
  };
  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l)
  {
    T a;
    return a;
  };
  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l, unsigned int m)
  {
    T a ;
    return a;
  };
  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    return v;
  };

  virtual T* getData()
  {
    return NULL;
  };

  virtual unsigned int getNumElems()
  {
    return 0;
  };

  virtual void setDims(std::vector<size_t> v)
  {
  }

};

template<typename T, std::size_t size>class StatArrayDim1 : public BaseArray<T>
{

public:
  StatArrayDim1(const T* data)
  {
    std::copy(data,data+size,_real_array.begin());
  }

  StatArrayDim1(const StatArrayDim1<T,size>& otherarray)
  {
    _real_array = otherarray._real_array;
  }

  StatArrayDim1()
  {
    for(int i = 0; i < size; i++)
    {
      _real_array[i] = 0.0;
    }
    //_real_array.assign(0.0);
  }

  ~StatArrayDim1() {}

  //void assign(StatArrayDim1<T,size> otherArray)
  //{
  //  _real_array = otherArray._real_array;
  //}

  void assign(const T* data)
  {
  for(int i= 0; i < size; i++)
    {
      _real_array[i] = data[i];
    }

  }


  void assign( BaseArray<T>& otherArray)
  {
    std::vector<size_t> v;
    v = otherArray.getDims();
    for(unsigned int i = 1; i <= min(v[0],size); i++)
    {
      _real_array[i-1] = otherArray(i);
    }
  }



  virtual T& operator()(unsigned int index)
  {
    return _real_array[index - 1];
  }
  virtual const T& operator()(unsigned int index) const
  {
    return _real_array[index - 1];
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size);
    return v;
  }

  virtual T* getData()
  {
    return _real_array.data();
  }

  virtual unsigned int getNumElems()
  {
    return size;
  }

  private:
    boost::array<T,size> _real_array;
};

template<typename T ,std::size_t size1,std::size_t size2>class StatArrayDim2 : public BaseArray<T>
{

public:
  StatArrayDim2(const T* data) //const T (&data)     const T (&data)[size1*size2]
  {
    std::copy(data,data+size1*size2,_real_array.begin());

  }

  StatArrayDim2()
  {
  }

  StatArrayDim2(const StatArrayDim2<T,size1,size2>& otherarray)
  {
    _real_array = otherarray._real_array;
  }


  ~StatArrayDim2(){}

  void assign(const StatArrayDim2<T,size1,size2> otherArray)
  {
    _real_array = otherArray._real_array;
  }

  void assign( BaseArray<T>& otherArray)
  {

    std::vector<size_t> v;
    v = otherArray.getDims();
    for(int i = 1; i <= min(v[0],size1); i++)
    {
      for(int j = 1; j <= min(v[1],size2); j++)
      {
        _real_array[size2*(i - 1) + j - 1] = otherArray(i,j);
      }
    }
  }

  void assign(const T* data)//)const T (&data) [size1*size2]
  {
    std::copy(data,data+size1*size2,_real_array.begin());

  }

  virtual T& operator()(const unsigned int i, const unsigned  int j)
  {
    return _real_array[size2*(i - 1) + j - 1];
  }

  virtual std::vector<size_t> getDims() const
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    return v;
  }

  virtual unsigned int getNumElems()
  {
    return size1 + size2;
  }

private:
  //boost::array< boost::array<T, size2>, size1> _real_array;
  boost::array<T, size2 * size1> _real_array;
  //T _real_array[size2*size1];
};





template<typename T ,std::size_t size1, std::size_t size2, std::size_t size3> class StatArrayDim3 : public BaseArray<T>
{
  //friend class ArrayDim3<T, size1, size2, size3>;
public:
  StatArrayDim3(const T data[])
  {
    for(int i = 0; i < size1; i++)
    {
      for(int j = 0; j < size2; j++)
      {
        for(int k = 0; k < size3; k++)
        {
          _real_array[i][j][k] = data[i * size2 * size3 + j * size3 + k];//TODO
        }

      }
    }
  }

  StatArrayDim3()
  {
  }

  ~StatArrayDim3(){}

  void assign(StatArrayDim3<T,size1,size2,size3> otherArray)
  {
    for(int i = 0; i < size1; i++)
    {
      for(int j = 0; j < size2; j++)
      {
        for(int k = 0; k < size3; k++)
        {
          _real_array[i][j][k] = otherArray._real_array[i][j][k];
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
          _real_array[i-1][j-1][k-1] = otherArray(i,j,k);
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
          _real_array[i][j][k] = data[i * size2 * size3 + j * size3 + k];//TODO
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
    return v;
  }

  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    return _real_array[i - 1][j - 1][k - 1];
  }

  virtual unsigned int getNumElems()
  {
    return size1 + size2 + size3;
  }
private:
  boost::array< boost::array< boost::array<T,size3> ,size2>,size1> _real_array;
};





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
            _real_array[i][j][k][l] = data[i * size2 * size3 * size4 + j * size3 * size4 + k * size4 + l];//TODO
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
            _real_array[i][j][k][l] = otherArray._real_array[i][j][k][l];
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
            _real_array[i - 1][j - 1][k - 1][l - 1] = otherArray(i,j,k,l);
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
            _real_array[i][j][k][l] = data[i * size2 * size3 * size4 + j * size3 * size4 + k * size4 + l];
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
    return _real_array[i - 1][j - 1][k - 1][l - 1];
  }

  virtual unsigned int getNumElems()
  {
    return size1 + size2 + size3 + size4;
  }
private:
  boost::array< boost::array< boost::array<boost::array<T,size4>,size3>,size2>,size1> _real_array;
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
              _real_array[i][j][k][l][m] = data[i * size2 * size3 * size4 *size5 + j * size3 * size4 * size5 + k * size4 * size5 + l * size5 + m];
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
              _real_array[i][j][k][l][m] = otherArray._real_array[i][j][k][l][m];
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
              _real_array[i - 1][j - 1][k - 1][l - 1][m - 1] = otherArray(i,j,k,l,m);
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
              _real_array[i][j][k][l][m] = data[i * size2 * size3 * size4 *size5 + j * size3 * size4 * size5 + k * size4 * size5 + l * size5 + m];
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
    return _real_array[i - 1][j - 1][k - 1][l - 1][m - 1];
  }
  virtual unsigned int getNumElems()
  {
    return size1 + size2 + size3 + size4 + size5;
  }
private:
  boost::array< boost::array< boost::array< boost::array<boost::array<T,size5>,size4>,size3>,size2>,size1> _real_array;
};





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




template<typename T>class DynArrayDim1 : public BaseArray<T>
{

public:


  DynArrayDim1()
  {
    _multi_array.reindex(1);
  }

  DynArrayDim1(const DynArrayDim1<T>& dynarray)
  {
    //assign(dynarray);
    setDims(dynarray.getDims()[0]);
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

  DynArrayDim1(unsigned int size1)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }

  DynArrayDim1(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v = otherArray.getDims();
    _multi_array.resize(v);
    _multi_array.reindex(1);
    for (int i = 1; i <= v[0]; i++)
    {
      //double tmp =  otherArray(i);
      _multi_array[i] = otherArray(i);
    }

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
  void assign(const BaseArray<T>& otherArray)
  {
    std::vector<size_t> v = otherArray.getDims();
    _multi_array.resize(v);
    _multi_array.reindex(1);
    for (int i = 1; i <= v[0]; i++)
    {
      //double tmp =  otherArray(i);
      _multi_array[i] = otherArray(i);
    }

  }

  void assign(const T* data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }

  virtual T& operator()(unsigned int index)
  {
    //double tmp = _multi_array[index];
    return _multi_array[index];
  }
  virtual const T& operator()(unsigned int index) const
  {
    //double tmp = _multi_array[index];
    return _multi_array[index];
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

  virtual T* getData()
  {
    return _multi_array.data();
  }

  virtual unsigned int getNumElems()
  {
    return _multi_array.num_elements();
  }

  private:
    boost::multi_array<T, 1> _multi_array;
};

template<typename T >class DynArrayDim2 : public BaseArray<T>
{

public:
  DynArrayDim2()
  {
    _multi_array.reindex(1);
  }

  DynArrayDim2(const DynArrayDim2<T>& dynarray)
  {
    //assign(dynarray);
    setDims(dynarray.getDims()[0],dynarray.getDims()[1]);
    _multi_array.reindex(1);
    _multi_array=dynarray._multi_array;
  }

  DynArrayDim2(unsigned int size1, unsigned int size2)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }
  ~DynArrayDim2(){}

  void assign(DynArrayDim2<T> otherArray)
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
      for (int j = 1; i <= v[1]; i++)
      {
        _multi_array[i][j] = otherArray(i,j);
      }
    }
  }

  void assign(const T& data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
  }

  virtual T& operator()(const unsigned  int i, const unsigned  int j)
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
    const unsigned int* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 2 );
    return ex;
  }

  virtual unsigned int getNumElems()
  {
    return _multi_array.num_elements();
  }

private:
  boost::multi_array<T, 2> _multi_array;
};





template<typename T> class DynArrayDim3 : public BaseArray<T>
{
  //friend class ArrayDim3<T, size1, size2, size3>;
public:
  DynArrayDim3()
  {
    _multi_array.reindex(1);
  }

  DynArrayDim3(unsigned int size1, unsigned int size2, unsigned int size3)
  {
    std::vector<size_t> v;
    v.push_back(size1);
    v.push_back(size2);
    v.push_back(size3);
    _multi_array.resize(v);//
    _multi_array.reindex(1);
  }

  ~DynArrayDim3(){}

  void assign(DynArrayDim3<T> otherArray)
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
      for (int j = 1; i <= v[1]; i++)
      {
        for (int k = 1; i <= v[1]; i++)
        {
          _multi_array[i][j][k] = otherArray(i,j,k);
        }
      }
    }
  }

  void assign(const T& data)
  {
    _multi_array.assign(data, data + _multi_array.num_elements() );
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
    const unsigned int* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 3 );
    return ex;
  }

  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k)
  {
    return _multi_array[i][j][k];
  }

  virtual unsigned int getNumElems()
  {
    return _multi_array.num_elements();
  }

private:
  boost::multi_array<T, 3> _multi_array;
};





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
    const unsigned int* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 4 );
    return ex;
  }


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l)
  {
    return _multi_array[i][j][k][l];
  }

  virtual unsigned int getNumElems()
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

  std::vector<size_t> getDims() const
  {
    const unsigned int* shape = _multi_array.shape();
    std::vector<size_t> ex;
    ex.assign( shape, shape + 5 );
    return ex;
  }


  virtual T& operator()(unsigned int i, unsigned int j, unsigned int k, unsigned int l, unsigned int m)
  {
    return _multi_array[i][j][k][l][m];
  }

  virtual unsigned int getNumElems()
  {
    return _multi_array.num_elements();
  }

private:
  boost::multi_array<T,5> _multi_array;
};



template < typename T>
void multiply_array( BaseArray<T> & inputArray ,const T &b, BaseArray<T> & outputArray  )
{
  outputArray.setDims(inputArray.getDims());
  T* data = inputArray.getData();
  unsigned int nelems = inputArray.getNumElems();
  T* aim = outputArray.getData();
  std::transform (data, data + nelems, aim, std::bind2nd( std::multiplies< T >(), b ));
};

template < typename T, size_t NumDims >
void fill_array( BaseArray<T> & inputArray , T b)
{
  T* data = inputArray.getData();
  unsigned int nelems = inputArray.getNumElems();
  std::fill( data, data + nelems, b);
};

template < typename T, size_t NumDims >
void subtract_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  )
{
  resultArray.setDims(leftArray.getDims());
  T* data1 = leftArray.getData();
  unsigned int nelems = leftArray.getNumElems();
  T* data2 = rightArray.getData();
  T* aim = resultArray.getData();

  std::transform (data1, data1 + nelems, data2, aim, std::minus<T>());
};

template < typename T, size_t NumDims >
void add_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  )
{
  resultArray.setDims(leftArray.getDims());
  T* data1 = leftArray.getData();
  unsigned int nelems = leftArray.getNumElems();
  T* data2 = rightArray.getData();
  T* aim = resultArray.getData();

  std::transform (data1, data1 + nelems, data2, aim, std::plus<T>());
};

template < typename T, size_t dims >
void usub_array(BaseArray<T> & a , BaseArray<T> & b)
{
  b.setDims(a.getDims());
  int numEle =  a.getNumElems();
  for ( unsigned int i = 1;  i <= numEle; i++)
  {
    b(i) = -(a(i));
  }
}

template < typename T, size_t NumDims >
T sum_array ( BaseArray<T> & leftArray )
{
   T val;
   val = std::accumulate( leftArray.getData(), leftArray.getData() + leftArray.getNumElems() ,0 );
   return val;
}
