#pragma once

#ifndef FORCE_INLINE
  #if defined(_MSC_VER)
    #define FORCE_INLINE __forceinline
  #else
    #define FORCE_INLINE __attribute__((always_inline))
  #endif
#endif

#include <string>
//#include <vector>
#include <algorithm>
#include <map>
#include <cmath>
#include <numeric>
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
#if defined (__vxworks)
#else 
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/factory_map.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/convenience.hpp"
#endif
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
#include <Core/Utils/extension/extension.hpp>
#include <Core/Utils/extension/factory.hpp>
#include <Core/Utils/extension/type_map.hpp>
#include <Core/Utils/extension/factory_map.hpp>
#if defined (__vxworks)
#else 
#include <Core/Utils/extension/shared_library.hpp>
#include <Core/Utils/extension/convenience.hpp>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#endif
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
#if defined (__vxworks)
#else 
#include <boost/program_options.hpp>
#endif
#include <boost/assign/list_inserter.hpp>
#include <boost/ptr_container/ptr_vector.hpp>
#include <boost/array.hpp>

//#include <boost/timer/timer.hpp>
#include <boost/noncopyable.hpp>
    /*Namespaces*/
using namespace boost::extensions;
#if defined (__vxworks)
#else 
namespace fs = boost::filesystem;
#endif
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
#if defined (__vxworks)
#else
namespace po = boost::program_options;
namespace fs = boost::filesystem;
#endif
//using boost::timer::cpu_timer;
//using boost::timer::cpu_times;
//using boost::timer::nanosecond_type;
typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double, adaptor_t> shared_matrix_t;
typedef boost::function<bool (unsigned int)> getCondition_type;
typedef boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)> init_prevars_type;
#include <Core/Math/Array.h>
#include <Core/System/IStateSelection.h>
#include <Core/System/ISystemProperties.h>
#include <Core/System/ISystemInitialization.h>
#include <Core/System/IWriteOutput.h>
#include <Core/System/IContinuous.h>
#include <Core/System/ITime.h>
#include <Core/System/IEvent.h>
#include <Core/System/IStepEvent.h>
#include <Core/Solver/INonLinSolverSettings.h>
#include <Core/Solver/ILinSolverSettings.h>
#include <Core/DataExchange/IHistory.h>
#include <Core/System/IMixedSystem.h>
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <Core/System/IMixedSystem.h>
#include <Core/System/IAlgLoop.h>
#include <Core/Solver/ISolverSettings.h>
#include <Core/Solver/ISolver.h>
#include <Core/Solver/IAlgLoopSolver.h>
#include <Core/System/IAlgLoopSolverFactory.h>
#include <Core/SimController/ISimData.h>
#include <Core/SimulationSettings/ISimControllerSettings.h>
#include <Core/Math/Functions.h>
#include <Core/Math/ArrayOperations.h>
#include <Core/Math/Utility.h>
#include <Core/Math/SparseMatrix.h>
#include <Core/HistoryImpl.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/DataExchange/Policies/MatfileWriter.h>
#if defined (__vxworks)
#include <Core/SimulationSettings/ISettingsFactory.h>
#endif
