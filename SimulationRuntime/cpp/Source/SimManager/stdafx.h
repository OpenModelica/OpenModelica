// stdafx.h : Includedatei für Standardsystem-Includedateien,
// oder projektspezifische Includedateien, die häufig benutzt, aber
// in unregelmäßigen Abständen geändert werden.
//

#pragma once
#include <string>
#include <sstream>

#include <map>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include "boost/tuple/tuple.hpp"
#include <boost/shared_ptr.hpp>
#include <boost/extension/type_map.hpp>
#include <boost/extension/shared_library.hpp>
#include <boost/extension/convenience.hpp>
using namespace boost::extensions;
using  boost::tuple;
using  boost::tie;
using namespace boost::numeric;
using namespace std;
using boost::shared_ptr;