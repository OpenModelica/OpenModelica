#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>

/*
Policy class to create nonlin solver object
*/
template <class CreationPolicy>
struct NonLinSolverOMCFactory : virtual public  ObjectFactory<CreationPolicy>
{

public:
    NonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
        ,_last_selected_solver("empty")
    {

    _non_linsolver_type_map= new type_map();
    }
    virtual ~NonLinSolverOMCFactory()
    {

    delete _non_linsolver_type_map;
    ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
    }

   virtual shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string nonlin_solver)
   {
       string nonlin_solver_key;

        if(nonlin_solver.compare("newton")==0)
        {

            fs::path newton_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path newton_name(NEWTON_LIB);
            newton_path/=newton_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(newton_path.string(),*_non_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {

                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Newton solver library!");
            }
            nonlin_solver_key.assign("extension_export_newton");
        }
        else if(nonlin_solver.compare("broyden")==0)
        {
            fs::path broyden_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path broyden_name(BROYDEN_LIB);
            broyden_path/=broyden_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(broyden_path.string(),*_non_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Broyden solver library!");
            }
            nonlin_solver_key.assign("extension_export_broyden");
        }
        else if(nonlin_solver.compare("kinsol")==0)
        {
            fs::path kinsol_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path kinsol_name(KINSOL_LIB);
            kinsol_path/=kinsol_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(kinsol_path.string(),*_non_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {

                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Kinsol solver library!");
            }
            nonlin_solver_key.assign("extension_export_kinsol");
        }
        else if(nonlin_solver.compare("hybrj")==0)
        {
            fs::path hybrj_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path hybrj_name(HYBRJ_LIB);
            hybrj_path/=hybrj_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(hybrj_path.string(),*_non_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {

                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Hybrj solver library!");
            }
            nonlin_solver_key.assign("extension_export_hybrj");
        }
        else if(nonlin_solver.compare("nox")==0)
        {
            fs::path nox_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path nox_name(NOX_LIB);
            nox_path/=nox_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(nox_path.string(),*_non_linsolver_type_map);
            if (result != LOADER_SUCCESS)
            {

                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Nox solver library!");
            }
            nonlin_solver_key.assign("extension_export_nox");
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlinear solver is not available");
        _last_selected_solver =  nonlin_solver;
        string nonlinsolversettings = nonlin_solver.append("Settings");
        std::map<std::string, factory<INonLinSolverSettings> >::iterator iter;
        std::map<std::string, factory<INonLinSolverSettings> >& nonLinSolversettingsfactory(_non_linsolver_type_map->get());
        iter = nonLinSolversettingsfactory.find(nonlinsolversettings);
        if (iter ==nonLinSolversettingsfactory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY,"No such nonlinear solver Settings");
        }
        shared_ptr<INonLinSolverSettings> nonlinsolversetting= shared_ptr<INonLinSolverSettings>(iter->second.create());
        return nonlinsolversetting;

   }

   virtual shared_ptr<INonLinearAlgLoopSolver> createNonLinSolver(string solver_name, shared_ptr<INonLinSolverSettings>  solver_settings,shared_ptr<INonLinearAlgLoop> algLoop = shared_ptr<INonLinearAlgLoop>())
   {
       if(_last_selected_solver.compare(solver_name)==0)
       {
            std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > >::iterator iter;
            std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > >& nonlinSolverFactory(_non_linsolver_type_map->get());
            iter = nonlinSolverFactory.find(solver_name);
            if (iter ==nonlinSolverFactory.end())
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"No such non linear Solver");
            }
            shared_ptr<INonLinearAlgLoopSolver> solver = shared_ptr<INonLinearAlgLoopSolver>(iter->second.create(solver_settings.get(),algLoop));
            return solver;
       }
       else
           throw ModelicaSimulationError(MODEL_FACTORY,"Selected nonlinear solver is not available");
   }
protected:
     string _last_selected_solver;
private:
    type_map* _non_linsolver_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
