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
/*
Policy class to create solver settings object
*/
template <class CreationPolicy>
struct SolverSettingsVxWorksFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SolverSettingsVxWorksFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }

    void loadGlobalSettings( shared_ptr<IGlobalSettings> global_settings)
    {

    }
    ~SolverSettingsVxWorksFactory()
    {
    }
    shared_ptr<ISolverSettings> createSolverSettings(string solvername,shared_ptr<IGlobalSettings> globalSettings)
    {

        string solver_settings_key;
        if(solvername.compare("Euler")==0)
        {
            solver_settings_key.assign("createEulerSettings");
        }
      else if(solvername.compare("RTEuler")==0)
        {
            solver_settings_key.assign("createRTEulerSettings");
        }
        else if(solvername.compare("RTRK")==0)
        {
            solver_settings_key.assign("createRTRKSettings");
        }
        else if(solvername.compare("Idas")==0)
        {
            solver_settings_key.assign("extension_export_idas");
        }
        else if(solvername.compare("Ida")==0)
        {
            solver_settings_key.assign("extension_export_ida");
        }
        else if(solvername.compare("CVode")==0)
        {
            solver_settings_key.assign("extension_export_cvode");
        }
        else
            throw std::invalid_argument("Selected Solver is not available");


        shared_ptr<ISolverSettings> solver_settings  = ObjectFactory<CreationPolicy>::_factory->LoadSolverSettings(solver_settings_key, globalSettings) ;


        return solver_settings;
    }
};
/** @} */ // end of simcorefactoriesPolicies
