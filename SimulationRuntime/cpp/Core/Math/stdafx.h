#pragma once


#define WIN32_LEAN_AND_MEAN             // Selten verwendete Teile der Windows-Header nicht einbinden.


// TODO: Hier auf zusätzliche Header, die das Programm erfordert, verweisen.
#pragma once

//typedef ublas::shallow_array_adaptor<double> adaptor_t;
//typedef ublas::vector<double, adaptor_t> shared_vector_t;
//typedef ublas::matrix<double, adaptor_t> shared_matrix_t;
#include <vector>
#include "boost/tuple/tuple.hpp"
#include <boost/array.hpp> 
using std::vector;
using boost::tuple;
using boost::tie;
using boost::get;
using boost::make_tuple;
using boost::array;