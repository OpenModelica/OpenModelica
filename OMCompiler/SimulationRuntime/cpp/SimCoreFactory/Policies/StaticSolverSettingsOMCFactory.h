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
/*includes removed for static linking not needed any more
#include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
#include <Core/Solver/SolverSettings.h>
#include <boost/shared_ptr.hpp>
#include <Core/SimulationSettings/IGlobalSettings.h>
*/
/*
Policy class to create solver settings object
*/
shared_ptr<ISolverSettings> createIdaSettings(shared_ptr<IGlobalSettings> globalSettings);
shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings);
template <class CreationPolicy>
struct StaticSolverSettingsOMCFactory : public ObjectFactory<CreationPolicy>
{

public:
    StaticSolverSettingsOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }

    virtual ~StaticSolverSettingsOMCFactory()
    {
    }

    void loadGlobalSettings(shared_ptr<IGlobalSettings> global_settings)
    {
    }

    virtual shared_ptr<ISolverSettings> createSolverSettings(string solvername,shared_ptr<IGlobalSettings> globalSettings)
    {
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
          shared_ptr<ISolverSettings> _solver_settings = createCVodeSettings(globalSettings);
          return _solver_settings;
        }
        else if((solvername.compare("ida")==0))
        {
           shared_ptr<ISolverSettings> _solver_settings = createIdaSettings(globalSettings);
           return _solver_settings;
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");
    }
};
/** @} */ // end of simcorefactoriesPolicies
