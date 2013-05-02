
#pragma once

#define WIN32_LEAN_AND_MEAN        // Selten verwendete Teile der Windows-Header nicht einbinden.
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <string>
#include "Utils/extension/extension.hpp"
#include <typeinfo>
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/factory.hpp"
using namespace boost::numeric;
using namespace std;
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif
