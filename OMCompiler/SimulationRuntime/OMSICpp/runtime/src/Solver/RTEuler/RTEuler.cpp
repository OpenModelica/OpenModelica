/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/RTEuler/RTEuler.h>
#include <Solver/RTEuler/RTEulerSettings.h>


RTEuler::RTEuler(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings)
    , _eulerSettings    (dynamic_cast<ISolverSettings*>(_settings))
    , _z          (NULL)
    , _dimSys        (0)
    , _f          (NULL)
	, _zInit          (NULL)

{
}

RTEuler::~RTEuler()
{
    if(_z)
        delete [] _z;
    if(_f)
        delete [] _f;
    if(_zInit)
      delete [] _zInit;
}


void RTEuler::initialize()
{
    _properties = dynamic_cast<ISystemProperties*>(_system);
    _continuous_system = dynamic_cast<IContinuous*>(_system);
    _event_system =  dynamic_cast<IEvent*>(_system);
    _mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    _time_system =  dynamic_cast<ITime*>(_system);

    _dimSys  = _continuous_system->getDimContinuousStates();



    //(Re-) Initialization of solver -> call default implementation service
	IGlobalSettings* globalsettings = _eulerSettings->getGlobalSettings();
	_h = globalsettings->gethOutput();

	if (_dimSys == 0)
		return;

	SolverDefaultImplementation::initialize();
    // Dimension of the system (number of variables)


    // Check system dimension

    //if(_dimSys <= 0 || !(_properties->isODE()))
    //{
    //    throw std::invalid_argument("Euler::assemble() error");
    //}


        // Allocate state vectors, stages and temporary arrays
	if(_z)        delete [] _z;
	if(_f)        delete [] _f;



	_z        = new double[_dimSys];
	_f         = new double[_dimSys];
	_zInit       = new double[_dimSys];







	memset(_z,0,_dimSys*sizeof(double));     //hier!!!
	memset(_zInit,0,_dimSys*sizeof(double));

	memset(_f,0,_dimSys*sizeof(double));



	_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
	_continuous_system->getContinuousStates(_zInit);

	// Ensures that solver is started with right sign of zero function
	_zeroStatus = UNCHANGED_SIGN;

	memcpy(_z,_zInit,_dimSys*sizeof(double));



}

/// Set start t for numerical solution
void RTEuler::setStartTime(const double& t)
{
    SolverDefaultImplementation::setStartTime(t);
};

/// Set end t for numerical solution
void RTEuler::setEndTime(const double& t)
{
    SolverDefaultImplementation::setEndTime(t);
};

/// Set the initial step size (needed for reinitialization after external zero search)
void RTEuler::setInitStepSize(const double& h)
{
    SolverDefaultImplementation::setInitStepSize(h);
};


/// Provides the status of the solver after returning
ISolver::SOLVERSTATUS RTEuler::getSolverStatus()
{
    return (SolverDefaultImplementation::getSolverStatus());
};

bool RTEuler::stateSelection()
 {
   return SolverDefaultImplementation::stateSelection();
 }

void RTEuler::solve(const SOLVERCALL command)
{

 //Todo: _continuous_system->stepStarted(_tCurrent);

  if(_dimSys > 0)
  {

  _continuous_system->getContinuousStates(_z);

  doRK1();
    //_totStps++;
    //_accStps++;
    //_tCurrent += _h; //time not required
   _continuous_system->setContinuousStates(_z);
  }


   _tCurrent += _h;
   _time_system->setTime(_tCurrent);
   _continuous_system->evaluateAll();
   /*Todo: Replaced by isStepEvent
   _continuous_system->stepCompleted(_tCurrent);
   */
}


void RTEuler::calcFunction(const double& t, const double* z, double* f)
{
    _time_system->setTime(t);
    _continuous_system->setContinuousStates(z);
    _continuous_system->evaluateODE();    // vxworksupdate
    _continuous_system->getRHS(f);
}


void RTEuler::writeSimulationInfo()
{
}

const int RTEuler::reportErrorMessage(ostream& messageStream)
{
    return 1;
}



void RTEuler::doRK1()
{

  calcFunction(_tCurrent, _z, _f);

  for(int i = 0; i < _dimSys; ++i)
    _z[i] += _h * _f[i];
}

void RTEuler::setTimeOut(unsigned int time_out)
{}
void RTEuler::stop()
{}
/** @} */ // end of solverRteuler
