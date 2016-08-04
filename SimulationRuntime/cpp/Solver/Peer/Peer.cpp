#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Core/Math/Functions.h>
#include <Core/Math/ILapack.h>
#include <Solver/Peer/Peer.h>

#if defined(USE_MPI) || defined(USE_OPENMP)

#ifdef MPIPEER
#include "mpi.h"
#else
#include "omp.h"
#endif

Peer::Peer(IMixedSystem* system, ISolverSettings* settings)
    : SolverDefaultImplementation(system, settings),
      _peersettings(dynamic_cast<ISolverSettings*>(_settings)),
      _h(1e-4),
      _continuous_system(),
      _time_system(),
      _hOut(0.0),
      _reuseJacobi(5000)
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
  //_data = ((void*) this);
}

Peer::~Peer()
{
  if (_G)
    delete [] _G;
  if (_E)
    delete [] _E;
  if (_Theta)
    delete [] _Theta;
  if (_c)
    delete [] _c;
  if (_F)
    delete [] _F;
  if (_Y1)
    delete [] _Y1;
  if (_Y2)
    delete [] _Y2;
  if (_Y3)
    delete [] _Y3;
  if (_T)
    delete [] _T;
  if (_P)
    delete [] _P;
  if (_y)
    delete [] _y;

#ifndef MPIPEER
  for(int i = 1; i < 5; i++)
  {
    delete _continuous_system[i];
    _continuous_system[i] = NULL;
    _time_system[i] = NULL;
    }
#endif
}

void Peer::initialize()
{
    IContinuous *continuous_system = dynamic_cast<IContinuous*>(_system);
    ITime *time_system =  dynamic_cast<ITime*>(_system);
    IGlobalSettings* global_settings = dynamic_cast<ISolverSettings*>(_peersettings)->getGlobalSettings();
    _numThreads=_peersettings->getGlobalSettings()->getSolverThreads();
    _hOut = global_settings->gethOutput();
#ifdef MPIPEER
    MPI_Comm_size(MPI_COMM_WORLD, &_size);
    if(_size>=5) {
        _size=5;
    } else {
        throw ModelicaSimulationError(SOLVER,"Peer::MPI initialization error");
    }
    MPI_Comm_rank(MPI_COMM_WORLD, &_rank);

    for(int i = 0; i < 5; i++)
    {
        _continuous_system[i] = continuous_system;
        _time_system[i] = time_system;
    }
#else
    _time_system[0] = time_system;
    _continuous_system[0] = continuous_system;

    for(int i = 1; i < 5; i++)
    {
        IMixedSystem* clonedSystem = _system->clone();
        _continuous_system[i] = dynamic_cast<IContinuous*>(clonedSystem);
        _time_system[i] = dynamic_cast<ITime*>(clonedSystem);
        dynamic_cast<ISystemInitialization*>(clonedSystem)->initialize();
    }
#endif //MPIPEER
    SolverDefaultImplementation::initialize();
    _dimSys = _continuous_system[0]->getDimContinuousStates();
    _rstages = 5;

    _G=new double[5];
    _G[0]=0.0681;
    _G[1]=0.1855545484594073;
    _G[2]=0.3756;
    _G[3]=0.5656454515405926;
    _G[4]=0.6831;

    _E=new double[25];
    _E[0]=-4.73606797749979e+00;
    _E[1]=6.85410196624968e+00;
    _E[2]=-3.23606797749979e+00;
    _E[3]=1.61803398874989e+00;
    _E[4]=-0.5;
    _E[5]=-1;
    _E[6]=-4.27050983124845e-01;
    _E[7]=2.;
    _E[8]=-8.09016994374946e-01;
    _E[9]=2.36067977499789e-01;
    _E[10]=3.09016994374947e-01;
    _E[11]=-1.30901699437495e+00;
    _E[12]=2.69090356243347e-15;
    _E[13]=1.30901699437495e+00;
    _E[14]=-3.09016994374947e-01;
    _E[15]=-2.36067977499789e-01;
    _E[16]=8.09016994374947e-01;
    _E[17]=-2.;
    _E[18]=4.27050983124842e-01;
    _E[19]=1.;
    _E[20]=0.5;
    _E[21]=-1.61803398874990e+00;
    _E[22]=3.23606797749979e+00;
    _E[23]=-6.85410196624968e+00;
    _E[24]=4.73606797749979e+00;

    _Theta=new double[25];
    _Theta[0]=0.;
    _Theta[1]=0.;
    _Theta[2]=1.;
    _Theta[3]=0.;
    _Theta[4]=0.;
    _Theta[5]=0.045084971874737;
    _Theta[6]=-0.163118960624632;
    _Theta[7]=0.527864045000421;
    _Theta[8]=0.690983005625053;
    _Theta[9]=-0.100813061875578;
    _Theta[10]=0.;
    _Theta[11]=0.;
    _Theta[12]=0.;
    _Theta[13]=0.;
    _Theta[14]=1.;
    _Theta[15]=1.809016994374949;
    _Theta[16]=-5.545084971874742;
    _Theta[17]=9.472135954999576;
    _Theta[18]=-12.399186938124409;
    _Theta[19]=7.663118960624626;
    _Theta[20]=5.854101966249686;
    _Theta[21]=-17.562305898749063;
    _Theta[22]=28.416407864998732;
    _Theta[23]=-33.270509831248397;
    _Theta[24]=17.562305898749038;

    _c=new double[5];
    _c[0]=-1.;
    _c[1]=-6.18033988749895e-01;
    _c[2]=0.;
    _c[3]=6.18033988749895e-01;
    _c[4]=1.;

    _h = std::max(std::min(_h, _peersettings->getUpperLimit()), _peersettings->getLowerLimit());
    _y = new double[_dimSys];

#ifdef MPIPEER
    _F=new double[_dimSys];
    _T=new double[_dimSys*_dimSys];
    _P=new long int[_dimSys];
    if(_rank==0) {
        _Y1=new double[_dimSys*_rstages];
        _Y2=new double[_dimSys*_rstages];
        _Y3=new double[_dimSys*_rstages];
    } else {
        _Y1=new double[_dimSys];
        _Y2=new double[_dimSys];
        _Y3=new double[_dimSys];
    }
#else
    _F=new double[_dimSys*5];
    _T=new double[_dimSys*_dimSys*5];
    _P=new long int[_dimSys*5];
    _Y1=new double[_dimSys*_rstages];
    _Y2=new double[_dimSys*_rstages];
    _Y3=new double[_dimSys*_rstages];
#endif

    _continuous_system[0]->evaluateAll(IContinuous::ALL);
    _continuous_system[0]->getContinuousStates(_y);
}

void Peer::evalJ(const double& t, const double* y, double* T, IContinuous *continuousSystem, ITime *timeSystem, double factor)
{
    double* f=new double[_dimSys];
    double* fh=new double[_dimSys];
    double* z=new double[_dimSys];
    std::copy(y,y+_dimSys,z);
    evalF(t, z, f, continuousSystem, timeSystem);
    for(int j=0; j<_dimSys; ++j)
    {
        // reset m_pYhelp for every colum

        z[j] += 1e-8;

        // delta_f berechnen
        evalF(t, z, fh, continuousSystem, timeSystem);

        // Jacobimatrix aufbauen
        for(int i=0; i<_dimSys; ++i)
        {
            T[i+j*_dimSys] = factor*(fh[i] - f[i]) / 1e-8;
        }
        z[j] -= 1e-8;
    }
    delete [] f;
    delete [] fh;
    delete [] z;
}

void Peer::evalD(const double& t, const double* y, double* T, IContinuous *continuousSystem, ITime *timeSystem)
{
    double* f=new double[_dimSys];
    double* fh=new double[_dimSys];
    evalF(t, y, f, continuousSystem, timeSystem);
    evalF(t+1e-6,y,fh,continuousSystem, timeSystem);
    for(int j=0; j<_dimSys; ++j)
    {
            T[j] = (fh[j] - f[j]) / 1e-6;
    }
    delete [] f;
    delete [] fh;
}

void Peer::evalF(const double& t, const double* z, double* f, IContinuous *continuousSystem, ITime *timeSystem)
{

    timeSystem->setTime(t);
    continuousSystem->setContinuousStates(z);
    continuousSystem->evaluateODE(IContinuous::ALL);    // vxworksupdate
    continuousSystem->getRHS(f);
}

void Peer::ros2(double * y, double& tstart, double tend, IContinuous *continuousSystem, ITime *timeSystem) {
    double *T=new double[_dimSys*_dimSys];
    double *D=new double[_dimSys];
    double *k1=new double[_dimSys];
    double *k2=new double[_dimSys];
    long int *P=new long int[_dimSys];
    long int info;
    long int dim=1;
    double t=tstart;
    const double gamma=1.-sqrt(2.)/2.;
    char trans='N';
    double hu=(tend-tstart)/10.;
    for(int count=0; count<10; ++count) {
        evalJ(t,y,T,continuousSystem, timeSystem,-hu*gamma);
        for(int i=0; i<_dimSys;++ i) T[i*_dimSys+i]+=1.;
        dgetrf_(&_dimSys, &_dimSys, T, &_dimSys, P, &info);
        evalF(t,y,k1,continuousSystem, timeSystem);
        evalD(t,y,D,continuousSystem, timeSystem);
        for(int i=0; i<_dimSys;++ i) k1[i]+=gamma*hu*D[i];
        dgetrs_(&trans, &_dimSys, &dim, T, &_dimSys, P, k1, &_dimSys, &info);
        for(int i=0; i<_dimSys;++ i) y[i]+=hu*k1[i];
        evalF(t,y,k2,continuousSystem, timeSystem);
        for(int i=0; i<_dimSys;++ i)  k2[i]+= hu*gamma*D[i]-2.*k1[i];
        dgetrs_(&trans, &_dimSys, &dim, T, &_dimSys, P, k2, &_dimSys, &info);
        for(int i=0; i<_dimSys;++ i) y[i]+=0.5*hu*(k1[i]+k2[i]);
    }
}

void Peer::solve(const SOLVERCALL action)
{
    double twrite=_hOut;
    if ((action & RECORDCALL) && (action & FIRST_CALL)) {
        initialize();
        return;
    }
    bool writeOutput = !(_settings->getGlobalSettings()->getOutputPointType() == OPT_NONE);
    double t=_tCurrent;
  // Initialization phase
    if(writeOutput) {
        _continuous_system[0]->evaluateAll(IContinuous::ALL);
        SolverDefaultImplementation::writeToFile(0, t, _h);
    }

#ifdef MPIPEER
    std::copy(_y,_y+_dimSys,_Y1);
    if (abs(_c[_rank]+1.)>1e-12)
    {

        ros2(_Y1,_tCurrent,_tCurrent+_h*(_c[_rank]+1.));
        t=_tCurrent;
    }
    MPI_Barrier(MPI_COMM_WORLD);
    if(_rank==0) {
        MPI_Gather(MPI_IN_PLACE,_dimSys,MPI_DOUBLE,_Y1,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
    } else {
        MPI_Gather(_Y1,_dimSys,MPI_DOUBLE,_Y1,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
    }
    t+=_h;
#else
#pragma omp parallel for num_threads(_numThreads)
    for(int _rank=0; _rank<5; ++_rank) {
        std::copy(_y,_y+_dimSys,&_Y1[_rank*_dimSys]);
        if (abs(_c[_rank]+1.)>1e-12)
        {
            ros2(&_Y1[_rank*_dimSys],_tCurrent,_tCurrent+_h*(_c[_rank]+1.), _continuous_system[_rank], _time_system[_rank]);
            t=_tCurrent;
        }
    }
    t+=_h;
    _time_system[0]->setTime(t);
    _continuous_system[0]->setContinuousStates(&_Y1[2*_dimSys]);
    if(writeOutput) {
        if(t>=twrite) {
            _continuous_system[0]->evaluateAll(IContinuous::ALL);
            SolverDefaultImplementation::writeToFile(0, t, _h);
            twrite+=_hOut;
        }
    }
#endif



//    std::cerr << "Finished init at rank  " << _rank<<std::endl;
// Solution phase
    t+=_h;
    char trans='N';
    long int dim=1;
    int count=0;
    while(std::abs(t-_tEnd)>1e-8)
    {
#ifdef MPIPEER
        if(_rank==0)
        {
            for(int i=0; i<_rstages; ++i)
            {
                for(int j=0; j<_dimSys; ++j) {
                    _Y2[i*_dimSys+j]=0.;
                    for(int k=0; k<_rstages;++k) {
                        _Y2[i*_dimSys+j]+=_Y1[k*_dimSys+j]*_Theta[i*_rstages+k];
                    }
                }
 //               Y2.vector(i)=Y1*mtl::vector::trans(Theta[i][iall]);
            }
            std::cout<<"_Y2 vals on rank "<<_rank<<": ";
              for(int i=0; i<_rstages*_dimSys;++i) {
                  if(!(i%20)) std::cout<<std::endl;
                std::cout<<_Y2[i]<<" ";
            }
            std::cout<<std::endl;
            for(int i=0; i<_rstages; i++)
            {
                 for(int j=0; j<_dimSys; ++j) {
                    _Y3[i*_dimSys+j]=0.;
                    for(int k=0; k<_rstages;++k) {
                        _Y3[i*_dimSys+j]+=_Y2[k*_dimSys+j]*_E[i*_rstages+k];
                    }
                }
//                Y3.vector(i)=Y2*mtl::vector::trans(E[i][iall]);
            }
        }
        MPI_Barrier(MPI_COMM_WORLD);
//        std::cerr << "Finished rank 0 calculation step at rank  " << _rank<<std::endl;
        if(_rank==0) {
            MPI_Scatter( _Y2,_dimSys,MPI_DOUBLE,MPI_IN_PLACE,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
            MPI_Scatter( _Y3,_dimSys,MPI_DOUBLE,MPI_IN_PLACE,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
        } else {
            MPI_Scatter(_Y2,_dimSys,MPI_DOUBLE,_Y2,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
            MPI_Scatter(_Y3,_dimSys,MPI_DOUBLE,_Y3,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
        }

        evalF(t+_c[_rank]*_h,_Y2,_F);
        evalJ(t+_c[_rank]*_h,_Y2,_T);
        if(_rank==0) {
            std::cout<<"Jac: ";
            for(int i(0); i<_dimSys*_dimSys;++i) {
                if(!(i%20)) std::cout<<std::endl;
                std::cout<<_T[i]<<" ";
            }
            std::cout<<std::endl;
        }
        for(int i=0; i<_dimSys; ++i) {
            for(int j=0; j<_dimSys; ++j) {
                _T[i*_dimSys+j]*=-_h*_G[_rank];
            }
            _T[i*_dimSys+i]+=1.;
        }


//        std::cerr << "Finished iteration matrix calculation step at rank  " << _rank<<std::endl;
        dgetrf_(&_dimSys, &_dimSys, _T, &_dimSys, _P, &info);
        for(int i=0; i<_dimSys; ++i) {
            _F[i]*=_h;
            _F[i]-=_Y3[i];
            _F[i]*=_G[_rank];
        }
        dgetrs_(&trans, &_dimSys, &dim, _T, &_dimSys, _P, _F, &_dimSys, &info);
        for(int i=0; i<_dimSys; ++i) {
            _Y1[i]=_F[i]+_Y2[i];
        }
        MPI_Barrier(MPI_COMM_WORLD);
        if(_rank==0) {
            MPI_Gather(MPI_IN_PLACE,_dimSys,MPI_DOUBLE,_Y1,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
        } else {
            MPI_Gather(_Y1,_dimSys,MPI_DOUBLE,_Y1,_dimSys,MPI_DOUBLE,0,MPI_COMM_WORLD);
        }

        if(t+_h>_tEnd) _h=_tEnd-t;
        if(_rank==0) {
            SolverDefaultImplementation::writeToFile(0, t, _h);
        }
        t+=_h;
#else
        for(int i=0; i<_rstages; ++i)
        {
            for(int j=0; j<_dimSys; ++j) {
                _Y2[i*_dimSys+j]=0.;
                    for(int k=0; k<_rstages;++k) {
                        _Y2[i*_dimSys+j]+=_Y1[k*_dimSys+j]*_Theta[i*_rstages+k];
                    }
                }
 //               Y2.vector(i)=Y1*mtl::vector::trans(Theta[i][iall]);
            }
            for(int i=0; i<_rstages; i++)
            {
                 for(int j=0; j<_dimSys; ++j) {
                    _Y3[i*_dimSys+j]=0.;
                    for(int k=0; k<_rstages;++k) {
                        _Y3[i*_dimSys+j]+=_Y2[k*_dimSys+j]*_E[i*_rstages+k];
                    }
                }
//                Y3.vector(i)=Y2*mtl::vector::trans(E[i][iall]);
            }

#pragma omp parallel for num_threads(_numThreads)
        for(int _rank=0; _rank<5; ++_rank) {
            long int info;
            evalF(t+_c[_rank]*_h,&_Y2[_rank*_dimSys],&_F[_rank*_dimSys],_continuous_system[_rank], _time_system[_rank]);
            if(!(count%_reuseJacobi)) {
               evalJ(t+_c[_rank]*_h,&_Y2[_rank*_dimSys],&_T[_rank*_dimSys*_dimSys], _continuous_system[_rank], _time_system[_rank]);
                for(int i=0; i<_dimSys; ++i) {
                    for(int j=0; j<_dimSys; ++j) {
                        _T[_rank*_dimSys*_dimSys+i*_dimSys+j]*=-_h*_G[_rank];
                    }
                    _T[_rank*_dimSys*_dimSys+i*_dimSys+i]+=1.;
                }

                dgetrf_(&_dimSys, &_dimSys, &_T[_rank*_dimSys*_dimSys], &_dimSys, &_P[_rank*_dimSys], &info);
            }


    //        std::cerr << "Finished iteration matrix calculation step at rank  " << _rank<<std::endl;

            for(int i=0; i<_dimSys; ++i) {
                _F[_rank*_dimSys+i]*=_h;
                _F[_rank*_dimSys+i]-=_Y3[_rank*_dimSys+i];
                _F[_rank*_dimSys+i]*=_G[_rank];
            }
            dgetrs_(&trans, &_dimSys, &dim, &_T[_rank*_dimSys*_dimSys], &_dimSys, &_P[_rank*_dimSys], &_F[_rank*_dimSys], &_dimSys, &info);
            for(int i=0; i<_dimSys; ++i) {
                _Y1[_rank*_dimSys+i]=_F[_rank*_dimSys+i]+_Y2[_rank*_dimSys+i];
            }
        }

        count++;
        if(t+_h>_tEnd) _h=_tEnd-t;
        _time_system[0]->setTime(t);
        _continuous_system[0]->setContinuousStates(&_Y1[2*_dimSys]);

        if(writeOutput) {
            if(t>=twrite) {
                _continuous_system[0]->evaluateAll(IContinuous::ALL);
                SolverDefaultImplementation::writeToFile(0, t, _h);
                twrite+=_hOut;
            }
        }
        t+=_h;
#endif

    }
#ifdef MPIPEER
    MPI_Barrier(MPI_COMM_WORLD);
    if(_rank==0)
    {
        for(int i=0; i<_dimSys; i++) _y[i]=_Y1[(_rstages-1)*_dimSys+i];
    }
    MPI_Bcast(_y, _dimSys, MPI_DOUBLE, 0, MPI_COMM_WORLD);
#else
    for(int i=0; i<_dimSys; i++) _y[i]=_Y1[(_rstages-1)*_dimSys+i];
#endif
    _tCurrent=_tEnd;
    _time_system[0]->setTime(_tCurrent);
    _continuous_system[0]->setContinuousStates(&_Y1[4*_dimSys]);
    if(writeOutput) {
        _continuous_system[0]->evaluateAll(IContinuous::ALL);
        SolverDefaultImplementation::writeToFile(0, t, _h);
    }
    _solverStatus = ISolver::DONE;
}



void Peer::writePeerOutput(const double &time, const double &h, const int &stp)
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

bool Peer::stateSelection()
{
  return SolverDefaultImplementation::stateSelection();
}

void Peer::setTimeOut(unsigned int time_out)
  {
       SimulationMonitor::setTimeOut(time_out);
  }
 void Peer::stop()
  {
       SimulationMonitor::stop();
  }


void Peer::setcycletime(double cycletime){}
void Peer::writeSimulationInfo(){}
int Peer::reportErrorMessage(std::ostream& messageStream) {
    return 0;
}
#endif
