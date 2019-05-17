#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/IDA/IDA.h>
#include <Core/Math/Functions.h>

//#include <Core/Utils/numeric/bindings/traits/ublas_vector.hpp>
//#include <Core/Utils/numeric/bindings/traits/ublas_sparse.hpp>

Ida::Ida(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings),
      _idasettings(dynamic_cast<ISolverSettings*>(_settings)),
      _idaMem(NULL),
      /*_z(NULL),
      _zInit(NULL),
      _zWrite(NULL),
	  */
	  _y(NULL),
	  _yp(NULL),
      _yInit(NULL),
      _yWrite(NULL),
	  _ypWrite(NULL),
	  _dae_res(NULL),
      _dimSys(0),
	  _dimAE(0),
	  _dimStates(0),
      _cv_rt(0),
      _outStps(0),
      _locStps(0),
      _idid(0),
      _hOut(0.0),
      _tOut(0.0),
      _tZero(0.0),
      _zeroSign(NULL),
      _absTol(NULL),
      _ida_initialized(false),
      _tLastEvent(0.0),
      _event_n(0),
      _properties(NULL),
      _continuous_system(NULL),
      _event_system(NULL),
      _mixed_system(NULL),
      _time_system(NULL),
      _delta(NULL),
      _deltaInv(NULL),
      _ysave(NULL),
      _colorOfColumn (NULL),
      _jacobianAIndex(NULL),
      _jacobianALeadindex(NULL),
      _CV_y0(),
      _CV_y(),
      _CV_yp(),
      _CV_yWrite(),
      _CV_ypWrite(),
      _CV_absTol(),
      _bWritten(false),
      _zeroFound(false),
      _maxColors(0),
      _tLastWrite(-1.0),
      _jacobianANonzeros(0)
{
  _data = ((void*) this);
  #ifdef RUNTIME_PROFILING
  if(MeasureTime::getInstance() != NULL)
  {
      measureTimeFunctionsArray = new std::vector<MeasureTimeData*>(7, NULL); //0 calcFunction //1 solve ... //6 solver statistics
      (*measureTimeFunctionsArray)[0] = new MeasureTimeData("calcFunction");
      (*measureTimeFunctionsArray)[1] = new MeasureTimeData("solve");
      (*measureTimeFunctionsArray)[2] = new MeasureTimeData("writeOutput");
      (*measureTimeFunctionsArray)[3] = new MeasureTimeData("evaluateZeroFuncs");
      (*measureTimeFunctionsArray)[4] = new MeasureTimeData("initialize");
      (*measureTimeFunctionsArray)[5] = new MeasureTimeData("stepCompleted");
      (*measureTimeFunctionsArray)[6] = new MeasureTimeData("solverStatistics");

      MeasureTime::addResultContentBlock(system->getModelName(),"ida", measureTimeFunctionsArray);
      measuredFunctionStartValues = MeasureTime::getZeroValues();
      measuredFunctionEndValues = MeasureTime::getZeroValues();
      solveFunctionStartValues = MeasureTime::getZeroValues();
      solveFunctionEndValues = MeasureTime::getZeroValues();
      solverValues = new MeasureTimeValuesSolver();

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

Ida::~Ida()
{
  /*
  if (_z)
    delete[] _z;
  if (_zInit)
    delete[] _zInit;
  if (_zWrite)
      delete[] _zWrite;
*/
  if (_y)
    delete[] _y;
  if (_yp)
    delete[] _yp;
  if (_yInit)
    delete[] _yInit;
  if (_yWrite)
      delete[] _yWrite;
  if (_ypWrite)
      delete[] _ypWrite;
  if (_dae_res)
	  delete[] _dae_res;
  if (_zeroSign)
    delete[] _zeroSign;
  if (_absTol)
    delete[] _absTol;

  if (_ida_initialized)
  {
    N_VDestroy_Serial(_CV_y0);
    N_VDestroy_Serial(_CV_y);
    N_VDestroy_Serial(_CV_yp);
    N_VDestroy_Serial(_CV_yWrite);
    N_VDestroy_Serial(_CV_absTol);
    IDAFree(&_idaMem);
  }

  if (_colorOfColumn)
    delete [] _colorOfColumn;
  if(_delta)
    delete [] _delta;
  if(_deltaInv)
    delete [] _deltaInv;
  if(_ysave)
    delete [] _ysave;

  #ifdef RUNTIME_PROFILING
  if(measuredFunctionStartValues)
    delete measuredFunctionStartValues;
  if(measuredFunctionEndValues)
    delete measuredFunctionEndValues;
  if(solveFunctionStartValues)
    delete solveFunctionStartValues;
  if(solveFunctionEndValues)
    delete solveFunctionEndValues;
  if(solverValues)
    delete solverValues;
  #endif
}

void Ida::initialize()
{
  _properties = dynamic_cast<ISystemProperties*>(_system);
  _continuous_system = dynamic_cast<IContinuous*>(_system);
  _event_system = dynamic_cast<IEvent*>(_system);
  _mixed_system = dynamic_cast<IMixedSystem*>(_system);
  _time_system = dynamic_cast<ITime*>(_system);
  IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_idasettings)->getGlobalSettings();
  // Kennzeichnung, dass initialize()() (vor der Integration) aufgerufen wurde
  _idid = 5000;
  _tLastEvent = 0.0;
  _event_n = 0;
  SolverDefaultImplementation::initialize();

  _dimStates = _continuous_system->getDimContinuousStates();
  _dimZeroFunc = _event_system->getDimZeroFunc();
  _dimAE = _continuous_system->getDimAE();
   if(_dimAE>0)
		_dimSys=_dimAE+ _dimStates;
	else
		_dimSys=_dimStates;
  if (_dimStates <= 0)

  {
    _idid = -1;
    throw std::invalid_argument("Ida::initialize()");
  }
  else
  {
    // Allocate state vectors, stages and temporary arrays

   /*if (_z)
      delete[] _z;
    if (_zInit)
      delete[] _zInit;
    if (_zWrite)
      delete[] _zWrite;*/
    if (_y)
      delete[] _y;
    if (_yInit)
      delete[] _yInit;
    if (_yWrite)
      delete[] _yWrite;
    if (_ypWrite)
      delete[] _ypWrite;
    if (_yp)
      delete[] _yp;
    if (_dae_res)
      delete[] _dae_res;
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


	_y = new double[_dimSys];
	_yp = new double[_dimSys];
    _yInit = new double[_dimSys];
    _yWrite = new double[_dimSys];
	_ypWrite = new double[_dimSys];
	_dae_res = new double[_dimSys];
	/*
	_z = new double[_dimSys];
    _zInit = new double[_dimSys];
    _zWrite = new double[_dimSys];
	*/

    _zeroSign = new int[_dimZeroFunc];
    _absTol = new double[_dimSys];
    _delta =new double[_dimSys];
    _deltaInv =new double[_dimSys];
    _ysave =new double[_dimSys];

    memset(_y, 0, _dimSys * sizeof(double));
	memset(_yp, 0, _dimSys * sizeof(double));
    memset(_yInit, 0, _dimSys * sizeof(double));
    memset(_ysave, 0, _dimSys * sizeof(double));
	 std::fill_n(_absTol, _dimSys, 1.0);
    // Counter initialisieren
    _outStps = 0;

    if (_idasettings->getDenseOutput())
    {
      // Ausgabeschrittweite
      _hOut = global_settings->gethOutput();

    }

    // Allocate memory for the solver
    _idaMem = IDACreate();
    if (check_flag((void*) _idaMem, "IDACreate", 0))
    {
      _idid = -5;
      throw std::invalid_argument(/*_idid,_tCurrent,*/"Ida::initialize()");
    }

    //
    // Make Ida ready for integration
    //

    // Set initial values for IDA
    //_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
   _continuous_system->getContinuousStates(_yInit);
    memcpy(_y, _yInit, _dimStates * sizeof(double));
    if(_dimAE>0)
	{
       _mixed_system->getAlgebraicDAEVars(_yInit+_dimStates);
	    memcpy(_y+_dimStates, _yInit+_dimStates, _dimAE * sizeof(double));
	  _continuous_system->getContinuousStates(_yp);
	}
    // Get nominal values
	 _continuous_system->getNominalStates(_absTol);
    for (int i = 0; i < _dimStates; i++)
	    _absTol[i] = dynamic_cast<ISolverSettings*>(_idasettings)->getATol();

    _CV_y0 = N_VMake_Serial(_dimSys, _yInit);
    _CV_y = N_VMake_Serial(_dimSys, _y);
    _CV_yp = N_VMake_Serial(_dimSys, _yp);
    _CV_yWrite = N_VMake_Serial(_dimSys, _yWrite);
	_CV_ypWrite = N_VMake_Serial(_dimSys, _ypWrite);
    _CV_absTol = N_VMake_Serial(_dimSys, _absTol);

    if (check_flag((void*) _CV_y0, "N_VMake_Serial", 0))
    {
      _idid = -5;
      throw std::invalid_argument("Ida::initialize()");
    }

	//is already initialized: calcFunction(_tCurrent, NV_DATA_S(_CV_y0), NV_DATA_S(_CV_yp),NV_DATA_S(_CV_yp));

    // Initialize Ida (Initial values are required)
    _idid = IDAInit(_idaMem, rhsFunctionCB, _tCurrent, _CV_y0, _CV_yp);
    if (_idid < 0)
    {
      _idid = -5;
      throw std::invalid_argument("Ida::initialize()");
    }
	_idid = IDASetErrHandlerFn(_idaMem, errOutputIDA, _data);
	 if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");
    // Set Tolerances
    _idid = IDASVtolerances(_idaMem, dynamic_cast<ISolverSettings*>(_idasettings)->getRTol(), _CV_absTol);    // RTOL and ATOL
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");

    // Set the pointer to user-defined data
    _idid = IDASetUserData(_idaMem, _data);
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");

    _idid = IDASetInitStep(_idaMem, 1e-6);    // INITIAL STEPSIZE
    if (_idid < 0)
      throw std::invalid_argument("Ida::initialize()");


    _idid = IDASetMaxStep(_idaMem, global_settings->getEndTime() / 10.0);       // MAXIMUM STEPSIZE
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");

    _idid = IDASetMaxNonlinIters(_idaMem, 5);      // Max number of iterations
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");
    _idid = IDASetMaxErrTestFails(_idaMem, 100);
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");

    _idid = IDASetMaxNumSteps(_idaMem, 1e3);            // Max Number of steps
    if (_idid < 0)
      throw std::invalid_argument(/*_idid,_tCurrent,*/"IDA::initialize()");

    // Initialize linear solver
    _idid = IDADense(_idaMem, _dimSys);
    if (_idid < 0)
      throw std::invalid_argument("IDA::initialize()");
    if(_dimAE>0)
	{
	    _idid = IDASetSuppressAlg(_idaMem, TRUE);
        double* tmp = new double[_dimSys];
	    std::fill_n(tmp, _dimStates, 1.0);
	    std::fill_n(tmp+_dimStates, _dimAE, 0.0);
	   _idid = IDASetId(_idaMem, N_VMake_Serial(_dimSys,tmp));
	    delete [] tmp;
	    if (_idid < 0)
         throw std::invalid_argument("IDA::initialize()");
	}

  // Use own jacobian matrix
  //_idid = CVDlsSetDenseJacFn(_idaMem, &jacobianFunctionCB);
  //if (_idid < 0)
  //    throw std::invalid_argument("IDA::initialize()");

    if (_dimZeroFunc)
    {
      _idid = IDARootInit(_idaMem, _dimZeroFunc, &zeroFunctionCB);

      memset(_zeroSign, 0, _dimZeroFunc * sizeof(int));
      _idid = IDASetRootDirection(_idaMem, _zeroSign);
      if (_idid < 0)
        throw std::invalid_argument(/*_idid,_tCurrent,*/"IDA::initialize()");
      memset(_zeroSign, -1, _dimZeroFunc * sizeof(int));
      memset(_zeroVal, -1, _dimZeroFunc * sizeof(int));

    }


    _ida_initialized = true;

    //
    // IDA is ready for integration
    //
    // BOOST_LOG_SEV(ida_lg::get(), ida_info) << "IDA initialized";
  }
}

void Ida::solve(const SOLVERCALL action)
{
  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == OPT_ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);

  #ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(idaSolveFunctionHandler, "solve");
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_START(solveFunctionStartValues, idaSolveFunctionHandler, "solve");
  }
  #endif

  if (_idasettings && _system)
  {
    // Solver und System fÃ¼r Integration vorbereiten
    if ((action & RECORDCALL) && (action & FIRST_CALL))
    {
        #ifdef RUNTIME_PROFILING
        MEASURETIME_REGION_DEFINE(idaInitializeHandler, "IDAInitialize");
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_START(measuredFunctionStartValues, idaInitializeHandler, "IDAInitialize");
        }
        #endif

        initialize();

        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[4], idaInitializeHandler);
        }
        #endif

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
        writeIDAOutput(_tCurrent, _h, _locStps);
       _continuous_system->getContinuousStates(_y);
    }

    // Solver soll fortfahren
    _solverStatus = ISolver::CONTINUE;

    while ((_solverStatus & ISolver::CONTINUE) && !_interrupt )
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
        IDACore();

      }

      // Integration war nicht erfolgreich und wurde auch nicht vom User unterbrochen
      if (_idid != 0 && _idid != 1)
      {
        _solverStatus = ISolver::SOLVERERROR;
        //throw std::invalid_argument(_idid,_tCurrent,"IDA::solve()");
        throw std::invalid_argument("IDA::solve()");
      }

      // Abbruchkriterium (erreichen der Endzeit)
      else if ((_tEnd - _tCurrent) <= dynamic_cast<ISolverSettings*>(_idasettings)->getEndTimeTol())
        _solverStatus = DONE;
    }

    _firstCall = false;

  }
  else
  {

    throw std::invalid_argument("IDA::solve()");
  }

  #ifdef RUNTIME_PROFILING
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_END(solveFunctionStartValues, solveFunctionEndValues, (*measureTimeFunctionsArray)[1], idaSolveFunctionHandler);

      long int nst, nfe, nsetups, netf, nni, ncfn;
      int qlast, qcur;
      realtype h0u, hlast, hcur, tcur;

      int flag;

      flag = IDAGetIntegratorStats(_idaMem, &nst, &nfe, &nsetups, &netf, &qlast, &qcur, &h0u, &hlast, &hcur, &tcur);
      flag = IDAGetNonlinSolvStats(_idaMem, &nni, &ncfn);

      MeasureTimeValuesSolver solverVals = MeasureTimeValuesSolver(nfe, netf);
      (*measureTimeFunctionsArray)[6]->_sumMeasuredValues->_numCalcs += nst;
      (*measureTimeFunctionsArray)[6]->_sumMeasuredValues->add(&solverVals);
  }
  #endif
}
bool Ida::isInterrupted()
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
void Ida::IDACore()
{
  _idid = IDAReInit(_idaMem, _tCurrent, _CV_y,_CV_yp);
  _idid = IDASetStopTime(_idaMem, _tEnd);
  _idid = IDASetInitStep(_idaMem, 1e-12);
  if (_idid < 0)
    throw std::runtime_error("IDA::ReInit");

  bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == OPT_ALL);
  bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);

  while ((_solverStatus & ISolver::CONTINUE) && !_interrupt )
  {
    _cv_rt = IDASolve(_idaMem, _tEnd, &_tCurrent,  _CV_y, _CV_yp, IDA_ONE_STEP);

    _idid = IDAGetNumSteps(_idaMem, &_locStps);
    if (_idid != IDA_SUCCESS)
      throw std::runtime_error("IDAGetNumSteps failed. The ida mem pointer is NULL");

    _idid =IDAGetLastStep(_idaMem, &_h);
    if (_idid != IDA_SUCCESS)
      throw std::runtime_error("IDAGetLastStep failed. The ida mem pointer is NULL");

    //Check if there was at least one output-point within the last solver interval
    //  -> Write output if true
    if (writeOutput)
    {
        writeIDAOutput(_tCurrent, _h, _locStps);
    }

    #ifdef RUNTIME_PROFILING
    MEASURETIME_REGION_DEFINE(idaStepCompletedHandler, "IDAStepCompleted");
    if(MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_START(measuredFunctionStartValues, idaStepCompletedHandler, "IDAStepCompleted");
    }
    #endif

    //set completed step to system and check if terminate was called
    /*Todo: Replaced by isStepEvent
    if(_continuous_system->stepCompleted(_tCurrent))
        _solverStatus = DONE;
    */

    #ifdef RUNTIME_PROFILING
    if(MeasureTime::getInstance() != NULL)
    {
        MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[5], idaStepCompletedHandler);
    }
    #endif

    // Perform state selection
    bool state_selection = stateSelection();
    if (state_selection)
      _continuous_system->getContinuousStates(_y);

    _zeroFound = false;

    // Check if step was successful
    if (check_flag(&_cv_rt, "IDA", 1))
    {
      _solverStatus = ISolver::SOLVERERROR;
      break;
    }

    // A root was found
    if ((_cv_rt == IDA_ROOT_RETURN) && !isInterrupted())
    {
      // IDA is setting _tCurrent to the time where the first event occurred
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
        throw std::runtime_error("Number of events exceeded  in time interval " + to_string(_abs) + " at time " + to_string(_tCurrent));

      // IDA has interpolated the states at time 'tCurrent'
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
		if(_dimAE>0)
		{
			 _continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
        }
		else
		{
		    _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
		}
        writeToFile(0, _tCurrent, _h);
      }

      _idid = IDAGetRootInfo(_idaMem, _zeroSign);

      for (int i = 0; i < _dimZeroFunc; i++)
        _events[i] = bool(_zeroSign[i]);

      if (_mixed_system->handleSystemEvents(_events))
      {
        // State variables were reinitialized, thus we have to give these values to the ida-solver
        // Take care about the memory regions, _z is the same like _CV_y
        _continuous_system->getContinuousStates(_y);
        if(_dimAE>0)
		{
           _mixed_system->getAlgebraicDAEVars(_y+_dimStates);
		   _continuous_system->getRHS(_yp);
		}
		calcFunction(_tCurrent, NV_DATA_S(_CV_y), NV_DATA_S(_CV_yp),_dae_res);

      }
    }

    if ((_zeroFound || state_selection)&& !isInterrupted())
    {
      // Write the values of (P2)
      if (writeEventOutput)
      {
        // If we want to write the event-results, we should evaluate the whole system again
        if(_dimAE>0)
		{
			 _continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
        }
		else
		{
		    _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
		}
        writeToFile(0, _tCurrent, _h);
      }

      _idid = IDAReInit(_idaMem, _tCurrent, _CV_y,_CV_yp);
      if (_idid < 0)
        throw std::runtime_error("IDA::ReInit()");

      // Der Eventzeitpunkt kann auf der Endzeit liegen (Time-Events). In diesem Fall wird der Solver beendet, da IDA sonst eine interne Warnung schmeißt
      if (_tCurrent == _tEnd)
        _cv_rt = IDA_TSTOP_RETURN;
    }

    // ZÃ¤hler fÃ¼r die Anzahl der ausgegebenen Schritte erhÃ¶hen
    ++_outStps;
    _tLastSuccess = _tCurrent;

    if (_cv_rt == IDA_TSTOP_RETURN)
    {
      _time_system->setTime(_tEnd);
      _continuous_system->setContinuousStates(NV_DATA_S(_CV_y));
	  if(_dimAE>0)
	  {
	    _mixed_system->setAlgebraicDAEVars(NV_DATA_S(_CV_y)+_dimStates);
	    _continuous_system->setStateDerivatives(NV_DATA_S(_CV_yp));
		_continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
      }
	  else
	  {
		_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
      }
      if(writeOutput)
         writeToFile(0, _tEnd, _h);

      _accStps += _locStps;
      _solverStatus = DONE;
    }
  }
}
void Ida::setTimeOut(unsigned int time_out)
  {
       SimulationMonitor::setTimeOut(time_out);
  }
 void Ida::stop()
  {
       SimulationMonitor::stop();
  }
void Ida::writeIDAOutput(const double &time, const double &h, const int &stp)
{
  #ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(idaWriteOutputHandler, "IDAWriteOutput");
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_START(measuredFunctionStartValues, idaWriteOutputHandler, "IDAWriteOutput");
  }
  #endif

  if (stp > 0)
  {
    if (_idasettings->getDenseOutput())
    {
      _bWritten = false;
      double *oldValues = NULL;

      //We have to find all output-points within the last solver step
      while (_tLastWrite + dynamic_cast<ISolverSettings*>(_idasettings)->getGlobalSettings()->gethOutput() <= time)
      {
        if (!_bWritten)
        {
          //Rescue the calculated derivatives
          oldValues = new double[_continuous_system->getDimRHS()];
          _continuous_system->getRHS(oldValues);
        }
        _bWritten = true;
        _tLastWrite = _tLastWrite + dynamic_cast<ISolverSettings*>(_idasettings)->getGlobalSettings()->gethOutput();
        //Get the state vars at the output-point (interpolated)
        _idid = IDAGetDky(_idaMem, _tLastWrite, 0, _CV_yWrite);
        _time_system->setTime(_tLastWrite);
        _continuous_system->setContinuousStates(NV_DATA_S(_CV_yWrite));
		if(_dimAE>0)
		{
		   _mixed_system->setAlgebraicDAEVars(NV_DATA_S(_CV_y)+_dimStates);
		   _idid = IDAGetDky(_idaMem, _tLastWrite, 1, _CV_ypWrite);
		   _continuous_system->setStateDerivatives(NV_DATA_S(_CV_ypWrite));
		   _continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
        }
		else
		{
			_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
		}
        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[2], idaWriteOutputHandler);
        }
        #endif
        SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);
        #ifdef RUNTIME_PROFILING
        MEASURETIME_REGION_DEFINE(idaWriteOutputHandler, "IDAWriteOutput");
        if(MeasureTime::getInstance() != NULL)
        {
          (*measureTimeFunctionsArray)[2]->_sumMeasuredValues->_numCalcs--;
            MEASURETIME_START(measuredFunctionStartValues, idaWriteOutputHandler, "IDAWriteOutput");
        }
        #endif
      }      //end if time -_tLastWritten
      if (_bWritten)
      {
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(_y);
        _continuous_system->setStateDerivatives(oldValues);
		if(_dimAE>0)
		{
		   _mixed_system->setAlgebraicDAEVars(_y+_dimStates);
		}
        delete[] oldValues;

      }
      else if (time == _tEnd && _tLastWrite != time)
      {
        _idid = IDAGetDky(_idaMem, time, 0, _CV_y);
		_idid = IDAGetDky(_idaMem, time, 1, _CV_yp);
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(NV_DATA_S(_CV_y));
		if(_dimAE>0)
		{
		   _mixed_system->setAlgebraicDAEVars(NV_DATA_S(_CV_y)+_dimStates);
		   _continuous_system->setStateDerivatives(NV_DATA_S(_CV_yp));
		   _continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
        }
		else
		{
		   _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
		}
        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[2], idaWriteOutputHandler);
        }
        #endif
        SolverDefaultImplementation::writeToFile(stp, _tEnd, h);
      }
    }
    else
    {
        #ifdef RUNTIME_PROFILING
        if(MeasureTime::getInstance() != NULL)
        {
            MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[2], idaWriteOutputHandler);
        }
        #endif
        SolverDefaultImplementation::writeToFile(stp, time, h);
    }
  }
}

bool Ida::stateSelection()
{
  return SolverDefaultImplementation::stateSelection();
}
int Ida::calcFunction(const double& time, const double* y, double *yp,double* res)
{
  #ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(idaCalcFunctionHandler, "IDACalcFunction");
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_START(measuredFunctionStartValues, idaCalcFunctionHandler, "IDACalcFunction");
  }
  #endif

  int returnValue = 0;
  try
  {
    if(_dimAE>0)
	{
	   _time_system->setTime(time);
      _continuous_system->setContinuousStates(y);
	  _continuous_system->setStateDerivatives(yp);
	  _mixed_system->setAlgebraicDAEVars(y+_dimStates);
	  _continuous_system->evaluateDAE(IContinuous::CONTINUOUS);
	  _mixed_system->getResidual(res);

	}
	else
	{
	  _time_system->setTime(time);
      _continuous_system->setContinuousStates(y);
      _continuous_system->evaluateODE(IContinuous::CONTINUOUS);
      _continuous_system->getRHS(res);
	  for(size_t i(0); i<_dimSys; ++i)
		   res[i]-=yp[i];

	}
  }      //workaround until exception can be catch from c- libraries
  catch (std::exception& ex)
  {
    std::string error = ex.what();
    cerr << "IDA integration error: " << error;
    returnValue = -1;
  }

  #ifdef RUNTIME_PROFILING
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[0], idaCalcFunctionHandler);
  }
  #endif

  return returnValue;
}

int Ida::rhsFunctionCB(double t, N_Vector y, N_Vector ydot, N_Vector resval, void *user_data)
{

  int status = ((Ida*) user_data)->calcFunction(t, NV_DATA_S(y), NV_DATA_S(ydot),NV_DATA_S(resval));

  return status;
}

void Ida::giveZeroVal(const double &t, const double *y,const double *yp,double *zeroValue)
{
  #ifdef RUNTIME_PROFILING
  MEASURETIME_REGION_DEFINE(idaEvalZeroHandler, "evaluateZeroFuncs");
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_START(measuredFunctionStartValues, idaEvalZeroHandler, "evaluateZeroFuncs");
  }
  #endif

  _time_system->setTime(t);
  _continuous_system->setContinuousStates(y);
   if(_dimAE>0)
   {
	 _mixed_system->setAlgebraicDAEVars(y+_dimStates);
	 _continuous_system->setStateDerivatives(yp);
   }
  // System aktualisieren
  _continuous_system->evaluateZeroFuncs(IContinuous::DISCRETE);

  _event_system->getZeroFunc(zeroValue);

  #ifdef RUNTIME_PROFILING
  if(MeasureTime::getInstance() != NULL)
  {
      MEASURETIME_END(measuredFunctionStartValues, measuredFunctionEndValues, (*measureTimeFunctionsArray)[3], idaEvalZeroHandler);
  }
  #endif
}

int Ida::zeroFunctionCB(double t, N_Vector y, N_Vector yp, double *zeroval, void *user_data)
{
  ((Ida*) user_data)->giveZeroVal(t, NV_DATA_S(y),NV_DATA_S(yp), zeroval);

  return (0);
}

int Ida::jacobianFunctionCB(long int N, double t, N_Vector y, N_Vector fy, DlsMat Jac,void *user_data, N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  return ((Ida*) user_data)->calcJacobian(t,N, tmp1, tmp2, tmp3,  NV_DATA_S(y), fy, Jac);

}


int Ida::calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthCol, double* y, N_Vector fy, DlsMat Jac)
{
  try
  {
  int l,g;
  double fnorm, minInc, *f_data, *fHelp_data, *errorWeight_data, h, srur, delta_inv;

  f_data = NV_DATA_S(fy);
  errorWeight_data = NV_DATA_S(errorWeight);
  fHelp_data = NV_DATA_S(fHelp);


  //Get relevant info
  _idid = IDAGetErrWeights(_idaMem, errorWeight);
  if (_idid < 0)
    {
      _idid = -5;
      throw std::invalid_argument("IDA::calcJacobian()");
  }
  _idid = IDAGetCurrentStep(_idaMem, &h);
  if (_idid < 0)
    {
      _idid = -5;
      throw std::invalid_argument("IDA::calcJacobian()");
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

  // Calculation of the jacobian

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

    calcFunction(t, y, fHelp_data,fHelp_data);

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

 }      //workaround until exception can be catch from c- libraries
  catch (std::exception& ex)
  {
    std::string error = ex.what();
    cerr << "IDA integration error: " << error;
    return 1;
  }


  return 0;
}



int Ida::reportErrorMessage(ostream& messageStream)
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

void Ida::writeSimulationInfo()
{
  long int nst, nfe, nsetups, nni, ncfn, netf;
  long int nfQe, netfQ;
  long int nfSe, nfeS, nsetupsS, nniS, ncfnS, netfS;
  long int nfQSe, netfQS;

  int qlast, qcur;
  realtype h0u, hlast, hcur, tcur;

  int flag;

  flag = IDAGetIntegratorStats(_idaMem, &nst, &nfe, &nsetups, &netf, &qlast, &qcur, &h0u, &hlast, &hcur, &tcur);

  flag = IDAGetNonlinSolvStats(_idaMem, &nni, &ncfn);

  LOGGER_WRITE("IDA: number steps = " + to_string(nst), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("IDA: function evaluations 'f' = " + to_string(nfe), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("IDA: error test failures 'netf' = " + to_string(netfS), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("IDA: linear solver setups 'nsetups' = " + to_string(nsetups), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("IDA: nonlinear iterations 'nni' = " + to_string(nni), LC_SOLVER, LL_INFO);
  LOGGER_WRITE("IDA: convergence failures 'ncfn' = " + to_string(ncfn), LC_SOLVER, LL_INFO);
}

int Ida::check_flag(void *flagvalue, const char *funcname, int opt)
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


void Ida::errOutputIDA(int error_code, const char *module, const char *function,
    char *msg, void *userData)
{

  cout << "#### IDA error message #####";
  cout << " -> error code" << error_code << "in module" << module << " and function " << function;
  cout << " Message: " << msg;

}
