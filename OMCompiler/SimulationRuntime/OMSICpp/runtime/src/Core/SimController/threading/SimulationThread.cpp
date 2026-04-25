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



#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/IExtendedSimObjects.h>
#include <Core/SimController/threading/SimulationThread.h>
#include <Core/SimController/ISimController.h>



SimulationThread::SimulationThread(Communicator* communicator)
:_communicator(communicator)
{
    
}

SimulationThread::~SimulationThread(void)
{

}

//void SimulationThread::setSimManager(shared_ptr<SimManager> simManager)
//{
//    _simMgr = simManager;
//}

/**
Run method of the simulation thread in which the simulation is executed
*/
void SimulationThread::Run(shared_ptr<SimManager> simManager, shared_ptr<IGlobalSettings> global_settings, shared_ptr<IMixedSystem> system, shared_ptr<ISimObjects> sim_objects, string modelKey)
{
 

    
    try
    {

#ifdef RUNTIME_PROFILING
        if (MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[0], simControllerInitializeHandler);
            measuredFunctionStartValues->reset();
            measuredFunctionEndValues->reset();
            MEASURETIME_START(measuredFunctionStartValues, simControllerSolveInitialSystemHandler, "SolveInitialSystem");
        }
#endif

        _simManager = simManager;

       bool starting = _communicator->waitForSimulationStarting(1);

       if (starting)
       {
           _communicator->setSimStarted();
          simManager->initialize();

#ifdef RUNTIME_PROFILING
           if (MeasureTime::getInstance() != NULL)
           {
               MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[1], simControllerSolveInitialSystemHandler);
               MeasureTime::addResultContentBlock(mixedsystem->getModelName(), "simController", measureTimeFunctionsArray);
           }
#endif
           high_resolution_clock::time_point t_s = high_resolution_clock::now();

           simManager->runSimulation();
           high_resolution_clock::time_point t1 = high_resolution_clock::now();
           seconds elapsed = duration_cast<std::chrono::seconds>(t1 - t_s);



           if (global_settings->getOutputFormat() == BUFFER)
           {
               
               shared_ptr<IExtendedSimObjects> extended_simObjects = dynamic_pointer_cast<IExtendedSimObjects>(sim_objects);

               if (!extended_simObjects)
               {
                   string error = string("Simulation data was not found for model: ") + modelKey;
                   throw ModelicaSimulationError(SIMMANAGER, error);
               }
               shared_ptr<ISimData> simData = extended_simObjects->getSimData(modelKey);
               
               shared_ptr<IWriteOutput> writeoutput_system = dynamic_pointer_cast<IWriteOutput>(system);

              
               simData->clearResults();
               //get history object to query simulation results
               shared_ptr<IHistory> history = writeoutput_system->getHistory();
               //simulation results (output variables)
               ublas::matrix<double> Ro;
               //query simulation result outputs
               history->getOutputResults(Ro);
               vector<string> output_names;
               history->getOutputNames(output_names);
               int j = 0;

               FOREACH(string & name, output_names)
               {
                   ublas::vector<double> o_j;
                   o_j = ublas::row(Ro, j);
                   simData->addOutputResults(name, o_j);
                   j++;
               }

               vector<double> time_values = history->getTimeEntries();
               simData->addTimeEntries(time_values);
           }

           _communicator->setSimStoped(true);
       }
       else
       {
           string error = string("Simulation failed for ") + modelKey;
            _communicator->setSimStoped(false,error);
           throw ModelicaSimulationError(SIMMANAGER, error);
       }
       
    }
    catch (ModelicaSimulationError& ex)
    {
        string error = add_error_info(string("Simulation failed for ") + modelKey, ex.what(), ex.getErrorID());
        _communicator->setSimStoped(false,error);
        globalExceptionPtr = std::current_exception();
    }

}

void SimulationThread::Stop()
{

    if (_simManager)
        _simManager->stopSimulation();
}