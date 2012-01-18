#include "stdafx.h"
#include "Cvode.h"
#include "CVodeSettings.h"
#include "Math/Implementation/Functions.h"
#include "System/Interfaces/ISystemProperties.h"	



Cvode::Cvode(IDAESystem* system, ISolverSettings* settings)
	: SolverDefaultImplementation( system, settings)
	, _cvodesettings		(dynamic_cast<ICVodeSettings*>(_settings))
	, _z					(NULL)
	, _z0					(NULL)
	, _z1					(NULL)				
	, _zInit				(NULL)
	, _zLastSucess			(NULL)
	, _zLargeStep			(NULL)
	, _zWrite				(NULL)
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
	, _doubleZero			(false)
	, _f0					(NULL)
	, _f1					(NULL)
{
	_data = ((void*)this);
}

Cvode::~Cvode()
{	
	if(_z)						
		delete [] _z;
	if(_z0)						
		delete [] _z0;
	if(_z1)						
		delete [] _z1;
	if(_zInit)					
		delete [] _zInit;
	if(_zLastSucess)			
		delete [] _zLastSucess;
	if(_zLargeStep)				
		delete [] _zLargeStep;
	if(_f0)
		delete [] _f0;
	if(_f1)
		delete [] _f1;

}


void Cvode::init()
{
	ISystemProperties* properties = dynamic_cast<ISystemProperties*>(_system);
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	// Kennzeichnung, dass init()() (vor der Integration) aufgerufen wurde
	_idid = 5000;

	// System im Solver assemblen, da folgende Reihenfolge einzuhalten ist: 
	// 1) System assemblen und updaten, alles für Nullstellsuche anlegen
	// 2) Spezielle Dimensionen bestimmen (muss wg. ODE/DAE im Solver stattfinden) 
	// 3) Zustandsvektor anlegen
	SolverDefaultImplementation::init();

	_dimSys		= continous_system->getDimVars(IContinous::ALL_STATES);
	int dimAEq	= continous_system->getDimVars(IContinous::DIFF_INDEX3);

	if(_dimSys <= 0 || dimAEq > 0)
	{
		_idid = -1; 
		throw std::invalid_argument("Cvode::init()()");
	}
	else
	{
		// Allocate state vectors, stages and temporary arrays
		if(_z)				delete [] _z;
		if(_zInit)			delete [] _zInit;
		if(_zLastSucess)	delete [] _zLastSucess;
		if(_zLargeStep)		delete [] _zLargeStep;
		if(_zWrite)			delete [] _zWrite;

		_z				= new double[_dimSys];
		_zInit			= new double[_dimSys];
		_zLastSucess	= new double[_dimSys];
		_zLargeStep		= new double[_dimSys];
		_zWrite		    = new double[_dimSys];
		_f0				= new double[_dimSys];
		_f1				= new double[_dimSys];

		memset(_z,0,_dimSys*sizeof(double));
		memset(_zInit,0,_dimSys*sizeof(double));
		memset(_zLastSucess,0,_dimSys*sizeof(double));
		memset(_zLargeStep,0,_dimSys*sizeof(double));
		// Arrays für Zustandswerte an den Berechnungsintervallgrenzen

		if(_z0)		delete [] _z0;
		if(_z1)		delete [] _z1;

		_z0 = new double[_dimSys];
		_z1 = new double[_dimSys];

		memset(_z0,0,sizeof(double));
		memset(_z1,0,sizeof(double));

		// Counter initialisieren
		_outStps	= 0;

		if(_cvodesettings->getDenseOutput())
		{
			// Ausgabeschrittweite
			_hOut		= dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput();

		}

		// Allocate memory for the solver
		_cvodeMem = CVodeCreate(CV_BDF, CV_NEWTON);
		if(check_flag((void*)_cvodeMem, "CVodeCreate", 0))
		{
			_idid = -5; 
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");
		}

		//
		// Make Cvode ready for integration
		//

		// Set initial values for CVODE

		// System und Events aktualisieren
		continous_system->update(IContinous::CONTINOUS);
		// giveVars (Zustand holen)
		continous_system->giveVars(_zInit);
		memcpy(_z,_zInit,_dimSys*sizeof(double));

		_CV_y0 = N_VMake_Serial(_dimSys, _zInit);
		_CV_y = N_VMake_Serial(_dimSys, _z);
		if(check_flag((void*)_CV_y0, "N_VMake_Serial", 0))
		{
			_idid = -5; 
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");
		}

		// Initialize Cvode (Initial values are required)
		_idid = CVodeInit(_cvodeMem, CV_fCallback, _tCurrent, _CV_y0);
		if(_idid < 0)
		{
			_idid = -5; 
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");
		}

		// Set Tolerances
		_idid = CVodeSStolerances(_cvodeMem, 1e-6, 1e-6);					// RTOL and ATOL
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		// Set the pointer to user-defined data
		_idid = CVodeSetUserData(_cvodeMem, _data);
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeSetInitStep(_cvodeMem, 0.001);							// INITIAL STEPSIZE
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeSetMinStep(_cvodeMem, 1e-14);							// MINIMUM STEPSIZE
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeSetMaxStep(_cvodeMem, 0.1);							// MAXIMUM STEPSIZE
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeSetMaxNonlinIters(_cvodeMem, 3);						// Max number of iterations
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVDense(_cvodeMem, _dimSys);
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeSetMaxNumSteps(_cvodeMem,1e10);						// Max Number of steps
		if(_idid < 0)
			throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::init()");

		_idid = CVodeRootInit(_cvodeMem,_dimZeroFunc, CV_ZerofCallback);

		//
		// CVODE is ready for integration
		//

	}
}


void Cvode::solve(const SOLVERCALL action)
{
	//_cvodesettings->bEventOutput = true;

	if (_cvodesettings && _system)
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
			if (_cvodesettings->getEventOutput())
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
				_h = max(min(_h,dynamic_cast<ISolverSettings*>(_cvodesettings)->getUpperLimit()),dynamic_cast<ISolverSettings*>(_cvodesettings)->getLowerLimit());


			// Zuvor gab es einen Userstop => Reset IDID
			//if(_idid == 1)
			//	_idid = 0;

			// Zuvor wurde init() aufgerufen und hat funktioniert => RESET IDID
			if(_idid == 5000)
				_idid = 0;

			// Solveraufruf
			if(_idid == 0)
			{
				// Zähler zurücksetzen
				_accStps = 0;
				_locStps = 0;

				// Solverstart
				callCVode();

			}

			// Integration war nicht erfolgreich und wurde auch nicht vom User unterbrochen
			if(_idid != 0 && _idid !=1)
			{
				_solverStatus = SOLVERERROR;
				throw std::invalid_argument(/*_idid,_tCurrent,*/"Cvode::solve()");
			}


			// Abbruchkriterium (erreichen der Endzeit)
			else if	( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_cvodesettings)->getEndTimeTol())	
				_solverStatus = DONE;
		}

		_firstCall = false; 

	}
	else
	{

		throw std::invalid_argument(/*-1,_tCurrent,*/"Cvode::solve()");
	}
}

void Cvode::callCVode()
{
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);

	while(_solverStatus & IDAESolver::CONTINUE)
	{
		_idid = CVode(_cvodeMem, _tEnd, _CV_y, &_tHelp, CV_ONE_STEP);
		if(check_flag(&_idid, "Cvode", 1))
		{
			_solverStatus = SOLVERERROR;
			break;
		}

		// A root is found
		if(_idid == 2)
		{
			//_idid = CVodeGetRootInfo(_cvodeMem, _zeroSign);
			event_system->giveZeroFunc(_zeroVal,dynamic_cast<ISolverSettings*>(_cvodesettings)->getZeroTol());

			//Event Iteration starten
			update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
			event_system->handleSystemEvents(_events,boost::ref(update_event));
			//EVENT Iteration beendet
		}
		// Diagnostics
		_idid = CVodeGetLastStep(_cvodeMem,&_h);
		//_idid = CVodeGetNumSteps(_cvodeMem,&_locStps);

		_tCurrent = _tHelp;
		//_z = NV_DATA_S(_CV_y);

		_accStps++;

		//if (_zeroState == UNCHANGED_SIGN)
		//{
		SolverDefaultImplementation::writeToFile(_accStps, _tCurrent, _h);

		continous_system->giveVars(_z);
		_idid = CVodeReInit(_cvodeMem, _tCurrent, _CV_y);

		// Zähler für die Anzahl der ausgegebenen Schritte erhöhen
		++ _outStps;

		//saveLastSuccessfullState();
		//}

		if	( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_cvodesettings)->getEndTimeTol())	
		{
			_solverStatus = DONE;
		}

	}
}

void Cvode::calcFunction(const double& time, const double* y, double* f)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	continous_system->setTime(time);
	continous_system->setVars(y,IContinous::ALL_STATES);
	continous_system->update(IContinous::CONTINOUS);
	continous_system->giveRHS(f,IContinous::ALL_STATES);
}

int Cvode::CV_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data)
{
	((Cvode*) user_data)->calcFunction(t, NV_DATA_S(y),NV_DATA_S(ydot));

	return(0);
}

void Cvode::giveZeroVal(const double &t,const double *y,double *zeroValue)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	continous_system->setTime(t);
	continous_system->setVars(y);

	// System aktualisieren
	continous_system->update(IContinous::CONTINOUS);

	event_system->giveZeroFunc(zeroValue,dynamic_cast<ISolverSettings*>(_cvodesettings)->getZeroTol());

}

int Cvode::CV_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data)
{
	((Cvode*) user_data)->giveZeroVal(t, NV_DATA_S(y),zeroval);

	return(0);
}

const int Cvode::reportErrorMessage(ostream& messageStream)
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

void Cvode::writeSimulationInfo(ostream& outputStream)
{
	//// Solver
	//outputStream	<< "\nSolver: " << getName()
	//	<< "\nVerfahren: ";

	//if(_cvodesettings->iMethod == EulerSettings::EULERFORWARD)
	//	outputStream << " Expliziter Cvode\n\n";
	//else if(_cvodesettings->iMethod == EulerSettings::EULERBACKWARD)
	//	outputStream << " Impliziter Cvode\n\n";


	//// System
	//outputStream 
	//	<< "Dimension  des Systems (ODE):             " << (int)_dimSys << "\n";

	//// Status, Anzahl Schritte, Nullstellenzeugs
	//SolverDefaultImplementation::writeSimulationInfo(outputStream);


	//// Nullstellensuche
	//if (_cvodesettings->iZeroSearchMethod == SolverSettings::NO_ZERO_SEARCH)
	//{
	//	outputStream << "Nullstellensuche:                         Keine\n\n" << endl;
	//}
	//else
	//{
	//	/*if (_cvodesettings->iZeroSearchMethod == SolverSettings::BISECTION)
	//	{
	//	outputStream << "Nullstellensuche:                         Bisektion\n" << endl;
	//	}
	//	else 
	//	{*/
	//	outputStream << "Nullstellensuche:                         Lineare Interpolation\n" << endl;
	//	/*}*/


	//}


	//// Schritteweite
	//outputStream
	//	<< "ausgegebene Schritte:                     " << _outStps << "\n"
	//	<< "Anfangsschrittweite:                      " << _cvodesettings->dH_init << "\n"
	//	<< "Ausgabeschrittweite:                      " << dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput() << "\n"
	//	<< "Obere Grenze für Schrittweite:            " << _hUpLim << "\n\n";

	//// Status
	//outputStream 
	//	<< "Solver-Status:                            " << _idid << "\n\n";
}


void Cvode::saveInitState()
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

void Cvode::restoreInitState()
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

void Cvode::saveLargeStepState()
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	// Aktuellen Zeitpunkt als "End-Zeitpunkt des großen Schrittes bei partitionierter Integration" abspeichern
	_tLargeStep = _tCurrent;

	// Zustandsvektor abspeichern
	continous_system->giveVars(_zLargeStep,IContinous::ALL_VARS);

	if (_zeroVal)
		memcpy(_zeroValLargeStep,_zeroVal,_dimZeroFunc*sizeof(double));
}

void Cvode::saveLastSuccessfullState()
{
	// Aktuellen Zeitpunkt als "letzten erfolgreichen Zeitpunkt" abspeichern
	_tLastSuccess = _tCurrent;

	// ZeroFunction-Vector abspeichern
	if (_zeroVal)
		memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));

	// Zustandsvektor abspeichern
	memcpy(_zLastSucess,_z,_dimSys*sizeof(double));
}

void Cvode::restoreLastSuccessfullState()
{
	// Letzten erfolgreichen Zeitpunkt wiederherstellen
	_tCurrent = _tLastSuccess;

	// Einträge im ZeroFunction-Vektor wiederherstellen
	if (_zeroVal)
		memcpy(_zeroVal,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));

	// Alten Zustandsvektor wiederherstellen
	memcpy(_z,_zLastSucess,_dimSys*sizeof(double));
}

void Cvode::giveScaledError(const double& h, double& error)
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

void Cvode::refineCurrentState(const double& r)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	// Approximation höherer Ordnung
	for(int i=0; i<_dimSys; ++i)
		_z[i] += (_z[i] - _zLargeStep[i]) / ( pow(1.0/r,3.0) );

	continous_system->setVars(_z);
}

int Cvode::check_flag(void *flagvalue, char *funcname, int opt)
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
		["CVodeSolver"].set<Cvode>();
	types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
		["CVodeSettings"].set<CVodeSettings>();
}