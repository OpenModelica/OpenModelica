#include <Solver/CppDASSL/CppDASSL.h>
#include <Core/Math/Functions.h>
//#include <Core/Math/ILapack.h>
#include <fstream>
#include <iomanip>

#if defined(USE_OPENMP)
#include "omp.h"
#include <Core/Utils/numeric/bindings/umfpack/umfpack.hpp>
#include <Core/Utils/numeric/bindings/ublas/vector.hpp>
#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <boost/numeric/ublas/io.hpp>

CppDASSL::CppDASSL(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings),
      _cppdasslsettings(dynamic_cast<ISolverSettings*>(_settings)),
      _continuous_systems(),
      _time_systems(),
      _event_system(),
      _mixed_systems(),
      _state_selections(),
      _jroot(NULL),
      _matrix(),
      _hOut(0.0)
/*      _cvodeMem(NULL),
      _z(NULL),
      _zInit(NULL),
      _zWrite(NULL),
      _dimSys(0),
      _cv_rt(0),
      _outStps(0),
      _locStps(0),
      _idid(0),
      _hOut(0.0),
      _tOut(0.0),
      _tZero(0.0),
      _zeroSign(NULL),
      _absTol(NULL),
      _cvode_initialized(false),
      _tLastEvent(0.0),
      _event_n(0),
      _properties(NULL),
      _continuous_system(NULL),
      _event_system(NULL),
      _mixed_system(NULL),
      _time_system(NULL),
    _delta(NULL),
    _ysave(NULL) */
{
  _data = ((void*) this);
}

CppDASSL::~CppDASSL()
{
  if (_y)
    delete [] _y;
  if (_yp)
    delete [] _yp;
  for(size_t i = 1; i < _continuous_systems.size(); i++)
    delete _continuous_systems[i];
}

void CppDASSL::initialize()
{
    std::cout<<std::fixed<<std::setprecision(16);
    SolverDefaultImplementation::initialize();
    IContinuous *continuous_system = dynamic_cast<IContinuous*>(_system);
    ITime *time_system =  dynamic_cast<ITime*>(_system);
    _numThreads=_cppdasslsettings->getGlobalSettings()->getSolverThreads();
    dasslSolver.setNumThreads(_numThreads);
    _continuous_systems = vector<IContinuous*>(size_t(_numThreads), NULL);
    _time_systems = vector<ITime*>(size_t(_numThreads), NULL);
    _mixed_systems = vector<IMixedSystem*>(size_t(_numThreads), NULL);
    _state_selections=vector<IStateSelection*>(size_t(_numThreads), NULL);
    _continuous_systems[0] = continuous_system;
    _time_systems[0] = time_system;
    _event_system = dynamic_cast<IEvent*>(_system);
    _mixed_systems[0] = dynamic_cast<IMixedSystem*>(_system);
    _state_selections[0] = dynamic_cast<IStateSelection*>(_system);
    _dimSys = _continuous_systems[0]->getDimContinuousStates();
    _states = new double[_dimSys];

    for(int i = 1; i < _numThreads; i++)
    {
        IMixedSystem* clonedSystem = _system->clone();
        _continuous_systems[i] = dynamic_cast<IContinuous*>(clonedSystem);
        _time_systems[i] = dynamic_cast<ITime*>(clonedSystem);
        _mixed_systems[i] = dynamic_cast<IMixedSystem*>(clonedSystem);
        _state_selections[i] = dynamic_cast<IStateSelection*>(clonedSystem);
        ISystemInitialization *initSystem = dynamic_cast<ISystemInitialization*>(clonedSystem);
        initSystem->setInitial(true);
        initSystem->initialize();
        initSystem->setInitial(false);

        for(size_t j=0; j<_state_selections[0]->getDimStateSets(); ++j) {
            _state_selections[0]->getAMatrix(j,_matrix);
            _state_selections[0]->getStates(j,_states);
            _state_selections[i]->setAMatrix(j,_matrix);
            _state_selections[i]->setStates(j,_states);
        }
    }

    IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_cppdasslsettings)->getGlobalSettings();
    _hOut = global_settings->gethOutput();
    std::cout<<"Using output step size "<<_hOut<<std::endl;
    _dimZeroFunc = _event_system->getDimZeroFunc();
    _y = new double[_dimSys];
    _yp = new double[_dimSys];
    for(int i=0; i<_numThreads; ++i) {

        _continuous_systems[i]->evaluateAll(IContinuous::ALL);
        _continuous_systems[i]->getContinuousStates(_y);
        _continuous_systems[i]->setContinuousStates(_y);
    }
// begin analyzation mode
    _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
    _continuous_systems[0]->getRHS(_yp);

    int _countnz=0;
    double delta=1e-6;
    double* _yphelp=new double[_dimSys];
    _time_systems[0]->setTime(_tCurrent);
    for(int i=0; i<_dimSys; ++i) {
        double _ysave;
        _ysave=_y[i];
        _y[i]+=delta;
        _continuous_systems[0]->setContinuousStates(_y);
        _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
        _continuous_systems[0]->getRHS(_yphelp);
        for(int j=0; j<_dimSys; ++j) {
            if(_yphelp[j]-_yp[j]>1e-12) {
                _countnz++;
            }
        }
        if(_countnz>_dimSys*_dimSys/100) {
            dasslSolver.setSparse(false);
            break;
        }
        _y[i]=_ysave;
    }
    if(_countnz<_dimSys*_dimSys/100) {
        dasslSolver.setSparse(true);
        std::cout<<"Using sparse solver!"<<std::endl;
    }
            //double* reals=new double[_continuous_systems[0]->getDimReal()];
    dasslSolver.setDenseOutput(true);
    dasslSolver.setATol(dynamic_cast<ISolverSettings*>(_cppdasslsettings)->getATol());
    dasslSolver.setRTol(dynamic_cast<ISolverSettings*>(_cppdasslsettings)->getRTol());
    dasslSolver.setReverseJacobi(false);
    delete [] _yphelp;
}



void CppDASSL::solve(const SOLVERCALL action)
{
    bool writeEventOutput = (_settings->getGlobalSettings()->getOutputPointType() == OPT_ALL);
    bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);
    double t,tend;
    if ((action & RECORDCALL) && (action & FIRST_CALL)) {
        initialize();
        return;
    }

    if (action & RECALL)
    {
        writeToFile(0, _tCurrent, _h);
        _continuous_systems[0]->getContinuousStates(_y);
    }
  // Initialization phase
    t=_tCurrent;

    _time_systems[0]->setTime(t);
    _continuous_systems[0]->setContinuousStates(_y);
    if(writeOutput) {
        tend=_tCurrent+_hOut;
        _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
        SolverDefaultImplementation::writeToFile(0, t, _h);
    } else {
        tend=_tEnd;
    }
    _continuous_systems[0]->getRHS(_yp);

    bool state_selection;
    if(!_dimZeroFunc) {
        int idid=dasslSolver.solve(&res,_dimSys,t,&_y[0],&_yp[0],tend,_data,NULL,NULL,NULL,_dimZeroFunc,NULL,false);
        /*Todo: replaced by stepCompleted
        for(int i=0; i<_numThreads; ++i) _continuous_systems[i]->stepCompleted(t);
        */
        state_selection = stateSelection();
        if (state_selection) {
            _continuous_systems[0]->getContinuousStates(_y);
            _continuous_systems[0]->setContinuousStates(_y);
            _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
            _continuous_systems[0]->getRHS(_yp);
        }
        while(idid==-1 || idid==1 || (writeOutput && idid>1)) {
            _time_systems[0]->setTime(t);
            _continuous_systems[0]->setContinuousStates(_y);
            if(writeOutput) {
                if(t>=tend) {
                    if(t>=_tEnd) {
                        break;
                    } else {
                        if (t+_hOut>=_tEnd) {
                            tend=_tEnd;
                        } else {
                            tend+=_hOut;
                        }
                    }
                    _continuous_systems[0]->evaluateAll(IContinuous::ALL);
                    SolverDefaultImplementation::writeToFile(0, t, _h);
                }

            }

            idid=dasslSolver.solve(&res,_dimSys,t,&_y[0],&_yp[0],tend,_data,NULL,NULL,NULL,_dimZeroFunc,NULL,true);
            /*Todo: Replaced by stepCompleted
            _continuous_systems[0]->stepCompleted(t);
            */
            state_selection = stateSelection();
            if (state_selection) {
                _continuous_systems[0]->getContinuousStates(_y);
                _continuous_systems[0]->setContinuousStates(_y);
                _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
                _continuous_systems[0]->getRHS(_yp);
            }
        }
    } else {
        if(_jroot) delete [] _jroot;
        _jroot=new int[_dimZeroFunc];
        int idid=dasslSolver.solve(&res,_dimSys,t,&_y[0],&_yp[0],_tEnd,_data,NULL,NULL,&zeroes,_dimZeroFunc,_jroot,false);
        #pragma omp parallel for num_threads(_numThreads)
        for(int i=0; i<_numThreads; ++i) {
            _continuous_systems[i]->setContinuousStates(_y);
            //_continuous_systems[i]->evaluateODE(IContinuous::ALL);
            /*Todo: Replaced by stepCompleted
            _continuous_systems[i]->stepCompleted(t);
            */
        }
        state_selection = stateSelection();
        if (state_selection) {
            for(size_t i = 0; i < _state_selections[0]->getDimStateSets(); i++)
            {
              _state_selections[0]->getAMatrix(i,_matrix);
              _state_selections[0]->getStates(i,_states);
              for(int j=1; j<_numThreads; ++j) {
                _state_selections[j]->setAMatrix(i,_matrix);
                _state_selections[j]->setStates(i,_states);
              }
            }
//            for(int i=1; i<_numThreads; ++i) {
//                    _continuous_system[i]->setContinuousStates(_y);
//                    _system_state_selection[i-1]->stateSelection(1);
//                }
            _continuous_systems[0]->getContinuousStates(_y);
            for(int i=1; i<_numThreads; ++i) {
                _continuous_systems[i]->setContinuousStates(_y);
            }
            _continuous_systems[0]->setContinuousStates(_y);
            _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
            _continuous_systems[0]->getRHS(_yp);
        }
        if(idid==5) {
            _time_systems[0]->setTime(t);
            _continuous_systems[0]->setContinuousStates(_y);
            _continuous_systems[0]->evaluateAll(IContinuous::ALL);
            SolverDefaultImplementation::writeToFile(0, t, _h);
            for (int i = 0; i < _dimZeroFunc; i++) _events[i] = bool(_jroot[i]);
            for(int i=1; i<_numThreads; ++i) {
                _continuous_systems[i]->setContinuousStates(_y);
                _mixed_systems[i]->handleSystemEvents(_events);
            }
            if (_mixed_systems[0]->handleSystemEvents(_events))
              {
                _continuous_systems[0]->getContinuousStates(_y);
                _continuous_systems[0]->setContinuousStates(_y);
                _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
                _continuous_systems[0]->getRHS(_yp);
              }

        }
        int run=2;
        while(idid==-1 || idid==5 || idid==1 || (writeOutput && idid>1)) {
            _time_systems[0]->setTime(t);
            _continuous_systems[0]->setContinuousStates(_y);
            if(writeOutput) {
                if(t>=tend) {
                    if(t>=_tEnd) {
                        break;
                    } else {
                        if (t+_hOut>=_tEnd) {
                            tend=_tEnd;
                        } else {
                            tend+=_hOut;
                        }
                    }
                    _continuous_systems[0]->evaluateAll(IContinuous::ALL);
                    SolverDefaultImplementation::writeToFile(0, t, _h);
                }

            }
            if(idid==5 || state_selection ) {
                idid=dasslSolver.solve(&res,_dimSys,t,&_y[0],&_yp[0],tend,_data,NULL,NULL,&zeroes,_dimZeroFunc,_jroot,false);
            } else {
                idid=dasslSolver.solve(&res,_dimSys,t,&_y[0],&_yp[0],tend,_data,NULL,NULL,&zeroes,_dimZeroFunc,_jroot,true);
            }
            #pragma omp parallel for num_threads(_numThreads)
            for(int i=0; i<_numThreads; ++i) {
                _continuous_systems[i]->setContinuousStates(_y);
                //_continuous_systems[i]->evaluateODE(IContinuous::ALL);
                /*Todo: Replaced by stepCompleted
               _continuous_systems[i]->stepCompleted(t);
               */
            }
            state_selection = stateSelection();
            run++;
            if (state_selection) {
                for(size_t i = 0; i < _state_selections[0]->getDimStateSets(); i++)
                {
                  _state_selections[0]->getAMatrix(i,_matrix);
                  _state_selections[0]->getStates(i,_states);
                  for(int j=1; j<_numThreads; ++j) {
                    _state_selections[j]->setAMatrix(i,_matrix);
                    _state_selections[j]->setStates(i,_states);
                  }
                }
                _continuous_systems[0]->getContinuousStates(_y);
                for(int i=1; i<_numThreads; ++i) {
                    _continuous_systems[i]->setContinuousStates(_y);
                }
                _continuous_systems[0]->setContinuousStates(_y);
                _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
                _continuous_systems[0]->getRHS(_yp);
            }
;
            if(idid==5) {
                _time_systems[0]->setTime(t);
                _continuous_systems[0]->setContinuousStates(_y);
                _continuous_systems[0]->evaluateAll(IContinuous::ALL);
                SolverDefaultImplementation::writeToFile(0, t, _h);
                for (int i = 0; i < _dimZeroFunc; i++) _events[i] = bool(_jroot[i]);
                for(int i=1; i<_numThreads; ++i) {
                    _continuous_systems[i]->setContinuousStates(_y);
                    _mixed_systems[i]->handleSystemEvents(_events);
                }
                if (_mixed_systems[0]->handleSystemEvents(_events))
                  {
                    _continuous_systems[0]->getContinuousStates(_y);
                    _continuous_systems[0]->setContinuousStates(_y);
                    _continuous_systems[0]->evaluateODE(IContinuous::ALL);    // vxworksupdate
                    _continuous_systems[0]->getRHS(_yp);
                  }

            }
        }

    }
    _tCurrent=_tEnd;
    if(writeOutput) {
        _time_systems[0]->setTime(_tCurrent);
        _continuous_systems[0]->setContinuousStates(_y);
        _continuous_systems[0]->evaluateAll(IContinuous::ALL);
        SolverDefaultImplementation::writeToFile(0, t, _h);
    }
    _solverStatus = ISolver::DONE;
}



void CppDASSL::writeCppDASSLOutput(const double &time, const double &h, const int &stp)
{
  /*
  if (stp > 0)
  {
    if (_cvodesettings->getDenseOutput())
    {
      _bWritten = false;
      double *oldValues = NULL;

      //We have to find all output-points within the last solver step
      while (_tLastWrite + dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput() <= time)
      {
        if (!_bWritten)
        {
          //Rescue the calculated derivatives
          oldValues = new double[_continuous_system->getDimRHS()];
          _continuous_system->getRHS(oldValues);
        }
        _bWritten = true;
        _tLastWrite = _tLastWrite + dynamic_cast<ISolverSettings*>(_cvodesettings)->getGlobalSettings()->gethOutput();
        //Get the state vars at the output-point (interpolated)
        _idid = CVodeGetDky(_cvodeMem, _tLastWrite, 0, _CV_yWrite);
        _time_system->setTime(_tLastWrite);
        _continuous_system->setContinuousStates(NV_DATA_S(_CV_yWrite));
        _continuous_system->evaluateAll(IContinuous::CONTINUOUS);
        SolverDefaultImplementation::writeToFile(stp, _tLastWrite, h);
      }      //end if time -_tLastWritten
      if (_bWritten)
      {
        _time_system->setTime(time);
        _continuous_system->setContinuousStates(_z);
        _continuous_system->setStateDerivatives(oldValues);
        delete[] oldValues;
        //_continuous_system->evaluateAll(IContinuous::CONTINUOUS);
      }
      else if (time == _tEnd && _tLastWrite != time)
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
  */
}

int CppDASSL::res(const double* t, const double* y, const double* yprime, double* cj, double* delta, int* ires, void *par) {
    return ((CppDASSL*) par)->calcFunction(t, y, yprime, cj, delta, ires);
}

int CppDASSL::calcFunction(const double* t, const double* y, const double* yprime, double* cj, double* delta, int* ires) {
    int numThread=omp_get_thread_num();
    _time_systems[numThread]->setTime(*t);
    _continuous_systems[numThread]->setContinuousStates(y);
    _continuous_systems[numThread]->evaluateODE(IContinuous::ALL);    // vxworksupdate
    _continuous_systems[numThread]->getRHS(delta);
    for(int i=0; i<_dimSys; ++i) delta[i]=yprime[i]-delta[i];
    return 0;
}

int CppDASSL::zeroes(const int* NEQ, const double* T, const double* Y, const double* YP, int* NRT, double* RVAL, void *par)
{
  ((CppDASSL*) par)->giveZeroVal(*T, Y, RVAL);

  return (0);
}


void CppDASSL::giveZeroVal(const double &t, const double *y, double *zeroValue)
{
  _time_systems[0]->setTime(t);
  _continuous_systems[0]->setContinuousStates(y);

  // System aktualisieren
  _continuous_systems[0]->evaluateZeroFuncs(IContinuous::DISCRETE);
  _event_system->getZeroFunc(zeroValue);
}

bool CppDASSL::stateSelection()
{
  return SolverDefaultImplementation::stateSelection();
}

void CppDASSL::setTimeOut(unsigned int time_out)
  {
       SimulationMonitor::setTimeOut(time_out);
  }
 void CppDASSL::stop()
  {
       SimulationMonitor::stop();
  }


//void CppDASSL::setcycletime(double cycletime){}
void CppDASSL::writeSimulationInfo(){}
int CppDASSL::reportErrorMessage(std::ostream& messageStream) {
    return 0;
}
#endif
