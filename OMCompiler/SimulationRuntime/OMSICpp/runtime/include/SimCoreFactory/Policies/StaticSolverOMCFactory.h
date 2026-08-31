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
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


/*
Policy class to create solver object
*/
shared_ptr<ISolver> createCVode(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings);
shared_ptr<ISolver> createIda(IMixedSystem* system, shared_ptr<ISolverSettings> solver_settings);
shared_ptr<ISettingsFactory> createFactory(PATH libraries_path, PATH config_path, PATH modelicasystem_path);

template <class CreationPolicy>
struct StaticSolverOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    StaticSolverOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    virtual ~StaticSolverOMCFactory()
    {
    };

    virtual shared_ptr<ISettingsFactory> createSettingsFactory()
    {
        return createFactory(ObjectFactory<CreationPolicy>::_library_path, ObjectFactory<CreationPolicy>::_config_path,
                             ObjectFactory<CreationPolicy>::_modelicasystem_path);
    }

    virtual shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername,
                                             shared_ptr<ISolverSettings> solver_settings)
    {
#ifdef ENABLE_SUNDIALS_STATIC
     if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
     {
         shared_ptr<ISolver> cvode = createCVode(system,solver_settings);
         return cvode;
     }
     else if((solvername.compare("ida")==0))
     {
         shared_ptr<ISolver> ida = createIda(system,solver_settings);
         return ida;
     }
#endif //ENABLE_SUNDIALS_STATIC

        throw ModelicaSimulationError(MODEL_FACTORY, "Selected Solver is not available");
    }

protected:
    virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_pat)
    {
    };
};
