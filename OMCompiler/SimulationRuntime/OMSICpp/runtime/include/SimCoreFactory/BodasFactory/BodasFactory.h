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
/** @defgroup simcorefactoryBodas SimCoreFactory.BodasFactory
 *  Object factories for the Bodas target
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

class ISimController;
class ISettingsFactory;

class BodasFactory
{
public:
    BodasFactory(std::string library_path, std::string modelicasystem_path);
    shared_ptr<ISimController> LoadSimController();
    shared_ptr<ISettingsFactory> LoadSettingsFactory();
    shared_ptr<IAlgLoopSolverFactory> LoadAlgLoopSolverFactory(IGlobalSettings*);
    shared_ptr<ISolver> LoadSolver(IMixedSystem* system, string solver_name,
                                   shared_ptr<ISolverSettings> solver_settings);
    shared_ptr<IMixedSystem> LoadSystem(IGlobalSettings*, shared_ptr<ISimObjects> simObjects);
    shared_ptr<ISimData> LoadSimData();
    shared_ptr<ISolverSettings> LoadSolverSettings(string solver_name, shared_ptr<IGlobalSettings>);
    shared_ptr<IAlgLoopSolver> LoadAlgLoopSolver(INonLinearAlgLoop* algLoop, string solver_name,
                                                 shared_ptr<INonLinSolverSettings> solver_settings);
    shared_ptr<INonLinSolverSettings> LoadAlgLoopSolverSettings(string solver_name);

private:
    string _library_path;
    string _modelicasystem_path;
};

/** @} */ // end of simcorefactoryBodas
