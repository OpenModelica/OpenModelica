/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
    if (lin_solver.compare("dgesvSolver") == 0)
    {
      // dgesv with dgetc2 (total pivoting) as fallback
      fs::path dgesvSolver_path = ObjectFactory<CreationPolicy>::_library_path;
      fs::path dgesvSolver_name(DGESVSOLVER_LIB);
      dgesvSolver_path /= dgesvSolver_name;
      LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dgesvSolver_path.string(), *_linsolver_type_map);
      if (result != LOADER_SUCCESS)
      {
        throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading dgesv solver library!");
      }
    }
    else if (lin_solver.compare("umfpack") == 0)
    {
      fs::path umfpack_path = ObjectFactory<CreationPolicy>::_library_path;
      fs::path umfpack_name(UMFPACK_LIB);
      umfpack_path /= umfpack_name;
      LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(umfpack_path.string(), *_linsolver_type_map);
      if (result != LOADER_SUCCESS)
      {
        throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading umfpack solver library!");
      }
    }
    else if (lin_solver.compare("linearSolver") == 0)
    {
      // dgesv/dgetc2 for dense and klu for sparce Jacobians
      fs::path linearSolver_path = ObjectFactory<CreationPolicy>::_library_path;
      fs::path linearSolver_name(LINEARSOLVER_LIB);
      linearSolver_path/=linearSolver_name;
      LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(linearSolver_path.string(), *_linsolver_type_map);
      if (result != LOADER_SUCCESS)
      {
        throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading linear solver library!");
      }
    }
    else
      throw ModelicaSimulationError(MODEL_FACTORY, "Selected linear solver is not available");

    _last_selected_solver = lin_solver;
    string linsolversettings = lin_solver.append("Settings");
    std::map<std::string, factory<ILinSolverSettings> >::iterator iter;
    std::map<std::string, factory<ILinSolverSettings> >& linSolversettingsfactory(_linsolver_type_map->get());
    iter = linSolversettingsfactory.find(linsolversettings);
    if (iter == linSolversettingsfactory.end())
    {
      throw ModelicaSimulationError(MODEL_FACTORY, "No such linear solver Settings");
    }
    shared_ptr<ILinSolverSettings> linsolversetting = shared_ptr<ILinSolverSettings>(iter->second.create());
    return linsolversetting;
  }

  virtual shared_ptr<ILinearAlgLoopSolver> createLinSolver(string solver_name, shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>())
  {
    if (_last_selected_solver.compare(solver_name) == 0)
    {
      std::map<std::string, factory<ILinearAlgLoopSolver, ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > >::iterator iter;
      std::map<std::string, factory<ILinearAlgLoopSolver, ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > >& linSolverFactory(_linsolver_type_map->get());
      iter = linSolverFactory.find(solver_name);
      if (iter == linSolverFactory.end())
      {
        throw ModelicaSimulationError(MODEL_FACTORY, "No such linear Solver");
      }
      shared_ptr<ILinearAlgLoopSolver> solver = shared_ptr<ILinearAlgLoopSolver>(iter->second.create(solver_settings.get(),algLoop));

      return solver;
    }
    else
      throw ModelicaSimulationError(MODEL_FACTORY, "Selected linear solver is not available");
  }

protected:
  string _last_selected_solver;

private:
  type_map* _linsolver_type_map;
};

/** @} */ // end of simcorefactoriesPolicies
