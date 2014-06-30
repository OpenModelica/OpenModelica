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
#include <boost/tuple/tuple.hpp>
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
#include <boost/program_options.hpp>
#include <boost/assign/list_inserter.hpp>
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
namespace po = boost::program_options;
namespace fs = boost::filesystem;

typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double, adaptor_t> shared_matrix_t;
typedef boost::function<bool (unsigned int)> getCondition_type;
typedef boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)> init_prevars_type;
#include <System/IStateSelection.h>
#include <System/ISystemProperties.h>
#include <System/ISystemInitialization.h>
#include <System/IWriteOutput.h>
#include <System/IContinuous.h>
#include <System/ITime.h>
#include <System/IEvent.h>
#include <Solver/INonLinSolverSettings.h>
#include <Solver/ILinSolverSettings.h>
#include <DataExchange/IHistory.h>
#include <System/IMixedSystem.h>
#include <SimulationSettings/IGlobalSettings.h>
#include <System/IMixedSystem.h>
#include <System/IAlgLoop.h>
#include <Solver/ISolverSettings.h>
#include <Solver/ISolver.h>
#include <Solver/IAlgLoopSolver.h>
#include <System/IAlgLoopSolverFactory.h>
#include <SimController/ISimData.h>
#include <SimulationSettings/ISimControllerSettings.h>
#include <Math/Functions.h>
#include <Math/ArrayOperations.h>
#include <Math/Utility.h>
#include <Math/SparseMatrix.h>
#include "HistoryImpl.h"
#include "DataExchange/Policies/TextfileWriter.h"

