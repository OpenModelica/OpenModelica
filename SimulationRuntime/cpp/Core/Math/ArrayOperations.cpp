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
template  void cat_array<double> (int k,BaseArray<double>& a, vector<BaseArray<double>* >& x );
template  void cat_array<int> (int k,BaseArray<int>& a, vector<BaseArray<int>* >& x );
template  void cat_array<bool> (int k,BaseArray<bool>& a, vector<BaseArray<bool>* >& x );