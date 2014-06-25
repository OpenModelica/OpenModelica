#include "Modelica.h"
#include "CVode.h"
#include <Math/Functions.h>

Cvode::Cvode(IMixedSystem* system, ISolverSettings* settings)
  : SolverDefaultImplementation( system, settings)
  , _cvodesettings    (dynamic_cast<ISolverSettings*>(_settings))
  , _z          (NULL)
  , _zInit        (NULL)
  , _zWrite        (NULL)
  , _dimSys        (0)
  , _outStps        (0)
  , _locStps        (0)
  , _idid          (0)
  , _hOut          (0.0)
  , _tOut          (0.0)
  , _zeroSign        (NULL)
  ,_cvode_initialized(false)
  ,_tLastEvent(0.0)
  ,_event_n(0)

{
  _data = ((void*)this);
}

Cvode::~Cvode()
{
  if(_z)
    delete [] _z;
  if(_zInit)
    delete [] _zInit;
  if(_zeroSign)
    delete [] _zeroSign;
  if(_cvode_initialized)
  {
    N_VDestroy_Serial(_CV_y0);
    N_VDestroy_Serial(_CV_y);
    N_VDestroy_Serial(_CV_yWrite);
    CVodeFree(&_cvodeMem);
  }
}


void Cvode::initialize()
{
  _properties = dynamic_cast<ISystemProperties*>(_system);
  _continuous_system = dynamic_cast<IContinuous*>(_system);
  _event_system =  dynamic_cast<IEvent*>(_system);
  _mixed_system =  dynamic_cast<IMixedSystem*>(_system);
  _time_system =  dynamic_cast<ITime*>(_system);
  IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings();
  // Kennzeichnung, dass initialize()() (vor der Integration) aufgerufen wurde
  _idid = 5000;
    _tLastEvent=0.0;
   _event_n=0;
  SolverDefaultImplementation::initialize();
  _dimSys    = _continuous_system->getDimContinuousStates();
  _dimZeroFunc = _event_system->getDimZeroFunc();

  if(_dimSys <= 0)
  {
    _idid = -1;
    throw std::invalid_argument("Cvode::initialize()");
  }
  else
  {
    // Allocate state vectors, stages and temporary arrays
    if(_z)        delete [] _z;
    if(_zInit)      delete [] _zInit;
    if(_zWrite)      delete [] _zWrite;
    if(_zeroSign)    delete [] _zeroSign;


    _z        = new double[_dimSys];
    _zInit      = new double[_dimSys];
    _zWrite        = new double[_dimSys];
    _zeroSign    = new int[_dimZeroFunc];

    memset(_z,0,_dimSys*sizeof(double));
    memset(_zInit,0,_dimSys*sizeof(double));


    // Counter initialisieren
    _outStps  = 0;

    if(_cvodesettings->getDenseOutput())
    {
      // Ausgabeschrittweite
      _hOut    = global_settings->gethOutput();

    }

    // Allocate memory for the solver
    _cvodeMem = CVodeCreate(CV_BDF, CV_NEWTON);
    if(check_flag((void*)_cvodeMem, "CVodeCreate", 0))
    {
      _idid = -5;
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::initialize()");
    }

    //
    // Make Cvode ready for integration
    //

    // Set initial values for CVODE
    _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
    _continuous_system->getContinuousStates(_zInit);
    memcpy(_z,_zInit,_dimSys*sizeof(double));

    _CV_y0 = N_VMake_Serial(_dimSys, _zInit);
    _CV_y = N_VMake_Serial(_dimSys, _z);
    _CV_yWrite = N_VMake_Serial(_dimSys, _zWrite);
    if(check_flag((void*)_CV_y0, "N_VMake_Serial", 0))
    {
      _idid = -5;
      throw std::invalid_argument("Cvode::initialize()");
    }

    // Initialize Cvode (Initial values are required)
    _idid = CVodeInit(_cvodeMem, CV_fCallback, _tCurrent, _CV_y0);
    if(_idid < 0)
    {
      _idid = -5;
      throw std::invalid_argument("Cvode::initialize()");
    }

    // Set Tolerances
    _idid = CVodeSStolerances(_cvodeMem,dynamic_cast<ISolverSettings*>(_cvodesettings)->getRTol(),dynamic_cast<ISolverSettings*>(_cvodesettings)->getATol());// RTOL and ATOL
    if(_idid < 0)
      throw std::invalid_argument("CVode::initialize()");

    // Set the pointer to user-defined data
    _idid = CVodeSetUserData(_cvodeMem, _data);
    if(_idid < 0)
      throw std::invalid_argument("Cvode::initialize()");

    _idid = CVodeSetInitStep(_cvodeMem, 1e-6);// INITIAL STEPSIZE
    if(_idid < 0)
      throw std::invalid_argument("Cvode::initialize()");

    _idid = CVodeSetMaxOrd(_cvodeMem, 5);       // Max Order
    if(_idid < 0)
      throw std::invalid_argument("CVoder::initialize()");

    _idid = CVodeSetMaxConvFails(_cvodeMem, 100);       // Maximale Fehler im Konvergenztest
    if(_idid < 0)
      throw std::invalid_argument("CVoder::initialize()");

    _idid = CVodeSetStabLimDet(_cvodeMem, FALSE);       // Stability Detection
    if(_idid < 0)
      throw std::invalid_argument("CVoder::initialize()");


    _idid = CVodeSetMinStep(_cvodeMem, dynamic_cast<ISolverSettings*>(_cvodesettings)->getLowerLimit());       // MINIMUM STEPSIZE
    if(_idid < 0)
      throw std::invalid_argument("CVode::initialize()");

    _idid = CVodeSetMaxStep(_cvodeMem, global_settings->getEndTime()/10.0);       // MAXIMUM STEPSIZE
    if(_idid < 0)
      throw std::invalid_argument("CVode::initialize()");

    _idid = CVodeSetMaxNonlinIters(_cvodeMem, 5);      // Max number of iterations
    if(_idid < 0)
      throw std::invalid_argument("CVode::initialize()");
    _idid = CVodeSetMaxErrTestFails(_cvodeMem, 100);
    if(_idid < 0)
      throw std::invalid_argument("CVode::initialize()");

    _idid = CVodeSetMaxNumSteps(_cvodeMem,1e3);            // Max Number of steps
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::initialize()");

     _idid = CVDense(_cvodeMem, _dimSys);
    if(_idid < 0)
      throw std::invalid_argument("Cvode::initialize()");

    if(_dimZeroFunc)
    {
      _idid = CVodeRootInit(_cvodeMem,_dimZeroFunc, CV_ZerofCallback);


   memset(_zeroSign,0,_dimZeroFunc*sizeof(int));
      _idid = CVodeSetRootDirection(_cvodeMem, _zeroSign);
      if(_idid < 0)
        throw std::invalid_argument(/*_idid,_tCurrent,*/"CVode::initialize()");
      memset(_zeroSign,-1,_dimZeroFunc*sizeof(int));
      memset(_zeroVal,-1,_dimZeroFunc*sizeof(int));

    }
    _cvode_initialized = true;


    //
    // CVODE is ready for integration
    //
   // BOOST_LOG_SEV(cvode_lg::get(), cvode_info) << "CVode initialized";
  }
}

void Cvode::solve(const SOLVERCALL action)
{
  //_eulerSettings->getEventOutput() = true;

  if (_cvodesettings && _system)
  {
    // Solver und System fÃ¼r Integration vorbereiten
    if(action & RECORDCALL && action & FIRST_CALL)
    {
      initialize();
      writeToFile(0, _tCurrent, _h);
      _tLastWrite = 0;
	  
	  return;
    }

    if(action & RECORDCALL && !(action & FIRST_CALL))
    {
      writeToFile(_accStps, _tCurrent, _h);
      return;
    }

    // Nach einem TimeEvent wird der neue Zustand recorded
    if(action & RECALL)
    {
      _firstStep = true;
       if (_cvodesettings->getEventOutput())
			writeToFile(0, _tCurrent, _h);
	   //else
			writeCVodeOutput(_tCurrent,_h,_locStps);
    }

    // Solver soll fortfahren
    _solverStatus = ISolver::CONTINUE;


    while ( _solverStatus & ISolver::CONTINUE )
    {
      // Zuvor wurde initialize aufgerufen und hat funktioniert => RESET IDID
      if(_idid == 5000)
        _idid = 0;

      // Solveraufruf
      if(_idid == 0)
      {
        // ZÃ¤hler zurÃ¼cksetzen
        _accStps = 0;
        _locStps = 0;

        // Solverstart
        CVodeCore();

      }

      // Integration war nicht erfolgreich und wurde auch nicht vom User unterbrochen
      if(_idid != 0 && _idid !=1)
      {
        _solverStatus = ISolver::SOLVERERROR;
        //throw std::invalid_argument(_idid,_tCurrent,"CVode::solve()");
        throw std::invalid_argument("CVode::solve()");
      }

      // Abbruchkriterium (erreichen der Endzeit)
      else if  ( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_cvodesettings)->getEndTimeTol())
        _solverStatus = DONE;
    }

    _firstCall = false;

  }
  else
  {

    throw std::invalid_argument("CVode::solve()");
  }
}

void Cvode::CVodeCore()
{
  _idid = CVodeReInit(_cvodeMem, _tCurrent, _CV_y);
  _idid = CVodeSetStopTime(_cvodeMem, _tEnd);
  _idid = CVodeSetInitStep(_cvodeMem, 1e-6);
  if(_idid <0)
    throw std::runtime_error("CVode::ReInit");

  while(_solverStatus & ISolver::CONTINUE)
  {
    _cv_rt = CVode(_cvodeMem, _tEnd, _CV_y, &_tCurrent, CV_ONE_STEP);

    _idid = CVodeGetNumSteps(_cvodeMem, &_locStps);
    _accStps +=_locStps;
    _idid = CVodeGetLastStep(_cvodeMem,&_h);
    //Ausgabe
    writeCVodeOutput(_tCurrent,_h,_locStps);
     _continuous_system->stepCompleted(_tCurrent);
    /*_continuous_system->stepCompleted(_tCurrent);   */
     /*ToDo
     if(dynamic_cast<IStepEvent*>(_system)->isStepEvent())
    {
      _cv_rt = 2;
    }*/

  bool state_selection = stateSelection();
  bool restart =false;
  if(state_selection)
  {
    restart=true;
    _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
  }
    _zeroFound = false;

    // Check, ob Schritt erfolgreich
    if(check_flag(&_cv_rt, "CVode", 1))
    {
      _solverStatus = ISolver::SOLVERERROR;
      break;
    }

    // A root is found
    if((_cv_rt == CV_ROOT_RETURN)  )
    {
      _zeroFound = true;
      if((abs(_tLastEvent - _tCurrent)<1e-3) &&   _event_n==0)
      {
        _tLastEvent=_tCurrent;
        _event_n++;
      }
      else if((abs(_tLastEvent - _tCurrent)<1e-3) && (_event_n>=1 && _event_n<500))
      {
            _event_n++;
      }
      else if((abs(_tLastEvent - _tCurrent)>=1e-3) )
      {
        //restart event counter
        _tLastEvent=_tCurrent;
        _event_n=0;
      }
      else
      {
            throw std::runtime_error("Number of events exceeded  in time interval " + boost::lexical_cast<string>(abs(_tLastEvent - _tCurrent))+ "at time " +  boost::lexical_cast<string>(_tCurrent) );
      }
      _time_system->setTime(_tCurrent);
      _continuous_system->setContinuousStates(NV_DATA_S(_CV_y));
      _continuous_system->evaluateODE(IContinuous::CONTINUOUS );
      // Zustände recorden bis hierher
      if (_cvodesettings->getEventOutput())
        writeToFile(0, _tCurrent, _h);

      _idid = CVodeGetRootInfo(_cvodeMem, _zeroSign);

      for(int i=0;i<_dimZeroFunc;i++)
        _events[i] = bool(_zeroSign[i]);

      //Event Iteration starten

      _mixed_system->handleSystemEvents(_events);
       _event_system->getZeroFunc(_zeroVal);
    }//EVENT Iteration beendet

    // Zustand aus dem System holen
    _continuous_system->getContinuousStates(_z);
    if(_zeroFound || restart)
    {
    restart=false;
      //Zustände nach der Ereignisbehandlung aufnehmen
      if (_cvodesettings->getEventOutput())
        writeToFile(0, _tCurrent, _h);

      _idid = CVodeReInit(_cvodeMem, _tCurrent, _CV_y);
      if(_idid < 0)
        throw std::runtime_error("CVode::ReInit()");

      // Der Eventzeitpunkt kann auf der Endzeit liegen (Time-Events). In diesem Fall wird der Solver beendet, da CVode sonst eine interne Warnung schmeißt
      if(_tCurrent == _tEnd)
        _cv_rt = CV_TSTOP_RETURN;
    }

    // ZÃ¤hler fÃ¼r die Anzahl der ausgegebenen Schritte erhÃ¶hen
    ++ _outStps;
    _tLastSuccess = _tCurrent;

    if(_cv_rt == CV_TSTOP_RETURN)
    {
      _time_system->setTime(_tEnd);
      _continuous_system->setContinuousStates(NV_DATA_S(_CV_y));
      _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
       writeToFile(0, _tEnd, _h);
      _solverStatus = DONE;
    }
  }
}

void Cvode::writeCVodeOutput(const double &time,const double &h,const int &stp)
{
  if (stp > 0)
  {
    if (_cvodesettings->getDenseOutput())
    {

      _bWritten = false;
      while (_tLastWrite +  dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput()  <= time)
      {
        _bWritten = true;
        _tLastWrite = _tLastWrite +  dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput();
        _idid = CVodeGetDky(_cvodeMem, _tLastWrite, 0, _CV_yWrite);
        _time_system->setTime(_tLastWrite);
        _continuous_system->setContinuousStates(NV_DATA_S(_CV_yWrite));
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS );
        SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);
      }//end if time -_tLastWritten
      if (_bWritten)
      {
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(_z);
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS );
      }else if(time == _tEnd && _tLastWrite != time)
      {
        _idid = CVodeGetDky(_cvodeMem, time, 0, _CV_y);
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(NV_DATA_S(_CV_y));
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        SolverDefaultImplementation::writeToFile(stp, _tEnd, h);
      }
    }
    else
      SolverDefaultImplementation::writeToFile(stp, time, h);
  }
}


bool Cvode::stateSelection()
 {
   return SolverDefaultImplementation::stateSelection();
 }
int Cvode::calcFunction(const double& time, const double* y, double* f)
{
  try
  {
    _time_system->setTime(time);
    _continuous_system->setContinuousStates(y);
    _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
    _continuous_system->getRHS(f);


  }//workaround until exception can be catch from c- libraries
  catch(std::exception& ex)
  {
    std::string error = ex.what();
    cerr << "CVode integration error: "<<  error ;
    return -1;
  }
  return 0;
}

int Cvode::CV_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data)
{
  return ((Cvode*) user_data)->calcFunction(t, NV_DATA_S(y),NV_DATA_S(ydot));


}

void Cvode::giveZeroVal(const double &t,const double *y,double *zeroValue)
{
  _time_system->setTime(t);
  _continuous_system->setContinuousStates(y);

  // System aktualisieren
  _continuous_system->evaluateZeroFuncs(IContinuous::CONTINUOUS);

  _event_system->getZeroFunc(zeroValue);

}

int Cvode::CV_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data)
{
  ((Cvode*) user_data)->giveZeroVal(t, NV_DATA_S(y),zeroval);

  return(0);
}

const int Cvode::reportErrorMessage(ostream& messageStream)
{
  if(_solverStatus == ISolver::SOLVERERROR)
  {
    if(_idid == -1)
      messageStream << "Invalid system dimension." << std::endl;
    if(_idid == -2)
      messageStream << "Method not implemented." << std::endl;
    if(_idid == -3)
      messageStream << "No valid system/settings available." << std::endl;
    if(_idid == -11)
      messageStream << "Step size too small." << std::endl;
  }

  else if(_solverStatus == ISolver::USER_STOP)
  {
    messageStream << "Simulation terminated by user at t: " << _tCurrent << std::endl;
  }

  return _idid;
}

void Cvode::writeSimulationInfo()
{


/*
   src::logger lg;



    // Now, let's try logging with severity
     src::severity_logger< cvodeseverity_level > slg;




  long int nst, nfe, nsetups, nni, ncfn, netf;
  long int nfQe, netfQ;
  long int nfSe, nfeS, nsetupsS, nniS, ncfnS, netfS;
  long int nfQSe, netfQS;

  int qlast, qcur;
  realtype h0u, hlast, hcur, tcur;

  int flag;


  flag = CVodeGetIntegratorStats(_cvodeMem, &nst, &nfe, &nsetups, &netf,
                                 &qlast, &qcur,
                                 &h0u, &hlast, &hcur,
                                 &tcur);

  flag = CVodeGetNonlinSolvStats(_cvodeMem, &nni, &ncfn);

  BOOST_LOG_SEV(slg, cvode_normal) << " Number steps: " << nst;
  BOOST_LOG_SEV(slg, cvode_normal) << " Function evaluations " << "f: " << nfe;
  BOOST_LOG_SEV(slg, cvode_normal) << " Error test failures " <<  "netf: " << netfS;
  BOOST_LOG_SEV(slg, cvode_normal) << " Linear solver setups " << "nsetups: " <<  nsetups;
  BOOST_LOG_SEV(slg, cvode_normal) << " Nonlinear iterations " <<  "nni: "  << nni ;
  BOOST_LOG_SEV(slg, cvode_normal) << " Convergence failures " <<  "ncfn: " <<  ncfn ;



*/


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

int Cvode::check_flag(void *flagvalue, const char *funcname, int opt)
{
  int *errflag;

  /* Check if SUNDIALS function returned NULL pointer - no memory allocated */

  if (opt == 0 && flagvalue == NULL) {
    fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n",
      funcname);
    return(1); }

  /* Check if flag < 0 */

  else if (opt == 1) {
    errflag = (int *) flagvalue;
    if (*errflag < 0) {
      fprintf(stderr, "\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n",
        funcname, *errflag);
      return(1); }}

  /* Check if function returned NULL pointer - no memory allocated */

  else if (opt == 2 && flagvalue == NULL) {
    fprintf(stderr, "\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n",
      funcname);
    return(1); }

  return(0);
}
