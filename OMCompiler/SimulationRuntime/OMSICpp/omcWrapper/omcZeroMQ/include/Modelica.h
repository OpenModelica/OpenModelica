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
#include  <iostream>
#include  <iterator>

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
namespace omcpp
{
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


/** @} */ // end of group1
