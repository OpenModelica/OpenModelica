//
// Copyright PELAB, Linkoping University
//

#include "modelica_array.hpp"
#include <algorithm>
#include <numeric>

// modelica_real_array::modelica_real_array()
// {

// }

// modelica_real_array::modelica_real_array(std::vector<int> dimensions)
// {
//   m_dim_size = dimensions;
//   m_data.resize(nr_of_elements());
// }

// modelica_real_array::modelica_real_array(std::vector<int> dimensions,
// 					 std::vector<double> scalars)
// {
//   assert(std::accumulate(m_dimensions.begin(),dimensions.end(),1,std::multiplies<int>() 
// 			 == scalars.size()));
//   m_dim_size = dimensions;
//   m_data = scalars;
// }

// modelica_real_array::~modelica_real_array()
// {

// }

// int modelica_real_array::ndims() const
// {
//   return m_dim_size.size();
// }

// std::vector<int> modelica_real_array::size() const
// {
//   return m_dim_size;
// }

// int modelica_real_array::size(int dim) const
// {
//   assert((dim >= 0) && (dim < m_dim_size.size()));
//   return m_dim_size[dim];
// }

// int modelica_real_array::nr_of_elements() const
// {
//   return std::accumulate(m_dim_size.begin(),m_dim_size.end(),1,std::multiplies<int>());
// }

// modelica_real_array modelica_real_array::slice(const index& idx)
// {
  
// }

// int modelica_real_array::compute_data_index(const index& idx) const
// {
//   assert(idx.size() > 0);
//   int stride = idx[0];
//   for (int i = 1; i < idx.size(); ++i)
//     {
//       assert((idx[i] > 0) && (idx[i] < m_dim_size[i]));
//       stride = idx[i] + m_dim_size[i]*stride;
//     }
//   return stride;
  
// }

// double modelica_real_array::operator() (const index& idx) const
// {
//   int data_idx = compute_data_index(idx);
//   assert(data_idx < m_dim_size.size());

//   return m_data[data_idx];
// }

// const modelica_real_array& modelica_real_array::operator+= (const modelica_real_array& arr)
// {
//   assert(dimensions() == arr.dimensions());

//   for (int i = 0; i < m_data.size(); ++i)
//     {
//       m_data[i] += arr.m_data[i];
//     }
//   return *this;
// }

// modelica_real_array modelica_real_array::operator+(const modelica_real_array& arr) const
// {
//   modelica_real_array tmp(*this);
  
//   tmp += arr;
//   return tmp;
// }

// const modelica_real_array& modelica_real_array::operator-= (const modelica_real_array& arr)
// {
//   assert(dimensions() == arr.dimensions());

//   for (int i = 0; i < m_data.size(); ++i)
//     {
//       m_data[i] -= arr.m_data[i];
//     }
//   return *this;
// }

// modelica_real_array modelica_real_array::operator-(const modelica_real_array& arr) const
// {
//   modelica_real_array tmp(*this);
  
//   tmp -= arr;
//   return tmp;
// }

// // modelica_real_array operator+(const modelica_real_array& a, const modelica_real_array& b)
// // {
// //   if ((a.m_dim_size() == 1) && (a.m_dim
// // }

// // const modelica_real_array& operator *= (const modelica_real_array& arr)
// // {
  
// // }
// double modelica_real_array::max() const
// {
//   return *std::max_element(m_data.begin(),m_data.end());
// }

// double modelica_real_array::min() const
// {
//   return *std::min_element(m_data.begin(),m_data.end());
// }

// double modelica_real_array::product() const
// {
//   return std::accumulate(m_data.begin(),m_data.end(),1.0,std::multiplies<double>());
// }

// double modelica_real_array::sum() const
// {
//   return std::accumulate(m_data.begin(),m_data.end(),0.0);
// }

// modelica_real_array modelica_real_array::diagonal() const
// {
//   assert(m_dim_size.size() == 1);

//   int n = m_dim_size.size();
//   modelica_real_array result(index(2,n));

//   for (int i = 0; i < n; ++i)
//     {
//       for (int j = 0; j < n; ++j)
// 	{
// 	  result.m_data[i*n + j] = (i==j) ? m_data[i] : 0;
// 	}
//     }

//   return result;
// }

// // modelica_real_array modelica_real_array::pow(const int c) const
// // {
// //   assert(n>=0);
// //   assert (m_dim_size == 2);
// //   assert(m_dim_size[0] == m_dim_size[1]);

// //   if (n == 0)
// //     {
// //       return *this;
// //     }
// //   else if ( n == 1)
// //     {
// //       return *this;
// //     }
  
  
  
// // }

// modelica_real_array modelica_real_array::skew() const
// {
//   assert(m_dim_size.size() == 1);
//   assert(m_dim_size[0] == 3);

//   modelica_real_array result(index(2,3));

//   result.m_data[0] = 0; 
//   result.m_data[1] = -m_data[2]; 
//   result.m_data[2] = m_data[2]; 
//   result.m_data[3] = m_data[2]; 
//   result.m_data[4] = 0; 
//   result.m_data[5] = -m_data[0]; 
//   result.m_data[6] = m_data[1]; 
//   result.m_data[7] = m_data[0]; 
//   result.m_data[8] = 0;

//   return result;
// }
