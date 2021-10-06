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
    void SetCheckTimeout(bool checkTimeout); // When the labeling reduction is used, then checking the timeout is enabeled
private:
    void computeSampleCycles();

    void runSingleProcess();
    void writeProperties();

    shared_ptr<IMixedSystem> _mixed_system;
    Configuration* _config;

    shared_ptr<ISolver>                        _solver;            ///< Solver
    int                                        _dimTimeEvent,      ///< Number of time events
                                               _dimZeroFunc;       ///< Number of zero functions
    int*                                       _timeEventCounter;  ///< Counter array for time events
    int                                        _cycleCounter,
                                               _resetCycle;
    ISolver::SOLVERCALL                        _solverTask;        ///< Current solver task
    int                                        _dbgId;             ///< DebugID
    bool                                       _continueSimulation;///< Flag endless simulation
    bool*                                      _events;            ///< Vector (of dimension _dimZeroF) indicating which zero function caused an event
    double*                                    _zeroVal;           ///< Values of zero function
    double                                     _H,                 ///< Interval length for endless simulation
                                               _tStart,
                                               _tEnd,
                                               _lastCycleTime;
    shared_ptr<Initialization>                 _initialization;

    bool _checkTimeout;
    shared_ptr<ITime> _timeevent_system;
    shared_ptr<IEvent> _event_system;
    shared_ptr<IContinuous> _cont_system;
    shared_ptr<IStepEvent> _step_event_system;

    int* _sampleCycles;

    #ifdef RUNTIME_PROFILING
    std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
    MeasureTimeValues *runSimStartValues, *runSimEndValues, *initSimStartValues, *initSimEndValues;
    #endif
};
/** @} */ // end of coreSimcontroller
