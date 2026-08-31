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

#include <Core/SimController/threading/INotify.h>
#include <Core/SimController/SimManager.h>
#include <Core/SimController/threading/Runnable.h>
#include <exception>


/**
Class that controls communication between the simulation progress thread and the simulation thread.
*/

class Communicator 
{

public:
    Communicator();
    ~Communicator(void);
    virtual bool startThreads(shared_ptr<SimManager> simManager, shared_ptr<IGlobalSettings> global_settings, shared_ptr<IMixedSystem> system, shared_ptr<ISimObjects> sim_objects, string modelKey);
    virtual  void stopThreads();
    virtual  bool waitForAllThreads(int timeout);
    virtual  bool waitForAllThreadsStarted(int timeout);
    virtual  bool waitForSimulationStarting(int timeout);
    virtual  bool waitForResults(double& time);
    virtual  bool isStoped();
    virtual bool isStarted();
    virtual void startPause();
    virtual void stopPause();
    virtual bool shouldStop();
    virtual void initialize(int pubPort, int subPort, string zeroMQJobiID,string zeroMQServerID, string zeroMQClientID);

    void notifyResults(double time);

    void setSimStoped(bool success, string erro_message = string("no error has occurred"));
    void setSimStarted();
    void setSimStopedByException(std::exception& except);
    void setGuiStoped();
    void setGuiStarted();
   


private:



    thread _simulation;
    thread _progress;
    ///Mutex,  waiting for end of simulation
    mutex        _stopsim_monitor;
    ///Mutex,  waiting for start of simulation
    mutex        _startsim_monitor;
    mutex			_mutex;
    condition_variable _simulation_finish;
    ///Object for notifying the client of new simulation results, simulation end
    shared_ptr<INotify> _notify;
    shared_ptr<IHistory> _history;
    bool _simstopped;
    bool _guistopped;
    bool _stop;
    double _pause_delay;
    bool _paused;
    double _end_time;
    shared_ptr<Runnable> _sim_thread;
    bool _isInitialized;

};

