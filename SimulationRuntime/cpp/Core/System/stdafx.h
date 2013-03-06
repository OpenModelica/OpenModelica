#pragma once

#pragma warning (disable: 4996)
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif
//includes for string algorithms
#include <string>
#include <vector>
#include <algorithm>
#include <map>
//#include <unordered_map>
#include <boost/unordered_map.hpp>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include "boost/tuple/tuple.hpp"
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>

/* Vorübergehend deaktiviert
#include <boost/log/common.hpp>
#include <boost/log/attributes.hpp>
#include <boost/log/utility/init/from_stream.hpp>
#include <boost/log/sources/severity_channel_logger.hpp>

namespace logging = boost::log;
namespace attrs = boost::log::attributes;
namespace src = boost::log::sources;
namespace keywords = boost::log::keywords;
*/

#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/convenience.hpp"
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/unordered_map.hpp>
#include <boost/any.hpp>
#include <valarray>
using namespace boost::extensions;
using  boost::tuple;
using  boost::tie;
using namespace boost::numeric;
using namespace std;
using boost::shared_ptr;

using std::vector;
using std::map;
using std::string;
using boost::get;
using namespace std;
using boost::unordered_map;
namespace fs = boost::filesystem;
#undef min
#undef max
using std::min;
using std::max;
