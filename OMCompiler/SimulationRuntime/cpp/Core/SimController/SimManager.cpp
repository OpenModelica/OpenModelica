/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/SimController/SimManager.h>

#include <sstream>

SimManager::SimManager(shared_ptr<IMixedSystem> system, Configuration* config)
  : _mixed_system      (system)
  , _config            (config)
  , _dimTimeEvent      (0)
  , _dimZeroFunc       (0)
  , _timeEventCounter  (NULL)
  , _zeroVal           (NULL)
  , _events            (NULL)
  , _sampleCycles      (NULL)
  , _cycleCounter      (0)
  , _resetCycle        (0)
  , _solverTask        (ISolver::UNDEF_CALL)
  , _H                 (0)
  , _dbgId             (0)
  , _tStart            (0)
  , _tEnd              (0)
  , _lastCycleTime     (0)
  , _continueSimulation(false)
  , _checkTimeout(false)
{
    _solver = _config->createSelectedSolver(system.get());
    _initialization = shared_ptr<Initialization>(new Initialization(dynamic_pointer_cast<ISystemInitialization>(_mixed_system), _solver));

    #ifdef RUNTIME_PROFILING
    if(MeasureTime::getInstance() != NULL)
    {
        measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(2, NULL); //0 runSimulation, initializeSimulation
        (*measureTimeFunctionsArray)[0] = new MeasureTimeData("initializeSimulation");
        (*measureTimeFunctionsArray)[1] = new MeasureTimeData("runSimulation");

        MeasureTime::addResultContentBlock(system->getModelName(),"simmanager",measureTimeFunctionsArray);

        initSimStartValues = MeasureTime::getZeroValues();
        initSimEndValues = MeasureTime::getZeroValues();
        runSimStartValues = MeasureTime::getZeroValues();
        runSimEndValues = MeasureTime::getZeroValues();
    }
    else
    {
        measureTimeFunctionsArray = new std::vector<MeasureTimeData*>();
        initSimStartValues = NULL;
        initSimEndValues = NULL;
        runSimStartValues = NULL;
        runSimEndValues = NULL;
    }
    #endif
}

SimManager::~SimManager()
{
    if (_timeEventCounter)
        delete[] _timeEventCounter;
    if (_zeroVal)
        delete[] _zeroVal;
    if (_events)
        delete[] _events;
    if (_sampleCycles)
        delete[] _sampleCycles;

    #ifdef RUNTIME_PROFILING
    if(initSimStartValues)
        delete initSimStartValues;
    if(initSimEndValues)
        delete initSimEndValues;
    if(runSimStartValues)
        delete runSimStartValues;
    if(runSimEndValues)
        delete runSimEndValues;
    #endif
}

void SimManager::initialize()
{
    #ifdef RUNTIME_PROFILING
    MEASURETIME_REGION_DEFINE(initSimHandler, "initializeSimulation");
    if (MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_START(initSimStartValues, initSimHandler, "initializeSimulation");
    }
    #endif

    _cont_system = dynamic_pointer_cast<IContinuous>(_mixed_system);
    _timeevent_system = dynamic_pointer_cast<ITime>(_mixed_system);
    _event_system = dynamic_pointer_cast<IEvent>(_mixed_system);
    _step_event_system = dynamic_pointer_cast<IStepEvent>(_mixed_system);

    // Check dynamic casts
    if (!_event_system)
    {
      throw ModelicaSimulationError(SIMMANAGER,"Could not get event system.");
    }
    if (!_cont_system)
    {
      throw ModelicaSimulationError(SIMMANAGER,"Could not get continuous-event system.");
    }
    if (!_timeevent_system)
    {
      throw ModelicaSimulationError(SIMMANAGER,"Could not get time-event system.");
    }
    if (!_step_event_system)
    {
      throw ModelicaSimulationError(SIMMANAGER,"Could not get step-event system.");
    }

    shared_ptr<IGlobalSettings> global_settings = _config->getGlobalSettings();
    _tStart = global_settings->getStartTime();
    _tEnd = global_settings->getEndTime();

    LOGGER_WRITE("SimManager: Start initialization", LC_SOLVER, LL_INFO);
    LOGGER_STATUS_STARTING(_tStart, _tEnd);

    // Reset debug ID
    _dbgId = 0;

    _solver->setStartTime(_tStart);
    try
    {
        // Build up system and update once
        _initialization->initializeSystem();
    }
    catch (std::exception& ex)
    {
        LOGGER_WRITE("SimManager: Could not initialize system", LC_INIT, LL_ERROR);
        LOGGER_WRITE("SimManager: " + string(ex.what()), LC_INIT, LL_ERROR);
        // Write current values as they might help to analyse the error
        _solver->solve(ISolver::RECORDCALL);
        throw ModelicaSimulationError(SIMMANAGER, "Could not initialize system",
                                      string(ex.what()), LOGGER_IS_SET(LC_INIT, LL_ERROR));
    }
    // Write initial values
    _solver->solve(ISolver::RECORDCALL);

    if (_timeevent_system)
    {
        _dimTimeEvent = _timeevent_system->getDimTimeEvent();
        if (_timeEventCounter)
            delete[] _timeEventCounter;
        _timeEventCounter = new int[_dimTimeEvent];
        memset(_timeEventCounter, 0, _dimTimeEvent * sizeof(int));
        // compute sampleCycles for RT simulation
        if (_config->getGlobalSettings()->useEndlessSim())
        {
            if (_sampleCycles)
                delete[] _sampleCycles;
            _sampleCycles = new int[_dimTimeEvent];
            computeSampleCycles();
        }
    }
    else
        _dimTimeEvent = 0;

    // Set flag for endless simulation (if solver returns)
    _continueSimulation = _tEnd > _tStart;

        if(_checkTimeout)
        {
        //being uncomment for labeling reduction
        _solver->setTimeOut(_config->getGlobalSettings()->getAlarmTime());
        }
    _dimZeroFunc = _event_system->getDimZeroFunc();
    _solverTask = ISolver::SOLVERCALL(ISolver::FIRST_CALL);
    if (_dimZeroFunc == _event_system->getDimZeroFunc())
    {
        if (_zeroVal)
            delete[] _zeroVal;
        if (_events)
            delete[] _events;
        _zeroVal = new double[_dimZeroFunc];
        _events = new bool[_dimZeroFunc];
        memset(_zeroVal, 0, _dimZeroFunc * sizeof(double));
        memset(_events, false, _dimZeroFunc * sizeof(bool));
    }

    LOGGER_WRITE("SimManager: Assemble completed",LC_INIT,LL_DEBUG);

    // Initialization for RT simulation
    if (_config->getGlobalSettings()->useEndlessSim())
    {
        _cycleCounter = 0;
        _resetCycle = _sampleCycles[0];
        for (int i = 1; i < _dimTimeEvent; i++)
            _resetCycle *= _sampleCycles[i];
        // All Events are updated every cycle. In order to have a change in timeEventCounter, the reset is set to two
        if(_resetCycle == 1)
          _resetCycle++;
        _solver->initialize();
    }

    #ifdef RUNTIME_PROFILING
    if (MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_END(initSimStartValues, initSimEndValues, (*measureTimeFunctionsArray)[0], initSimHandler);
    }
    #endif
}

void SimManager::runSingleStep()
{
    // Increase time event counter
  double cycletime = _config->getGlobalSettings()->gethOutput();
    if (_dimTimeEvent && cycletime > 0.0)
    {

      if (_lastCycleTime && cycletime != _lastCycleTime)
            throw ModelicaSimulationError(SIMMANAGER,"Cycle time can not be changed, if time events (samples) are present!");
        else
            _lastCycleTime = cycletime;

        for (int i = 0; i < _dimTimeEvent; i++)
        {
            if (_cycleCounter % _sampleCycles[i] == 0)
                _timeEventCounter[i]++;
        }

        // Handle time event
        _timeevent_system->computeTimeEventConditions(cycletime);
        _cont_system->evaluateAll(IContinuous::CONTINUOUS);
        _event_system->saveAll();
        _timeevent_system->resetTimeConditions();
    }
    // Solve
    _solver->solve(_solverTask);

    _cycleCounter++;
    // Reset everything to prevent overflows
    if (_cycleCounter == _resetCycle + 1)
    {
      _cycleCounter = 1;
        for (int i = 0; i < _dimTimeEvent; i++)
          _timeEventCounter[i] = 0;
    }
}

void SimManager::computeSampleCycles()
{
    int counter = 0;
    time_event_type timeEventPairs;                        ///< - Contains start times and time spans

    _timeevent_system->initTimeEventData();
    std::vector<std::pair<double, double> >::iterator iter;
    iter = timeEventPairs.begin();
    for (; iter != timeEventPairs.end(); ++iter)
    {
        if (iter->first != 0.0 || iter->second == 0.0)
        {
            throw ModelicaSimulationError(SIMMANAGER,"Time event not starting at t=0.0 or not cyclic!");
        }
        else
        {
            // Check if sample time is a multiple of the cycle time (with a tolerance)
            if ((iter->second / _config->getGlobalSettings()->gethOutput()) - int((iter->second / _config->getGlobalSettings()->gethOutput()) + 0.5) <= 1e6 * UROUND)
            {
                _sampleCycles[counter] = int((iter->second / _config->getGlobalSettings()->gethOutput()) + 0.5);
            }
            else
            {
                throw ModelicaSimulationError(SIMMANAGER,"Sample time is not a multiple of the cycle time!");
            }

        }
        counter++;
    }
}

void SimManager::runSimulation()
{
    #ifdef RUNTIME_PROFILING
    MEASURETIME_REGION_DEFINE(runSimHandler, "runSimulation");
    if (MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_START(runSimStartValues, runSimHandler, "runSimulation");
    }
    #endif
    try
    {
        LOGGER_WRITE("SimManager: Start simulation at t = " + to_string(_tStart), LC_SOLVER, LL_INFO);
        runSingleProcess();
        // Measure time; Output SimInfos
        ISolver::SOLVERSTATUS status = _solver->getSolverStatus();
        if ((status & ISolver::DONE) || (status & ISolver::USER_STOP))
        {
            //LOGGER_WRITE("SimManager: Simulation done at t = " + to_string(_tEnd), LC_SOLVER, LL_INFO);
            writeProperties();
        }
    }
    catch (std::exception & ex)
    {
        LOGGER_WRITE("SimManager: Simulation stopped with errors before t = " +
                     to_string(_tEnd), LC_SOLVER, LL_ERROR);
        LOGGER_WRITE("SimManager: " + string(ex.what()), LC_SOLVER, LL_ERROR);
        writeProperties();
        // rethrow with suppress depending on logger setting to not appear twice
        throw ModelicaSimulationError(SIMMANAGER, "Simulation stopped with errors before t = " + to_string(_tEnd),
                                      string(ex.what()), LOGGER_IS_SET(LC_SOLVER, LL_ERROR));
    }
    #ifdef RUNTIME_PROFILING
    if (MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_END(runSimStartValues, runSimEndValues, (*measureTimeFunctionsArray)[1], runSimHandler);
    }
    #endif
}

void SimManager::stopSimulation()
{
    if (_solver)
        _solver->stop();
}

void SimManager::SetCheckTimeout(bool checkTimeout)
{
    _checkTimeout=checkTimeout;
}

void SimManager::writeProperties()
{
  // declaration for Logging
  std::pair<LogCategory, LogLevel> logM = Logger::getLogMode(LC_SOLVER, LL_INFO);

  LOGGER_WRITE_TUPLE("SimManager: Simulation stop time: " + to_string(_tEnd), logM);
  //LOGGER_WRITE("Rechenzeit in Sekunden:                 " + to_string>(_tClockEnd-_tClockStart), logM);

  LOGGER_WRITE_BEGIN("Simulation info from solver:", LC_SOLVER, LL_INFO);
  _solver->writeSimulationInfo();
  LOGGER_WRITE_END(LC_SOLVER, LL_INFO);
}

void SimManager::runSingleProcess()
{
    double startTime, endTime;
    double closestTimeEvent = 0.0;

    _H = _tEnd;
    //nw _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECORDCALL);
    _solver->setStartTime(_tStart);
    _solver->setEndTime(_tEnd);

    //nw _solver->solve(_solverTask);
    //initialize();
    //nw _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::RECORDCALL);

    //get information about time events
    _timeevent_system->initTimeEventData();
    closestTimeEvent = _timeevent_system->computeNextTimeEvents(_tStart);

  /* Logs temporarily disabled
     BOOST_LOG_SEV(simmgr_lg::get(), simmgr_normal) <<"Run single process." ; */
    LOGGER_WRITE("SimManager: Run single process", LC_SOLVER, LL_DEBUG);

    memset(_timeEventCounter, 0, _dimTimeEvent * sizeof(int));
    _timeevent_system->setTime(_tStart);
    if (_dimTimeEvent)
    {
        _timeevent_system->computeTimeEventConditions(_tStart);
    }
   // _cont_system->evaluateAll(IContinuous::CONTINUOUS);      // vxworksupdate
    _event_system->getZeroFunc(_zeroVal);

    for (int i = 0; i < _dimZeroFunc; i++)
    {
        _events[i] = bool(_zeroVal[i]);
    }
    _mixed_system->handleSystemEvents(_events);
    //_cont_system->evaluateODE(IContinuous::CONTINUOUS);
    // Reset the time-events after the evaluation of handleSystemEvents()
    if (_dimTimeEvent)
    {
      _timeevent_system->resetTimeConditions();
    }

    _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECORDCALL);
    _solver->setStartTime(_tStart);
    _solver->setEndTime(_tEnd);
    _solver->solve(_solverTask);
    _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::RECORDCALL);

    /* time measurement temporary disabled
     // Startzeit messen
     _tClockStart = Time::Time().getSeconds();
     */
    startTime = endTime = _tStart;
    bool user_stop = false;

    while (_continueSimulation)
    {
        while (closestTimeEvent <= _tEnd)
        {

            // Set start time, end time, initial step size
            endTime = closestTimeEvent;//endTime = iter->first;
            _solver->setStartTime(startTime);
            _solver->setEndTime(endTime);
            _solver->setInitStepSize(_config->getGlobalSettings()->gethOutput());
            _solver->solve(_solverTask);

            if (_solverTask & ISolver::FIRST_CALL)
            {
                _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::FIRST_CALL);
                _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
            }
            //prepare next step, starting from last endTime
            startTime = endTime;
            if (_dimTimeEvent)
            {
              // Find all time events at the current time and compute next one
              closestTimeEvent = _timeevent_system->computeNextTimeEvents(startTime);
              _timeevent_system->computeTimeEventConditions(startTime);

              _event_system->getZeroFunc(_zeroVal);
              for (int i = 0; i < _dimZeroFunc; i++)
              {
                _events[i] = bool(_zeroVal[i]);
              }
              //handleSystemEvents calls evaluateAll() at some point and evaluates the sampler conditions
              _mixed_system->handleSystemEvents(_events);
              // Reset time-events after the evaluation in handleSystemEvents
              _timeevent_system->resetTimeConditions();

              // Record result of time event (important for pulses)
              _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECORDCALL);
              _solver->setStartTime(startTime);
              _solver->solve(_solverTask);
              _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::RECORDCALL);

              //evaluate all to finish the step
              _cont_system->evaluateAll(IContinuous::CONTINUOUS);
              _event_system->saveAll();
            }

            user_stop = (_solver->getSolverStatus() & ISolver::USER_STOP);
            if (user_stop)
              break;
        }  // end for time events

        if (abs(_tEnd - endTime) > _config->getSolverSettings()->getEndTimeTol() && !user_stop)
        {
            startTime = endTime;
            _solver->setStartTime(startTime);
            _solver->setEndTime(_tEnd);
            _solver->setInitStepSize(_config->getGlobalSettings()->gethOutput());
            _solver->solve(_solverTask);
            // In _solverTask FIRST_CALL Bit löschen und RECALL Bit setzen
            if (_solverTask & ISolver::FIRST_CALL)
            {
                _solverTask = ISolver::SOLVERCALL(_solverTask ^ ISolver::FIRST_CALL);
                _solverTask = ISolver::SOLVERCALL(_solverTask | ISolver::RECALL);
            }
            if (user_stop)
                break;
        }  // end if weiter nach Time Events

        // Finish Simulation
        if ((!(_config->getGlobalSettings()->useEndlessSim())) || (_solver->getSolverStatus() & ISolver::SOLVERERROR) || (_solver->getSolverStatus() & ISolver::USER_STOP))
        {
            _continueSimulation = false;
        }

        // Endless simulation
        else
        {
            // increase time intervall
            _tStart = _tEnd;
            _tEnd += _H;

            if (_dimTimeEvent)
            {
                if (_zeroVal)
                {
                  closestTimeEvent = _timeevent_system->computeNextTimeEvents(startTime);
                  _timeevent_system->computeTimeEventConditions(_tEnd);
                  _cont_system->evaluateAll(IContinuous::CONTINUOUS);   // vxworksupdate
                  _event_system->getZeroFunc(_zeroVal);
                  for (int i = 0; i < _dimZeroFunc; i++)
                  {
                    _events[i] = bool(_zeroVal[i]);
                  }
                  //_cont_system->evaluateODE(IContinuous::CONTINUOUS);
                  //reset time-events
                  _timeevent_system->resetTimeConditions();
                  _cont_system->evaluateAll(IContinuous::CONTINUOUS);
                  _event_system->saveAll();
                }
            }
        }

    }  // end while continue

    // treat terminal() and continuous events at final time
    _step_event_system->setTerminal(true);
    _cont_system->evaluateZeroFuncs(IContinuous::DISCRETE);
    _event_system->getZeroFunc(_zeroVal);
    for (int i = 0; i < _dimZeroFunc; i++)
      _events[i] = bool(_zeroVal[i]);
    _mixed_system->handleSystemEvents(_events);

    // record final values
    _solverTask = ISolver::SOLVERCALL(ISolver::RECORDCALL);
    _solver->solve(_solverTask);

    LOGGER_STATUS("Finished", endTime, 0.0);
}  // end singleprocess
/** @} */ // end of coreSimcontroller
