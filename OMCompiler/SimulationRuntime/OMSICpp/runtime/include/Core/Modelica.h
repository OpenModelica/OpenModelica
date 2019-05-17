#pragma once
/** @addtogroup core
 *
 *  @{
 */

#include <string>
#include <vector>
#include <algorithm>
#include <deque>
#include <map>
#include <cmath>
#include <numeric>
#include <functional>

#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <boost/numeric/ublas/storage.hpp>

#include <boost/container/vector.hpp>
#include <boost/lambda/bind.hpp>
#include <boost/lambda/lambda.hpp>
/*Namespaces*/
using std::abs;
using std::ios;
using std::endl;
using std::cout;
using std::cerr;
using std::ostream_iterator;
using std::map;
using std::pair;
using std::make_pair;
using std::max;
using std::min;
using std::string;
using std::ostream;
using std::ostringstream;
using std::stringstream;
using std::vector;
using std::deque;
using std::copy;
using std::exception;
using std::runtime_error;

// uBLAS library
namespace ublas = boost::numeric::ublas;

#if !defined(USE_CPP_03) && !defined(__vxworks)
  #include <array>
  #include <tuple>
  #include <memory>
  #include <unordered_map>
  #include <unordered_set>
  #include <chrono>
   using namespace std::chrono;
  #define USE_CHRONO
  #if defined(USE_THREAD)
    #include <thread>
    #include <atomic>
    #include <mutex>
    #include <condition_variable>
    using std::thread;
    using std::atomic;
    using std::mutex;
    using std::memory_order_release;
    using std::memory_order_relaxed;
    using std::condition_variable;
    using std::unique_lock;
  #endif //USE_THREAD

  // builtin range based for loop
  #define FOREACH(element, range) for(element : range)

  // builtin list initializers
  #define LIST_OF {
  #define LIST_SEP ,
  #define LIST_END }
  #define MAP_LIST_OF {{
  #define MAP_LIST_SEP },{
  #define MAP_LIST_END }}
  #define TUPLE_LIST_OF {std::make_tuple(
  #define TUPLE_LIST_SEP ),std::make_tuple(
  #define TUPLE_LIST_END )}

  /** namespace for generated code to avoid name clashes */
  namespace omcpp {
    using std::ref;
    using std::trunc;
    using std::to_string;
  }
  using std::bind;
  using std::function;
  using std::make_tuple;
  using std::array;
  using std::isfinite;
  using std::minmax_element;
  using std::get;
  using std::tuple;
  using std::unordered_map;
  using std::unordered_set;
  using std::shared_ptr;
  using std::weak_ptr;
  using std::dynamic_pointer_cast;
  using std::to_string;
#else
  #if defined(_MSC_VER)
    #include <tuple>
    using std::get;
    using std::tuple;
    using std::make_tuple;
    using std::minmax_element;
  #else
    #include <boost/tuple/tuple.hpp>
    #include <boost/algorithm/minmax_element.hpp>
    using boost::get;
    using boost::tuple;
    using boost::make_tuple;
    using boost::minmax_element;
  #endif
  #include <boost/foreach.hpp>
  #include <boost/lexical_cast.hpp>
  #include <boost/assign/list_of.hpp>
  #include <boost/array.hpp>
  #include <boost/math/special_functions/fpclassify.hpp>
  #include <boost/math/special_functions/trunc.hpp>
  #include <boost/unordered_map.hpp>
  #include <boost/unordered_set.hpp>
  #include <boost/ref.hpp>
  #include <boost/shared_ptr.hpp>
  #include <boost/weak_ptr.hpp>

  #if defined(USE_THREAD)
    #include <boost/thread.hpp>
    #include <boost/atomic.hpp>
    #include <boost/thread/mutex.hpp>
    #include <boost/bind.hpp>
    using boost::bind;
    using boost::function;
    using boost::thread;
    using boost::atomic;
    using boost::mutex;
    using boost::memory_order_release;
    using boost::memory_order_relaxed;
    using boost::condition_variable;
    using boost::unique_lock;
  #endif //USE_THREAD

  // boost range based for loop
  #define FOREACH BOOST_FOREACH

  // boost list initializers
  #define LIST_OF boost::assign::list_of(
  #define LIST_SEP )(
  #define LIST_END )
  #define MAP_LIST_OF boost::assign::map_list_of(
  #define MAP_LIST_SEP )(
  #define MAP_LIST_END )
  #define TUPLE_LIST_OF boost::assign::tuple_list_of(
  #define TUPLE_LIST_SEP )(
  #define TUPLE_LIST_END )

  /** namespace for generated code to avoid name clashes */
  namespace omcpp {
    using boost::ref;
    using boost::math::trunc;
    template <typename T>
    std::string to_string(T val) {
      return boost::lexical_cast<std::string>(val);
    }
  }
  using boost::array;
  using boost::math::isfinite;
  using boost::unordered_map;
  using boost::unordered_set;
  using boost::shared_ptr;
  using boost::weak_ptr;
  using boost::dynamic_pointer_cast;
  using omcpp::to_string;
  using namespace boost::lambda;
#endif //!USE_CPP_03

#if defined(USE_THREAD)
  #include <Core/Utils/extension/barriers.hpp>
#endif //USE_THREAD


typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double,  ublas::column_major,adaptor_t> shared_matrix_t;

//typedef boost::function<bool (unsigned int)> getCondition_type;
//typedef boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)> init_prevars_type;
typedef ublas::compressed_matrix<double, ublas::column_major, 0, ublas::unbounded_array<int>, ublas::unbounded_array<double> > sparsematrix_t;
typedef ublas::matrix<double, ublas::column_major> matrix_t;
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <Core/Solver/ISolverSettings.h>
#include <Core/SimulationSettings/ISettingsFactory.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <Core/Utils/Modelica/ModelicaSimulationError.h>
#include <ModelicaUtilities.h>
#include <Core/Math/Array.h>
#include <Core/System/IStateSelection.h>
#include <Core/System/ISystemProperties.h>
#include <Core/System/ISystemInitialization.h>
#include <Core/System/IWriteOutput.h>
#include <Core/System/IContinuous.h>
#include <Core/System/ITime.h>
#include <Core/System/IEvent.h>
#include <Core/System/IStepEvent.h>
#include <Core/System/IOMSI.h>
//OpenModelica Simulation Interface
#include <Core/Solver/INonLinSolverSettings.h>
#include <Core/Solver/ILinSolverSettings.h>
#include <Core/DataExchange/IHistory.h>
#include <Core/System/ILinearAlgLoop.h>
#include <Core/System/INonLinearAlgLoop.h>
#include <Core/System/ISystemTypes.h>
#include <Core/Solver/ISolver.h>
#include <Core/Solver/ILinearAlgLoopSolver.h>
#include <Core/Solver/INonLinearAlgLoopSolver.h>
#include <Core/System/IAlgLoopSolverFactory.h>
#include <Core/System/ISimVars.h>
#include <Core/DataExchange/ISimVar.h>
#include <Core/SimController/ISimData.h>
#include <Core/System/ISimObjects.h>
#include <Core/System/IMixedSystem.h>
#include <Core/SimulationSettings/ISimControllerSettings.h>
#include <Core/Math/Functions.h>
#include <Core/Math/ArrayOperations.h>
#include <Core/Math/ArraySlice.h>
#include <Core/Math/Utility.h>
#include <Core/DataExchange/IPropertyReader.h>
#include <Core/DataExchange/SimDouble.h>
#ifdef USE_REDUCE_DAE
#include <Core/ReduceDAE/IReduceDAE.h>
#include <core/ReduceDAE/ReduceDAESettings.h>
#endif
/** @} */ // end of group1
