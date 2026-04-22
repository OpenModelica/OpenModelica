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
/** @defgroup coreSimcontroller Core.SimController
 *  Configuration and control of simulation
 *
 *  @{
 */

#include <SimCoreFactory/Policies/FactoryPolicy.h>

class Configuration : public ConfigurationPolicy
{
public:
    Configuration(PATH libraries_path, PATH config_path, PATH modelicasystem_path);
    ~Configuration(void);
    shared_ptr<ISolver> createSelectedSolver(IMixedSystem* system);
    shared_ptr<IGlobalSettings> getGlobalSettings();
    ISolverSettings* getSolverSettings();
    ISimControllerSettings* getSimControllerSettings();

private:
    shared_ptr<ISettingsFactory> _settings_factory;
    shared_ptr<ISolverSettings> _solver_settings;
    shared_ptr<IGlobalSettings> _global_settings;
    shared_ptr<ISimControllerSettings> _simcontroller_settings;
    shared_ptr<ISolver> _solver;
};

/** @} */ // end of coreSimcontroller
