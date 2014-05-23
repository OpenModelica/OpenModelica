#pragma once

#include <string>
//#include <vector>
#include <algorithm>
#include <map>
#include <cmath>
using namespace std;
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif

#include <boost/assign/std/vector.hpp> // for 'operator+=()'
#include <boost/assign/list_of.hpp> // for 'list_of()'
#include <boost/unordered_map.hpp>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/numeric/conversion/cast.hpp>
#include "boost/tuple/tuple.hpp"
#include <boost/circular_buffer.hpp>
#include <boost/foreach.hpp>
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/factory_map.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/convenience.hpp"
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/any.hpp>
#include <boost/preprocessor/arithmetic/inc.hpp>
#include <boost/preprocessor/if.hpp>
#include <boost/preprocessor/punctuation/comma_if.hpp>
#include <boost/preprocessor/repetition.hpp>
#include <boost/preprocessor/iteration/iterate.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <boost/multi_array.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
#include <functional>
#include <boost/range/irange.hpp>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/math/special_functions/trunc.hpp>
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/convenience.hpp"
#include "Utils/extension/factory_map.hpp"
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/assert.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <boost/multi_array.hpp>
#include <functional>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/storage.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/unordered_map.hpp>

    /*Namespaces*/
using namespace boost::extensions;
namespace fs = boost::filesystem;
using boost::unordered_map;
namespace uBlas = boost::numeric::ublas;
using namespace boost::extensions;
using namespace boost::assign;
using namespace boost::numeric;
using boost::multi_array;
using boost::const_multi_array_ref;
using boost::multi_array_ref;
using boost::unordered_map;
using boost::lexical_cast;
using boost::numeric_cast;
using boost::tuple;
using boost::tie;
using boost::get;
using boost::make_tuple;
using boost::multi_array;
using boost::array;
using std::max;
using std::min;
using std::string;
using std::vector;
typedef  double modelica_real ;
typedef  int modelica_integer;
typedef  bool modelica_boolean;
typedef  bool  edge_rettype;
typedef  bool sample_rettype;
typedef double cos_rettype;
typedef double cosh_rettype;
typedef double sin_rettype;
typedef double sinh_rettype;
typedef double log_rettype;
typedef double tan_rettype;
typedef double atan_rettype;
typedef double tanh_rettype;
typedef double exp_rettype;
typedef double sqrt_rettype;
typedef double abs_rettype;
typedef double max_rettype;
typedef double min_rettype;
typedef double arctan_rettype;
typedef double floorRetType;
typedef double asinRetType;
typedef double tan_rettype;
typedef double tanhRetType;
typedef double acosRetType;
typedef double logRetType;
typedef double coshRetType;
typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double, adaptor_t> shared_matrix_t;
#include <System/IStateSelection.h>
#include <System/ISystemProperties.h>
#include <System/ISystemInitialization.h>
#include <System/IWriteOutput.h>
#include <System/IContinuous.h>
#include <System/ITime.h>
#include <System/IEvent.h>
#include <Solver/INonLinSolverSettings.h>
#include <DataExchange/IHistory.h>
/*
extern template class boost::multi_array<double,2>; 
extern template class boost::multi_array<double,1>;
extern template class boost::multi_array<int,2>; 
extern template class boost::multi_array<int,1>;
extern template class ublas::vector<double>;
extern template class ublas::vector<int>; 
extern template class uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > ;
*/