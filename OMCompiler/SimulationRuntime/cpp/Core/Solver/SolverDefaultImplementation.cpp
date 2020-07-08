/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Solver/SolverSettings.h>
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <Core/Math/Constants.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

SolverDefaultImplementation::SolverDefaultImplementation(IMixedSystem* system, ISolverSettings* settings)
    : SimulationMonitor()
    , _system               (system)
    , _settings             (settings)

    , _tInit                (0.0)
    , _tCurrent             (0.0)
    , _tEnd                 (0.0)
    , _tLastSuccess         (0.0)
    , _tLastUnsucess        (0.0)
    , _tLargeStep           (0.0)
    , _h                    (0.0)

    , _firstCall            (false)
    , _firstStep            (true)

    , _totStps              (0)
    , _accStps              (0)
    , _rejStps              (0)
    , _zeroStps             (0)
    , _zeros                (0)
    , _dimSys               (0)
    , _zeroStatus           (ISolver::UNCHANGED_SIGN)
    , _zeroValInit          (NULL)
    , _dimZeroFunc          (0)
    , _zeroVal              (NULL)
    , _zeroValLastSuccess   (NULL)
    , _events               (NULL)
    , _solverStatus         (ISolver::UNDEF_STATUS)
    , _outputCommand        (IWriteOutput::WRITEOUT)
{
  _state_selection = shared_ptr<SystemStateSelection>(new SystemStateSelection(system));

    #ifdef RUNTIME_PROFILING
    if(MeasureTime::getInstance() != NULL)
    {
        measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(1, NULL); //0 write output
        (*measureTimeFunctionsArray)[0] = new MeasureTimeData("writeOutput");

        MeasureTime::addResultContentBlock(system->getModelName(),"solver",measureTimeFunctionsArray);
        writeFunctionStartValues = MeasureTime::getZeroValues();
        writeFunctionEndValues = MeasureTime::getZeroValues();
    }
    else
    {
      measureTimeFunctionsArray = new std::vector<MeasureTimeData*>();
      writeFunctionStartValues = NULL;
      writeFunctionEndValues = NULL;
    }
    #endif
}

SolverDefaultImplementation::~SolverDefaultImplementation()
{
  if(_zeroVal)
    delete [] _zeroVal;
  if(_zeroValInit)
    delete [] _zeroValInit;
  if(_zeroValLastSuccess)
    delete [] _zeroValLastSuccess;
  if(_events)
    delete [] _events;

  #ifdef RUNTIME_PROFILING
  if(writeFunctionStartValues)
      delete writeFunctionStartValues;
  if(writeFunctionEndValues)
      delete writeFunctionEndValues;
  #endif
}

void SolverDefaultImplementation::setStartTime(const double& t)
{
  _tCurrent = t;
};

void SolverDefaultImplementation::setEndTime(const double& t)
{
  _tEnd = t;
};

void SolverDefaultImplementation::setInitStepSize(const double& h)
{
  _h = h;
};

const ISolver::SOLVERSTATUS SolverDefaultImplementation::getSolverStatus()
{
  return _solverStatus;
};

bool SolverDefaultImplementation::stateSelection()
{
  return _state_selection->stateSelection(1);
}

void SolverDefaultImplementation::initialize()
{
  SimulationMonitor::initialize();
  IContinuous* continous_system = dynamic_cast<IContinuous*>(_system);
  IEvent* event_system =  dynamic_cast<IEvent*>(_system);
  ITime* timeevent_system = dynamic_cast<ITime*>(_system);
  IWriteOutput* writeoutput_system = dynamic_cast<IWriteOutput*>(_system);
  // Set current start time to the system
  timeevent_system->setTime(_tCurrent);


  if(_settings->getGlobalSettings()->getOutputPointType() != OPT_NONE)
    writeoutput_system->writeOutput(IWriteOutput::HEAD_LINE);

  // Allocate array with values of zero functions
  if (_dimZeroFunc != event_system->getDimZeroFunc())
  {
    // Number (dimension) of zero functions
    _dimZeroFunc = event_system->getDimZeroFunc();

    if(_zeroVal)
      delete [] _zeroVal;
    if(_zeroValInit)
      delete [] _zeroValInit;
    if(_zeroValLastSuccess)
      delete [] _zeroValLastSuccess;
    if(_events)
      delete [] _events;

    _zeroVal = new double[_dimZeroFunc];
    _zeroValLastSuccess = new double[_dimZeroFunc];
    _events = new bool[_dimZeroFunc];
    _zeroValInit = new double[_dimZeroFunc];
    continous_system->evaluateZeroFuncs(IContinuous::CONTINUOUS);
    event_system->getZeroFunc(_zeroVal);
    memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));
    memcpy(_zeroValInit,_zeroVal,_dimZeroFunc*sizeof(double));
    memset(_events,false,_dimZeroFunc*sizeof(bool));
  }

  // Set flags
  _firstCall = true;
  _firstStep = true;

  // Reset counter
  _totStps = 0;
  _accStps = 0;
  _rejStps = 0;
  _zeroStps = 0;
  _zeros = 0;

  // Set initial step size
  //_h = _settings->_globalSettings->_hOutput;
}

void SolverDefaultImplementation::setZeroState()
{
  // Reset Zero-State
  _zeroStatus = ISolver::UNCHANGED_SIGN;;

  // Alle Elemente im ZeroFunction-Array durchgehen
  for (int i=0; i<_dimZeroFunc; ++i)
  {
    // Überprüfung auf Vorzeichenwechsel
    if ((_zeroVal[i] < 0 && _zeroValLastSuccess[i] > 0) || (_zeroVal[i] > 0 && _zeroValLastSuccess[i] < 0))
    {
      // Vorzeichenwechsel, aber Eintrag ist größer (oder kleiner) als Toleranzbereich
      _zeroStatus = ISolver::EQUAL_ZERO;

      // Rest ZeroSign
      _events[i] = true;

      // Zeitpunkt des letzten verworfenen Schrittes abspeichern
      _tLastUnsucess = _tCurrent;
      break;
    }
    else
      _events[i] = false;
  }

}

void SolverDefaultImplementation::writeToFile(const int& stp, const double& t, const double& h)
{
  #ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(solverWriteOutputHandler, "solverWriteOutput");
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_START(writeFunctionStartValues, solverWriteOutputHandler, "solverWriteOutput");
  }
  #endif

  LOGGER_STATUS("Running", t, h);

  if(_settings->getGlobalSettings()->getOutputPointType()!= OPT_NONE)
  {
    IWriteOutput* writeoutput_system = dynamic_cast<IWriteOutput*>(_system);

    if(_outputCommand & IWriteOutput::WRITEOUT)
    {
      writeoutput_system->writeOutput(_outputCommand);

    }
  }
  checkTimeout();

  #ifdef RUNTIME_PROFILING
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_END(writeFunctionStartValues, writeFunctionEndValues, (*measureTimeFunctionsArray)[0], solverWriteOutputHandler);
  }
  #endif
}

void SolverDefaultImplementation::updateEventState()
{
  dynamic_cast<IEvent*>(_system)->getZeroFunc(_zeroVal);
  setZeroState();
  if (_zeroStatus == ISolver::ZERO_CROSSING)       // An event triggered an other event
  {
    _tLastSuccess = _tCurrent;         // Concurrently occured events are in the time tollerance
    setZeroState();                     // Upate status of events vector
  }
}
 /** @} */ // end of coreSolver
