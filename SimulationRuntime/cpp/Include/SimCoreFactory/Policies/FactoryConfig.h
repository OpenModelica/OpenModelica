#if defined(__vxworks)

  /*Defines*/
  #define PATH string
  #include <SimCoreFactory/VxWorksFactory/VxWorksFactory.h>

#elif defined(__TRICORE__)

  /*Defines*/
  #define PATH string
  #include <BodasFactory/BodasFactory.h>

#elif defined(SIMSTER_BUILD)

  /*Defines*/
  #define PATH fs::path
  #include <Genericfactory/GenericFactory.h>

#elif defined(OMC_BUILD)


  #include <boost/unordered_map.hpp>
  /*Factory includes*/
  #include <Core/Utils/extension/extension.hpp>
  #include <Core/Utils/extension/factory.hpp>
  #include <Core/Utils/extension/type_map.hpp>
  #include <Core/Utils/extension/shared_library.hpp>
  #include <Core/Utils/extension/convenience.hpp>
  #include <Core/Utils/extension/factory_map.hpp>
  #include <boost/filesystem/operations.hpp>
  #include <boost/filesystem/path.hpp>
  #include <boost/unordered_map.hpp>
  #include <boost/program_options.hpp>
  #include <string>
  /*Namespaces*/
  using namespace boost::extensions;
  namespace fs = boost::filesystem;
  using boost::unordered_map;
  namespace po = boost::program_options;
  using std::string;
  /*Defines*/
  #define PATH fs::path
  #include "LibrariesConfig.h"
  /*
  #include <Core/System/IAlgLoop.h>
  #include <Core/Solver/IAlgLoopSolver.h>
  #include <Core/System/IAlgLoopSolverFactory.h>
  #include <Core/SimController/ISimData.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/SimulationSettings//IGlobalSettings.h>
  #include <Core/SimController/ISimController.h>  */
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>

#else
  #error "operating system not supported"
#endif
