#include <OMCFactory/StaticOMCFactory.h>

StaticOMCFactory::StaticOMCFactory() : OMCFactory()
{
}

StaticOMCFactory::StaticOMCFactory(PATH library_path, PATH modelicasystem_path) : OMCFactory(library_path, modelicasystem_path)
{
}

StaticOMCFactory::~StaticOMCFactory()
{

}

std::pair<boost::shared_ptr<ISimController>,SimSettings> StaticOMCFactory::createSimulation(int argc, const char* argv[])
{
  SimSettings settings = ReadSimulationParameter(argc,argv);
    boost::shared_ptr<ISimController>  simcontroller = boost::shared_ptr<ISimController>(new SimController(_library_path,_modelicasystem_path));
    return std::make_pair(simcontroller,settings);
}