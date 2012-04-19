#include "stdafx.h"
#include "Idas.h"
#include "IdasSettings.h"





Idas::Idas(IDAESystem* system, ISolverSettings* settings)
  : SolverDefaultImplementation( system, settings)
  , _idasSettings    (dynamic_cast<IIdasSettings*>(_settings))
  	, _z					(NULL)
	, _zp0					(NULL)
	, _z0					(NULL)
	, _zInit				(NULL)
	, _fHelp				(NULL)
	, _zLastSucess			(NULL)
	, _zLargeStep			(NULL)
	, _zWrite				(NULL)
	, _id					(NULL)
	, _dimSys				(0)
	, _outStps				(0)
	, _locStps				(0)
	, _idid					(0)
	, _hOut					(0.0)	
	, _hZero				(0.0)	
	, _hUpLim				(0.0)
	, _hZeroCrossing		(0.0)
	, _hUpLimZeroCrossing	(0.0)
	, _tOut					(0.0)	
	, _tLastZero			(0.0)
	, _tRealInitZero		(0.0)
	, _doubleZeroDistance	(0.0)
	, _f0					(NULL)
	, _f1					(NULL)
	, _zeroSign        (NULL)

{
  _data = ((void*)this);
}

Idas::~Idas()
{	
	if(_z)						
		delete [] _z;
	if(_zp0)						
		delete [] _zp0;
	if(_z0)						
		delete [] _z0;
	if(_fHelp)						
		delete [] _fHelp;
	if(_zInit)					
		delete [] _zInit;
	if(_zWrite)					
		delete [] _zWrite;
	if(_id)					
		delete [] _id;
	if(_zLastSucess)			
		delete [] _zLastSucess;
	if(_zLargeStep)				
		delete [] _zLargeStep;
	if(_f0)
		delete [] _f0;
	if(_f1)
		delete [] _f1;
 if(_zeroSign)
		delete [] _zeroSign;
	N_VDestroy_Serial(_IDA_z0);
	N_VDestroy_Serial(_IDA_zp0);	
	N_VDestroy_Serial(_IDA_z);		
	N_VDestroy_Serial(_IDA_zp);
	N_VDestroy_Serial(_ID);	
	N_VDestroy_Serial(_IDA_zWrite);

	IDAFree(&_idaMem);

}


void Idas::init()
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
   IEvent* event_system =  dynamic_cast<IEvent*>(_system);
  // Kennzeichnung, dass init() (vor der Integration) aufgerufen wurde
  _idid = 5000;

  // System im Solver assemblen, da folgende Reihenfolge einzuhalten ist: 
  // 1) System assemblen und updaten, alles für Nullstellsuche anlegen
  // 2) Spezielle Dimensionen bestimmen (muss wg. ODE/DAE im Solver stattfinden) 
  // 3) Zustandsvektor anlegen
  SolverDefaultImplementation::init();

	_dimIndex0		= continous_system->getDimVars(IContinous::VAR_INDEX0);
	_dimIndex1		= continous_system->getDimVars(IContinous::VAR_INDEX1);
	_dimIndex2		= continous_system->getDimVars(IContinous::VAR_INDEX2);
    _dimDEq			= _dimIndex0 + _dimIndex1 + _dimIndex2;
	_dimSys			= continous_system->getDimVars(IContinous::ALL_STATES);
	_dimAEq			= continous_system->getDimVars(IContinous::DIFF_INDEX3);
	_dimDiffIndex3	= 0;
	 _dimZeroFunc = event_system->getDimZeroFunc();
  if(_dimSys <= 0 )
  {
    _idid = -1; 
    throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");
  }
  else
  {
    	// Allocate state vectors, stages and temporary arrays
		if(_z)				delete [] _z;
		if(_zp0)			delete [] _zp0;
		if(_fHelp)			delete [] _fHelp;
		if(_zInit)			delete [] _zInit;
		if(_zLastSucess)	delete [] _zLastSucess;
		if(_zLargeStep)		delete [] _zLargeStep;
		if(_zWrite)			delete [] _zWrite;
		if(_id)				delete [] _id;
		 if(_zeroSign)    delete [] _zeroSign;
		_z				= new double[_dimSys];
		_zp0			= new double[_dimSys];
		_zInit			= new double[_dimSys];
		_fHelp			= new double[_dimSys];
		_zLastSucess	= new double[_dimSys];
		_zLargeStep		= new double[_dimSys];
		_zWrite		    = new double[_dimSys];
		_f0				= new double[_dimSys];
		_f1				= new double[_dimSys];
		_id				= new double[_dimSys];
		_zeroSign    = new int[_dimZeroFunc];
		memset(_z,0,_dimSys*sizeof(double));
		memset(_zp0,0,_dimSys*sizeof(double));
		memset(_zInit,0,_dimSys*sizeof(double));
		memset(_fHelp,0,_dimSys*sizeof(double));
		memset(_zWrite,0,_dimSys*sizeof(double));
		memset(_zLastSucess,0,_dimSys*sizeof(double));
		memset(_zLargeStep,0,_dimSys*sizeof(double));
		memset(_id,0,_dimSys*sizeof(double));
		// Arrays für Zustandswerte an den Berechnungsintervallgrenzen

		if(_z0)		delete [] _z0;
		
		_z0 = new double[_dimSys];
		
		memset(_z0,0,_dimSys*sizeof(double));
		
		
		for(int i=0;i<_dimSys-_dimAEq;i++)
			_id[i] = 1;
		// Counter initialisieren
		_outStps	= 0;

    if(_idasSettings->getDenseOutput())
    {
      // Ausgabeschrittweite
      _hOut    = dynamic_cast<ISolverSettings*>(_idasSettings)->getGlobalSettings()->gethOutput();

    }

    
    //
    // Make IDA ready for integration
    //

    _idaMem = IDACreate();

		// System und Events aktualisieren
		continous_system->update();
		_updateCalls++;
		// giveVars (Zustand holen)
		continous_system->giveVars(_zInit);
		continous_system->giveRHS(_zp0,IContinous::ALL_STATES);
		memcpy(_z,_zInit,_dimSys*sizeof(double));

		_IDA_z0 = N_VMake_Serial(_dimSys, _zInit);
		_IDA_zp0 = N_VMake_Serial(_dimSys, _zp0);
		_IDA_z = N_VMake_Serial(_dimSys, _z);
		_IDA_zp = N_VMake_Serial(_dimSys, _zp0);
		_ID = N_VMake_Serial(_dimSys, _id);
		_IDA_zWrite = N_VMake_Serial(_dimSys, _zWrite);
		
		if(check_flag((void*)_IDA_z0, "N_VMake_Serial", 0))
		{
			_idid = -5; 
			//throw SimIdasException(_idid,_tCurrent,"Idas::assemble()");
			throw std::invalid_argument("Idas::init()");
		}

    // Allocate memory for the solver
    _idid = IDAInit(_idaMem,IDA_fCallback, _tCurrent, _IDA_z0, _IDA_zp0);
    if(check_flag((void*)_idaMem, "CVodeCreate", 0))
    {
      _idid = -5; 
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");
    }


    // Set Tolerances
   	_idid = IDASStolerances(_idaMem, dynamic_cast<ISolverSettings*>(_idasSettings)->getRTol(), dynamic_cast<ISolverSettings*>(_idasSettings)->getATol());					// RTOL and ATOL
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

    // Set the pointer to user-defined data
    _idid = IDASetUserData(_idaMem, _data);
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

    	_idid = IDASetInitStep(_idaMem, dynamic_cast<ISolverSettings*>(_idasSettings)->gethInit());							// INITIAL STEPSIZE
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

   _idid = IDASetMaxStep(_idaMem, dynamic_cast<ISolverSettings*>(_idasSettings)->getUpperLimit());							// MAXIMUM STEPSIZE
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

    	_idid = IDASetMaxNonlinIters(_idaMem, 15);											// Max number of iterations
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

    _idid = IDASetMaxNumSteps(_idaMem,1e10);            // Max Number of steps
    if(_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::init()");

		_idid = IDADense(_idaMem, _dimSys);

		_idid = IDARootInit(_idaMem,_dimZeroFunc, IDA_ZerofCallback);

		// ID initialisieren
		_idid = IDASetId(_idaMem, _ID);
		_idid = IDACalcIC(_idaMem, IDA_YA_YDP_INIT,  dynamic_cast<ISolverSettings*>(_idasSettings)->gethInit());
		
		if(_idid < 0)
			throw std::invalid_argument("Idas::init()");
			//throw SimIdasException(_idid,_tCurrent,"Idas::assemble()");


		//
		// IDA is ready for integration
		//

  }
}


void Idas::solve(const SOLVERCALL action)
{
  //_idasSettings->getEventOutput() = true;

  if (_idasSettings && _system)
  {
    // Solver und System für Integration vorbereiten
    if(action & RECORDCALL && action & FIRST_CALL)
    {
      init();
      writeToFile(0, _tCurrent, _h);
      saveInitState();
      _tLastWrite = 0;
      /*return;*/
    }


    /*if(action & RECORDCALL)
    {
      writeToFile(0, _tCurrent, _h);
      return;
    }*/

    // Veranlasst das Auslesen des Systemzustandes bevor der erste Solverschritt erfolgt
    if (action & RECALL)
      _firstStep = true;

    // Nach einem TimeEvent wird der neue Zustand recorded
    if(action & TIMEEVENTCALL)
    {
      _firstStep = true;
      if (_idasSettings->getEventOutput())
        writeToFile(0, _tCurrent, _h);
    }

    // Curser wird an den Anfang gestzt und das Schreiben veranlasst (RESET&WRITE)
    if (action & REPEATED_CALL)
      _outputCommand = IDAESystem::OVERWRITE;
    else if (action & REGULAR_CALL)
      _outputCommand = IDAESystem::WRITE;
    else
      _outputCommand = IDAESystem::UNDEF_OUTPUT;

    // Solver soll fortfahren
    _solverStatus = IDAESolver::CONTINUE;


    while ( _solverStatus & IDAESolver::CONTINUE )
    {
      // Schrittweite auf initstep setzen es sei denn h > master step
      if(!_zeroSearchActive)
        _h = max(min(_h,dynamic_cast<ISolverSettings*>(_idasSettings)->getUpperLimit()),dynamic_cast<ISolverSettings*>(_idasSettings)->getLowerLimit());


      // Zuvor gab es einen Userstop => Reset IDID
      //if(_idid == 1)
      //  _idid = 0;

      // Zuvor wurde init aufgerufen und hat funktioniert => RESET IDID
      if(_idid == 5000)
        _idid = 0;

      // Solveraufruf
      if(_idid == 0)
      {
        // Zähler zurücksetzen
        _accStps = 0;
        _locStps = 0;

        // Solverstart
        callIDA();

      }

      // Integration war nicht erfolgreich und wurde auch nicht vom User unterbrochen
      if(_idid != 0 && _idid !=1)
      {
        _solverStatus = SOLVERERROR;
        throw std::invalid_argument(/*_idid,_tCurrent,*/"Idas::solve()");
      }

      // Abbruchkriterium (erreichen der Endzeit)
      else if  ( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_idasSettings)->getEndTimeTol())  
        _solverStatus = DONE;
    }

    _firstCall = false; 

  }
  else
  {
    
    throw std::invalid_argument(/*-1,_tCurrent,*/"Idas::solve()");
  }
}

void Idas::callIDA()
{
  IEvent* event_system =  dynamic_cast<IEvent*>(_system);
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  while(_solverStatus & IDAESolver::CONTINUE)
  {
    _idid = IDASolve(_idaMem, _tEnd, &_tHelp,_IDA_z, _IDA_zp, IDA_ONE_STEP);
    if(check_flag(&_idid, "IDA", 1))
    {
      _solverStatus = SOLVERERROR;
      break;
    }

		_accStps++;
		_locStps++;

		// A root is found
		if(_idid == 2)
		{
			_zeroFound = true;
			continous_system->setTime(_tHelp);
			continous_system->setVars(NV_DATA_S(_IDA_z));
			continous_system->update(IContinous::ALL);
			_updateCalls++;
		}

		// Falls über tEnd hinaus. Zustand bei tEnd holen
		if(_tHelp <= _tEnd)
		{
			_tCurrent = _tHelp;
			continous_system->giveVars(_z);
		}
		else
		{
			_idid = IDAGetDky(_idaMem, _tEnd, 0, _IDA_z);
			_idid = IDAGetDky(_idaMem, _tEnd, 1, _IDA_zp);
			_tCurrent = _tEnd;
			_zeroFound = false;
		}

		if(_zeroFound)
		{
			// Falls getEventOutput, den Zustand vor Eventbehandlung recorden
			if (_idasSettings->getDenseOutput() && abs(_tLastWrite - _tCurrent) > dynamic_cast<ISolverSettings*>(_idasSettings)->getZeroTimeTol())
			{
				if(_idasSettings->getEventOutput())
				{
					SolverDefaultImplementation::writeToFile(_locStps, _tCurrent, _h);
				}
			}else
			{
				SolverDefaultImplementation::writeToFile(_locStps, _tCurrent, _h);
			}

			_idid = IDAGetRootInfo(_idaMem, _zeroSign);
			for(int i=0;i<_dimZeroFunc;i++)
				_events[i] = bool(_zeroSign[i]);
			event_system->giveZeroFunc(_zeroVal);

      //Event Iteration starten
      //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
      event_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);
      //EVENT Iteration beendet
    }
    

    // Diagnostics
    _idid = IDAGetLastStep(_idaMem,&_h);
    //_idid = CVodeGetNumSteps(_cvodeMem,&_locStps);

		//_z = NV_DATA_S(_CV_y);

		// Zustand aus dem System holen
		continous_system->giveVars(_z);
		
		if(!_zeroFound)
		{
			writeIDAOutput(_tCurrent,_h,_locStps);
		}
		else
		{
			_idid = IDAReInit(_idaMem, _tCurrent, _IDA_z, _IDA_zp);
		}
		
		// Zähler für die Anzahl der ausgegebenen Schritte erhöhen
		++ _outStps;

   

    if  ( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_idasSettings)->getEndTimeTol())  
    {
      _solverStatus = DONE;
    }
	}
}

void Idas::writeIDAOutput(const double &time,const double &h,const int &stp)
{
	
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	if (stp > 0)
	{
		if (_idasSettings->getDenseOutput())
		{
			_bWritten = false;
			while (_tLastWrite + dynamic_cast<ISolverSettings*>(_idasSettings)->getGlobalSettings()->gethOutput()  <= time + dynamic_cast<ISolverSettings*>(_idasSettings)->getEndTimeTol())
			{
				_bWritten = true;
				_tLastWrite = _tLastWrite + dynamic_cast<ISolverSettings*>(_idasSettings)->getGlobalSettings()->gethOutput();
				_idid = IDAGetDky(_idaMem, _tLastWrite, 0, _IDA_zWrite);
				continous_system->setTime(_tLastWrite);
				continous_system->setVars(NV_DATA_S(_IDA_zWrite));
				continous_system->update(IContinous::ALL);
				_updateCalls++;
				SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);
			}//end if time -_tLastWritten
			if (_bWritten)
			{
				continous_system->setTime(time);
				continous_system->setVars(_z,IContinous::VAR_INDEX0);
				continous_system->update(IContinous::ALL);
				_updateCalls++;
			}
		}
		else
			SolverDefaultImplementation::writeToFile(stp, time, h);
	}
}

void Idas::calcFunction(const double& time, const double* y, double* f)
{
  
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  continous_system->setTime(time);
  continous_system->setVars(y,IContinous::ALL_STATES);
  continous_system->update(IContinous::CONTINOUS);
  continous_system->giveRHS(f,IContinous::ALL_STATES);
}

int Idas::IDA_fCallback(double t, N_Vector y, N_Vector ydot, N_Vector resval, void *user_data)
{
  	((Idas*) user_data)->calcFunction(t, NV_DATA_S(y), NV_DATA_S(resval));

	for(int i=0; i<((Idas*) user_data)->_dimDEq; ++i)
		NV_Ith_S(resval,i) = NV_Ith_S(resval,i) - NV_Ith_S(ydot,i);
	
	
	//double *y1 = NV_DATA_S(resval);
	
	return(0);
}

void Idas::giveZeroVal(const double &t,const double *y,double *zeroValue)
{
  
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  IEvent* event_system =  dynamic_cast<IEvent*>(_system);
  continous_system->setTime(t);
  continous_system->setVars(y);

  // System aktualisieren
  continous_system->update(IContinous::CONTINOUS);

  event_system->giveZeroFunc(zeroValue);

}

int Idas::IDA_ZerofCallback(double t, N_Vector y, N_Vector yp, double *zeroval, void *user_data)
{
  ((Idas*) user_data)->giveZeroVal(t, NV_DATA_S(y),zeroval);

  return(0);
}

const int Idas::reportErrorMessage(ostream& messageStream)
{
  if(_solverStatus == IDAESolver::SOLVERERROR)
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

  else if(_solverStatus == IDAESolver::USER_STOP)
  {
    messageStream << "Simulation terminated by user at t: " << _tCurrent << std::endl;
  }

  return _idid;
}


void Idas::writeSimulationInfo(ostream& outputStream)
{
  // Solver
  outputStream  << "\nSolver: IDas" 
    << "\nVerfahren: ";

  

  // System
  outputStream 
    << "Dimension  des Systems (ODE):             " << (int)_dimSys << "\n";

  
   outputStream  
      << "Zero function tolerance:      " << dynamic_cast<ISolverSettings*>(_idasSettings)->getZeroTol() << " \n"
      << "Zero t tolerance:          " << dynamic_cast<ISolverSettings*>(_idasSettings)->getZeroTimeTol() << " \n"
      << "Number of zero search steps:  " << _zeroStps << " \n"
      << "Number of zeros in interval:  " << _zeros << std::endl;
 


  // Schritteweite
  outputStream
  << "Total number of steps:        " << _totStps << "\n"
    << "Number of output steps:       " << _outStps << "\n"
    << "Status:                       " << _idid;

  
}


void Idas::saveInitState()
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  
  // Aktuellen Zeitpunkt als initialen Zeitpunkt (Anfangszeit des gesamten Integrationsintervalls) abspeichern
  _tInit= _tCurrent;

  // ZeroFunction-Vector abspeichern
  if (_zeroVal)
    memcpy(_zeroValInit,_zeroVal,_dimZeroFunc*sizeof(double));

  // Zustandsvektor abspeichern
  continous_system->giveVars(_zInit,IContinous::ALL_VARS);
}

void Idas::restoreInitState()
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  // Initialen Zeitpunkt wiederherstellen
  _tCurrent = _tInit;

  // Einträge im ZeroFunction-Vektor wiederherstellen
  if (_zeroVal)
    memcpy(_zeroVal,_zeroValInit,_dimZeroFunc*sizeof(double));

  // Initialen Zustandsvektor wiederherstellen
  continous_system->setVars(_zInit);
}

void Idas::saveLargeStepState()
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  // Aktuellen Zeitpunkt als "End-Zeitpunkt des großen Schrittes bei partitionierter Integration" abspeichern
  _tLargeStep = _tCurrent;

  // Zustandsvektor abspeichern
  continous_system->giveVars(_zLargeStep,IContinous::ALL_VARS);

  if (_zeroVal)
    memcpy(_zeroValLargeStep,_zeroVal,_dimZeroFunc*sizeof(double));
}

void Idas::saveLastSuccessfullState()
{
  // Aktuellen Zeitpunkt als "letzten erfolgreichen Zeitpunkt" abspeichern
  _tLastSuccess = _tCurrent;

  // ZeroFunction-Vector abspeichern
  if (_zeroVal)
    memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));

  // Zustandsvektor abspeichern
  memcpy(_zLastSucess,_z,_dimSys*sizeof(double));
}

void Idas::restoreLastSuccessfullState()
{
  // Letzten erfolgreichen Zeitpunkt wiederherstellen
  _tCurrent = _tLastSuccess;

  // Einträge im ZeroFunction-Vektor wiederherstellen
  if (_zeroVal)
    memcpy(_zeroVal,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));

  // Alten Zustandsvektor wiederherstellen
  memcpy(_z,_zLastSucess,_dimSys*sizeof(double));
}

void Idas::giveScaledError(const double& h, double& error)
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  continous_system->giveVars(_z,IContinous::ALL_VARS);

  // Berechnung der Skalierten Fehlernorm für ODE-Systeme
  double sc = 0.0;
  for(int i=0; i<_dimSys; ++i)
  {
    sc = 1e-4 + 1e-4 * max(abs(_zLargeStep[i]),abs(_zInit[i]));
    error += pow((_z[i] - _zLargeStep[i]),2) / sc;
  }
}

void Idas::refineCurrentState(const double& r)
{
  IContinous* continous_system = dynamic_cast<IContinous*>(_system);
  // Approximation höherer Ordnung
  for(int i=0; i<_dimSys; ++i)
    _z[i] += (_z[i] - _zLargeStep[i]) / ( pow(1.0/r,3.0) );

  continous_system->setVars(_z);
}

int Idas::check_flag(void *flagvalue, char *funcname, int opt)
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


using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  /*types.get<std::map<std::string, factory<SolverDefaultImplementation,IDAESystem*, ISolverSettings*> > >()
  ["DefaultsolverImpl"].set<SolverDefaultImplementation>();*/
  types.get<std::map<std::string, factory<IDAESolver,IDAESystem*, ISolverSettings*> > >()
    ["IdasSolver"].set<Idas>();
  types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["IdasSettings"].set<IdasSettings>();
}
