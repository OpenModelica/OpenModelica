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
#include <Core/SimController/Configuration.h>
#include <Core/SimController/Initialization.h>
//#include <Core/SimController/FactoryExport.h>
//#include <Core/Utils/extension/logger.hpp>

#ifdef RUNTIME_PROFILING
#include <Core/Utils/extension/measure_time.hpp>
#endif

class SimManager
{
public:
    SimManager(shared_ptr<IMixedSystem> system, Configuration* _config);
    ~SimManager();
    void runSimulation();
    void stopSimulation();
    void initialize();

    // for real-time usage (VxWorks and BODAS)
    void runSingleStep();
    void SetCheckTimeout(bool checkTimeout);
    // When the labeling reduction is used, then checking the timeout is enabeled
private:
    void computeSampleCycles();

    void runSingleProcess();
    void writeProperties();

    shared_ptr<IMixedSystem> _mixed_system;
    Configuration* _config;

    std::vector<std::vector<std::pair<double, int>>> _tStops; ///< - Stopzeitpunkte aufgrund von Time-Events
    shared_ptr<ISolver> _solver; ///< - Solver
    int _dimtimeevent, ///< Temp - Timeevent-Dimensionen-Array
        _dimZeroFunc; ///< - Number of zero functions
    int* _timeEventCounter; ///< Temp - Timeevent-Counter-Array
    int _cycleCounter,
        _resetCycle;
    ISolver::SOLVERCALL _solverTask; ///< Temporary - Beschreibt die Aufgabe mit der der Solver aufgerufen wird
    int _dbgId; ///< Output - DebugID
    bool _continueSimulation, ///< - Flag für Endlossimulation (wird gesetzt, wenn Solver zurückkehrt)
         _writeFinalState; ///< Temporary - Ist am Ende noch ein Time-Event???
    bool* _events; ///< - Vector (of dimension _dimZeroF) indicating which zero function caused an event
    double _H, ///< Input, Output - Koppelschrittweite
           _tStart,
           _tEnd,
           _lastCycleTime;
    shared_ptr<Initialization> _initialization;

    bool _checkTimeout;
    shared_ptr<ITime> _timeevent_system;
    shared_ptr<IEvent> _event_system;
    shared_ptr<IContinuous> _cont_system;
    shared_ptr<IStepEvent> _step_event_system;

    int* _sampleCycles;

    bool _interrupt;
    #ifdef RUNTIME_PROFILING
    std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
    MeasureTimeValues *runSimStartValues, *runSimEndValues, *initSimStartValues, *initSimEndValues;
	#endif
};

/** @} */ // end of coreSimcontroller
