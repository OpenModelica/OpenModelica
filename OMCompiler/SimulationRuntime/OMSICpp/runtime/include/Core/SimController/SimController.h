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
#if defined(USE_ZEROMQ)
#include <thread>
#include <Core/SimController/threading/Communicator.h>
#endif //USE_ZEROMQ
class SimController : public ISimController,
                      public SimControllerPolicy
{
public:
    SimController(PATH library_path, PATH modelicasystem_path,bool startZeroMQ=false);
    virtual ~SimController();

    virtual weak_ptr<IMixedSystem> LoadSystem(string modelLib, string modelKey);
    virtual weak_ptr<IMixedSystem> LoadOSUSystem(string osu_name, string osu_key);
    /// Stops the simulation
    virtual void Stop();
    virtual void Start(SimSettings simsettings, string modelKey);

    virtual shared_ptr<IMixedSystem> getSystem(string modelname);
    virtual void StartReduceDAE(SimSettings simsettings, string modelPath, string modelKey, bool loadMSL,
                                bool loadPackage);
    virtual void initialize(SimSettings simsettings, string modelKey, double timeout);
    virtual void runReducedSimulation();
private:
    void initialize(PATH library_path, PATH modelicasystem_path);
    bool _initialized;
    bool _startZeroMQ;
    shared_ptr<Configuration> _config;

    std::map<string, shared_ptr<IMixedSystem> > _systems;
#if defined(USE_ZEROMQ)
    shared_ptr < Communicator> _communicator;
#endif //USE_ZEROMQ


    // for real-time usage (VxWorks and BODAS)
    //removed, has to be released after simulation run, see SimController.Start
    shared_ptr<SimManager> _simMgr;
    shared_ptr<ISimObjects> _sim_objects;
#ifdef RUNTIME_PROFILING
    std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
    MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
#endif
};

/** @} */ // end of coreSimcontroller
