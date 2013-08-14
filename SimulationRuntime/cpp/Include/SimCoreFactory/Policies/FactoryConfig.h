#pragma once

#if defined(__vxworks)
    
    /*Defines*/
    #define PATH string
    #include <VxWorksFactory/VxWorksFactory.h>
    
#elif defined(SIMSTER_BUILD)
   

    /*Factory includes*/
    #include "Utils/extension/extension.hpp"
    #include "Utils/extension/factory.hpp"
    #include "Utils/extension/type_map.hpp"
    #include "Utils/extension/shared_library.hpp"
    #include "Utils/extension/convenience.hpp"
    #include "Utils/extension/factory_map.hpp"
    #include <boost/filesystem/operations.hpp>
    #include <boost/filesystem/path.hpp>
    #include <boost/archive/xml_oarchive.hpp>
    #include <boost/archive/xml_iarchive.hpp>
   
    #include <boost/unordered_map.hpp>
    /*Namespaces*/
    using namespace boost::extensions;
    namespace fs = boost::filesystem;
    using boost::unordered_map;
    
     /*Defines*/
    #define PATH fs::path

     #include <Genericfactory/Factory.h>
#elif defined(OMC_BUILD)
    /*Factory includes*/
    #include "Utils/extension/extension.hpp"
    #include "Utils/extension/factory.hpp"
    #include "Utils/extension/type_map.hpp"
    #include "Utils/extension/shared_library.hpp"
    #include "Utils/extension/convenience.hpp"
    #include "Utils/extension/factory_map.hpp"
    #include <boost/filesystem/operations.hpp>
    #include <boost/filesystem/path.hpp>
    #include <boost/archive/xml_oarchive.hpp>
    #include <boost/archive/xml_iarchive.hpp>
   
    #include <boost/unordered_map.hpp>
   
    /*Namespaces*/
    using namespace boost::extensions;
    namespace fs = boost::filesystem;
    using boost::unordered_map;
    
     /*Defines*/
    #define PATH fs::path
    #include "LibrariesConfig.h"
    #include <OMCFactory/OMCFactory.h>
#else
    #error "operating system not supported"
#endif
