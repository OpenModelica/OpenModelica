/** @addtogroup solverDASSL
 *
 *  @{
 */

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/DASSL/DASSL.h>

#include <Core/Utils/extension/logger.hpp>
#include <Core/Math/Functions.h>
#include <Core/Utils/numeric/bindings/ublas/matrix_sparse.hpp>
#include <Core/Utils/extension/logger.hpp>

// Cdaskr declaration
extern "C" int _daskr_ddaskr_(
  int (*res) (double *t, double *y, double *yprime, double* cj, double *delta, int *ires, double *rpar, int* ipar),
  int *neq,
  double *t,
  double *y,
  double *yprime,
  double *tout,
  int *info,
  double *rtol,
  double *atol,
  int *idid,
  double *rwork,
  int *lrw,
  int *iwork,
  int *liw,
  double *rpar,
  int *ipar,
  int (*jac) (double *t, double *y, double *yprime, double *delta, double *pd, double *cj, double *h, double *wt, double *rpar, int* ipar),
  int (*psol) (int *neq, double *t, double *y, double *yprime, double *savr, double *wk, double *cj, double *wght, double *wp, int *iwp, double *b, double eplin, int* ier, double *rpar, int* ipar),
  int (*rt) (int *neq, double *t, double *y, double *yp, int *nrt, double *rval, double *rpar, int* ipar),
  int *nrt,
  int *jroot
);

DASSL::DASSL(IMixedSystem* system, ISolverSettings* settings)
  : SolverDefaultImplementation(system, settings)
  , _info(NULL)
  , _iwork(NULL)
  , _iworkAcc(NULL)
  , _liw(0)
  , _rwork(NULL)
  , _lrw(0)
  , _y(NULL)
  , _yPrime(NULL)
  , _rtol(NULL)
  , _atol(NULL)
  , _idid(0)
  , _zeroFound(false)
  , _zeroSign(NULL)
  , _tLastEvent(0.0)
  , _event_n(0)
  , _properties(NULL)
  , _continuous_system(NULL)
  , _event_system(NULL)
  , _mixed_system(NULL)
  , _time_system(NULL)
  , _yJac(NULL)
  , _dyJac(NULL)
  , _fJac(NULL)
  , _maxColors(0)
{
#ifdef RUNTIME_PROFILING
  if (MeasureTime::getInstance() != NULL)
  {
    measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(7, NULL); //0 calcFunction //1 solve ... //6 solver statistics
    (*measureTimeFunctionsArray)[0] = new MeasureTimeData("calcFunction");
    (*measureTimeFunctionsArray)[1] = new MeasureTimeData("solve");
    (*measureTimeFunctionsArray)[2] = new MeasureTimeData("writeOutput");
    (*measureTimeFunctionsArray)[3] = new MeasureTimeData("evaluateZeroFuncs");
    (*measureTimeFunctionsArray)[4] = new MeasureTimeData("initialize");
    (*measureTimeFunctionsArray)[5] = new MeasureTimeData("stepCompleted");
    (*measureTimeFunctionsArray)[6] = new MeasureTimeData("solverStatistics");

    MeasureTime::addResultContentBlock(system->getModelName(), "dassl", measureTimeFunctionsArray);
    measuredFunctionStartValues = MeasureTime::getZeroValues();
    measuredFunctionEndValues = MeasureTime::getZeroValues();
    solveFunctionStartValues = MeasureTime::getZeroValues();
    solveFunctionEndValues = MeasureTime::getZeroValues();
    solverValues = new MeasureTimeValuesSolver();

    delete (*measureTimeFunctionsArray)[6]->_sumMeasuredValues;
    (*measureTimeFunctionsArray)[6]->_sumMeasuredValues = solverValues;
  }
  else
  {
    measureTimeFunctionsArray = new std::vector<MeasureTimeData*>();
    measuredFunctionStartValues = NULL;
    measuredFunctionEndValues = NULL;
    solveFunctionStartValues = NULL;
    solveFunctionEndValues = NULL;
    solverValues = NULL;
  }
#endif
}

DASSL::~DASSL()
{
  if (_info)
    delete[] _info;
  if (_iwork)
    delete[] _iwork;
  if (_iworkAcc)
    delete[] _iworkAcc;
  if (_rwork)
    delete[] _rwork;
  if (_y)
    delete[] _y;
  if (_yPrime)
    delete[] _yPrime;
  if (_zeroSign)
    delete[] _zeroSign;
  if (_rtol)
    delete[] _rtol;
  if (_atol)
    delete[] _atol;
  if (_yJac)
    delete[] _yJac;
  if (_dyJac)
    delete[] _dyJac;
  if (_fJac)
    delete[] _fJac;

#ifdef RUNTIME_PROFILING
  if (measuredFunctionStartValues)
    delete measuredFunctionStartValues;
  if (measuredFunctionEndValues)
    delete measuredFunctionEndValues;
  if (solveFunctionStartValues)
    delete solveFunctionStartValues;
  if (solveFunctionEndValues)
    delete solveFunctionEndValues;
#endif
}

void DASSL::initialize()
{
  LOGGER_WRITE_BEGIN("DASSL: initialize", LC_SOLVER, LL_DEBUG);

  _properties = dynamic_cast<ISystemProperties*>(_system);
  _continuous_system = dynamic_cast<IContinuous*>(_system);
  _event_system = dynamic_cast<IEvent*>(_system);
  _mixed_system = dynamic_cast<IMixedSystem*>(_system);
  _time_system = dynamic_cast<ITime*>(_system);
  IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_settings)->getGlobalSettings();

  _tLastEvent = 0.0;
  _event_n = 0;
  SolverDefaultImplementation::initialize();
  _dimSys = _continuous_system->getDimContinuousStates();
  _dimZeroFunc = _event_system->getDimZeroFunc();

  if (_dimSys == 0)
    _dimSys = 1; // introduce dummy state

  // Allocate memory
  if (_info)
    delete[] _info;
  if (_iwork)
    delete[] _iwork;
  if (_iworkAcc)
    delete[] _iworkAcc;
  if (_rwork)
    delete[] _rwork;
  if (_y)
    delete[] _y;
  if (_yPrime)
    delete[] _yPrime;
  if (_zeroSign)
    delete[] _zeroSign;
  if (_rtol)
    delete[] _rtol;
  if (_atol)
    delete[] _atol;
  if (_yJac)
    delete[] _yJac;
  if (_dyJac)
    delete[] _dyJac;
  if (_fJac)
    delete[] _fJac;

  _info = new int[20];
  _liw = 40 + _dimSys;
  _lrw = 60 + 9 * _dimSys + _dimSys*_dimSys + 3 * _dimZeroFunc;
  _iwork = new int[_liw];
  _iworkAcc = new int[40];
  _rwork = new double[_lrw];
  _y = new double[_dimSys];
  _yPrime = new double[_dimSys];
  _zeroSign = new int[_dimZeroFunc];
  _rtol = new double[_dimSys];
  _atol = new double[_dimSys];
  _yJac = new double[_dimSys];
  _dyJac = new double[_dimSys];
  _fJac = new double[_dimSys];

  memset(_info, 0, 20 * sizeof(int));
  memset(_iwork, 0, _liw * sizeof(int));
  memset(_iworkAcc, 0, 40 * sizeof(int));
  memset(_rwork, 0, _lrw * sizeof(double));
  memset(_y, 0, _dimSys * sizeof(double));
  memset(_yPrime, 0, _dimSys * sizeof(double));

  //
  // Setup DASSL
  //

  // Set initial values
  _continuous_system->getContinuousStates(_y);

  // Set tolerances
  _info[1] = 1;
  _atol[0] = _rtol[0] = 1.0; // in case of dummy state
  _continuous_system->getNominalStates(_atol);
  for (int i = 0; i < _dimSys; i++) {
    _atol[i] *= _settings->getATol();
    _rtol[i] = _settings->getRTol();
  }
  LOGGER_WRITE_VECTOR("atol", _atol, _dimSys, LC_SOLVER, LL_DEBUG);
  LOGGER_WRITE_VECTOR("rtol", _rtol, _dimSys, LC_SOLVER, LL_DEBUG);

  // Return after every step
  _info[2] = 1;

  // Use supplied Jacobian function
  _info[4] = 1;
  _maxColors = _system->getAMaxColors();
  if (_system->isAnalyticJacobianGenerated() && _continuous_system->getDimContinuousStates() > 0)
  {
    LOGGER_WRITE("Jacobian size " + to_string(_dimSys) + ", generated symbolically", LC_SOLVER, LL_DEBUG);
  }
  else if (_maxColors > 0)
  {
    LOGGER_WRITE("Jacobian size " + to_string(_dimSys) + " with " + to_string(_maxColors) + " colors", LC_SOLVER, LL_DEBUG);
  }
  else
  {
    LOGGER_WRITE("Jacobian size " + to_string(_dimSys) + ", dense numerical", LC_SOLVER, LL_DEBUG);
  }

  // Max step size
  _info[6] = 1;
  _rwork[1] = _settings->getGlobalSettings()->gethOutput();

  // Initial step size
  _info[7] = 1;
  _rwork[2] = 1e-30; // start with very small value to not miss events later on -- see StateGraph!?

  LOGGER_WRITE_END(LC_SOLVER, LL_DEBUG);
}

void DASSL::solve(const SOLVERCALL action)
{
  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == OPT_ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);

#ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(dasslSolveFunctionHandler, "solve");
  if (MeasureTime::getInstance() != NULL)
    MEASURETIME_START(solveFunctionStartValues, dasslSolveFunctionHandler, "solve");
#endif

  if (!_settings || !_system)
    throw ModelicaSimulationError(SOLVER, "DASSL::solve missing system or settings");

  // prepare solver and system
  if ((action & RECORDCALL) && (action & FIRST_CALL))
  {
#ifdef RUNTIME_PROFILING
    MEASURETIME_REGION_DEFINE(dasslInitializeHandler, "DASSLInitialize");
    if (MeasureTime::getInstance() != NULL)
      MEASURETIME_START(measuredFunctionStartValues, dasslInitializeHandler, "DASSLInitialize");
#endif

    initialize();

#ifdef RUNTIME_PROFILING
    if (MeasureTime::getInstance() != NULL)
      MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[4], dasslInitializeHandler);
#endif

    if (writeOutput)
      writeToFile(_accStps, _tCurrent, _h);

    return;
  }

  if ((action & RECORDCALL) && !(action & FIRST_CALL))
  {
    writeToFile(_accStps, _tCurrent, _h);
    return;
  }

  // recored new state after time event
  if (action & RECALL)
  {
    _firstStep = true;
    if (writeOutput || writeEventOutput)
      writeToFile(_accStps, _tCurrent, _h);
    _continuous_system->getContinuousStates(_y);
  }

  // solver shall continue
  _solverStatus = ISolver::CONTINUE;

  while ((_solverStatus & ISolver::CONTINUE) && !_interrupt)
  {
    // call solver
    DASSLCore();
  }

  // not successful and not interruped by user
  if (_solverStatus == ISolver::SOLVERERROR)
  {
    throw ModelicaSimulationError(SOLVER, "DASSL: solve failed with idid = " + to_string(_idid));
  }

  _firstCall = false;

#ifdef RUNTIME_PROFILING
  if (MeasureTime::getInstance() != NULL)
  {
    MEASURETIME_END(solveFunctionStartValues, solveFunctionEndValues, (*measureTimeFunctionsArray)[1], dasslSolveFunctionHandler);

    long int nst, nfe, nsetups, netf, nni, ncfn;
    int qlast, qcur;
    realtype h0u, hlast, hcur, tcur;

    int flag;

    flag = DASSLGetIntegratorStats(_dasslMem, &nst, &nfe, &nsetups, &netf, &qlast, &qcur, &h0u, &hlast, &hcur, &tcur);
    flag = DASSLGetNonlinSolvStats(_dasslMem, &nni, &ncfn);

    MeasureTimeValuesSolver solverVals = MeasureTimeValuesSolver(nfe, netf);
    (*measureTimeFunctionsArray)[6]->_sumMeasuredValues->_numCalcs += nst;
    (*measureTimeFunctionsArray)[6]->_sumMeasuredValues->add(&solverVals);
  }
#endif
}

bool DASSL::isInterrupted()
{
  if (_interrupt)
  {
    _solverStatus = DONE;
    return true;
  }
  else
  {
    return false;
  }
}

void DASSL::DASSLCore()
{
  LOGGER_WRITE_BEGIN("DASSL: solve at t = " + to_string(_tCurrent), LC_SOLVER, LL_DEBUG);

  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == OPT_ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);

  _info[0] = 0; // (re-)start dassl

  while ((_solverStatus & ISolver::CONTINUE) && !_interrupt)
  {
    if (_info[0] == 0)
    {
      // accumulate previous solver stats upon restart
      for (int i = 10; i <= 35; i++)
        _iworkAcc[i] += _iwork[i];
    }

    if (_tEnd - _tCurrent > _settings->getEndTimeTol())
      _daskr_ddaskr_(_res, &_dimSys, &_tCurrent, _y, _yPrime, &_tEnd, _info,
                     _rtol, _atol, &_idid, _rwork, &_lrw, _iwork, &_liw, /*rpar*/NULL,
                     (int *)this, _jac, /*psol*/NULL, _rt, &_dimZeroFunc, _zeroSign);
    else
      _idid = 3; // daskr would return -33 as end time too close

    if (_idid != 1)
      LOGGER_WRITE("proceed to t = " + to_string(_tCurrent) + ", idid = " + to_string(_idid), LC_SOLVER, LL_DEBUG);
    if (_idid < 0)
    {
      _rejStps ++;
      _solverStatus = ISolver::SOLVERERROR;
      break;
    }
    else if (1 < _idid && _idid < 4)
      _solverStatus = DONE;

    try
    {
      // complete step for system and check for terminate
      if (_continuous_system->stepCompleted(_tCurrent))
        _solverStatus = DONE;

      if (writeOutput)
      {
        if (_idid == 3)
          _time_system->setTime(_tEnd); // interpolated time point
        _continuous_system->setContinuousStates(_y);
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        writeToFile(_accStps, _tCurrent, _h);
      }

  #ifdef RUNTIME_PROFILING
      MEASURETIME_REGION_DEFINE(dasslStepCompletedHandler, "DASSLStepCompleted");
      if (MeasureTime::getInstance() != NULL)
        MEASURETIME_START(measuredFunctionStartValues, dasslStepCompletedHandler, "DASSLStepCompleted");
      if (MeasureTime::getInstance() != NULL)
        MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[5], dasslStepCompletedHandler);
  #endif

      // Perform state selection
      bool state_selection = stateSelection();
      if (state_selection) {
        _continuous_system->getContinuousStates(_y);
      }
      _zeroFound = false;

      // Check for found root
      if (_idid == 5 && !isInterrupted())
      {
        _zeros ++;
        LOGGER_WRITE_VECTOR("jroot", _zeroSign, _dimZeroFunc, LC_SOLVER, LL_DEBUG);
        // DASSL sets _tCurrent to the time where the first event occurred
        double _abs = fabs(_tLastEvent - _tCurrent);
        _zeroFound = true;

        if (_abs < 1e-3 && _event_n == 0)
        {
          _tLastEvent = _tCurrent;
          _event_n++;
        }
        else if ((_abs < 1e-3) && (_event_n >= 1 && _event_n < 500))
        {
          _event_n++;
        }
        else if (_abs >= 1e-3)
        {
          //restart event counter
          _tLastEvent = _tCurrent;
          _event_n = 0;
        }
        else
        {
          _solverStatus = ISolver::SOLVERERROR;
          break;
        }

        // DASSL has interpolated the states at time _tCurrent
        _time_system->setTime(_tCurrent);

        // To get steep steps in the result file, two value points (P1 and P2) are added
        //
        // Y |   (P2) X...........
        //   |        :
        //   |        :
        //   |........X (P1)
        //   |---------------------------------->
        //   |        ^                         t
        //        _tCurrent

        // Write the values of (P1) if not done via writeOutput above
        if (writeEventOutput && !writeOutput)
        {
          try
          {
            _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
          }
          catch (std::exception& ex)
          {
            // if a zero crossing was dected before the event iteration was called and evalutateAll throws an error
            // for this time step the event iteration evaluates the system with corrected values.
          }

          writeToFile(_accStps, _tCurrent, _h);
        }

        for (int i = 0; i < _dimZeroFunc; i++)
          _events[i] = (_zeroSign[i] != 0);

        if (_mixed_system->handleSystemEvents(_events))
        {
          // State variables were reinitialized, thus we have to give these values to dassl
          _continuous_system->getContinuousStates(_y);
        }
      }

      if ((_zeroFound || state_selection) && !isInterrupted())
      {
        // Write the values of (P2)
        if (writeEventOutput)
        {
          // If we want to write the event-results, we should evaluate the whole system again
          _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
          writeToFile(_accStps, _tCurrent, _h);
        }

        _info[0] = 0; // restart dassl

        // Check for event at end time
        if (_tEnd - _tCurrent <= _settings->getEndTimeTol())
          _solverStatus = DONE;
        if (_continuous_system->stepCompleted(_tCurrent))
          _solverStatus = DONE;
      }

      _accStps ++;
      _tLastSuccess = _tCurrent;
    }
    catch (const std::exception& ex)
    {
      LOGGER_WRITE("DASSL: failed step at t = " + to_string(_tCurrent) + ": " + ex.what(), LC_SOLVER, LL_ERROR);
      _solverStatus = ISolver::SOLVERERROR;
      break;
    }
  }

  LOGGER_WRITE_END(LC_SOLVER, LL_DEBUG);
}

void DASSL::setTimeOut(unsigned int time_out)
{
  SimulationMonitor::setTimeOut(time_out);
}

void DASSL::stop()
{
  SimulationMonitor::stop();
}

bool DASSL::stateSelection()
{
  return SolverDefaultImplementation::stateSelection();
}

int DASSL::_res(double *t, double *y, double *yp,
	            double *cj, double *delta, int *ires, double *rpar, int *ipar)
{
  int success = ((DASSL *)ipar)->calcFunction(*t, y, delta);
  int n = ((DASSL *)ipar)->_dimSys;
  for (int i = 0; i < n; i++)
    delta[i] -= yp[i];
  if (!success)
    *ires = -1;
  return 0;
}

int DASSL::calcFunction(const double& time, const double* y, double* f)
{
  int success = 0;

#ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(dasslCalcFunctionHandler, "DASSLCalcFunction");
  if (MeasureTime::getInstance() != NULL)
  {
    MEASURETIME_START(measuredFunctionStartValues, dasslCalcFunctionHandler, "DASSLCalcFunction");
  }
#endif

  try
  {
    f[0] = 0.0; // in case of dummy state
    _time_system->setTime(time);
    _continuous_system->setContinuousStates(y);
    _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
    _continuous_system->getRHS(f);
    success = 1;
  }
  catch (std::exception & ex)
  {
    LOGGER_WRITE("DASSL: failed evaluation of residual at t = " + to_string(_tCurrent) + ": " + ex.what(), LC_SOLVER, LL_DEBUG);
  }

#ifdef RUNTIME_PROFILING
  if (MeasureTime::getInstance() != NULL)
  {
    MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[0], dasslCalcFunctionHandler);
  }
#endif

  return success;
}

int DASSL::_rt(int *neq, double *t, double *y, double *yp,
               int *nrt, double *rval, double *rpar, int *ipar)
{
  int success = ((DASSL *)ipar)->calcRoots(*t, y, rval);
  if (!success)
    memset(rval, 0, *nrt * sizeof(double));
  return 0;
}

int DASSL::calcRoots(double t, const double *y, double *zeroValue)
{
  int success = 0;

#ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(dasslEvalZeroHandler, "evaluateZeroFuncs");
  if (MeasureTime::getInstance() != NULL)
  {
    MEASURETIME_START(measuredFunctionStartValues, dasslEvalZeroHandler, "evaluateZeroFuncs");
  }
#endif

  try
  {
    _time_system->setTime(t);
    _continuous_system->setContinuousStates(y);
    _continuous_system->evaluateZeroFuncs(IContinuous::DISCRETE);
    _event_system->getZeroFunc(zeroValue);
    success = 1;
  }
  catch (std::exception & ex)
  {
    LOGGER_WRITE("DASSL: failed evaluation of roots at t = " + to_string(_tCurrent) + ": " + ex.what(), LC_SOLVER, LL_WARNING);
  }

#ifdef RUNTIME_PROFILING
  if (MeasureTime::getInstance() != NULL)
  {
    MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[3], dasslEvalZeroHandler);
  }
#endif

  return success;
}

int DASSL::_jac(double *t, double *y, double *yp, double *delta,
                double *pd, double *cj, double *h, double *wt, double *rpar, int *ipar)
{
  int success = ((DASSL *)ipar)->calcJacobian(*t, y, yp, delta, pd, *cj, *h, wt);
  int n = ((DASSL *)ipar)->_dimSys;
  if (!success)
    memset(pd, 0, n * n * sizeof(double));
  else
    for (int i = 0; i < n; i++)
      pd[i*n + i] -= *cj;
  return 0;
}

int DASSL::calcJacobian(double t, double *y, double *yp, double *delta,
                        double *pd, double cj, double h, double *wt)
{
  int success = 0;

  try
  {
    if (_system->isAnalyticJacobianGenerated() && _continuous_system->getDimContinuousStates() > 0)
    {
      memcpy(pd, &_system->getJacobian().data()[0], _dimSys * _dimSys * sizeof(double));
    }
    else
    {
      for (int j = 0; j < _dimSys; j++)
      {
        _dyJac[j] = max(1e-10, 1e-8 * max(max(abs(y[j]), abs(h * yp[j])), abs(1.0 / wt[j])));
        _dyJac[j] = y[j] + _dyJac[j];
        _dyJac[j] -= y[j];
        _yJac[j] = y[j];
      }

      if (_maxColors > 0) // colored numerical
      {
        for (int color = 1; color <= _maxColors; color++)
        {
          for (int j: _system->getAColumnsOfColor(color))
          {
            _yJac[j] += _dyJac[j];
          }

          calcFunction(t, _yJac, _fJac);

          for (int j: _system->getAColumnsOfColor(color))
          {
            int startOfColumn = j * _dimSys;
            for (int i: _system->getADependenciesOfColumn(j))
            {
              pd[startOfColumn + i] = (_fJac[i] - delta[i] - yp[i]) / _dyJac[j];
            }
            _yJac[j] = y[j];
          }
        }
      }
      else // dense numerical
      {
        for (int j = 0; j < _dimSys; j++)
        {
          _yJac[j] += _dyJac[j];

          calcFunction(t, _yJac, _fJac);

          int startOfColumn = j * _dimSys;
          for (int i = 0; i < _dimSys; i++)
          {
            pd[startOfColumn + i] = (_fJac[i] - delta[i] - yp[i]) / _dyJac[j];
          }

          _yJac[j] = y[j];
        }
      }
    }
    success = 1;
  }
  catch (std::exception & ex)
  {
    LOGGER_WRITE("DASSL: failed evaluation of Jacobian at t = " + to_string(_tCurrent) + ": " + ex.what(), LC_SOLVER, LL_WARNING);
  }

  return success;
}

void DASSL::writeSimulationInfo()
{
  // don't write before memory has been initialized
  if (_rwork == NULL || _iwork == NULL)
    return;

  for (int i = 10; i <= 35; i++)
    _iworkAcc[i] += _iwork[i];

  LOGGER_WRITE("DASSL: steps taken nst = " + to_string(_iworkAcc[10]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: residual evaluations nre = " + to_string(_iworkAcc[11]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: jacobian evaluations nje = " + to_string(_iworkAcc[12]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: root evaluations nrt = " + to_string(_iworkAcc[35]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: error test failures netf = " + to_string(_iworkAcc[13]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: nonlinear convergence failures ncfn = " + to_string(_iworkAcc[14]), LC_SOLVER, LL_INFO);
  //LOGGER_WRITE("DASSL: linear convergence failures ncfl = " + to_string(_iworkAcc[15]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: nonlinear iterations nni = " + to_string(_iworkAcc[18]), LC_SOLVER, LL_INFO);
  //LOGGER_WRITE("DASSL: linear iterations nli = " + to_string(_iworkAcc[19]), LC_SOLVER, LL_INFO);
  //LOGGER_WRITE("DASSL: preconditioning calls nps = " + to_string(_iworkAcc[20]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: last evaluation time t = " + to_string(_rwork[3]), LC_SOLVER, LL_INFO);
  //LOGGER_WRITE("DASSL: next step size h = " + to_string(_rwork[2]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: last step size h = " + to_string(_rwork[6]), LC_SOLVER, LL_INFO);
  //LOGGER_WRITE("DASSL: next used order k = " + to_string(_iwork[6]), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("DASSL: last used order k = " + to_string(_iwork[7]), LC_SOLVER, LL_INFO);
}

/** @} */ // end of solverDASSL
