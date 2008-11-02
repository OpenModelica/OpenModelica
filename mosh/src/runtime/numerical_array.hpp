/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/


#ifndef NUMERICAL_ARRAY_
#define NUMERICAL_ARRAY_

#include "modelica_array.hpp"

template <class Tp>
class numerical_array : public modelica_array<Tp>
{
public:
  virtual ~numerical_array() {};

  // **** Reduction functions ******
  /// Returns the largest element.
  Tp max() const;

  /// Returns the smallest element.
  Tp min() const;

  /// Returns the product of the elements.
  Tp product() const;

  /// Returns the sum of the elements.
  Tp sum() const;



  /// Returns a square matrix with the elements of v on the diagonal and all other elements set to zero.
  friend numerical_array<Tp> diagonal<Tp>(const numerical_array<Tp>& arr);

  // arithmetic operators
  const numerical_array<Tp>& operator+= (const numerical_array<Tp>& arr);
  numerical_array<Tp> operator+(const numerical_array<Tp>& arr) const;

  const numerical_array<Tp>& operator-= (const numerical_array<Tp>& arr);
  numerical_array<Tp> operator-(const numerical_array<Tp>& arr) const;

  numerical_array<Tp> operator- () const;

  numerical_array<Tp>& operator*= (const numerical_array<Tp>& arr);

  numerical_array<Tp> operator* (const numerical_array<Tp>& arr) const;
  numerical_array<Tp>& operator*= (const Tp& s);
  numerical_array<Tp> operator* (const Tp& s);

  numerical_array<Tp>& operator/= (const Tp& s);
  numerical_array<Tp> operator/ (const Tp& s);

  friend Tp mul_vector_vector<Tp>(const numerical_array<Tp>& v1,const numerical_array<Tp>& v2);
  friend numerical_array<Tp> mul_vector_matrix<Tp>(const numerical_array<Tp>& v1, const numerical_array<Tp>& v2);
  friend numerical_array<Tp> mul_matrix_vector<Tp>(const numerical_array<Tp>& v1, const numerical_array<Tp>& v2);

  numerical_array() {};
  numerical_array(std::vector<int> dims) : modelica_array<Tp>(dims) {};
  numerical_array(std::vector<int> dims,std::vector<Tp> scalars) : modelica_array<Tp>(dims,scalars) {};
  numerical_array(modelica_array<Tp> const& arr) : modelica_array<Tp>(arr) {};
protected:

};

template <class Tp>
Tp numerical_array<Tp>::max() const
{
  return *std::max_element(m_data.begin(),m_data.end());
}

template <class Tp>
Tp numerical_array<Tp>::min() const
{
  return *std::min_element(m_data.begin(),m_data.end());
}

template <class Tp>
Tp numerical_array<Tp>::product() const
{
  return std::accumulate(m_data.begin(),m_data.end(),Tp(1),std::multiplies<Tp>());
}

template <class Tp>
Tp numerical_array<Tp>::sum() const
{
  return std::accumulate(m_data.begin(),m_data.end(),Tp(0));
}

template <class Tp>
numerical_array<Tp> diagonal(const numerical_array<Tp>& arr)
{
  assert(arr.ndims() == 1);

  int n = arr.m_data.size();
  numerical_array<Tp> result(std::vector<int>(2,n));

  for (int i = 0; i < n; ++i)
    {
      for (int j = 0; j < n; ++j)
 	{
 	  result.m_data[i*n + j] = (i==j) ? arr.m_data[i] : 0;
 	}
     }
  return result;
}

template <typename Tp>
const numerical_array<Tp>& numerical_array<Tp>::operator+= (const numerical_array<Tp>& arr)
{
  assert(m_dim_size == arr.m_dim_size);


  for (size_t i = 0; i < m_data.size(); ++i)
    {
      m_data[i] += arr.m_data[i];
    }
  return *this;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator+(const numerical_array<Tp>& arr) const
{
  numerical_array tmp(*this);

  tmp += arr;
  return tmp;
}

template <typename Tp>
const numerical_array<Tp>& numerical_array<Tp>::operator-= (const numerical_array<Tp>& arr)
{
  assert(m_dim_size == arr.m_dim_size);


  for (size_t i = 0; i < m_data.size(); ++i)
    {
      m_data[i] -= arr.m_data[i];
    }
  return *this;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator-(const numerical_array<Tp>& arr) const
{
  numerical_array tmp(*this);

  tmp -= arr;
  return tmp;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator- () const
{
  numerical_array<Tp> tmp(*this);
  for (size_t i = 0; i < m_data.size(); ++i)
    {
      tmp.m_data[i] = -m_data[i];
    }
  return tmp;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator* (const numerical_array<Tp>& arr) const
{
  assert(ndims() == 2);
  assert(arr.ndims() ==2);
  assert(m_dim_size[1] == arr.m_dim_size[0]);

  int i_size = m_dim_size[0];
  int j_size = arr.m_dim_size[1];
  int k_size = m_dim_size[1];

  std::vector<int> result_dims(2);
  result_dims[0] = i_size; // Number of rows in result
  result_dims[1] = j_size; // Number of cols in result

  numerical_array<Tp> result(result_dims);
  for (int i = 0; i < i_size; ++i)
    {
      for (int j = 0; j < j_size; ++j)
	{
	  Tp tmp = static_cast<Tp>(0);
	  for (int k = 0; k < k_size; ++k)
	    {
	      tmp += m_data[i*k_size+k]*arr.m_data[k*j_size+j];
	    }
	  result.m_data[i*j_size+j] = tmp;
	}
    }
  return result;
}

template<typename Tp>
Tp mul_vector_vector(const numerical_array<Tp>& v1,const numerical_array<Tp>& v2)
{
  assert(v1.ndims() == 1);
  assert(v2.ndims() == 1);
  assert(v1.m_dim_size[0] == v2.m_dim_size[0]);

  return std::inner_product(v1.m_data.begin(),v1.m_data.end(),v2.m_data.begin(),static_cast<Tp>(0));
}

template<typename Tp>
numerical_array<Tp> mul_vector_matrix(const numerical_array<Tp>& v1, const numerical_array<Tp>& v2)
{
  assert(v1.ndims() == 1);
  assert(v2.ndims() == 2);
  assert(v1.m_dim_size[0] == v2.m_dim_size[0]);

  int i_size = v2.m_dim_size[1];
  int j_size = v2.m_dim_size[0];

  numerical_array<Tp> result(std::vector<int>(1,v2.m_dim_size[1]));

  for (int i = 0; i < i_size; ++i)
    {
      Tp tmp = static_cast<Tp>(0);
      for (int j = 0; j < j_size; ++j)
	{
	  tmp += v1.m_data[j]*v2.m_data[j*i_size+i];
	}
      result.m_data[i] = tmp;
    }

  return result;
}

template<typename Tp>
numerical_array<Tp> mul_matrix_vector(const numerical_array<Tp>& v1, const numerical_array<Tp>& v2)
{
  assert(v1.ndims() == 2);
  assert(v2.ndims() == 1);
  assert(v1.m_dim_size[1] == v2.m_dim_size[0]);

  int i_size = v1.m_dim_size[0];
  int j_size = v1.m_dim_size[1];

  numerical_array<Tp> result(std::vector<int>(1,v1.m_dim_size[0]));

  for (int i = 0; i < i_size; ++i)
    {
      Tp tmp = static_cast<Tp>(0);
      for (int j = 0; j < j_size; ++j)
	{
	  tmp += v1.m_data[i*j_size+j]*v2.m_data[j];
	}
      result.m_data[i] = tmp;
    }

  return result;
}

// template<typename Tp>
// numerical_array<Tp>& numerical_array<Tp>::operator*= (const numerical_array<Tp>& arr)
// {

//   if ( (m_dims_size.size() == 1 ) && (arr.m_dim_size.size() == 1))
//     {
//       if (m_dims_size[0] == val.m_dim_size[0])
// 	{
// 	  std::inner_product(m_data.begin(),m_data.end(),arr.m_data.begin(),0);
// 	}
//       else
// 	{
// 	  throw modelica_runtime_error("Incompatible vector dimensions\n");
// 	}
//     }
//   for (size_t i = 0; i < m_data.size(); ++i)
//     {
//       m_data[i] *= s;
//     }
//   return *this;
// }

template<typename Tp>
numerical_array<Tp>& numerical_array<Tp>::operator*= (const Tp& s)
{
  for (size_t i = 0; i < m_data.size(); ++i)
    {
      m_data[i] *= s;
    }
  return *this;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator * (const Tp& s)
{
  numerical_array tmp(*this);

  tmp *= s;
  return tmp;
}

template<typename Tp>
numerical_array<Tp>& numerical_array<Tp>::operator/= (const Tp& s)
{
  for (size_t i = 0; i < m_data.size(); ++i)
    {
      m_data[i] /= s;
    }
  return *this;
}

template<typename Tp>
numerical_array<Tp> numerical_array<Tp>::operator/ (const Tp& s)
{
  numerical_array tmp(*this);

  tmp *= s;
  return tmp;
}

class real_array : public numerical_array<double>
{
public:
  /// Constructs an empty array.
  real_array() : numerical_array<double>() {};

  /// Constructs an empty array with specified dimensions dims.
  real_array(std::vector<int> dims) : numerical_array<double>(dims) {};

  /// Constructs an array with specified dimensions from scalars.
  real_array(std::vector<int> dims,std::vector<double> scalars) : numerical_array<double>(dims,scalars) {};

  real_array(modelica_array<double> const& arr) : numerical_array<double>(arr) {};

  real_array(modelica_array<int> const& arr)
  {
    m_dim_size = arr.size();
    m_ndims = m_dim_size.size();
    m_data.resize(nr_of_elements());
    std::copy(arr.data_begin(),arr.data_end(),m_data.begin());
  }


 ~real_array() {};

};


class integer_array : public numerical_array<int>
{
public:
  /// Constructs an empty array.
  integer_array() : numerical_array<int>() {};

  /// Constructs an empty array with specified dimensions dims.
  integer_array(std::vector<int> dims) : numerical_array<int>(dims) {};

  /// Constructs an array with specified dimensions from scalars.
  integer_array(std::vector<int> dims,std::vector<int> scalars) : numerical_array<int>(dims,scalars) {};
  integer_array(modelica_array<int> const& arr) : numerical_array<int>(arr) {};

  //integer_array(const modelica_array<int>& arr) : modelica_array<int>(arr) {};
  //  integer_array(const modelica_array<int>& arr) { m_dim_size = arr.m_dim_size;};

 ~integer_array() {};



  /// Returns the n x n identity matrix.
  //  friend integer_array identity_matrix(int n);

//   /// Returns an array filled with zeros with dimensions given by dim.
//   friend integer_array zeros(std::vector<int> dims);

//   /// Returns an array filled with ones with dimensions given by dim.
//   friend integer_array ones(std::vector<int> dims);

};


// integer_array identity_matrix(int n)
// {
//   assert (n >= 1);

//   integer_array result(std::vector<int>(2,n));

//   for (int i = 0; i < n; ++i)
//     {
//       for (int j = 0; j < n; ++j)
// 	{
// 	  result.m_data[i*n + j] = (i==j) ? 1 : 0;
// 	}
//     }
//   return result;
// }

// integer_array zeros(std::vector<int> dims)
// {
//   integer_array result(dims);

//   for (int i = 0; i < result.nr_of_elements(); ++i)
//     {
//       result.m_data[i] = 0;
//     }
//   return result;
// }

// integer_array ones(std::vector<int> dims)
// {
//   integer_array result(dims);

//   for (int i = 0; i < result.nr_of_elements(); ++i)
//     {
//       result.m_data[i] = 1;
//     }
//   return result;
// }

class boolean_array : public modelica_array<bool>
{

};

class string_array : public modelica_array<std::string>
{

};


#endif
