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

  virtual shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
    {
    string lin_solver_key;

        if(lin_solver.compare("umfpack") == 0)
        {
            fs::path umfpack_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path umfpack_name(UMFPACK_LIB);
            umfpack_path/=umfpack_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(umfpack_path.string(),*_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading umfpack solver library!");
            }
            lin_solver_key.assign("extension_export_umfpack");
        }
		else if(lin_solver.compare("linearSolver") == 0)
        {
            fs::path linearSolver_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path linearSolver_name(LINEARSOLVER_LIB);
            linearSolver_path/=linearSolver_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(linearSolver_path.string(),*_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading linear solver library!");
            }
            lin_solver_key.assign("extension_export_linearSolver");
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
        shared_ptr<ILinSolverSettings> linsolversetting = shared_ptr<ILinSolverSettings>(iter->second.create());
        return linsolversetting;
  }

  virtual shared_ptr<ILinearAlgLoopSolver> createLinSolver(string solver_name, shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>())
  {
    if(_last_selected_solver.compare(solver_name) == 0)
    {
            std::map<std::string, factory<ILinearAlgLoopSolver, ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > >::iterator iter;
            std::map<std::string, factory<ILinearAlgLoopSolver, ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > >& linSolverFactory(_linsolver_type_map->get());
            iter = linSolverFactory.find(solver_name);
            if (iter == linSolverFactory.end())
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"No such linear Solver");
            }
            shared_ptr<ILinearAlgLoopSolver> solver = shared_ptr<ILinearAlgLoopSolver>(iter->second.create(solver_settings.get(),algLoop));

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
