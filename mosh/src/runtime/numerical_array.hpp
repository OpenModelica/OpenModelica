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

  
//   /// Returns an array filled with zeros with dimensions given by dim.
//   friend modelica_real_array zeros(std::vector<Tp> dim);

  /// Returns a square matrix with the elements of v on the diagonal and all other elements set to zero.
  friend numerical_array<Tp> diagonal<Tp>(const numerical_array<Tp>& arr);
numerical_array() {};
  numerical_array(std::vector<int> dims) : modelica_array<Tp>(dims) {};
  numerical_array(std::vector<int> dims,std::vector<Tp> scalars) : modelica_array<Tp>(dims,scalars) {};
  
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

  numerical_array<Tp> result(std::vector<int>(2,arr.m_data.size()));
 
  for (int i = 0; i < arr.ndims(); ++i)
    {
      for (int j = 0; j < arr.ndims(); ++j)
 	{
 	  result.m_data[i*arr.ndims() + j] = (i==j) ? arr.m_data[i] : 0;
 	}
     }
  return result;
}

typedef numerical_array<double> real_array;
typedef numerical_array<int> integer_array;

// class real_array : public numerical_array<double>
// {
// public:
//   /// Constructs an empty array.
//   real_array() : numerical_array<double>() {};
  
//   /// Constructs an empty array with specified dimensions dims.
//   real_array(std::vector<int> dims) : numerical_array<double>(dims) {};

//   /// Constructs an array with specified dimensions from scalars.
//   real_array(std::vector<int> dims,std::vector<double> scalars) : numerical_array<double>(dims,scalars) {};
 
//  ~real_array() {};

// };

// class integer_array : public numerical_array<int>
// {

// };

// class boolean_array : public modelica_array<bool>
// {

// };

// class string_array : public modelica_array<std::string>
// {

// };


#endif
