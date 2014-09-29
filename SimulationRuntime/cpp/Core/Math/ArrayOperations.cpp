#include <Core/Modelica.h>
#include <Core/Math/ArrayOperations.h>
#include <sstream>
#include <stdio.h>
using namespace std;
//void boost::assertion_failed(char const * expr, char const * function,
//                             char const * file, long line)
//{
//  fprintf(stdout, "Range check failed for Array please check indices \n" );
//}
size_t getNextIndex(vector<size_t> idx,size_t k)
{
  if((idx.size()-1)<k)
    return idx.back();
  else
    return idx[k];
}
/**
Concatenates n real arrays along the k:th dimension.
*/
template < typename T >
void cat_array (int k,BaseArray<T>& a, vector<BaseArray<T>* >& x )
{
    unsigned int new_k_dim_size = 0;
    unsigned int n = x.size();
    /* check dim sizes of all inputs */
    if(n<1)
      throw std::invalid_argument("No input arrays");

    if(x[0]->getDims().size() < k)
     throw std::invalid_argument("Wrong dimension for input array");

    new_k_dim_size = x[0]->getDims()[k-1];
    for(int i = 1; i < n; i++)
    {
        if(x[0]->getDims().size() != x[i]->getDims().size())
           throw std::invalid_argument("Wrong dimension for input array");
        for(int j = 0; j < (k - 1); j++)
        {
            if (x[0]->getDims()[j] != x[i]->getDims()[j])
                throw std::invalid_argument("Wrong size for input array");
        }
        new_k_dim_size += x[i]->getDims()[k-1];
        for(int j = k; j < x[0]->getDims().size(); j++)
        {
          if (x[0]->getDims()[j] != x[i]->getDims()[j])
            throw std::invalid_argument("Wrong size for input array");
        }
    }
    /* calculate size of sub and super structure in 1-dim data representation */
    unsigned int n_sub = 1;
    unsigned int n_super = 1;
    for (int i = 0; i < (k - 1); i++)
    {
        n_super *= x[0]->getDims()[i];
    }
    for (int i = k; i < x[0]->getDims().size(); i++)
    {
        n_sub *= x[0]->getDims()[i];
    }
    /* allocate output array */
    vector<size_t> ex = x[0]->getDims();
    ex[k-1] = new_k_dim_size;
    if(ex.size()<k)
     throw std::invalid_argument("Error resizing concatenate array");
    a.setDims( ex );

  /* concatenation along k-th dimension */
    T* a_data = a.getData();
    int j = 0;
    for(int i = 0; i < n_super; i++)
  {
        for(int c = 0; c < n; c++)
    {
            int n_sub_k = n_sub * x[c]->getDims()[k-1];
            T* x_data = x[c]->getData();
      for(int r = 0; r < n_sub_k; r++)
      {
                a_data[j] =       x_data[r + (i * n_sub_k)];
                j++;
            }
        }
    }


}
/*
creates an array (d) for passed multi array  shape (sp) and initialized it with elements from passed source array (s)
s source array
d destination array
sp (shape,indices) of source array
*/
template < typename T >
void create_array_from_shape(const spec_type& sp,BaseArray<T>& s,BaseArray<T>& d)
{
     //alocate target array
   vector<size_t> shape;
     vector<size_t>::const_iterator iter;
     for(iter = (sp.first).begin();iter!=(sp.first).end();++iter)
     {
          if(*iter!=0)
               shape.push_back(*iter);

     }
     d.setDims(shape);

     //Check if the dimension of passed indices match the dimension of target array
   if(sp.second.size()!=s.getNumDims())
     throw std::invalid_argument("Erro in create array from shape, number of dimensions does not match");

   T* data = new T[d.getNumElems()];

   idx_type::const_iterator spec_iter;
   //calc number of indeces
   size_t n =1;
   for(spec_iter = sp.second.begin();spec_iter!=sp.second.end();++spec_iter)
     {

        n*=spec_iter->size();
   }
   size_t k =0;
     size_t index=0;
   vector<size_t>::const_iterator indeces_iter;

   //initialize target array with elements of source array using passed indices
   vector<size_t> idx;
   for(int i=0;i<n;i++)
   {
    spec_iter = sp.second.begin();
        for(int dim=0;dim<s.getNumDims();dim++)
    {
      size_t idx1 = getNextIndex(*spec_iter,i);
      idx.push_back(idx1);
      spec_iter++;
    }
    if(index>(d.getNumElems()-1))
    {
      throw std::invalid_argument("Erro in create array from shape, number of dimensions does not match");
    }
    data[index] = s(idx);
    idx.clear();
    index++;
   }
   //assign elemets to target array
   d.assign( data );
     delete [] data;
}


 //template < typename T , size_t NumDims, size_t NumDims2 >
template < typename T >
void promote_array(unsigned int n,BaseArray<T>& s,BaseArray<T>& d)
{
   vector<size_t> ex = s.getDims();
   for(int i=0;i<n;i++)
    ex.push_back(1);
   d.setDims(ex);
   T* data = s.getData();
   d.assign( data );
}


template < typename T >
void transpose_array (BaseArray< T >& a, BaseArray< T >&  x )

{
    if(a.getNumDims()!=2 || x.getNumDims()!=2)
       throw std::invalid_argument("Erro in transpose_array, number of dimensions does not match");

    vector<size_t> ex = x.getDims();
    std::swap( ex[0], ex[1] );
    a.setDims(ex);
    a.assign(x);

}

template < typename T>
void multiply_array( BaseArray<T> & inputArray ,const T &b, BaseArray<T> & outputArray  )
{
  outputArray.setDims(inputArray.getDims());
  T* data = inputArray.getData();
  unsigned int nelems = inputArray.getNumElems();
  T* aim = outputArray.getData();
  std::transform (data, data + nelems, aim, std::bind2nd( std::multiplies< T >(), b ));
};


template < typename T>
void divide_array( BaseArray<T> & inputArray ,const T &b, BaseArray<T> & outputArray  )
{
  unsigned int nelems = inputArray.getNumElems();
  if ( outputArray.getNumElems() != nelems)
  {
    outputArray.setDims(inputArray.getDims());
  }
  T* data = inputArray.getData();
  T* aim = outputArray.getData();
  std::transform (data, data + nelems, aim, std::bind2nd( std::divides< T >(), b ));
};


template < typename T >
void fill_array( BaseArray<T> & inputArray , T b)
{
  T* data = inputArray.getData();
  unsigned int nelems = inputArray.getNumElems();
  std::fill( data, data + nelems, b);
};

template < typename T >
void subtract_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  )
{
  resultArray.setDims(leftArray.getDims());
  T* data1 = leftArray.getData();
  unsigned int nelems = leftArray.getNumElems();
  T* data2 = rightArray.getData();
  T* aim = resultArray.getData();

  std::transform (data1, data1 + nelems, data2, aim, std::minus<T>());
};

template < typename T >
void add_array( BaseArray<T> & leftArray , BaseArray<T> & rightArray, BaseArray<T> & resultArray  )
{
  resultArray.setDims(leftArray.getDims());
  T* data1 = leftArray.getData();
  unsigned int nelems = leftArray.getNumElems();
  T* data2 = rightArray.getData();
  T* aim = resultArray.getData();

  std::transform (data1, data1 + nelems, data2, aim, std::plus<T>());
};

template < typename T >
void usub_array(BaseArray<T> & a , BaseArray<T> & b)
{
  b.setDims(a.getDims());
  int numEle =  a.getNumElems();
  for ( unsigned int i = 1;  i <= numEle; i++)
  {
    b(i) = -(a(i));
  }
}

template < typename T>
T sum_array ( BaseArray<T> & leftArray )
{
   T val;
   T* data = leftArray.getData();
   unsigned int dim = leftArray.getNumElems();
   val = std::accumulate( data, data + dim ,0.0 );
   return val;
}


/**
scalar product of two arrays (a,b type as template parameter)
*/
template < typename T >
T dot_array( BaseArray<T> & a ,  BaseArray<T> & b  )
{
  if(a.getNumDims()!=1  || b.getNumDims()!=1)
    throw std::invalid_argument("error in dot array function. Wrong dimension");

  T* data1 = a.getData();
  unsigned int nelems = a.getNumElems();
  T* data2 = b.getData();
  T r = std::inner_product(data1, data1 + nelems, data2, 0.0);
  return r;
};

/**
cross product of two arrays (a,b type as template parameter)
*/
template < typename T >
void cross_array( BaseArray<T> & a ,BaseArray<T> & b, BaseArray<T> & res )
{
  res(1) = (a(2) * b(3)) - (a(3) * b(2));
  res(2) = (a(3) * b(1)) - (a(1) * b(3));
  res(3) = (a(1) * b(2)) - (a(2) * b(1));

};

/**
finds min/max elements of an array */
template < typename T >
std::pair <T,T>
min_max (BaseArray<T>& x)
{
  T* data = x.getData();
  std::pair <T*,T*> ret =
  boost::minmax_element(data, data + x.getNumElems());
  return std::make_pair(*(ret.first),*(ret.second));
}
/*
Explicit template instantiation for double,int,bool
*/
template  void cat_array<double> (int k,BaseArray<double>& a, vector<BaseArray<double>* >& x );
template  void cat_array<int> (int k,BaseArray<int>& a, vector<BaseArray<int>* >& x );
template  void cat_array<bool> (int k,BaseArray<bool>& a, vector<BaseArray<bool>* >& x );

template void transpose_array (BaseArray< double >& a, BaseArray< double >&  x );
template void transpose_array (BaseArray< int >& a, BaseArray< int >&  x );
template void transpose_array (BaseArray< bool >& a, BaseArray< bool >&  x );

template void promote_array(unsigned int n,BaseArray<double>& s,BaseArray<double>& d);
template void promote_array(unsigned int n,BaseArray<int>& s,BaseArray<int>& d);
template void promote_array(unsigned int n,BaseArray<bool>& s,BaseArray<bool>& d);

template void create_array_from_shape(const spec_type& sp,BaseArray<double>& s,BaseArray<double>& d);
template void create_array_from_shape(const spec_type& sp,BaseArray<int>& s,BaseArray<int>& d);
template void create_array_from_shape(const spec_type& sp,BaseArray<bool>& s,BaseArray<bool>& d);



template void multiply_array( BaseArray<double> & inputArray ,const double &b, BaseArray<double> & outputArray  );
template void multiply_array( BaseArray<int> & inputArray ,const int &b, BaseArray<int> & outputArray  );
template void multiply_array( BaseArray<bool> & inputArray ,const bool &b, BaseArray<bool> & outputArray  );


template void divide_array( BaseArray<double> & inputArray ,const double &b, BaseArray<double> & outputArray  );
template void divide_array( BaseArray<int> & inputArray ,const int &b, BaseArray<int> & outputArray  );
template void divide_array( BaseArray<bool> & inputArray ,const bool &b, BaseArray<bool> & outputArray  );


template void fill_array( BaseArray<double> & inputArray , double b);
template void fill_array( BaseArray<int> & inputArray , int b);
template void fill_array( BaseArray<bool> & inputArray , bool b);

template void subtract_array( BaseArray<double> & leftArray , BaseArray<double> & rightArray, BaseArray<double> & resultArray  );
template void subtract_array( BaseArray<int> & leftArray , BaseArray<int> & rightArray, BaseArray<int> & resultArray  );
template void subtract_array( BaseArray<bool> & leftArray , BaseArray<bool> & rightArray, BaseArray<bool> & resultArray  );

template void add_array( BaseArray<double> & leftArray , BaseArray<double> & rightArray, BaseArray<double> & resultArray  );
template void add_array( BaseArray<int> & leftArray , BaseArray<int> & rightArray, BaseArray<int> & resultArray  );
template void add_array( BaseArray<bool> & leftArray , BaseArray<bool> & rightArray, BaseArray<bool> & resultArray  );

template void usub_array(BaseArray<double> & a , BaseArray<double> & b);
template void usub_array(BaseArray<int> & a , BaseArray<int> & b);
template void usub_array(BaseArray<bool> & a , BaseArray<bool> & b);

template double sum_array ( BaseArray<double> & leftArray );
template int sum_array ( BaseArray<int> & leftArray );
template bool sum_array ( BaseArray<bool> & leftArray );

template void cross_array( BaseArray<double> & a ,BaseArray<double> & b, BaseArray<double> & res );
template void cross_array( BaseArray<int> & a ,BaseArray<int> & b, BaseArray<int> & res );
template void cross_array( BaseArray<bool> & a ,BaseArray<bool> & b, BaseArray<bool> & res );

template double dot_array( BaseArray<double> & a ,  BaseArray<double> & b  );
template int dot_array( BaseArray<int> & a ,  BaseArray<int> & b  );
template bool dot_array( BaseArray<bool> & a ,  BaseArray<bool> & b  );

template std::pair <double,double> min_max (BaseArray<double>& x);
template std::pair <int,int> min_max (BaseArray<int>& x);
template std::pair <bool,bool> min_max (BaseArray<bool>& x);