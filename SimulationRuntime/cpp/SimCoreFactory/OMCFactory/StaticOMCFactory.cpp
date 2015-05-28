/** @addtogroup simcorefactoryOMCFactory
 *  
 *  @{
 */

#include <SimCoreFactory/OMCFactory/StaticOMCFactory.h>
#include <Core/SimController/SimController.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/SimulationSettings/Factory.h>
StaticOMCFactory::StaticOMCFactory() : OMCFactory()
{
}

StaticOMCFactory::StaticOMCFactory(PATH library_path, PATH modelicasystem_path) : OMCFactory(library_path, modelicasystem_path)
{
}

StaticOMCFactory::~StaticOMCFactory()
{

}
boost::shared_ptr<IAlgLoopSolverFactory> StaticOMCFactory::createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
{
    boost::shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = boost::shared_ptr<IAlgLoopSolverFactory>(new AlgLoopSolverFactory(globalSettings, _library_path, _modelicasystem_path));
    return algloopsolverfactory;
}
boost::shared_ptr<ISettingsFactory> StaticOMCFactory::createSettingsFactory()
{

    boost::shared_ptr<ISettingsFactory>  settings_factory = boost::shared_ptr<ISettingsFactory>(new SettingsFactory(_library_path,_modelicasystem_path,PATH("")));
    return settings_factory;

}

std::pair<boost::shared_ptr<ISimController>,SimSettings> StaticOMCFactory::createSimulation(int argc, const char* argv[])
{
  SimSettings settings = ReadSimulationParameter(argc,argv);
    boost::shared_ptr<ISimController>  simcontroller = boost::shared_ptr<ISimController>(new SimController(_library_path,_modelicasystem_path));
    return std::make_pair(simcontroller,settings);
}
/** @} */ // end of simcorefactoryOMCFactory

