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
/** @addtogroup coreSystem
 *
 *  @{
 */
/*****************************************************************************/
/**
Factory used by the system to create a solver for the solution of a (possibly
non-linear) system of the Form F(x)=0.
*/

#include <SimCoreFactory/Policies/FactoryPolicy.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public NonLinSolverPolicy, public LinSolverPolicy
{
public:
  AlgLoopSolverFactory(IGlobalSettings* gloabl_settings, PATH library_path, PATH modelicasystem_path);
  virtual ~AlgLoopSolverFactory();

  /// Creates a solver according to given system of equations of type algebraic loop
  virtual shared_ptr<ILinearAlgLoopSolver> createLinearAlgLoopSolver(shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>());
  virtual shared_ptr<INonLinearAlgLoopSolver> createNonLinearAlgLoopSolver(shared_ptr<INonLinearAlgLoop> algLoop = shared_ptr<INonLinearAlgLoop>());
private:
  //std::vector<shared_ptr<IKinsolSettings> > _algsolversettings;
  std::vector<shared_ptr<INonLinSolverSettings> > _algsolversettings;
  std::vector<shared_ptr<ILinSolverSettings> > _linalgsolversettings;
  std::vector<shared_ptr<ILinearAlgLoopSolver> > _linear_algsolvers;
  std::vector<shared_ptr<INonLinearAlgLoopSolver> > _non_linear_algsolvers;
  IGlobalSettings* _global_settings;
};
/** @} */ // end of coreSystem
