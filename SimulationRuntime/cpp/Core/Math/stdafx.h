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
#include <boost/multi_array.hpp>
#include <functional>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/assert.hpp>
#include <boost/algorithm/minmax_element.hpp>
using namespace boost::numeric;
using boost::multi_array;
using boost::const_multi_array_ref;
using boost::multi_array_ref;
using std::vector;
using boost::tuple;
using boost::tie;
using boost::get;
using boost::make_tuple;
using boost::array;


