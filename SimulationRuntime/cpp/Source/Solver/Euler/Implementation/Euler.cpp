#include "stdafx.h"

#include "Euler.h"
#include "EulerSettings.h"
#include "../../Math/Implementation/Functions.h"
#include "../../../System/Interfaces/ISystemProperties.h"
Euler::Euler(IDAESystem* system, ISolverSettings* settings)
: SolverDefaultImplementation(system, settings)
, _eulerSettings		(dynamic_cast<IEulerSettings*>(_settings))
, _z					(NULL)
, _zLeftBoundary		(NULL)
, _zRightBoundary		(NULL)				
, _zLastSucess			(NULL)
, _dimSys				(0)			
, _idid					(0)
, _hOutput				(0.0)	
, _hUplim				(0.0)
, _hLowlim				(0.0)
, _tOutput				(0.0)	
{
}

Euler::~Euler()
{	
	if(_z)						
		delete [] _z;
	if(_zLastSucess)			
		delete [] _zLastSucess;
	if(_zLeftBoundary)						
		delete [] _zLeftBoundary;
	if(_zRightBoundary)						
		delete [] _zRightBoundary;
}


void Euler::init()
{
	ISystemProperties* properties = dynamic_cast<ISystemProperties*>(_system);
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	//(Re-) Initialization of solver -> call default implementation service
	SolverDefaultImplementation::init();

	// Dimension of the system (number of variables)
	_dimSys	= continous_system->getDimVars(IContinous::ALL_STATES);

	// Check system dimension
	if(_dimSys <= 0 || !(properties->isODE()) || (properties->isAlgebraic()) || !(properties->isExplicit()) )
	{
		_idid = -1; 
	}
	else
	{
		// Initialization of state vector
		if(_z)				delete [] _z;
		if(_zLastSucess)	delete [] _zLastSucess;

		_z				= new double[_dimSys];
		_zLastSucess	= new double[_dimSys];

		memset(_z,0,_dimSys*sizeof(double));
		memset(_zLastSucess,0,_dimSys*sizeof(double));

		if(_eulerSettings->getDenseOutput())
		{

			// Arrays für Zustandswerte an den Berechnungsintervallgrenzen
			if(_zLeftBoundary)		delete [] _zLeftBoundary;


			_zLeftBoundary = new double[_dimSys];


			memset(_zLeftBoundary,0,sizeof(double));


			// Initialize output step size
			_hOutput = dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

			// Statevectors at intervall borders (needed for interpolation in _denseOutput)

			if(_zRightBoundary)		delete [] _zRightBoundary;
			_zRightBoundary = new double[_dimSys];
			memset(_zRightBoundary,0,sizeof(double));

		}
	}

	// Reset counter
	_outputStps = 0;

	// Set step size limits
	_hUplim		=  dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
	_hLowlim	=  dynamic_cast<ISolverSettings*>(_eulerSettings)->getLowerLimit();
}

/// Set start time for numerical solution
void Euler::setStartTime(const double& t)
{
	SolverDefaultImplementation::setStartTime(t);
};

/// Set end time for numerical solution
void Euler::setEndTime(const double& t)
{
	SolverDefaultImplementation::setEndTime(t);
};

/// Set the initial step size (needed for reinitialization after external zero search)
void Euler::setInitStepSize(const double& h)	
{
	SolverDefaultImplementation::setInitStepSize(h);
};


/// Provides the status of the solver after returning
const IDAESolver::SOLVERSTATUS Euler::getSolverStatus()
{
	return (SolverDefaultImplementation::getSolverStatus());
};
void Euler::solve(const SOLVERCALL command)
{

	if (_eulerSettings && _system)
	{

		// Prepare solver and system for integration
		if (command & IDAESolver::FIRST_CALL)
		{
			init();
		}

		// Causes the solver to read the states from the system in the very first step 
		if (command & IDAESolver::RECALL)
			_firstStep = true;

		// Set command for calling writeToFile. Depends wheter solve is called during zero search or ordninary integration 
		if (command & IDAESolver::REPEATED_CALL)
			_outputCommand = IDAESystem::OVERWRITE;
		else if (command & IDAESolver::REGULAR_CALL)
			_outputCommand = IDAESystem::WRITE;
		else
			_outputCommand = IDAESystem::UNDEF_OUTPUT;

		// Reset status flag
		_solverStatus = IDAESolver::CONTINUE;

		while ( _solverStatus & IDAESolver::CONTINUE )
		{
			// Limit step size to borders (during zero search, step size may be changed)
			if(!_zeroSearchActive)
				_h = std::max(std::min(_h, dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit()), dynamic_cast<ISolverSettings*>(_eulerSettings)->getLowerLimit());

			if (_eulerSettings->getDenseOutput())
			{
				// During zero search the step size is decreased until zero is found 
				if(_zeroSearchActive == true)
					_hOutput = std::min(_h,  dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput() );

				// without zero search
				else
					_hOutput = dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

				// Set time for output
				_tOutput = _tCurrent + _hOutput;
			}




			// Call solver
			//-------------
			if(_idid == 0)
			{
				// Reset counter 
				_accStps = 0;

				// Get initial values from system, write out initial state vector
				solverOutput(_accStps,_tCurrent,_z,_h);

				// Choose integration method
				if (_eulerSettings->getEulerMethod() == IEulerSettings::EULERFORWARD)
				{

					doEulerForward();
				}
				else if (_eulerSettings->getEulerMethod() == IEulerSettings::LINEAREULER)
					doLinearEuler();
				else 
				{
					// Method currently not implemented
					_idid = -2;
				}
			}


			// Zero search
			if (_zeroVal)
				doZeroSearch();



			// Integration was not sucessfull (=0) or was terminated by the user (=1) 
			if(_idid != 0 && _idid !=1)
			{
				_solverStatus = IDAESolver::SOLVERERROR;
			}

			// Stopping criterion (end time reached)
			else if	( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol())	
				_solverStatus = IDAESolver::DONE;
		}

		_firstCall = false; 

		// Termination after last call only (optional)
		if ( (command & IDAESolver::LAST_CALL) || (_solverStatus & IDAESolver::USER_STOP))
		{
		}
	}
	else
	{
		// Invalid system
		_idid = -3;
	}
}




void Euler::doEulerForward()
{
	double *f	= new double[_dimSys];

	//Check for time events at beginning
	doTimeEvents();
	while( (_tEnd - _tCurrent) > dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() && _idid == 0 && _solverStatus != IDAESolver::USER_STOP)
	{
		// Adapt step size for last step
		if((_tCurrent + _h) > _tEnd)
			_h = (_tEnd - _tCurrent); 

		// Determination of right hand side
		calcFunction(_tCurrent, _z, f);

		// save old state vector for dense output (=left boundary of intervall)
		if (_eulerSettings->getDenseOutput())
			memcpy(_zLeftBoundary,_z,(int)_dimSys*sizeof(double));


		// Euler step (determination of new state)
		for(int i = 0; i < _dimSys; ++i) 
			_z[i] += _h * f[i];

		// Increase counter
		++ _totStps;
		++ _accStps;


		if (!_eulerSettings->getDenseOutput())
		{
			// Increase time
			_tCurrent += _h;

			// Write out current state vector
			solverOutput(_accStps,_tCurrent,_z,_h);
		}
		else
		{
			// Increase time -> see denseOut()

			// save new state for _denseOutput (=right boundary of intervall)
			memcpy(_zRightBoundary,_z,(int)_dimSys*sizeof(double));

			// write out state in equidistant time steps
			denseOutput(f);
		}

		doTimeEvents();

		// Zero crossing occured
		if(_zeroVal && _zeroStatus != IDAESolver::UNCHANGED_SIGN)
		{
			break;
		}
	}

	delete [] f;
}


void Euler::doLinearEuler()
{
	int			numberOfIterations; 
	double		tHelp;
	long int	dimRHS = 1;							// Dimension der rechten Seite zur Lösung LGS

	double 	
		*k1		= new double[_dimSys],				// Steigung (1. Stufe)
		*k1Help	= new double[_dimSys],				// Hilfsvariable
		*yHelp	= new double[_dimSys];				// Hilfsvariale y-Wert


	while( (_tEnd - _tCurrent) > dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() && _idid == 0)
	{
		// Letzten Schritt ggf. anpassen
		if((_tCurrent + _h) > _tEnd)
			_h = (_tEnd - _tCurrent); 

		// neue Stelle
		tHelp = _tCurrent + _h;



		// Startwerte setzten
		calcFunction(_tCurrent,_z,k1);
		memcpy(k1Help,k1,_dimSys*sizeof(double));

		// alten Zustandsvektor zwischenspeichren
		if (_eulerSettings->getDenseOutput())
			memcpy(_zLeftBoundary,_z,(int)_dimSys*sizeof(double));

		numberOfIterations = 0;



		double 	
			*jac	= new double[_dimSys*_dimSys],		// Jacobimatrix
			*fHelp	= new double[_dimSys],				// Hilfsvariale rechte Seite
			*jacHelp	= new double[_dimSys*_dimSys];		// Jacobimatrix
		// Jacobimatrix aufstellen
		calcJac(yHelp,fHelp,k1,jac,false);



		for(int j=0; j<_dimSys; ++j)
		{
			for(int i=0; i<_dimSys; ++i)
			{
				if(i==j )
					jacHelp[i+j*_dimSys] = 1.0 - _h*jac[i+j*_dimSys];
				else
					jacHelp[i+j*_dimSys] = - _h*jac[i+j*_dimSys];						

			}
		}


		DGESV(&_dimSys,&dimRHS,jacHelp,&_dimSys,fHelp,k1,&_dimSys,&_idid);

		// Berechnung des neuen y
		for(int i = 0; i < _dimSys; ++i) 
			_z[i] += _h * k1[i];

		if (jac)
			delete [] jac;
		if (fHelp) 
			delete [] fHelp;



		if (_idid != 0)
			throw std::invalid_argument("Euler::dolinearEuler");


		++_totStps;
		++_accStps;


		// Normale oder dichte Ausgabe
		if (!_eulerSettings->getDenseOutput())
		{
			// Erhoehung des Zeitschrittes
			_tCurrent += _h;

			solverOutput(_accStps,_tCurrent,_z,_h);
		}
		else
		{
			// Erhoehung des Zeitschrittes erfolgt in denseOut()

			// speichern des neuen Zustandsvektors
			memcpy(_zRightBoundary,_z,(int)_dimSys*sizeof(double));// alter Wert der Nst.fkt.

			denseOutput(k1);
		}

		if(_zeroVal && _zeroStatus != UNCHANGED_SIGN)
		{
			break;
		}
	}

	delete [] k1;
	delete [] k1Help;
	delete [] yHelp;
}


/**
Check for time events
*/
void Euler::doTimeEvents()
{

	IEvent* event_system =  dynamic_cast<IEvent*>(_system);

	if(_time_events.size()>0)
	{
		event_times_type::iterator iter;

		iter = find_if( _time_events.begin(), _time_events.end(), floatCompare<double>(_tCurrent,dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol()) );

		//Time event is reached
		if(iter!=_time_events.end())
		{
			//Handle time event
			event_system->handleEvent(iter->second);
			//Handle all events that occured at this time
			update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
			event_system->handleSystemEvents(_events,boost::ref(update_event));

			//Check if old time events were overrned because step size is not adequate 
			if(distance(_time_events.begin(),iter)>0)
				throw std::runtime_error("Time event was not reached, please check solver step size");
			//Erase old time entries
			_time_events.erase(iter);
		}

	}

}

void Euler::doZeroSearch()
{

	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	if (_zeroStatus == IDAESolver::ZERO_CROSSING && _idid == 0)
	{
		// Bisection
		if (_eulerSettings->getZeroSearchMethod() == IEulerSettings::BISECTION)
			_hUplim = (_tCurrent - _tLastSuccess) * 0.5;

		// Linear interpolation
		else
		{
			_hUplim = _tCurrent - _tLastSuccess;

			// Determination of zero crossing time, dt_new = [0.1 ... 0.9] * dt_old, => between 10% and 90%
			for (int i=0; i<_dimZeroFunc; ++i)
				if (_zeroValLastSuccess[i] * _zeroVal[i] < 0.0 || (_tLastSuccess - 1e-8) < 0.0 )
					_hUplim = std::min( _hUplim , ((_tCurrent - _tLastSuccess) * std::max(0.1, std::min(0.9, _zeroValLastSuccess[i] / (_zeroValLastSuccess[i]-_zeroVal[i]) ))) );
		}

		// Step size too small
		if(_h < UROUND)
		{
			_solverStatus = IDAESolver::SOLVERERROR;
			_idid = -11;
		}

		// Set step size for next step
		_h = _hUplim;

		// Reset state vector to last sucessfull time (before zero crossing)
		restoreLastSuccessfullState();
	}


	else if (_zeroStatus == IDAESolver::NO_ZERO)
	{
		// Reset zero flag
		_zeroSearchActive = false;

		// Reset step size
		_hUplim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
		_h = dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit(); 

		// Reset flag
		_idid = 0;
	}


	else if (_zeroStatus == IDAESolver::EQUAL_ZERO)
	{
		// Restart of integration => Denote by flag
		_firstStep = true;

		// Reset zero flag
		_zeroSearchActive = false;

		// Reset step size
		_hUplim = dynamic_cast<ISolverSettings*>(_eulerSettings)->getUpperLimit();
		_h		= dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit();

		// Reset flag
		_idid = 0;

		//handle all events that occured at this time
		update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
		event_system->handleSystemEvents(_events,boost::ref(update_event));


	}
}

void Euler::calcFunction(const double& t, const double* z, double* f)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	continous_system->setTime(t);
	continous_system->setVars(z,IContinous::ALL_STATES);
	continous_system->update(IContinous::CONTINOUS);
	continous_system->giveRHS(f,IContinous::ALL_STATES);
}

void Euler::solverOutput(const int& stp, const double& t, double* z, const double& h)
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	continous_system->setTime(t);

	// (Re-)start of integration => First step: read state vector from the system
	if (_firstStep)	
	{
		_firstStep	= false;

		// Update the system
		continous_system->update(IContinous::CONTINOUS);

		// read variables from the system
		continous_system->giveVars(z);



		if (_zeroVal)
		{
			// read values of zero functions
			event_system->giveZeroFunc(_zeroVal,dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTol());

			// Determine the sign and hence the status of zero crossings
			SolverDefaultImplementation::setZeroState();
		}

		// Ensures that solver is started with right sign of zero function
		_zeroStatus = UNCHANGED_SIGN;

	}


	// During integration: write state vector to the system
	else
	{
		// set variables to the system
		continous_system->setVars(z);

		// Update the system
		continous_system->update(IContinous::CONTINOUS);


		if(_zeroVal && (stp > 0))
		{
			// read values of zero functions
			event_system->giveZeroFunc(_zeroVal,dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTol());

			// Determine the sign and hence the status of zero crossings
			SolverDefaultImplementation::setZeroState();
		}
	}


	// Actions according to current status of zero crossing
	//-------------------------------------------------------
	if (_zeroStatus == IDAESolver::UNCHANGED_SIGN)
	{
		// Prompts the system to write out its results
		SolverDefaultImplementation::writeToFile(stp,t,h);

		// Increase counter
		++ _outputStps;

		// Save state as last sucessfull one
		saveLastSuccessfullState();
	}

	else if ((_zeroStatus == IDAESolver::EQUAL_ZERO) && (stp > 0))
	{
		// Prompts the system to write out its results
		SolverDefaultImplementation::writeToFile(stp, t, h);

		// Increase counter
		++_zeros;
	}

	else if (_zeroStatus == IDAESolver::ZERO_CROSSING && _idid==0)
	{
		// Zero crossing occured -> Set flag
		_zeroSearchActive = true;

		// Increase number of zero search steps
		++_zeroStps;
	}

	// Ensures that no user stop occurs in the very first step, when the solver has not done at least one step
	if (stp == 0)
		_zeroStatus = IDAESolver::UNCHANGED_SIGN;
}


void Euler::denseOutput(double* rhs)
{	
	double 
		tLeftBoundary	= _tCurrent,
		tRightBoundary	= _tCurrent + _h;


	// local auxillary flags
	bool 
		lastStep = false, 
		timeDone = false;


	while ((_tOutput - dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() < tRightBoundary) && timeDone == false && _idid==0)	//solange bis _tOutput in neuem Zeitintervall
	{
		// Linear interpolation 
		//for(int i = 0; i < _dimSys; ++i)
		//	_z[i] = _zLeftBoundary[i] + ( (_zRightBoundary[i]-_zLeftBoundary[i])/(tRightBoundary-tLeftBoundary) )*(_tOutput-tLeftBoundary);

		// Euler-Step (rhs = Gradiant between left and right boundary of intervall)
		for(int i = 0; i < _dimSys; ++i)
			_z[i] = _zLeftBoundary[i] + (_tOutput - tLeftBoundary) * rhs[i];


		// Stopping criterion
		if (lastStep == true)
			timeDone = true;

		// wird mit _z wegen saveLastSuccessfullState() benötigt (!)
		_tCurrent = _tOutput;

		// Write out current state vector
		solverOutput(_accStps,_tCurrent,_z,_h);

		// Increase time step
		_tOutput += _hOutput;

		if (lastStep == false && (_tEnd - dynamic_cast<ISolverSettings*>(_eulerSettings)->getEndTimeTol() < _tOutput))
		{
			// Set tOutput to tEnd
			_tOutput = _tEnd;

			lastStep = true;
		}
	}


	// Reset _tCurrent to right boundary of intervall to continuoue integration
	// only when zero search is not active, since then reset to _tLastSuccess
	if(_zeroSearchActive==false)
	{
		_tCurrent = tRightBoundary;

		// Reset state vector to continoue integration
		memcpy(_z,_zRightBoundary,(int)_dimSys*sizeof(double));
	}
}

void Euler::writeSimulationInfo(ostream& outputStream)
{
	// Solver
	outputStream	
		<< "Solver:                       Euler\n"
		<< "Method:                       ";

	if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERFORWARD)
		outputStream << "Explicit Euler";
	else if(_eulerSettings->getEulerMethod() ==IEulerSettings::HEUN)
		outputStream << "Heun";
	else if(_eulerSettings->getEulerMethod() == IEulerSettings::MODIFIEDEULER)
		outputStream << "Euler-Cauchy";
	else if(_eulerSettings->getEulerMethod() == IEulerSettings::MODIFIEDHEUN)
		outputStream << "Heun 3rd order";
	else if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERBACKWARD)
		outputStream << "Implicite Euler";
	else if(_eulerSettings->getEulerMethod() ==IEulerSettings::MIDPOINT)
		outputStream << "Mitpoint rule";
	else if(_eulerSettings->getEulerMethod() ==IEulerSettings::LINEAREULER)
		outputStream << "Linear Euler rule";

	outputStream << std::endl;

	// Time
	outputStream	
		<< "Simulation end time:          " << _tCurrent << " \n"
		<< "Step size:                    " << dynamic_cast<ISolverSettings*>(_eulerSettings)->gethInit() << " \n"
		<< "Output step size:             " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getGlobalSettings()->gethOutput();

	outputStream << std::endl;

	// System
	outputStream	
		<< "Number of equations (ODE):    " << (int)_dimSys << " \n"
		<< "Number of zero functions:     " << _dimZeroFunc;

	outputStream << std::endl;

	// Root finding
	if (!(_zeroVal) && _eulerSettings->getZeroSearchMethod() == IEulerSettings::NO_ZERO_SEARCH)
	{
		outputStream << "\nZero search method:           No zero search\n" << std::endl;
	}
	else
	{
		if (_eulerSettings->getZeroSearchMethod() == IEulerSettings::BISECTION)
		{
			outputStream << "Zero search method:           Bisection" << std::endl;
		}
		else 
		{
			outputStream << "Zero search method:           Linear Interpolation" << std::endl;
		}

		outputStream	
			<< "Zero function tolerance:      " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTol() << " \n"
			<< "Zero time tolerance:          " << dynamic_cast<ISolverSettings*>(_eulerSettings)->getZeroTimeTol() << " \n"
			<< "Number of zero search steps:  " << _zeroStps << " \n"
			<< "Number of zeros in interval:  " << _zeros << std::endl;
	}

	if(_eulerSettings->getEulerMethod() == IEulerSettings::EULERBACKWARD || _eulerSettings->getEulerMethod() == IEulerSettings::MIDPOINT && _eulerSettings->getUseNewtonIteration() == true)
		outputStream	<< "Iteration tolerance:          " << _eulerSettings->getIterTol() << std::endl;

	// Steps
	outputStream	
		<< "Total number of steps:        " << _totStps << "\n"
		<< "Number of output steps:       " << _outputStps << "\n"
		<< "Status:                       " << _idid;

	outputStream << std::endl;
}

const int Euler::reportErrorMessage(ostream& messageStream)
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
		messageStream << "Simulation terminated by user at time: " << _tCurrent << std::endl;
	}

	return _idid;
}


void Euler::saveLastSuccessfullState()
{
	// Save current time step as "last sucessfull"
	_tLastSuccess = _tCurrent;

	// Save current zero function values
	if (_zeroVal)
		memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));

	// Save current state as "last sucessfull" one
	memcpy(_zLastSucess,_z,_dimSys*sizeof(double));
}

void Euler::restoreLastSuccessfullState()
{
	// Restore last sucessfull time step
	_tCurrent = _tLastSuccess;

	// Restore zero values of last successfull time step
	if (_zeroVal)
		memcpy(_zeroVal,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));

	// Restore state vector of last sucessfull time step
	memcpy(_z,_zLastSucess,_dimSys*sizeof(double));
}
void Euler::calcJac(double* yHelp, double* _fHelp, const double* _f, double* jac, const bool& flag)
{
	for(int j=0; j<_dimSys; ++j)
	{
		// reset m_pYhelp for every colum
		memcpy(yHelp,_z,_dimSys*sizeof(double));

		yHelp[j] += 1e-8;

		// delta_f berechnen
		calcFunction(_tCurrent, yHelp, _fHelp);

		// Jacobimatrix aufbauen
		for(int i=0; i<_dimSys; ++i)
		{
			if(i==j && !flag )
				jac[i+j*_dimSys] = 1.0 - (_h * (_fHelp[i] - _f[i]) / 1e-8);
			else
				jac[i+j*_dimSys] = _h * (_fHelp[i] - _f[i]) / 1e-8;
		}
	}
}
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
	/*types.get<std::map<std::string, factory<SolverDefaultImplementation,IDAESystem*, ISolverSettings*> > >()
		["DefaultsolverImpl"].set<SolverDefaultImplementation>();*/
	types.get<std::map<std::string, factory<IDAESolver,IDAESystem*, ISolverSettings*> > >()
		["EulerSolver"].set<Euler>();
	types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
		["EulerSettings"].set<EulerSettings>();
}
