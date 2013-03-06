// stdafx.h : Includedatei für Standardsystem-Includedateien,
// oder projektspezifische Includedateien, die häufig benutzt, aber
// in unregelmäßigen Abständen geändert werden.
//

#pragma once
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif

#define WIN32_LEAN_AND_MEAN

#include <vector>
#include <map>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <string>
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/nvp.hpp>
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/convenience.hpp"
#include "boost/tuple/tuple.hpp"
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <boost/foreach.hpp>
using namespace boost::extensions;
using  boost::tuple;
using  boost::tie;
using namespace boost::numeric;
using namespace std;
using boost::shared_ptr;
using boost::shared_ptr;
using std::vector;
using std::map;
using std::string;
using boost::get;
namespace fs = boost::filesystem;
