#pragma once
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
#include <fstream>
using namespace boost::numeric;
using namespace std;
using std::ios;
