#if defined(__vxworks)

    /*Defines*/
    #define PATH string
    #include <VxWorksFactory/VxWorksFactory.h>

#elif defined(SIMSTER_BUILD)




     /*Defines*/
    #define PATH fs::path

     #include <Genericfactory/GenericFactory.h>
#elif defined(OMC_BUILD)

#ifdef ANALYZATION_MODE
    #include <boost/unordered_map.hpp>
    /*Factory includes*/
    #include "Utils/extension/extension.hpp"
    #include "Utils/extension/factory.hpp"
    #include "Utils/extension/type_map.hpp"
    #include "Utils/extension/shared_library.hpp"
    #include "Utils/extension/convenience.hpp"
    #include "Utils/extension/factory_map.hpp"
    #include <boost/filesystem/operations.hpp>
    #include <boost/filesystem/path.hpp>


    #include <boost/unordered_map.hpp>

    /*Namespaces*/
    using namespace boost::extensions;
    namespace fs = boost::filesystem;
    using boost::unordered_map;
#endif

     /*Defines*/
    #define PATH fs::path
    #include "LibrariesConfig.h"
    /*
    #include <System/IAlgLoop.h>
    #include <Solver/IAlgLoopSolver.h>
    #include <System/IAlgLoopSolverFactory.h>
    #include <SimController/ISimData.h>
    #include <System/IMixedSystem.h>
    #include <SimulationSettings/IGlobalSettings.h>
    #include <SimController/ISimController.h>  */
    #include <SimCoreFactory/OMCFactory/OMCFactory.h>

#else
    #error "operating system not supported"
#endif
