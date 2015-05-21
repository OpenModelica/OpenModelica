#pragma once
/** @addtogroup simcorefactoriesPolicies
 *  
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>

/*
 Policy class to create lin solver object
 */
template<class CreationPolicy>
struct LinSolverOMCFactory : virtual public ObjectFactory<CreationPolicy>
{
public:
  LinSolverOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
    : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    , _last_selected_solver("empty")
  {
    _linsolver_type_map = new type_map();
  }
  virtual ~LinSolverOMCFactory()
  {
    delete _linsolver_type_map;
    // ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs(); todo solver lib wird in linsolver factory entlanden
  }

  virtual boost::shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
    {
    string lin_solver_key;

        if(lin_solver.compare("umfpack") == 0)
        {
            PATH umfpack_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH umfpack_name(UMFPACK_LIB);
            umfpack_path/=umfpack_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(umfpack_path.string(),*_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading umfpack solver library!");
            }
            lin_solver_key.assign("extension_export_umfpack");
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected linear solver is not available");

        _last_selected_solver = lin_solver;
        string linsolversettings = lin_solver.append("Settings");
        std::map<std::string, factory<ILinSolverSettings> >::iterator iter;
        std::map<std::string, factory<ILinSolverSettings> >& linSolversettingsfactory(_linsolver_type_map->get());
        iter = linSolversettingsfactory.find(linsolversettings);
        if (iter == linSolversettingsfactory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY,"No such linear solver Settings");
        }
        boost::shared_ptr<ILinSolverSettings> linsolversetting = boost::shared_ptr<ILinSolverSettings>(iter->second.create());
        return linsolversetting;
  }

  virtual boost::shared_ptr<IAlgLoopSolver> createLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<ILinSolverSettings> solver_settings)
  {
    if(_last_selected_solver.compare(solver_name) == 0)
    {
            std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, ILinSolverSettings*> >::iterator iter;
            std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, ILinSolverSettings*> >& linSolverFactory(_linsolver_type_map->get());
            iter = linSolverFactory.find(solver_name);
            if (iter == linSolverFactory.end())
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"No such linear Solver");
            }
            boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(iter->second.create(algLoop,solver_settings.get()));

            return solver;
    }
    else
           throw ModelicaSimulationError(MODEL_FACTORY,"Selected linear solver is not available");
  }

protected:
  string _last_selected_solver;

private:
    type_map* _linsolver_type_map;
};
/** @} */ // end of simcorefactoriesPolicies