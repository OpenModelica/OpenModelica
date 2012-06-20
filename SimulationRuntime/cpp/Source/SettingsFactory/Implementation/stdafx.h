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
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/extension.hpp"
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/convenience.hpp"
using namespace boost::extensions;
namespace fs = boost::filesystem;
using std::ios;
using boost::tuple;
using boost::shared_ptr;
// TODO: Hier auf zusätzliche Header, die das Programm erfordert, verweisen.

