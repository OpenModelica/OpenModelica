#pragma once
/** @addtogroup simcorefactoryOMCFactory
 *  
 *  @{
 */

#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

#include <SimCoreFactory/OMCFactory/OMCFactory.h>

class StaticOMCFactory : public OMCFactory
{
    public:
    StaticOMCFactory();
    StaticOMCFactory(PATH library_path, PATH modelicasystem_path);
    virtual ~StaticOMCFactory();
    virtual boost::shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings);
    virtual boost::shared_ptr<ISettingsFactory> createSettingsFactory();
    virtual std::pair<boost::shared_ptr<ISimController>, SimSettings> createSimulation(int argc, const char* argv[]);
};
/** @} */ // end of simcorefactoryOMCFactory