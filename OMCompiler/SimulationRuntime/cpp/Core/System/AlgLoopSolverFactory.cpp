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

/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Core/System/AlgLoopSolverFactory.h>

AlgLoopSolverFactory::AlgLoopSolverFactory(IGlobalSettings* global_settings,PATH library_path,PATH modelicasystem_path)
  : IAlgLoopSolverFactory(), ObjectFactory<BaseFactory>(library_path,modelicasystem_path,library_path)
  , NonLinSolverPolicy(library_path,modelicasystem_path,library_path)
  , LinSolverPolicy(library_path,modelicasystem_path,library_path)
  , _global_settings(global_settings)
{
}
/*#endif*/

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{
}

shared_ptr<ILinearAlgLoopSolver> AlgLoopSolverFactory::createLinearAlgLoopSolver(shared_ptr<ILinearAlgLoop> algLoop)
{
  try
  {
    string linsolver_name = _global_settings->getSelectedLinSolver();
		shared_ptr<ILinSolverSettings> algsolversetting = createLinSolverSettings(linsolver_name);
		_linalgsolversettings.push_back(algsolversetting);
    shared_ptr<ILinearAlgLoopSolver> algsolver = createLinSolver(linsolver_name, algsolversetting, algLoop);
    _linear_algsolvers.push_back(algsolver);
    return algsolver;
  }
  catch(std::exception &arg)
  {
    throw ModelicaSimulationError(MODEL_FACTORY, "Linear AlgLoop solver is not available");
  }
}

/// Creates a nonlinear solver according to given system of equations of type algebraic loop
shared_ptr<INonLinearAlgLoopSolver> AlgLoopSolverFactory::createNonLinearAlgLoopSolver(shared_ptr<INonLinearAlgLoop> algLoop)
{
  try
  {
    string nonlinsolver_name = _global_settings->getSelectedNonLinSolver();
    shared_ptr<INonLinSolverSettings> algsolversetting = createNonLinSolverSettings(nonlinsolver_name);
    algsolversetting->setGlobalSettings(_global_settings);
    algsolversetting->setContinueOnError(_global_settings->getNonLinearSolverContinueOnError());
    _algsolversettings.push_back(algsolversetting);

    shared_ptr<INonLinearAlgLoopSolver> algsolver= createNonLinSolver(nonlinsolver_name, algsolversetting, algLoop);
    _non_linear_algsolvers.push_back(algsolver);
    return algsolver;
	}
  catch(std::exception &arg)
  {
    throw ModelicaSimulationError(MODEL_FACTORY, "Nonlinear AlgLoop solver is not available");
  }
}

/** @} */ // end of coreSystem
