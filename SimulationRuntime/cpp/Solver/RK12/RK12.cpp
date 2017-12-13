/** @addtogroup solverRK12
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include <Solver/RK12/RK12.h>
#include <Solver/RK12/RK12Settings.h>
#include <Core/Math/ILapack.h>



RK12::RK12(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings)
    , _RK12Settings      (dynamic_cast<IRK12Settings*>(_settings))
    , _z                (NULL)
	, _z_a		    (NULL)
    , _z0               (NULL)
	, _z_a_0			(NULL)
	, _zPred            (NULL)
    , _z1               (NULL)
	, _z_a_1			(NULL)
    , _zInit            (NULL)
    , _zWrite           (NULL)
	, _zDot0			(NULL)
	, _zDotPred			(NULL)

    , _dimSys           (0)
    , _outputStps       (0)
    , _idid             (0)
    , _hOut             (0.0)
    , _hZero            (0.0)
    , _hUpLim           (0.0)
    , _tLastZero        (0.0)
    , _tRealInitZero    (0.0)
    , _doubleZeroDistance  (0.0)
    , _h00              (0.0)
    , _h01              (0.0)
    , _h10              (0.0)
    , _h11              (0.0)
	, _h_a			(0.0)
    , _f0               (NULL)
    , _f1               (NULL)
    ,_zeroTol            (1e-8)
    ,_outputStp(1)
    ,_tZero(-1)
	,_dimParts 	(0)
	,_activePartitions	(NULL)
	,_activeStates		(NULL)
{
}

RK12::~RK12()
{
    if(_z)
        delete [] _z;
    if(_z0)
        delete [] _z0;
    if(_z1)
        delete [] _z1;
    if(_zInit)
        delete [] _zInit;
    if(_zWrite)
        delete [] _zWrite;
    if(_f0)
        delete [] _f0;
    if(_f1)
        delete [] _f1;
    if(_activePartitions)
        delete [] _activePartitions;

}

bool RK12::stateSelection()
 {
   return SolverDefaultImplementation::stateSelection();
 }
void RK12::initialize()
{
    // Kennzeichnung, dass assemble() (vor der Integration) aufgerufen wurde
    _idid = 5000;

    _properties = dynamic_cast<ISystemProperties*>(_system);
    _continuous_system = dynamic_cast<IContinuous*>(_system);
    _event_system =  dynamic_cast<IEvent*>(_system);
    _mixed_system =  dynamic_cast<IMixedSystem*>(_system);
    _time_system =  dynamic_cast<ITime*>(_system);

    //(Re-) Initialization of solver -> call default implementation service
    SolverDefaultImplementation::initialize();

    // Dimension of the system (number of variables)
    _dimSys   = _continuous_system->getDimContinuousStates();
    _dimParts = _continuous_system->getNumPartitions();

    // Check system dimension
    if(_dimSys <= 0 || !(_properties->isODE()))
    {
        _idid = -1;
        throw ModelicaSimulationError(SOLVER,"RK12::assemble() error");
    }
    else
    {
        // Allocate state vectors, stages and temporary arrays
        if(_z)            	delete [] _z;
        if(_z0)        		delete [] _z0;
        if(_zPred)        	delete [] _zPred;
        if(_z1)        		delete [] _z1;
        if(_z_a)          delete [] _z_a;
        if(_z_a_0)        	delete [] _z_a_0;
        if(_z_a_1)         delete [] _z_a_1;

        if(_zPred)        	delete [] _zPred;
        if(_zDotPred)      delete [] _zDotPred;
        if(_zDot0)          delete [] _zDot0;

        if(_zInit)          delete [] _zInit;
        if(_zWrite)         delete [] _zWrite;

        if(_f0)         	delete [] _f0;
        if(_f1)        		delete [] _f1;
        if(_zeroSignIter)   delete [] _zeroSignIter;

        if(_activeStates)	delete [] _activeStates;

        _z  		= new double[_dimSys];
        _z0 		= new double[_dimSys];
        _zPred 		= new double[_dimSys];
        _z1 		= new double[_dimSys];
        _z_a  	= new double[_dimSys];
        _z_a_0 	= new double[_dimSys];
        _z_a_1 	= new double[_dimSys];

        _zPred	 	= new double[_dimSys];
        _zDotPred 	= new double[_dimSys];
        _zDot0 		= new double[_dimSys];

        _zInit      = new double[_dimSys];
        _zWrite     = new double[_dimSys];

        _f0         = new double[_dimSys];
        _f1         = new double[_dimSys];
        _zeroSignIter	= new int[_dimZeroFunc];

        _activeStates = new bool[_dimSys];

        memset(_z,			0,_dimSys*sizeof(double));
        memset(_z0,			0,_dimSys*sizeof(double));
        memset(_zPred,		0,_dimSys*sizeof(double));
        memset(_z1,			0,_dimSys*sizeof(double));
        memset(_z_a,		0,_dimSys*sizeof(double));
        memset(_z_a_0,		0,_dimSys*sizeof(double));
        memset(_z_a_1,		0,_dimSys*sizeof(double));

        memset(_zPred		,0,_dimSys*sizeof(double));
        memset(_zDotPred	,0,_dimSys*sizeof(double));
        memset(_zDot0		,0,_dimSys*sizeof(double));

        memset(_zInit,		0,_dimSys*sizeof(double));
        memset(_zWrite,		0,_dimSys*sizeof(double));

        memset(_f0,0,_dimSys*sizeof(double));
        memset(_f1,0,_dimSys*sizeof(double));
        memset(_zeroSignIter,0,_dimSys*sizeof(int));

        memset(_activeStates,0,_dimSys*sizeof(bool));

        // Counter initialisieren
        _outputStps    = 0;

        if( _RK12Settings->getDenseOutput())
        {
            // Ausgabeschrittweite
            _hOut    =  dynamic_cast<ISolverSettings*>(_RK12Settings)->getGlobalSettings()->gethOutput();
      _h=_hOut;
        }
    else
    {
      _h = std::max(std::min(_h, dynamic_cast<ISolverSettings*>(_RK12Settings)->getUpperLimit()), dynamic_cast<ISolverSettings*>(_RK12Settings)->getLowerLimit());
    }
    _tZero=-1;

    }
	// partition activation
	if(_dimParts != -1)
	{
		if(_activePartitions)   delete [] _activePartitions;
		_activePartitions = new bool[_dimParts];
		memset(_activePartitions,true,_dimParts*sizeof(bool));
		_h_a = 0.5*_h;
	}

}
void RK12::setTimeOut(unsigned int time_out)
  {
       SimulationMonitor::setTimeOut(time_out);
  }
void RK12::stop()
  {
       SimulationMonitor::stop();
  }

/// Set start t for numerical solution
void RK12::setStartTime(const double& t)
{
    SolverDefaultImplementation::setStartTime(t);
};

/// Set end t for numerical solution
void RK12::setEndTime(const double& t)
{
    SolverDefaultImplementation::setEndTime(t);
};

/// Set the initial step size (needed for reinitialization after external zero search)
void RK12::setInitStepSize(const double& h)
{
    SolverDefaultImplementation::setInitStepSize(h);
};


/// Provides the status of the solver after returning
ISolver::SOLVERSTATUS RK12::getSolverStatus()
{
    return (SolverDefaultImplementation::getSolverStatus());
};

/// Does time integration loop
void RK12::solve(const SOLVERCALL command)
{

    if (_RK12Settings && _system)
    {
        // Prepare solver and system for integration
        if (command & ISolver::FIRST_CALL)
        {
            initialize();
           _tLastWrite = 0;
        }

        // Causes the solver to read the states from the system in the very first step
        if (command & ISolver::RECALL)
            _firstStep = true;

        // Reset status flag
        _solverStatus = ISolver::CONTINUE;

        while ( _solverStatus & ISolver::CONTINUE && !_interrupt )
        {
            // Zuvor wurde assemble aufgerufen und hat funktioniert => RESET IDID
            if(_idid == 5000)
                _idid = 0;

            // Call solver
            //-------------
            if(_idid == 0)
            {
                // Reset counter
                _accStps = 0;

                // Get initial values from system, write out initial state vector
                solverOutput(_accStps,_tCurrent,_z,_h);

                // Choose integration method
                if (_RK12Settings->getRK12Method()  == RK12Settings::STEPSIZECONTROL){
                	//doRK12 with global step size and step size control
            		std::cout<<"do RK12 step size controlled! "<<std::endl;
            		doRK12_stepControl();
                	}

                else if (_RK12Settings->getRK12Method()  == RK12Settings::MULTIRATE){

                	//doRK12 with multi-rate();
            		std::cout<<"do RK12 multirate!"<<std::endl;
                	doRK12();
                	}

                else{
            		std::cout<<"do RK12 else!"<<std::endl;}
            }

            // Integration was not sucessfull (=0) or was terminated by the user (=1)
            if(_idid != 0 && _idid !=1)
            {
                _solverStatus = ISolver::SOLVERERROR;
            }

            // Stopping criterion (end time reached)
            else if   ( (_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_RK12Settings)->getEndTimeTol())
                _solverStatus = ISolver::DONE;
        }

        _firstCall = false;
        if(_interrupt)
           throw ModelicaSimulationError(SOLVER,"RK12::solve() time out reached");

    }
    else
    {
        // Invalid system
        _idid = -3;
    }
}

void RK12::RK12Integration(bool *activeStates, double time, double *z0, double *z1, double h, double *error, double relTol, double absTol, int *numErrors)
{
	*numErrors = 0;
	//calculate system
	calcFunction(time, z0, _zDot0);

	for(int i = 0; i < _dimSys; ++i){
		//calculate the activated states only
		if (activeStates[i] == true){
			//do a forward euler step as predictor
			_zPred[i] = _z0[i] + h * _zDot0[i];
		}
	}

	//calculate system for predictor
	calcFunction(time+h, _zPred, _zDotPred);

	//final modified euler step
	for(int i = 0; i < _dimSys; ++i){
		if (activeStates[i] == true){
			z1[i] = z0[i] + 0.5*h *(_zDot0[i] + _zDotPred[i]);
			//calculate error
			if (!toleranceOK(z0[i], z1[i], relTol, absTol)) {
				*numErrors = *numErrors+1;
			}
		}
	}
	//printing
	for (int i=0;i < _dimSys; i++) {
		if (activeStates[i] == true){
		 //std::cout<<"state"<<i<<" at "<<time<<"   z0  "<<z0[i]<<"  _zDot0	"<<_zDot0[i]<<"  _zPred  "<<_zPred[i]<<"  _zDotPred  "<<_zDotPred[i]<<"	 z1	"<<z1[i]<<" relError "<<relError(z0[i],z1[i])<<"  correct?  "<<toleranceOK(z0[i], z1[i], relTol, absTol)<<std::endl;
	 	 }
	}
}


void RK12::RK12InterpolateStates(bool *activeStates, double *leftIntervalStates, double *rightIntervalStates,double leftTime,double rightTime, double *interpolStates, double interpolTime){
	for (int i; i<_dimSys;i++)
	{
		if (activeStates[i] == false)
			interpolStates[i] = ( (rightIntervalStates[i]-leftIntervalStates[i]) * (interpolTime-leftTime) / (rightTime-leftTime) ) +  leftIntervalStates[i];
	}
}


void RK12::doRK12()
{
	int
		numAccSteps = 0,
		numAccActiveSteps = 0,
		numErrors = 0;

    double
		tNext,
		tActNext,
		tActCurrent;						// point of time after another step with step size _h

    double
		hNew = _h;

    double
	    absTol = 1e-6,					// the max absolute error per step per state
		relTol = 1e-4;					// the max relative error per step per state

    double
		*delta_z = new double[_dimSys];			// the error

    bool
		*allPartitionsActive = new bool[_dimParts],						// to switch on all partitions
    	*allStatesActive = new bool[_dimSys];							// to calculate all states
    	memset(allPartitionsActive,true,_dimParts*sizeof(bool));
    	memset(allStatesActive,true,_dimSys*sizeof(bool));


    while( _idid == 0 && _solverStatus != USER_STOP )
    {
    	//update step size
        _h = hNew;

    	// adapt step size of the last step before endTime
        if((_tCurrent + _h) > _tEnd) {
            _h = (_tEnd - _tCurrent);
            std::cout<<"last step size "<<_h<<std::endl;
        }

        // time for the next latent step
        tNext = _tCurrent + _h;

        //MAKE A LATENT STEP
        //------------------
        //std::cout<<"START LATENT STEP ("<<_h<<") at "<<_tCurrent<<std::endl;

        // save old state vector for latent step
        memcpy(_z0,_z,(int)_dimSys*sizeof(double));

        //set partitions to active
		_continuous_system->setPartitionActivation(allPartitionsActive);

        //integrate with latent step size
        RK12Integration(allStatesActive, _tCurrent, _z0, _z, _h, delta_z, relTol, absTol, &numErrors);

    	//latent step is completely or partially ok
        if (numErrors == 0) {
			++ numAccSteps;
			if (numAccSteps==4) {
				// increase step size for the next step
		        //std::cout<<"INCREASE LATENT STEP SIZE "<<_h<<std::endl;
		        hNew = _h*2.0;
				numAccSteps = 0;
			}

			// some printing
			RK12::outputStepSize(_activeStates, _tCurrent, _h, -2.0);

        }
    	//latent step is completely wrong
        else if(numErrors == _dimSys) {
            //std::cout<<"ALL IS WRONG -> REDUCE LATENT STEP SIZE "<<_h<<std::endl;
            hNew = _h/ 2.0;
            memcpy(_z,_z0,(int)_dimSys*sizeof(double));
          	tNext = _tCurrent;
        }

				//refine wrong states in an active step
				else {
					//which partitions belong to this errors?
					for (int i=0;  i<  _dimSys; i++ ){
						int j = _continuous_system->getActivator(i);
						if (toleranceOK(_z0[i], _z[i], relTol, absTol)) {
							//this error is small enough, no need to calculate this partition
							_activePartitions[j] = false;
							_activeStates[i] = false;
							}
						else {
							_activePartitions[j] = true;
							_activeStates[i] = true;
						}
					}
					_continuous_system->setPartitionActivation(_activePartitions);

					//std::cout<<"active partitions ";
					//for (int i=0;i < _dimParts; i++) std::cout<<"  "<<_activePartitions[i];
					//std::cout<<std::endl;


					// integrate with active step size
					tActCurrent = _tCurrent;

					// set the start values for the active interval
					memcpy(_z_a_0,_z0,(int)_dimSys*sizeof(double));

					while (tActCurrent < tNext) {
						numErrors = 0;

						// In case the active step size is too big for the latent one, reduce it, adapt last step as well
						if (_h <= _h_a) _h_a = _h/2;
						if (tActCurrent + _h_a - tNext > 1e-8) std::cout<<"ADAPT LAST ACTIVE STEP "<<std::endl;

						//some printing
						//std::cout<<"START ACTIVE STEP ("<<_h_a<<") at "<<tActCurrent<<std::endl;
						//std::cout<<"active partitions in active step";
						//for (int i=0;i < _dimParts; i++) std::cout<<"  "<<_activePartitions[i];
						//std::cout<<std::endl;

						//interpolate states
						RK12InterpolateStates(_activeStates, _z0,_z,_tCurrent,tNext, _z_a_0,tActCurrent);

						//integrate with active step size
						RK12Integration(_activeStates, tActCurrent, _z_a_0, _z_a, _h_a, delta_z, relTol, absTol, &numErrors);

						//active step is ok
						if(numErrors == 0)
						{
							if (numAccActiveSteps == 4) {
								_h_a = _h_a * 2.0;
								numAccActiveSteps = 0;
								//std::cout<<"INCREASE ACTIVE STEP SIZE "<<_h_a<<std::endl;

							}
							else {
								numAccActiveSteps = numAccActiveSteps+1;
							}
							//std::cout<<"ACTIVE STEP WAS OK "<<std::endl;
							tActCurrent = tActCurrent+_h_a;
							//set state for the next step
							memcpy(_z_a_0, _z_a, (int)_dimSys*sizeof(double));

							// some printing
							RK12::outputStepSize(_activeStates, tActCurrent, _h, _h_a);

						}
						//active step is wrong
						else {
							//std::cout<<"REDUCE ACTIVE STEP SIZE AND REPEAT"<<std::endl;
							_h_a = _h_a / 2.0;
						}
					  }
					}

        ++ _totStps;

        //write result to right interval boarder vector
        memcpy(_z1,_z,_dimSys*sizeof(double));


    	//printing
        solverOutput(_accStps,tNext,_z,_h);

        //event handling
        doMyZeroSearch();

        if (((_tEnd - _tCurrent) < dynamic_cast<ISolverSettings*>(_RK12Settings)->getEndTimeTol()))
            break;

        if (_zeroStatus ==EQUAL_ZERO && _tZero > -1)   {

        	// found zero crossing -> complete step
            _firstStep            = true;
            _hUpLim = dynamic_cast<ISolverSettings*>(_RK12Settings)->getUpperLimit();

            //handle all events that occured at this t
            //update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);
            _mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);
            _event_system->getZeroFunc(_zeroVal);
            _zeroStatus = EQUAL_ZERO;
            memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));
        }

        if (_tZero > -1)        {
            solverOutput(_accStps,_tZero,_z,_h);
            _tCurrent = _tZero;
            _tZero=-1;
        }
        else        {
            //_tCurrent += _h;
            _tCurrent = tNext;
        }
    }
}


void RK12::outputStepSize(bool *_activeStates, double time ,double hLatent, double hActive){
	double stepsize = 0.0;
	std::cout<<"time "<<time;
	for (int i=0; i<_dimSys; i++) {
		if (_activeStates[i]==true)
		{
			stepsize = hActive;
		}
		else
		{
			stepsize = hLatent;
		}
		std::cout<<"  ;  "<<stepsize;
	}
	std::cout<<""<<std::endl;
}

double RK12::toleranceOK(double z1, double z2, double relTol, double absTol)
{
	double absError = fabs(z1-z2);
	//std::cout<<"absError "<<absError<<std::endl;
	//std::cout<<"relError "<<relError(z1,z2)<<std::endl;

	if (absError <= absTol)
	{
		return true;
	}

	else if (absError/max(max(fabs(z1),fabs(z2)),1e-12) <= relTol)
	{
		return true;
	}

	else {
		return false;
	}
}

double RK12::relError(double z1, double z2)
{
	return fabs(z1-z2)/max(max(fabs(z1),fabs(z2)),1e-12);
}


void RK12::doRK12_stepControl()
{
	int
		numAccSteps = 0,
		numErrors = 0;

    double
		tNext;

    double
		hNew = _h;

    double
	    absTol = 1e-6,					// the max absolute error per step per state
		relTol = 1e-4;					// the max relative error per step per state

    double
		*delta_z = new double[_dimSys];			// the error

    bool
		*allPartitionsActive = new bool[_dimParts],						// to switch on all partitions
    	*allStatesActive = new bool[_dimSys];							// to calculate all states
    	memset(allPartitionsActive,true,_dimParts*sizeof(bool));
    	memset(allStatesActive,true,_dimSys*sizeof(bool));


	//set partitions to active
	_continuous_system->setPartitionActivation(allPartitionsActive);

    while( _idid == 0 && _solverStatus != USER_STOP )
    {
    	//update step size
        _h = hNew;

    	// adapt step size of the last step before endTime
        if((_tCurrent + _h) > _tEnd) {
            _h = (_tEnd - _tCurrent);
            std::cout<<"last step size "<<_h<<std::endl;
        }

        // time for the next latent step
        tNext = _tCurrent + _h;

        //MAKE A LATENT STEP
        //------------------
        //std::cout<<"START LATENT STEP ("<<_h<<") at "<<_tCurrent<<std::endl;

        // save old state vector for latent step
        memcpy(_z0,_z,(int)_dimSys*sizeof(double));

        //integrate with latent step size
        RK12Integration(allStatesActive, _tCurrent, _z0, _z, _h, delta_z, relTol, absTol, &numErrors);

    	//latent step is completely or partially ok
        if (numErrors == 0) {
			++ numAccSteps;
			if (numAccSteps==4) {
				// increase step size for the next step
		        //std::cout<<"INCREASE LATENT STEP SIZE "<<_h<<std::endl;
		        hNew = _h*2.0;
				numAccSteps = 0;
			}
        }

    	//latent step is completely wrong
        else {
            //std::cout<<"ALL IS WRONG -> REDUCE LATENT STEP SIZE "<<_h<<std::endl;
            hNew = _h/ 2.0;
            memcpy(_z,_z0,(int)_dimSys*sizeof(double));
          	tNext = _tCurrent;
        }

		// some printing
		RK12::outputStepSize(_activeStates, _tCurrent, _h, -2.0);

		++ _accStps;

		//write result to right interval boarder vector
		memcpy(_z1,_z,_dimSys*sizeof(double));


		solverOutput(_accStps,tNext,_z,_h);

		//event handling
		doMyZeroSearch();

		if (((_tEnd - _tCurrent) < dynamic_cast<ISolverSettings*>(_RK12Settings)->getEndTimeTol()))
			break;

		if (_zeroStatus ==EQUAL_ZERO && _tZero > -1)   {

			// found zero crossing -> complete step
			_firstStep            = true;
			_hUpLim = dynamic_cast<ISolverSettings*>(_RK12Settings)->getUpperLimit();

			//handle all events that occured at this t
			//update_events_type update_event = boost::bind(&SolverDefaultImplementation::updateEventState, this);

			_mixed_system->handleSystemEvents(_events/*,boost::ref(update_event)*/);
			_event_system->getZeroFunc(_zeroVal);
			_zeroStatus = EQUAL_ZERO;
			memcpy(_zeroValLastSuccess,_zeroVal,_dimZeroFunc*sizeof(double));
		}

		if (_tZero > -1) {
			solverOutput(_accStps,_tZero,_z,_h);
			_tCurrent = _tZero;
			_tZero=-1;
		}
		else {
			//_tCurrent += _h;
			_tCurrent = tNext;
		}
   }
}



void RK12::giveZeroVal(const double &t,const double *y,double *zeroValue)
{
    _time_system->setTime(t);
    _continuous_system->setContinuousStates(y);

    // System aktualisieren
    _continuous_system->evaluateODE(IContinuous::ALL);  // vxworksupdate
    _event_system->getZeroFunc(zeroValue);
}

void RK12::giveZeroIdx(double *vL,double *vR,int *zeroIdx, int &zeroExist)
{
    zeroExist = 0;
    for (int i=0; i<_dimZeroFunc; i++)
    {
        // Überprüfung auf Vorzeichenwechsel
        if (vL[i] * vR[i] <= 0 && abs(vL[i]- vR[i])>UROUND)
        {
            zeroIdx[i] = 1;
            zeroExist++;
        }
        else
            zeroIdx[i] = 0;
    }
}

void RK12::doMyZeroSearch()
{

    if (_zeroStatus == ZERO_CROSSING)
    {

        double
            count = 0,
            tL = _tCurrent,
            tR = _tCurrent+_h,
            tDelta,
            tTry,
            tSwap,
            maybe,
            change,
            lastMoved,
            *yL,
            *yR,
            *yTry,
            *ySwap,
            *vL,
            *vR,
            *vTry,
            *vSwap,
            *IllinoisV;

        int  zeroExist,
            leftZero,
            *zeroIdx;
        bool notDone = true,
            zeroBreak = false;

        yL = new double[_dimSys];
        yR = new double[_dimSys];
        yTry = new double[_dimSys];
        ySwap = new double[_dimSys];
        vL = new double[_dimZeroFunc];
        vR = new double[_dimZeroFunc];
        vTry = new double[_dimZeroFunc];
        vSwap = new double[_dimZeroFunc];
        IllinoisV = new double[_dimZeroFunc];
        zeroIdx = new int[_dimZeroFunc];

        // Initialisierung der benötigten Größen
        //
        //tL,tR: Zeit am linken/rechten Intervallrans
        //yL,yR: Zustand am linken/rechten Intervallrand
        //vL,vR: Nullstellenfunktion am ...
        //

        memcpy(yL,_z0,_dimSys*sizeof(double));
        memcpy(yR,_z,_dimSys*sizeof(double));
        memcpy(vL,_zeroValLastSuccess,_dimZeroFunc*sizeof(double));
        memcpy(vR,_zeroVal,_dimZeroFunc*sizeof(double));


        // DBG
        //for (long int i=1;i<=_dimSys;i++)
        //      yL[i-1] = CONTR5(&i,&tR,cont,lrc);

        //


        _tZero = -1;
        tTry = tR;
        while(true)
        {
            lastMoved = 0;

            // Finde die Nullstelle
            while(true)
            {
                notDone = true;
                giveZeroIdx(vL,vR,zeroIdx,zeroExist);
                if ( zeroExist == 0)
                    return;
                //Ist das Zeitintervall noch groß genug ?
                tDelta = tR - tL;

                if (tDelta <= _zeroTol)
                    notDone = false;

                if (notDone==false)
                    break;

                leftZero = 0;
                for (int i=0;i<_dimZeroFunc;i++)
                    if ((zeroIdx[i] == 1) && ((abs(vL[i]) < UROUND) & (abs(vR[i]) >= UROUND)))
                        leftZero = 1;

                if((tL==_tCurrent) & leftZero)
                    tTry = tL + 0.5*_zeroTol;
                else
                {
                    // Regula Falsi
                    change = 1;
                    for (int i=0;i<_dimZeroFunc;i++)
                    {
                        if (zeroIdx[i] == 0)
                            continue;
                        // Falls vL oder vR Null ist, altes tTry verwenden
                        if (abs(vL[i])<UROUND)
                        {
                            if (tTry>tR && vTry[i] != vR[i])
                            {
                                maybe = 1-vR[i]*(tTry-tR)/((vTry[i]-vR[i])*tDelta);
                                if (maybe < 0 || maybe > 1)
                                    maybe = 0.5;
                            }
                            else
                            {
                                maybe = 0.5;
                            }

                        }
                        else
                        {
                            if (abs(vR[i] < UROUND))
                            {
                                if (tTry<tL && vTry[i] != vL[i])
                                {
                                    maybe = vL[i]*(tL-tTry)/((vTry[i]-vL[i])*tDelta);
                                    if (maybe < 0 || maybe > 1)
                                        maybe = 0.5;
                                }
                                else
                                {
                                    maybe = 0.5;
                                }

                            }
                            else
                            {
                                maybe = -vL[i]/(vR[i]-vL[i]);
                            }
                        }
                        // die Nullstelle die weitesten links liegt wird betrachtet
                        if (maybe < change)
                            change = maybe;
                    } //end for

                    change = change*abs(tDelta);
                    change = std::max(0.5*_zeroTol,_zeroTol);

                    tTry = tL + change;

                }// end if tL== tOld

                // vTry berechnen
                interp1(tTry,yTry);
                giveZeroVal(tTry,yTry,vTry);

                // Nullstellendurchgänge zwischen tL und tTry
                giveZeroIdx(vL,vTry,zeroIdx,zeroExist);
                for(int i=0;i<_dimZeroFunc;i++)
                    if(abs(vTry[i]) == 0.0 && !zeroExist)
                    {

                        //_kk << "Bad Loop" << endl <<  vTry[i] << endl << _dimZeroFunc <<endl;
                        /*
                        tR = tTry;
                        for (long int j=1;j<=_dimSys;j++)
                        yR[j-1] = CONTR5(&j,&tR,cont,lrc);
                        giveZeroVal(tR,yR,vR);
                        zeroBreak = true;
                        //break;
                        */
                        while(true)
                        {
                            count++;
                            tR = tTry + count*10*_zeroTol;
                             interp1(tR,yR);
                            giveZeroVal(tR,yR,vR);
                            if(abs(vR[i]) > 0.0)
                            {
                                zeroBreak = true;
                                break;
                            }
                        }

                    }


                    if (zeroBreak)
                        break;

                if (zeroExist)
                {
                    // rechte Intervallgrenze nach links schieben
                    tSwap = tR;
                    tR = tTry;
                    tTry = tSwap;

                    memcpy(ySwap,yR,_dimSys*sizeof(double));
                    memcpy(yR,yTry,_dimSys*sizeof(double));
                    memcpy(yTry,ySwap,_dimSys*sizeof(double));

                    memcpy(vSwap,vR,_dimZeroFunc*sizeof(double));
                    memcpy(vR,vTry,_dimZeroFunc*sizeof(double));
                    memcpy(vTry,vSwap,_dimZeroFunc*sizeof(double));

                    // falls zweimal in Folge nach links verschoben wurde, wird vL halbiert (nächstes mal wird weiter gerückt)
                    if (lastMoved == 2)
                    {
                        for (int i=0;i<_dimZeroFunc;i++)
                        {
                            IllinoisV[i] = 0.5*vL[i];
                            if (abs(IllinoisV[i]) >=UROUND)
                                vL[i] = IllinoisV[i];
                        }
                    }
                    lastMoved = 2;
                }
                else
                {
                    // linke Intervallgrenze nach rechts schieben
                    tSwap = tL;
                    tL = tTry;
                    tTry = tSwap;

                    memcpy(ySwap,yL,_dimSys*sizeof(double));
                    memcpy(yL,yTry,_dimSys*sizeof(double));
                    memcpy(yTry,ySwap,_dimSys*sizeof(double));

                    memcpy(vSwap,vL,_dimZeroFunc*sizeof(double));
                    memcpy(vL,vTry,_dimZeroFunc*sizeof(double));
                    memcpy(vTry,vSwap,_dimZeroFunc*sizeof(double));

                    // falls zweimal in Folge nach rechts verschoben wurde, wird vR halbiert (nächstes mal wird weiter gerückt)
                    if (lastMoved == 1)
                    {
                        for (int i=0;i<_dimZeroFunc;i++)
                        {
                            IllinoisV[i] = 0.5*vR[i];
                            if (abs(IllinoisV[i]) >=UROUND)
                                vR[i] = IllinoisV[i];
                        }
                    }
                    lastMoved = 1;
                }// end for zeroExist
            }// end while REGULA-FALSI

            _tZero = tR;

            if (_tInit != tL)
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                break;
            }
            else
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                //tZero = -1;
                break;
            }
            if (abs(_tCurrent+_h-tR) < _zeroTol)
            {
                memcpy(_zeroVal,vR,_dimZeroFunc*sizeof(double));
                break;
            }
            else
            { // betrachte [tR+0.5*tol tnew]
                tTry = tR;
                yTry = yR;
                vTry = vR;
                tL = tR + 0.5*_zeroTol;
                interp1(tL,yL);
                giveZeroVal(tL,yL,vL);
                tR = _tCurrent+_h;
                yR = _z;
                memcpy(vR,_zeroVal,_dimZeroFunc*sizeof(double));
            }


        }//end while terminal

        /*
        for (int i=0;i<_dimZeroFunc;i++)
        {
        if (zeroIdx[i] ==0)
        _zeroSign[i] = 0;
        else
        _zeroSign[i] = sgn(_zeroVal[i]-_zeroValLastSuccess[i]);
        if ( abs(_zeroVal[i]) == 0 )
        _zeroVal[i] = -sgn(_zeroValLastSuccess[i]) * UROUND;
        }
        */
        interp1(_tZero,_z);
        _tLastSuccess = tL;
        _tCurrent = _tZero;
        setZeroState();

        _time_system->setTime(_tCurrent);
        _continuous_system->setContinuousStates(_z);
        _continuous_system->evaluateODE(IContinuous::ALL);  // vxworksupdate


        delete [] yL;
        delete [] yR;
        delete [] yTry;
        delete [] ySwap;
        delete [] vL;
        delete [] vR;
        delete [] vTry;
        delete [] vSwap;
        delete [] IllinoisV;
        delete [] zeroIdx;

    }// end if ZERO_STATE
    else if (_zeroStatus == EQUAL_ZERO)
    {

        _tZero = _tCurrent+_h;
        _tCurrent = _tZero;
    }
}

void RK12::calcFunction(const double& t, const double* z, double* f)
{

    _time_system->setTime(t);
    _continuous_system->setContinuousStates(z);
    _continuous_system->evaluateODE(IContinuous::ALL);    // vxworksupdate
    _continuous_system->getRHS(f);
}

void RK12::solverOutput(const int& stp, const double& t, double* z, const double& h)
{

    _time_system->setTime(t);

    // (Re-)start of integration => First step: read state vector from the system
    if (_firstStep)
    {
        _firstStep    = false;

        // Update the system
        _continuous_system->evaluateAll(IContinuous::ALL);  // vxworksupdate

        // read variables from the system
        _continuous_system->getContinuousStates(z);



        if (_zeroVal)
        {
            // read values of zero functions
            _event_system->getZeroFunc(_zeroVal);

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
        _continuous_system->setContinuousStates(z);

        // Update the system
        _continuous_system->evaluateAll(IContinuous::ALL);   // vxworksupdate


        if(_zeroVal && (stp > 0))
        {
            // read values of zero functions
            _event_system->getZeroFunc(_zeroVal);

            // Determine the sign and hence the status of zero crossings
            SolverDefaultImplementation::setZeroState();
        }
        if (abs(t-_tEnd) <= dynamic_cast<ISolverSettings*>(_RK12Settings)->getEndTimeTol())
            _zeroStatus = UNCHANGED_SIGN;
    }


    if (_zeroStatus == UNCHANGED_SIGN || _zeroStatus == EQUAL_ZERO)
    {
        if (_RK12Settings->getDenseOutput())
        {
            if (t == 0)
            {

                SolverDefaultImplementation::writeToFile(stp, t, h);
            }
            else
            {
                while (_tLastWrite + dynamic_cast<ISolverSettings*>(_RK12Settings)->getGlobalSettings()->gethOutput() -t  <= 0)
                {
                    // Zeitpunkt an dem geschrieben wird
                    _tLastWrite = _tLastWrite +  dynamic_cast<ISolverSettings*>(_RK12Settings)->getGlobalSettings()->gethOutput();

                    // System in den richtigen Zustand bringen
                    interp1(_tLastWrite,_zWrite);

                    // setTime
                    _time_system->setTime(_tLastWrite);

                    // setVars
                    _continuous_system->setContinuousStates(_zWrite);

                    // System aktualisieren
                    _continuous_system->evaluateAll(IContinuous::ALL);  // vxworksupdate
                   /*if(stp%_outputStp==0)*/

                    SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);

                }//end while t -_tLastWritten
                // System in den alten Zustand zurück versetzen

                // setTime
                _time_system->setTime(t);

                // setVars
                _continuous_system->setContinuousStates(z);

                _continuous_system->evaluateAll(IContinuous::ALL);  // vxworksupdate

            }
        }
        else
        {
           /*if(stp%_outputStp==0)*/


                SolverDefaultImplementation::writeToFile(stp, t, h);

        }

        // Zähler für die Anzahl der ausgegebenen Schritte erhöhen
        ++ _outputStps;


    }

    // Ensures that no user stop occurs in the very first step, when the solver has not done at least one step
    if (stp == 0)
        _zeroStatus = UNCHANGED_SIGN;
}





void RK12::interp1(double time, double *value)
{

    double t = (time-_tCurrent)/_h;

    _h00 = 2*pow(t,3)-3*pow(t,2)+1;
    _h10= pow(t,3)-2*pow(t,2)+t;
    _h01 = -2*pow(t,3)+3*pow(t,2);
    _h11 = pow(t,3)-pow(t,2);

    for (int i=0;i<_dimSys;i++)
        value[i] = _h00*_z0[i] + _h10*_h*_f0[i]  + _h01*_z1[i] + _h11*_h*_f1[i];
}




void RK12::writeSimulationInfo()
{
    //// Solver
    //outputStream
    //    << "Solver:                       RK12\n"
    //    << "Method:                       ";

    //if(_RK12Settings->getRK12Method() == IRK12Settings::RK12FORWARD)
    //    outputStream << "Explicit RK12";
    //else if(_RK12Settings->getRK12Method() == IRK12Settings::RK12BACKWARD)
    //    outputStream << "Implicite RK12";
    //else if(_RK12Settings->getRK12Method() ==IRK12Settings::MIDPOINT)
    //    outputStream << "Mitpoint rule";


    //outputStream << std::endl;

    //// Time
    //outputStream
    //    << "Simulation end t:          " << _tCurrent << " \n"
    //    << "Step size:                    " << dynamic_cast<ISolverSettings*>(_RK12Settings)->gethInit() << " \n"
    //    << "Output step size:             " << dynamic_cast<ISolverSettings*>(_RK12Settings)->getGlobalSettings()->gethOutput();

    //outputStream << std::endl;

    //// System
    //outputStream
    //    << "Number of equations (ODE):    " << (int)_dimSys << " \n"
    //    << "Number of zero functions:     " << _dimZeroFunc;

    //outputStream << std::endl;

    //// Root finding
    //if (!(_zeroVal) && _RK12Settings->getZeroSearchMethod() == IRK12Settings::NO_ZERO_SEARCH)
    //{
    //    outputStream << "\nZero search method:           No zero search\n" << std::endl;
    //}
    //else
    //{
    //    if (_RK12Settings->getZeroSearchMethod() == IRK12Settings::BISECTION)
    //    {
    //        outputStream << "Zero search method:           Bisection" << std::endl;
    //    }
    //    else
    //    {
    //        outputStream << "Zero search method:           Linear Interpolation" << std::endl;
    //    }

    //    outputStream
    //        << "Zero function tolerance:      " << dynamic_cast<ISolverSettings*>(_RK12Settings)->getZeroTol() << " \n"
    //        << "Zero t tolerance:          " << dynamic_cast<ISolverSettings*>(_RK12Settings)->getZeroTimeTol() << " \n"
    //        << "Number of zero search steps:  " << _zeroStps << " \n"
    //        << "Number of zeros in interval:  " << _zeros << std::endl;
    //}

    //if(_RK12Settings->getRK12Method() == IRK12Settings::RK12BACKWARD || _RK12Settings->getRK12Method() == IRK12Settings::MIDPOINT && _RK12Settings->getUseNewtonIteration() == true)
    //    outputStream    << "Iteration tolerance:          " << _RK12Settings->getIterTol() << std::endl;

    //// Steps
    //outputStream
    //    << "Total number of steps:        " << _totStps << "\n"
    //    << "Number of output steps:       " << _outputStps << "\n"
    //    << "Status:                       " << _idid;

    //outputStream << std::endl;
}
int RK12::reportErrorMessage(ostream& messageStream)
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

void RK12::calcJac(double* yHelp, double* _fHelp, const double* _f, double* jac, const bool& flag)
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
            jac[i+j*_dimSys] = (_fHelp[i] - _f[i]) / 1e-8;
        }
    }
}
/** @} */ // end of solverRK12
