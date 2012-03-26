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
#include <string>
#include <fstream>
#include <iostream>
using namespace std;
#include <typeinfo>

#include "boost/tuple/tuple.hpp"
#include <boost/archive/xml_oarchive.hpp>
#include <boost/archive/xml_iarchive.hpp>
#include <boost/serialization/nvp.hpp>
#include <boost/shared_ptr.hpp>


#include <boost/extension/shared_library.hpp>
#include <boost/extension/extension.hpp>
#include <boost/extension/type_map.hpp>
#include <boost/extension/factory.hpp>
#include <boost/extension/convenience.hpp>
using namespace boost::extensions;

using std::ios;
using boost::tuple;
using boost::shared_ptr;
// TODO: Hier auf zusätzliche Header, die das Programm erfordert, verweisen.

