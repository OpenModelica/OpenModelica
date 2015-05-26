/** @defgroup simcorefactoriesPolicies SimCoreFactory.Policies
 *  Object factory policy classes for all targets
 *  @{
 */
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

#elif defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)


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
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
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
  /*interface includes*/
  #include <Core/System/ISystemProperties.h>
  #include <Core/System/ISystemInitialization.h>
  #include <Core/System/IWriteOutput.h>
  #include <Core/System/IContinuous.h>
  #include <Core/System/ITime.h>
  #include <Core/System/IEvent.h>
  #include <Core/System/IStepEvent.h>
  #include <Core/Solver/INonLinSolverSettings.h>
  #include <Core/Solver/ILinSolverSettings.h>
  #include <Core/DataExchange/IHistory.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/SimulationSettings/IGlobalSettings.h>
  #include <Core/System/IMixedSystem.h>
  #include <Core/System/IAlgLoop.h>
  #include <Core/Solver/ISolverSettings.h>
  #include <Core/Solver/ISolver.h>
  #include <Core/Solver/IAlgLoopSolver.h>
  #include <Core/System/IAlgLoopSolverFactory.h>
  #include <Core/System/ISimVars.h>
  #include <Core/DataExchange/ISimVar.h>
  #include <Core/SimController/ISimData.h>
  #include <Core/SimulationSettings/ISimControllerSettings.h>
  #include <Core/SimController/ISimController.h>
  #include <SimCoreFactory/OMCFactory/OMCFactory.h>
  #include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>


#else
  #error "operating system not supported"
#endif

/** @} */ // end of simcorefactoriesPolicies

