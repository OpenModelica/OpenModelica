#pragma once
/** @addtogroup core
 *
 *  @{
 */


#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <cmath>
#include <numeric>

#include <boost/assign/std/vector.hpp> // for 'operator+=()'
#include <boost/assign/list_of.hpp> // for 'list_of()'
#include <boost/unordered_map.hpp>
#include <boost/unordered_set.hpp>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/numeric/conversion/cast.hpp>
#include <boost/tuple/tuple.hpp>
#include <boost/circular_buffer.hpp>
#include <boost/foreach.hpp>
#include <boost/algorithm/string.hpp>
#include <boost/any.hpp>
#include <boost/preprocessor/arithmetic/inc.hpp>
#include <boost/preprocessor/if.hpp>
#include <boost/preprocessor/punctuation/comma_if.hpp>
#include <boost/preprocessor/repetition.hpp>
#include <boost/preprocessor/iteration/iterate.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <boost/multi_array.hpp>
#include <boost/weak_ptr.hpp>
#include <functional>
#include <boost/range/irange.hpp>
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <boost/numeric/ublas/storage.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/math/special_functions/trunc.hpp>
#include <boost/assert.hpp>
#include <boost/algorithm/minmax_element.hpp>
#include <boost/multi_array.hpp>
#include <functional>
#include <boost/unordered_map.hpp>
#include <boost/assign/list_inserter.hpp>
#include <boost/ptr_container/ptr_vector.hpp>
//#include <boost/timer/timer.hpp>
#include <boost/noncopyable.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <fstream>

 /*Namespaces*/
#ifndef _MSC_VER
using namespace std;
#endif //_MSC_VER
using std::ios;
using std::endl;
using std::cout;
using std::cerr;
using std::ostream_iterator;
using boost::unordered_map;
namespace uBlas = boost::numeric::ublas;
using namespace boost::numeric;
using std::map;
using std::pair;
using std::make_pair;
using namespace boost::assign;
using boost::multi_array;
using namespace boost::algorithm;
using boost::const_multi_array_ref;
using boost::multi_array_ref;
using boost::unordered_map;
using boost::lexical_cast;
using boost::numeric_cast;
using boost::tie;
using boost::get;
using boost::make_tuple;
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

#if defined(USE_CPP_ELEVEN)
  #include <array>
  #include <thread>
  #include <atomic>
  #include <mutex>
  #include <condition_variable>
  #include <tuple>
  #include <memory>
  using std::bind;
  using std::function;
  using std::thread;
  using std::atomic;
  using std::mutex;
  using std::memory_order_release;
  using std::memory_order_relaxed;
  using std::condition_variable;
  using std::unique_lock;

  using std::array;
  using std::tuple;
  using std::shared_ptr;
  using std::weak_ptr;
  using std::dynamic_pointer_cast;
#else
  #include <boost/array.hpp>
  #include <boost/shared_ptr.hpp>
  #include <boost/weak_ptr.hpp>
  #if defined(USE_THREAD)
    #include <boost/thread.hpp>
    #include <boost/atomic.hpp>
    #include <boost/thread/mutex.hpp>
    using boost::bind;
    using boost::function;
    using boost::thread;
    using boost::atomic;
    using boost::mutex;
    using boost::memory_order_release;
    using boost::memory_order_relaxed;
    using boost::condition_variable;
    using boost::unique_lock;
    using boost::dynamic_pointer_cast;
  #endif //USE_THREAD

  using boost::array;
  using boost::tuple;
  using boost::shared_ptr;
  using boost::weak_ptr;
#endif //USE_CPP_ELEVEN

#if defined(USE_THREAD)
  #include <Core/Utils/extension/busywaiting_barrier.hpp>
#endif //USE_THREAD

//using boost::timer::cpu_timer;
//using boost::timer::cpu_times;
//using boost::timer::nanosecond_type;
typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double,  ublas::column_major,adaptor_t> shared_matrix_t;
//typedef boost::function<bool (unsigned int)> getCondition_type;
//typedef boost::function<void (unordered_map<string,unsigned int>&,unordered_map<string,unsigned int>&)> init_prevars_type;
typedef uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > sparsematrix_t;
typedef ublas::matrix<double, ublas::column_major> matrix_t;
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <Core/Solver/ISolverSettings.h>
#include <Core/SimulationSettings/ISettingsFactory.h>
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <Core/Utils/Modelica/ModelicaSimulationError.h>
#include <Core/Utils/Modelica/ModelicaUtilities.h>
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
#include <Core/System/IAlgLoop.h>
#include <Core/Solver/ISolver.h>
#include <Core/Solver/IAlgLoopSolver.h>
#include <Core/System/IAlgLoopSolverFactory.h>
#include <Core/System/ISimVars.h>
#include <Core/System/PreVariables.h>
#include <Core/DataExchange/ISimVar.h>
#include <Core/SimController/ISimData.h>
#include <Core/SimulationSettings/ISimControllerSettings.h>
#include <Core/Math/Functions.h>
#include <Core/Math/ArrayOperations.h>
#include <Core/Math/ArraySlice.h>
#include <Core/Math/Utility.h>
#include <Core/DataExchange/IPropertyReader.h>
#include <Core/DataExchange/Writer.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/DataExchange/Policies/MatfileWriter.h>
#include <Core/DataExchange/Policies/BufferReaderWriter.h>
#include <Core/HistoryImpl.h>
#include <Core/DataExchange/SimDouble.h>
/** @} */ // end of group1
