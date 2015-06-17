#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
 
#include <Solver/ARKode/ARKode.h>

#include <Core/Math/Functions.h>
#include <arkode/arkode.h>

#include <arkode/arkode_dense.h>      // prototype for ARKDense solver
#include <sundials/sundials_dense.h>  // defs. of DlsMat and DENSE_ELEM
#include <sundials/sundials_types.h>  // def. of type 'realtype'


//#include <Core/Utils/numeric/bindings/traits/ublas_vector.hpp>
//#include <Core/Utils/numeric/bindings/traits/ublas_sparse.hpp>

Arkode::Arkode(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings),
      _arkodesettings(dynamic_cast<ISolverSettings*>(_settings)),
      _arkodeMem(NULL),
      _z(NULL),
      _zInit(NULL),
      _zWrite(NULL),
      _dimSys(0),
      _ark_rt(0),
      _outStps(0),
      _locStps(0),
      _idid(0),
      _hOut(0.0),
      _tOut(0.0),
      _tZero(0.0),
      _zeroSign(NULL),
      _absTol(NULL),
      _arkode_initialized(false),
      _tLastEvent(0.0),
      _event_n(0),
      _properties(NULL),
      _continuous_system(NULL),
      _event_system(NULL),
      _mixed_system(NULL),
      _time_system(NULL),
      _delta(NULL),
      _deltaInv(NULL),
      _ysave(NULL)
{
  _data = ((void*) this);
}

Arkode::~Arkode()
{
  if (_z)
    delete[] _z;
  if (_zInit)
    delete[] _zInit;
  if (_zeroSign)
    delete[] _zeroSign;
  if (_absTol)
    delete[] _absTol;
  if (_zWrite)
      delete[] _zWrite;
  //add free arkode
  if (_arkode_initialized)
  {
    N_VDestroy_Serial(_ARK_y0);
    N_VDestroy_Serial(_ARK_y);
    N_VDestroy_Serial(_ARK_yWrite);
    N_VDestroy_Serial(_ARK_absTol);
    ARKodeFree(&_arkodeMem);
  }


  // free Cvode
  /*
  if (_colorOfColumn)
    delete [] _colorOfColumn;
  if(_delta)
    delete [] _delta;
    if(_deltaInv)
    delete [] _deltaInv;
  if(_ysave)
    delete [] _ysave;
  */
}

void Arkode::initialize()
{
  _properties = dynamic_cast<ISystemProperties*>(_system);
  _continuous_system = dynamic_cast<IContinuous*>(_system);
  _event_system = dynamic_cast<IEvent*>(_system);
  _mixed_system = dynamic_cast<IMixedSystem*>(_system);
  _time_system = dynamic_cast<ITime*>(_system);
  IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_arkodesettings)->getGlobalSettings();
  // Kennzeichnung, dass initialize()() (vor der Integration) aufgerufen wurde
  _idid = 5000;
  _tLastEvent = 0.0;
  _event_n = 0;
  SolverDefaultImplementation::initialize();
  _dimSys = _continuous_system->getDimContinuousStates();
  _dimZeroFunc = _event_system->getDimZeroFunc();

  if (_dimSys == 0)
    _dimSys = 1; // introduce dummy state

  if (_dimSys <= 0)
  {
    _idid = -1;
    throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");
  }
  else
  {
    // Allocate state vectors, stages and temporary arrays
    if (_z)
      delete[] _z;
    if (_zInit)
      delete[] _zInit;
    if (_zWrite)
      delete[] _zWrite;
    if (_zeroSign)
      delete[] _zeroSign;
    if (_absTol)
      delete[] _absTol;
  if(_delta)
    delete [] _delta;
    if(_deltaInv)
    delete [] _deltaInv;
    if(_ysave)
    delete [] _ysave;

    _z = new double[_dimSys];
    _zInit = new double[_dimSys];
    _zWrite = new double[_dimSys];
    _zeroSign = new int[_dimZeroFunc];
    _absTol = new double[_dimSys];
  _delta =new double[_dimSys];
    _deltaInv =new double[_dimSys];
  _ysave =new double[_dimSys];

    memset(_z, 0, _dimSys * sizeof(double));
    memset(_zInit, 0, _dimSys * sizeof(double));
  memset(_ysave, 0, _dimSys * sizeof(double));

    // Counter initialisieren
    _outStps = 0;

    if (_arkodesettings->getDenseOutput())
    {
      // Ausgabeschrittweite
      _hOut = global_settings->gethOutput();

    }

    // Allocate memory for the solver  //arkodeCreate
    _arkodeMem = ARKodeCreate();
    /*
    if (check_flag((void*) _cvodeMem, "CVodeCreate", 0))
    {
      _idid = -5;
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");
    }
    */
    //
    // Make Cvode ready for integration
    //

    // Set initial values for CVODE
    _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
    _continuous_system->getContinuousStates(_zInit);
    memcpy(_z, _zInit, _dimSys * sizeof(double));

    // Get nominal values
    _absTol[0] = 1.0; // in case of dummy state
    _continuous_system->getNominalStates(_absTol);
    for (int i = 0; i < _dimSys; i++)
      _absTol[i] *= dynamic_cast<ISolverSettings*>(_arkodesettings)->getATol();

    _ARK_y0 = N_VMake_Serial(_dimSys, _zInit);
    _ARK_y = N_VMake_Serial(_dimSys, _z);
    _ARK_yWrite = N_VMake_Serial(_dimSys, _zWrite);
    _ARK_absTol = N_VMake_Serial(_dimSys, _absTol);


    /*
    if (check_flag((void*) _CV_y0, "N_VMake_Serial", 0))
    {
      _idid = -5;
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");
    }
    */
    // Initialize Cvode (Initial values are required)
    _idid = ARKodeInit(_arkodeMem, NULL, ARK_fCallback, _tCurrent, _ARK_y0);
    if (_idid < 0)
    {
      _idid = -5;
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");
    }


    // Set Tolerances

    _idid = ARKodeSVtolerances(_arkodeMem, dynamic_cast<ISolverSettings*>(_arkodesettings)->getRTol(), _ARK_absTol);    // RTOL and ATOL
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVode::initialize()");

    // Set the pointer to user-defined data

    _idid = ARKodeSetUserData(_arkodeMem, _data);
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");

    _idid = ARKodeSetInitStep(_arkodeMem, 1e-6);    // INITIAL STEPSIZE
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");

    _idid = ARKodeSetMaxConvFails(_arkodeMem, 100);       // Maximale Fehler im Konvergenztest
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVoder::initialize()");

    _idid = ARKodeSetMinStep(_arkodeMem, dynamic_cast<ISolverSettings*>(_arkodesettings)->getLowerLimit());       // MINIMUM STEPSIZE
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVode::initialize()");

    _idid = ARKodeSetMaxStep(_arkodeMem, global_settings->getEndTime() / 10.0);       // MAXIMUM STEPSIZE
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVode::initialize()");

    _idid = ARKodeSetMaxNonlinIters(_arkodeMem, 5);      // Max number of iterations
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVode::initialize()");
    _idid = ARKodeSetMaxErrTestFails(_arkodeMem, 100);
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"CVode::initialize()");

    _idid = ARKodeSetMaxNumSteps(_arkodeMem, 1000);            // Max Number of steps
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");

    // Initialize linear solver
    /*
    #ifdef USE_SUNDIALS_LAPACK
      _idid = CVLapackDense(_cvodeMem, _dimSys);
    #else
    */
      _idid = ARKDense(_arkodeMem, _dimSys);
    /*
    #endif
    */
    if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"Cvode::initialize()");

  // Use own jacobian matrix
  // Check if Colored Jacobians are worth to use

  if (_idid < 0)
      throw ModelicaSimulationError(SOLVER,"ARKode::initialize()");

    if (_dimZeroFunc)
    {
      _idid = ARKodeRootInit(_arkodeMem, _dimZeroFunc, &ARK_ZerofCallback);

      memset(_zeroSign, 0, _dimZeroFunc * sizeof(int));
      _idid = ARKodeSetRootDirection(_arkodeMem, _zeroSign);
      if (_idid < 0)
        throw ModelicaSimulationError(SOLVER,"CVode::initialize()");
      memset(_zeroSign, -1, _dimZeroFunc * sizeof(int));
      memset(_zeroVal, -1, _dimZeroFunc * sizeof(int));

    }


    _arkode_initialized = true;

    //
    // CVODE is ready for integration
    //
    // BOOST_LOG_SEV(cvode_lg::get(), cvode_info) << "CVode initialized";
  }
}

void Arkode::solve(const SOLVERCALL action)
{
  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputFormat() == EMPTY) && !(_settings->getGlobalSettings()->getOutputPointType() == EMPTY2);

  if (_arkodesettings && _system)
  {
    // Solver und System fÃ¼r Integration vorbereiten
    if ((action & RECORDCALL) && (action & FIRST_CALL))
    {
        initialize();

        if (writeOutput)
          writeToFile(0, _tCurrent, _h);
        _tLastWrite = 0;

      return;
    }

    if ((action & RECORDCALL) && !(action & FIRST_CALL))
    {
      writeToFile(_accStps, _tCurrent, _h);
      return;
    }

    // Nach einem TimeEvent wird der neue Zustand recorded
    if (action & RECALL)
    {
      _firstStep = true;
      if (writeEventOutput)
        writeToFile(0, _tCurrent, _h);
      if (writeOutput)
        writeArkodeOutput(_tCurrent, _h, _locStps);
    _continuous_system->getContinuousStates(_z);
    }

    // Solver soll fortfahren
    _solverStatus = ISolver::CONTINUE;

    while (_solverStatus & ISolver::CONTINUE && !_interrupt )
    {
      // Zuvor wurde initialize aufgerufen und hat funktioniert => RESET IDID
      if (_idid == 5000)
        _idid = 0;

      // Solveraufruf
      if (_idid == 0)
      {
        // ZÃ¤hler zurÃ¼cksetzen
        _accStps = 0;
        _locStps = 0;

        // Solverstart
        //ARKode Core !!!!      
      ArkodeCore();

      }

      // Integration war nicht erfolgreich und wurde auch nicht vom User unterbrochen
      
      if (_idid != 0 && _idid != 1)
      {
        _solverStatus = ISolver::SOLVERERROR;
        //throw ModelicaSimulationError(SOLVER,_idid,_tCurrent,"CVode::solve()");
        throw ModelicaSimulationError(SOLVER,"CVode::solve()");
      }
      
      // Abbruchkriterium (erreichen der Endzeit)
      else if ((_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_arkodesettings)->getEndTimeTol())
        _solverStatus = DONE;

    }

    _firstCall = false;

  }
  else
  {

    throw ModelicaSimulationError(SOLVER,"CVode::solve()");
  }

}
bool Arkode::isInterrupted()
{
    if(_interrupt)
    {
       _solverStatus = DONE;
       return true;
    }
    else
    {
      return false;
    }
}
void Arkode::ArkodeCore()
{
  
  _idid = ARKodeReInit(_arkodeMem, NULL, ARK_fCallback, _tCurrent, _ARK_y);
  _idid = ARKodeSetStopTime(_arkodeMem, _tEnd);
  _idid = ARKodeSetInitStep(_arkodeMem, 1e-12);
  if (_idid < 0)
    throw ModelicaSimulationError(SOLVER,"ARKode::ReInit");

  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputFormat() == EMPTY) && !(_settings->getGlobalSettings()->getOutputPointType() == EMPTY2);

  while (_solverStatus & ISolver::CONTINUE && !_interrupt )
  {
    _ark_rt = ARKode(_arkodeMem, _tEnd, _ARK_y, &_tCurrent, ARK_ONE_STEP);

    _idid = ARKodeGetNumSteps(_arkodeMem, &_locStps);
    //if (_idid != CV_SUCCESS)
    //  throw ModelicaSimulationError(SOLVER,"CVodeGetNumSteps failed. The cvode mem pointer is NULL");

    _idid = ARKodeGetLastStep(_arkodeMem, &_h);
    //if (_idid != CV_SUCCESS)
    //  throw ModelicaSimulationError(SOLVER,"CVodeGetLastStep failed. The cvode mem pointer is NULL");

    //Check if there was at least one output-point within the last solver interval
    //  -> Write output if true
    if (writeOutput)
    {
        writeArkodeOutput(_tCurrent, _h, _locStps);
    }

    //set completed step to system and check if terminate was called
    if(_continuous_system->stepCompleted(_tCurrent))
        _solverStatus = DONE;

    // Perform state selection
    bool state_selection = stateSelection();
    if (state_selection)
      _continuous_system->getContinuousStates(_z);

    _zeroFound = false;

    // Check if step was successful
    /*
    if (check_flag(&_cv_rt, "CVode", 1))
    {
      _solverStatus = ISolver::SOLVERERROR;
      break;
    }*/

    // A root was found

    if ((_ark_rt == ARK_ROOT_RETURN) && !isInterrupted())
    {
      // CVode is setting _tCurrent to the time where the first event occurred
      double _abs = fabs(_tLastEvent - _tCurrent);
      _zeroFound = true;

      if ((_abs < 1e-3) && _event_n == 0)
      {
        _tLastEvent = _tCurrent;
        _event_n++;
      }
      else if ((_abs < 1e-3) && (_event_n >= 1 && _event_n < 500))
      {
        _event_n++;
      }
      else if ((_abs >= 1e-3))
      {
        //restart event counter
        _tLastEvent = _tCurrent;
        _event_n = 0;
      }
      else
        throw ModelicaSimulationError(EVENT_HANDLING,"Number of events exceeded  in time interval " + boost::lexical_cast<string>(_abs) + " at time " + boost::lexical_cast<string>(_tCurrent));

      // CVode has interpolated the states at time 'tCurrent'
      _time_system->setTime(_tCurrent);

      // To get steep steps in the result file, two value points (P1 and P2) must be added
      //
      // Y |   (P2) X...........
      //   |        :
      //   |        :
      //   |........X (P1)
      //   |---------------------------------->
      //   |        ^                         t
      //        _tCurrent

      // Write the values of (P1)
      if (writeEventOutput)
      {
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        writeToFile(0, _tCurrent, _h);
      }

      _idid = ARKodeGetRootInfo(_arkodeMem, _zeroSign);

      for (int i = 0; i < _dimZeroFunc; i++)
        _events[i] = bool(_zeroSign[i]);

      if (_mixed_system->handleSystemEvents(_events))
      {
        // State variables were reinitialized, thus we have to give these values to the cvode-solver
        // Take care about the memory regions, _z is the same like _CV_y
        _continuous_system->getContinuousStates(_z);
      }
    }

    if ((_zeroFound || state_selection)&& !isInterrupted())
    {
      // Write the values of (P2)
      if (writeEventOutput)
      {
        // If we want to write the event-results, we should evaluate the whole system again
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        writeToFile(0, _tCurrent, _h);
      }

      _idid = ARKodeReInit(_arkodeMem, NULL, ARK_fCallback, _tCurrent, _ARK_y);
      if (_idid < 0)
        throw ModelicaSimulationError(SOLVER,"CVode::ReInit()");

      // Der Eventzeitpunkt kann auf der Endzeit liegen (Time-Events). In diesem Fall wird der Solver beendet, da CVode sonst eine interne Warnung schmeißt
      if (_tCurrent == _tEnd)
        _ark_rt = ARK_TSTOP_RETURN;
    }

    // ZÃ¤hler fÃ¼r die Anzahl der ausgegebenen Schritte erhÃ¶hen
    ++_outStps;
    _tLastSuccess = _tCurrent;

    if (_ark_rt == ARK_TSTOP_RETURN)
    {
      _time_system->setTime(_tEnd);
      //Solver has finished calculation - calculate the final values
      _continuous_system->setContinuousStates(NV_DATA_S(_ARK_y));
      _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
      if(writeOutput)
         writeToFile(0, _tEnd, _h);

      _accStps += _locStps;
      _solverStatus = DONE;
    }

    }
}
void Arkode::setTimeOut(unsigned int time_out)
  {
       SimulationMonitor::setTimeOut(time_out);
  }
 void Arkode::stop()
  {
       SimulationMonitor::stop();
  }
void Arkode::writeArkodeOutput(const double &time, const double &h, const int &stp)
{
  if (stp > 0)
  {
    if (_arkodesettings->getDenseOutput())
    {
      _bWritten = false;
      double *oldValues = NULL;

      //We have to find all output-points within the last solver step
      while (_tLastWrite + dynamic_cast<ISolverSettings*>(_arkodesettings)->getGlobalSettings()->gethOutput() <= time)
      {
        if (!_bWritten)
        {
          //Rescue the calculated derivatives
          oldValues = new double[_continuous_system->getDimRHS()];
          _continuous_system->getRHS(oldValues);
        }
        _bWritten = true;
        _tLastWrite = _tLastWrite + dynamic_cast<ISolverSettings*>(_arkodesettings)->getGlobalSettings()->gethOutput();
        //Get the state vars at the output-point (interpolated)
        _idid = ARKodeGetDky(_arkodeMem, _tLastWrite, 0, _ARK_yWrite);
        _time_system->setTime(_tLastWrite);
        _continuous_system->setContinuousStates(NV_DATA_S(_ARK_yWrite));
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        
        SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);
        
        }      //end if time -_tLastWritten
        
      if (_bWritten)
      {
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(_z);
        _continuous_system->setRHS(oldValues);
        delete[] oldValues;
        //_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
      }
      else if (time == _tEnd && _tLastWrite != time)
      {
        _idid = ARKodeGetDky(_arkodeMem, time, 0, _ARK_y);
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(NV_DATA_S(_ARK_y));
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        SolverDefaultImplementation::writeToFile(stp, _tEnd, h);
      }

    }
    else
    {
        SolverDefaultImplementation::writeToFile(stp, time, h);
    }
  }
}

bool Arkode::stateSelection()
{
  return SolverDefaultImplementation::stateSelection();
}
int Arkode::calcFunction(const double& time, const double* y, double* f)
{
  int returnValue = 0;
  try
  {
    f[0] = 0.0; // in case of dummy state
    _time_system->setTime(time);
    _continuous_system->setContinuousStates(y);
    _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
    _continuous_system->getRHS(f);
  }      //workaround until exception can be catch from c- libraries
  catch (std::exception/* & ex */)
  {

    returnValue = 1;
  }
  return returnValue;
}

int Arkode::ARK_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data)
{
  return ((Arkode*) user_data)->calcFunction(t, NV_DATA_S(y), NV_DATA_S(ydot));
}

void Arkode::giveZeroVal(const double &t, const double *y, double *zeroValue)
{
  _time_system->setTime(t);
  _continuous_system->setContinuousStates(y);

  // System aktualisieren
  _continuous_system->evaluateZeroFuncs(IContinuous::DISCRETE);

  _event_system->getZeroFunc(zeroValue);

}

int Arkode::ARK_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data)
{
  ((Arkode*) user_data)->giveZeroVal(t, NV_DATA_S(y), zeroval);

  return (0);
}

/*int Arkode::CV_JCallback(long int N, double t, N_Vector y, N_Vector fy, DlsMat Jac,void *user_data, N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  return 0;
  //return ((Cvode*) user_data)->calcJacobian(t,N, tmp1, tmp2, tmp3,  NV_DATA_S(y), fy, Jac);

}*/

//int Arkode::calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthCol, double* y, N_Vector fy, DlsMat Jac)
//{
/*
  try
  {
  int l,g;
  double fnorm, minInc, *f_data, *fHelp_data, *errorWeight_data, h, srur, delta_inv;

  f_data = NV_DATA_S(fy);
  errorWeight_data = NV_DATA_S(errorWeight);
  fHelp_data = NV_DATA_S(fHelp);


  //Get relevant info
  _idid = CVodeGetErrWeights(_cvodeMem, errorWeight);
  if (_idid < 0)
    {
      _idid = -5;
      throw ModelicaSimulationError(SOLVER,"Cvode::calcJacobian()");
  }
  _idid = CVodeGetCurrentStep(_cvodeMem, &h);
  if (_idid < 0)
    {
      _idid = -5;
      throw ModelicaSimulationError(SOLVER,"Cvode::calcJacobian()");
  }

  srur = sqrt(UROUND);

  fnorm = N_VWrmsNorm(fy, errorWeight);
  minInc = (fnorm != 0.0) ?
           (1000.0 * abs(h) * UROUND * N * fnorm) : 1.0;

  for(int j=0;j<N;j++)
  {
    _delta[j] = max(srur*abs(y[j]), minInc/errorWeight_data[j]);
  }

  for(int j=0;j<N;j++)
  {
    _deltaInv[j] = 1/_delta[j];
  }

 if (_jacobianANonzeros != 0)
 {
  for(int color=1; color <= _maxColors; color++)
  {
      for(int k=0; k < _dimSys; k++)
    {
      if((_colorOfColumn[k] ) == color)
      {
        _ysave[k] = y[k];
        y[k]+= _delta[k];
      }
    }

    calcFunction(t, y, fHelp_data);

  for (int k = 0; k < _dimSys; k++)
   {
       if((_colorOfColumn[k]) == color)
     {
        y[k] = _ysave[k];

    int startOfColumn = k * _dimSys;
    for (int j = _jacobianALeadindex[k]; j < _jacobianALeadindex[k+1];j++)
      {
        l = _jacobianAIndex[j];
        g = l + startOfColumn;
        Jac->data[g] = (fHelp_data[l] - f_data[l]) * _deltaInv[k];
      }
    }
  }
  }
 }





  }
*/





  /*
  //Calculation of J without colouring
   for (j = 0; j < N; j++)
   {


    //N_VSetArrayPointer(DENSE_COL(Jac,j), jthCol);

     _ysave[j] = y[j];

    y[j] += _delta[j];

    calcFunction(t, y, fHelp_data);

    y[j] = _ysave[j];

    delta_inv = 1.0/_delta[j];
    N_VLinearSum(delta_inv, fHelp, -delta_inv, fy, jthCol);

    for(int i=0; i<_dimSys; ++i)
        {
            Jac->data[i+j*_dimSys] = NV_Ith_S(jthCol,i);
        }

    //DENSE_COL(Jac,j) = N_VGetArrayPointer(jthCol);
  }
  */

    //workaround until exception can be catch from c- libraries
  /*
  catch (std::exception & ex )
  {

    cerr << "CVode integration error: " <<  ex.what();
    return 1;
  }
  */

//  return 0;
//}

int Arkode::reportErrorMessage(ostream& messageStream)
{
  if (_solverStatus == ISolver::SOLVERERROR)
  {
    if (_idid == -1)
      messageStream << "Invalid system dimension." << std::endl;
    if (_idid == -2)
      messageStream << "Method not implemented." << std::endl;
    if (_idid == -3)
      messageStream << "No valid system/settings available." << std::endl;
    if (_idid == -11)
      messageStream << "Step size too small." << std::endl;
  }

  else if (_solverStatus == ISolver::USER_STOP)
  {
    messageStream << "Simulation terminated by user at t: " << _tCurrent << std::endl;
  }

  return _idid;
}

void Arkode::writeSimulationInfo()
{
#ifdef USE_BOOST_LOG
/*
  src::logger lg;

  // Now, let's try logging with severity
  src::severity_logger<cvodeseverity_level> slg;

  long int nst, nfe, nsetups, nni, ncfn, netf;
  long int nfQe, netfQ;
  long int nfSe, nfeS, nsetupsS, nniS, ncfnS, netfS;
  long int nfQSe, netfQS;

  int qlast, qcur;
  realtype h0u, hlast, hcur, tcur;

  int flag;

  flag = CVodeGetIntegratorStats(_cvodeMem, &nst, &nfe, &nsetups, &netf, &qlast, &qcur, &h0u, &hlast, &hcur, &tcur);

  flag = CVodeGetNonlinSolvStats(_cvodeMem, &nni, &ncfn);

  BOOST_LOG_SEV(slg, cvode_normal)<< " Number steps: " << nst;
  BOOST_LOG_SEV(slg, cvode_normal)<< " Function evaluations " << "f: " << nfe;
  BOOST_LOG_SEV(slg, cvode_normal)<< " Error test failures " << "netf: " << netfS;
  BOOST_LOG_SEV(slg, cvode_normal)<< " Linear solver setups " << "nsetups: " << nsetups;
  BOOST_LOG_SEV(slg, cvode_normal)<< " Nonlinear iterations " << "nni: " << nni;
  BOOST_LOG_SEV(slg, cvode_normal)<< " Convergence failures " << "ncfn: " << ncfn;
*/
#endif
  //// Solver
  //outputStream  << "\nSolver: " << getName()
  //  << "\nVerfahren: ";
  //if(_cvodesettings->iMethod == EulerSettings::EULERFORWARD)
  //  outputStream << " Expliziter Cvode\n\n";
  //else if(_cvodesettings->iMethod == EulerSettings::EULERBACKWARD)
  //  outputStream << " Impliziter Cvode\n\n";

  //// System
  //outputStream
  //  << "Dimension  des Systems (ODE):             " << (int)_dimSys << "\n";
  //// Status, Anzahl Schritte, Nullstellenzeugs
  //SolverDefaultImplementation::writeSimulationInfo(outputStream);

  //// Nullstellensuche
  //if (_cvodesettings->iZeroSearchMethod == SolverSettings::NO_ZERO_SEARCH)
  //{
  //  outputStream << "Nullstellensuche:                         Keine\n\n" << endl;
  //}
  //else
  //{
  //  /*if (_cvodesettings->iZeroSearchMethod == SolverSettings::BISECTION)
  //  {
  //  outputStream << "Nullstellensuche:                         Bisektion\n" << endl;
  //  }
  //  else
  //  {*/
  //  outputStream << "Nullstellensuche:                         Lineare Interpolation\n" << endl;
  //  /*}*/

  //}

  //// Schritteweite
  //outputStream
  //  << "ausgegebene Schritte:                     " << _outStps << "\n"
  //  << "Anfangsschrittweite:                      " << _cvodesettings->dH_init << "\n"
  //  << "Ausgabeschrittweite:                      " << dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput() << "\n"
  //  << "Obere Grenze fÃ¼r Schrittweite:            " << _hUpLim << "\n\n";
  //// Status
  //outputStream
  //  << "Solver-Status:                            " << _idid << "\n\n";
}

int Arkode::check_flag(void *flagvalue, const char *funcname, int opt)
{
  int *errflag;

  /* Check if SUNDIALS function returned NULL pointer - no memory allocated */

  if (opt == 0 && flagvalue == NULL)
  {
    fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n", funcname);
    return (1);
  }

  /* Check if flag < 0 */

  else if (opt == 1)
  {
    errflag = (int *) flagvalue;
    if (*errflag < 0)
    {
      fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n", funcname, *errflag);
      return (1);
    }
  }

  /* Check if function returned NULL pointer - no memory allocated */

  else if (opt == 2 && flagvalue == NULL)
  {
    fprintf(stderr, "\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n", funcname);
    return (1);
  }

  return (0);
}