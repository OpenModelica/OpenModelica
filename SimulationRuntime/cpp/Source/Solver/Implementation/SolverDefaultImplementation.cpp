#include "stdafx.h"
#define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL

#include "SolverDefaultImplementation.h"
#include "SolverSettings.h"
#include "../../Settingsfactory/Interfaces/IGlobalSettings.h"


SolverDefaultImplementation::SolverDefaultImplementation(IDAESystem* system, ISolverSettings* settings)
: _system				(system)
, _settings				((ISolverSettings*)settings)


, _tCurrent				(0.0)
, _tEnd					(0.0)
, _tLastSuccess			(0.0)
, _tLastUnsucess		(0.0)

, _h					(0.0)

, _firstCall			(true)
, _firstStep			(true)

, _totStps				(0)
, _accStps				(0)
, _rejStps				(0)
, _zeroStps				(0)
, _zeros				(0)

, _zeroStatus			(IDAESolver::UNCHANGED_SIGN)

, _dimZeroFunc			(0)
, _zeroVal				(NULL)
, _zeroValLastSuccess	(NULL)
, _events				(NULL)
, _zeroSearchActive		(false)

, _outputCommand		(IDAESystem::WRITE)

{
}
SolverDefaultImplementation::~SolverDefaultImplementation()
{
	if(_zeroVal)
		delete [] _zeroVal;
	if(_zeroValLastSuccess)
		delete [] _zeroValLastSuccess;
	if(_events)
		delete [] _events;
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

	

	const IDAESolver::SOLVERSTATUS SolverDefaultImplementation::getSolverStatus()
	{
		return _solverStatus;
	};
void SolverDefaultImplementation::init()
{
	IContinous* continous_system = dynamic_cast<IContinous*>(_system);
	IEvent* event_system =  dynamic_cast<IEvent*>(_system);
	// Set current start time to the system
	continous_system->setTime(_tCurrent);

	// Assemble the system 
	continous_system->init(_settings->getGlobalSettings()->getStartTime(),_settings->getGlobalSettings()->getEndTime());
	

	//// Write out head line
	//if (_outputStream)
	//{
	//	// Write head line (step time step size) into output stream
	//	*_outputStream << "step\t time\t h";
	//	
	//	// Prompt system to write out its results
	//	_system->writeOutput(IDAESystem::HEAD_LINE);

	//	// Write a line break into output stream		
	//	*_outputStream << std::endl;
	//}
   _system->writeOutput(IDAESystem::HEAD_LINE);

	// Allocate array with values of zero functions
	if (_dimZeroFunc != event_system->getDimZeroFunc())
	{
		// Number (dimension) of zero functions
		_dimZeroFunc = event_system->getDimZeroFunc();

		if(_zeroVal)
			delete [] _zeroVal;
		if(_zeroValLastSuccess)
			delete [] _zeroValLastSuccess;
		if(_events)
			delete [] _events;

		_zeroVal			= new double[_dimZeroFunc];
		_zeroValLastSuccess	= new double[_dimZeroFunc];
		_events				= new bool[_dimZeroFunc];

		event_system->giveZeroFunc(_zeroVal,_settings->getZeroTol());
		memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));
		memset(_events,false,_dimZeroFunc*sizeof(bool));
	}
     _time_events = event_system->getTimeEvents();
	 // Set flags
	_firstCall			= true; 
	_firstStep			= true;
	_zeroSearchActive	= false;

	// Reset counter 
	_totStps 	= 0;
	_accStps 	= 0;
	_rejStps	= 0;
	_zeroStps	= 0;
	_zeros		= 0;

	// Set initial step size
	//_h = _settings->_globalSettings->_hOutput;	
}
void SolverDefaultImplementation::updateEventState()
{
	dynamic_cast<IEvent*>(_system)->giveZeroFunc(_zeroVal,_settings->getZeroTol());
	setZeroState();
	if (_zeroStatus == IDAESolver::ZERO_CROSSING)	 // An event triggered an other event
	{
		_tLastSuccess = _tCurrent;		 // Concurrently occured events are in the time tollerance
		setZeroState();				     // Upate status of events vector
	}
}

void SolverDefaultImplementation::setZeroState()
{
	// Reset Zero-State
	_zeroStatus = IDAESolver::UNCHANGED_SIGN;


	
	// For all zero functions...
	for (int i=0; i<_dimZeroFunc; ++i)
	{
		// Check for change in sign in each zero function
		if (_zeroVal[i] * _zeroValLastSuccess[i] <= 0.0 && fabs(_zeroVal[i]-_zeroValLastSuccess[i]) > UROUND)
		{
			// EQUAL_ZERO
			//-----------
			// Check whether value zero function is smaller than tolerance OR step size is smaller than time-tolerance
			if ( (fabs(_zeroVal[i])) < _settings->getZeroTol() || (_tCurrent != 0 && (_tCurrent-_tLastSuccess) < _settings->getZeroTimeTol()) ) 
			{
				_zeroStatus = IDAESolver::EQUAL_ZERO;
				
				// Store which zero function caused event
				_events[i] = true; //_zeroSign = sgn(_zeroVal[i]-_zeroValLastSuccess[i]);
				
				// zeroVal is not allowed to be =0, since otherwise the direction of sign change cannot be determined in next step
				if ( _zeroVal[i] == 0.0 )
					_zeroVal[i] = -sgn(_zeroValLastSuccess[i]) * UROUND;
			}

			// ZERO_CROSSING
			//--------------
			else
			{
				// Change in sign, but zeroVal is not smaller than given tolerance
				_zeroStatus = IDAESolver::ZERO_CROSSING;
				
				// Reset zeroSign
				_events[i] = 0;
				// Store time of last rejected step
				_tLastUnsucess = _tCurrent;

				break;
			}
		}

		// UNCHANGED_SIGN
		//----------------
		else
			_events[i] = false;
			
	}

	// NO_ZERO
	//--------------
	if (_zeroSearchActive && (_tCurrent > _tLastUnsucess))
		_zeroStatus = IDAESolver::NO_ZERO;
}



void SolverDefaultImplementation::writeToFile(const int& stp, const double& t, const double& h)
{
	
	//if (_outputStream && _settings->_globalSettings->_resultsOutput)
	//{
	//	// Reset curser within output stream to last valid position (before zero crossing) 
	//	if(_outputCommand & IContinous::RESET)
	//		if(stp == 1)
	//			_outputStream->seekp(_curserPosition);

	//	if(_outputCommand & IContinous::WRITE)
	//	{
	//		// In the first step, tell (inital) curser position within output stream
	//		if(stp == 1)
	//			_curserPosition = _outputStream->tellp();

	//		// Write current step, time and step size into output stream
	//		*_outputStream << stp << "\t" << t << "\t" << h;

	//		// Write out output stream
	//		_system->writeOutput(_outputCommand);
	//		
	//		// Write a line break into output stream
	//		*_outputStream << std::endl;
	//	}
	//}
	
	if(_outputCommand & IDAESystem::WRITE)
	{
        _system->writeOutput(_outputCommand);
	}
}

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<SolverDefaultImplementation,IDAESystem*, ISolverSettings*> > >()
    ["DefaultsolverImpl"].set<SolverDefaultImplementation>();
  types.get<std::map<std::string, factory<ISolverSettings, IGlobalSettings* > > >()
    ["SolverSettings"].set<SolverSettings>();
}