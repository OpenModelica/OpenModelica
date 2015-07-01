#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/SolverOMCFactory.h>

/*
Policy class to create solver object
*/
template <class CreationPolicy>
struct StaticSolverOMCFactory : public SolverOMCFactory<CreationPolicy>
{

public:
    StaticSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path);
    virtual ~StaticSolverOMCFactory();

    virtual boost::shared_ptr<ISettingsFactory> createSettingsFactory();
    virtual boost::shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername, boost::shared_ptr<ISolverSettings> solver_settings);

protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_pat);
};
