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
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/SimController/SimManager.h>
#include <Core/SimController/ISimController.h>

class SimController : public ISimController,
                      public SimControllerPolicy
{
public:
    SimController(PATH library_path, PATH modelicasystem_path);
    virtual ~SimController();

    virtual weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey);
    virtual weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey);
      /// Stops the simulation
    virtual void Stop();
    virtual void Start(SimSettings simsettings, string modelKey);
    virtual void Start(SimSettings simsettings, string modelKey, string nls);
    virtual shared_ptr<IMixedSystem> getSystem(string modelname);
    virtual shared_ptr<ISimObjects> getSimObjects();
    virtual void StartReduceDAE(SimSettings simsettings,string modelPath, string modelKey,bool loadMSL, bool loadPackage);

private:
    shared_ptr<Configuration> _config;
    std::map<string, shared_ptr<IMixedSystem> > _systems;

    // for real-time usage (VxWorks and BODAS)
    //removed, has to be released after simulation run, see SimController.Start
    shared_ptr<SimManager> _simMgr;
    shared_ptr<ISimObjects> _sim_objects;
    #ifdef RUNTIME_PROFILING
    std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
    MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
    #endif
    string _modelLib;
    string _modelKey;
};
/** @} */ // end of coreSimcontroller
