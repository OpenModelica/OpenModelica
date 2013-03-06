// stdafx.h : Includedatei für Standardsystem-Includedateien
// oder häufig verwendete projektspezifische Includedateien,
// die nur in unregelmäßigen Abständen geändert werden.
//

#pragma once
#ifndef BOOST_THREAD_USE_DLL
#define BOOST_THREAD_USE_DLL
#endif
#ifndef BOOST_ALL_DYN_LINK
#define BOOST_ALL_DYN_LINK
#endif

#define WIN32_LEAN_AND_MEAN

#include <map>
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/nvp.hpp>
#include <string>
#include <fstream>
#include "Utils/extension/extension.hpp"
#include <typeinfo>
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/factory.hpp"
using namespace boost::numeric;
using namespace std;
using std::ios;

// TODO: Hier auf zusätzliche Header, die das Programm erfordert, verweisen.
