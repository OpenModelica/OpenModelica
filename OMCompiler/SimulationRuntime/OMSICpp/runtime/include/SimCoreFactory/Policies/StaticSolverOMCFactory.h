#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


/*
Policy class to create solver object
*/
shared_ptr<ISolver> createCVode(IMixedSystem* system,  shared_ptr<ISolverSettings> solver_settings);
shared_ptr<ISolver> createIda(IMixedSystem* system,  shared_ptr<ISolverSettings> solver_settings);
shared_ptr<ISettingsFactory> createFactory(PATH libraries_path, PATH config_path, PATH modelicasystem_path);
template <class CreationPolicy>
struct StaticSolverOMCFactory  : public  ObjectFactory<CreationPolicy>
{

public:
    StaticSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {

    }
    virtual ~StaticSolverOMCFactory() {};

    virtual shared_ptr<ISettingsFactory> createSettingsFactory()
    {
      return  createFactory(ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_config_path,ObjectFactory<CreationPolicy>::_modelicasystem_path);
    }
    virtual shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername, shared_ptr<ISolverSettings> solver_settings)
    {
     #ifdef ENABLE_SUNDIALS_STATIC
     if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
     {
         shared_ptr<ISolver> cvode = createCVode(system,solver_settings);
         return cvode;
     }
     else if((solvername.compare("ida")==0))
     {
         shared_ptr<ISolver> ida = createIda(system,solver_settings);
         return ida;
     }
     #endif //ENABLE_SUNDIALS_STATIC

     throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");
   }

protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_pat) {};
};
