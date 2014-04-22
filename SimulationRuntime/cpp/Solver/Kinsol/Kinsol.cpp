#include "stdafx.h"
#include "Kinsol.h"
#include "KinsolSettings.h"



Kinsol::Kinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings)
     : _algLoop      (algLoop)
     , _kinsolSettings  ((INonLinSolverSettings*)settings)
     , _y        (NULL)
     , _y0       (NULL)
     , _yScale   (NULL)
     , _fScale   (NULL)
     , _f        (NULL)
     , _helpArray    (NULL)
     , _jac          (NULL)
     , _dimSys      (0)
     , _firstCall    (true)
     , _iterationStatus  (CONTINUE)
{
     _data = ((void*)this);
}

Kinsol::~Kinsol()
{  
     if(_y)            delete []  _y;
     if(_y0)            delete []  _y0;
     if(_yScale)     delete []  _yScale;
     if(_fScale)     delete []  _fScale;
     if(_f)            delete []  _f;
     if(_helpArray)            delete []  _helpArray;
     if(_jac)            delete []  _jac;

     N_VDestroy_Serial(_Kin_y);
     N_VDestroy_Serial(_Kin_y0);
     N_VDestroy_Serial(_Kin_yScale);
     N_VDestroy_Serial(_Kin_fScale);

     KINFree(&_kinMem);
}

void Kinsol::initialize()
{
     int idid;

     _firstCall = false;

     //(Re-) Initialization of algebraic loop
     _algLoop->initialize();

     // Dimension of the system (number of variables)
     int 
          dimDouble  = _algLoop->getDimReal(),
          dimInt    = 0,
          dimBool    = 0; 

     // Check system dimension
     if (dimDouble != _dimSys)
     {
          _dimSys = dimDouble;

          if(_dimSys > 0)
          {
               // Initialization of vector of unknowns
               if(_y)               delete []  _y;
               if(_y0)          delete []  _y0;
               if(_yScale)     delete []  _yScale;
               if(_fScale)     delete []  _fScale;
               if(_f)               delete []  _f;
               if(_helpArray)           delete []  _helpArray;
               if(_jac)           delete []  _jac;

               _y            = new double[_dimSys];
               _y0         = new double[_dimSys];
               _yScale     = new double[_dimSys];
               _fScale     = new double[_dimSys];
               _f            = new double[_dimSys];
               _helpArray       = new double[_dimSys];
               _jac            = new double[_dimSys*_dimSys];  

               _algLoop->getReal(_y);
               _algLoop->getReal(_y0);

               memset(_f,0,_dimSys*sizeof(double));
               memset(_helpArray,0,_dimSys*sizeof(double));

               
               _algLoop->getNominalReal(_yScale);

               for (int i=0;i<_dimSys;i++)
               {
                    _fScale[i] = 1;
               }

               _Kin_y = N_VMake_Serial(_dimSys, _y);
               _Kin_y0 = N_VMake_Serial(_dimSys, _y0);
               _Kin_yScale = N_VMake_Serial(_dimSys, _yScale);
               _Kin_fScale = N_VMake_Serial(_dimSys, _fScale);
               _kinMem = KINCreate();

               //Set Options
               //idid = KINSetNumMaxIters(_kinMem, _kinsolSettings->getNewtMax());
               idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
               if (check_flag(&idid, "KINInit", 1)) 
                    throw std::invalid_argument("Kinsol::initialize()");
               idid = KINSetUserData(_kinMem, _data);
               if (check_flag(&idid, "KINSetUserData", 1)) 
                    throw std::invalid_argument("Kinsol::initialize()");

               idid = KINSpgmr(_kinMem,0);
               if (check_flag(&idid, "KINSpgmr", 1)) 
                    throw std::invalid_argument("Kinsol::initialize()");

               idid = KINSetErrFile(_kinMem, NULL);

               KINSetNumMaxIters(_kinMem, 1000);

               _fnormtol  = 1.e-12;     /* function tolerance */
               _scsteptol = 1.e-12;     /* step tolerance */
               
               idid = KINSetFuncNormTol(_kinMem, _fnormtol);
               


          }
          else
          {
               _iterationStatus = SOLVERERROR;
          }
     }


}

void Kinsol::solve()
{
     long int
          dimRHS  = 1,          // Dimension of right hand side of linear system (=b)
          irtrn  = 0;          // Retrun-flag of Fortran code
     int idid;
     bool tryIterative = true;
     bool EventRetry = false;
     int iter = 0;
     realtype tmp, tmp1;

     if (_firstCall)
          initialize();

     _iterationStatus = CONTINUE;

     if(_algLoop->isLinear())
     {
          long int dimRHS  = 1;          // Dimension of right hand side of linear system (=b)
          long int dimSys = _dimSys;
          long int irtrn  = 0;          // Retrun-flag of Fortran code        _algLoop->getReal(_y);
     
          _algLoop->getRHS(_f);
          _algLoop->getSystemMatrix(_jac);
          dgesv_(&dimSys,&dimRHS,_jac,&dimSys,_helpArray,_f,&dimSys,&irtrn);
          memcpy(_y,_f,_dimSys*sizeof(double));
          _algLoop->setReal(_y);
     }
     else
     {
          _scsteptol = 1.e-12;               // step tolerance
          idid = KINSetScaledStepTol(_kinMem, _scsteptol);

          idid = KINDense(_kinMem, _dimSys);
          while(_iterationStatus == CONTINUE)
          {
               iter++;
               //Increase max. Newton Step size
               idid = KINSetMaxNewtonStep(_kinMem, pow(10.0,iter));

               // Reset initial guess
               memcpy(_y,_y0,_dimSys*sizeof(double));
               
               // Call Kinsol
               idid = KINSol(_kinMem, _Kin_y, KIN_NONE, _Kin_yScale, _Kin_yScale);
               
               //Check of return flag
               if (idid < 0)
               {
                    //did we ran into a solution that is inconsistent?
                    _algLoop->setReal(_y); 
                    if(!(_algLoop->isConsistent()) && !EventRetry)
                    {
                         memcpy(_helpArray, _y,_dimSys*sizeof(double));
                         EventRetry = true;
                    }
                    // If maxstep is exceeded, increase the limit, otherwise exit the loop
                    if(idid != KIN_MXNEWT_5X_EXCEEDED)
                         break;
               }
               else
               {
                    _iterationStatus = DONE;
                    break;
               }
               
               if(iter > 10)
               {
                    break;
               }
          }     
               
          
          // TRY ITERATIVE SOLVER
          if(_iterationStatus == CONTINUE)
          {
               memcpy(_y,_y0,_dimSys*sizeof(double));
               
               _scsteptol = 1.e-8;     // step tolerance 

               idid = KINSetScaledStepTol(_kinMem, _scsteptol);

               /*
               KINSetNoResMon(_kinMem, TRUE);
               KINSetNumMaxIters(_kinMem, 5000);
               KINSetEtaForm(_kinMem, KIN_ETACHOICE2);
               KINSpilsSetMaxRestarts(_kinMem, 50);
               */

               // TRY ITERATIVE SOLVER
               idid = KINSpgmr(_kinMem,5);
               idid = KINSol(_kinMem, _Kin_y, KIN_NONE, _Kin_yScale, _Kin_yScale);
               
               if (idid< 0)
               {
                    _algLoop->setReal(_y); 
                    if(!(_algLoop->isConsistent()) && !EventRetry)
                    {
                         memcpy(_helpArray, _y,_dimSys*sizeof(double));
                         EventRetry = true;
                    } else
                         _iterationStatus = SOLVERERROR;
               }else
                    _iterationStatus = DONE;
          }
          
     }

     if(_iterationStatus == SOLVERERROR)
          throw std::runtime_error("Nonlinear solver failed!");
     
     if(_iterationStatus == CONTINUE && EventRetry)
          memcpy(_y, _helpArray ,_dimSys*sizeof(double));
}

IAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus()
{
     return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual)
{
     _algLoop->setReal(y);
     _algLoop->evaluate();
     _algLoop->getRHS(residual);
}

int Kinsol::kin_fCallback(N_Vector y,N_Vector fval, void *user_data)
{
     ((Kinsol*) user_data)->calcFunction(NV_DATA_S(y),NV_DATA_S(fval));

     return(0);
}



void Kinsol::stepCompleted(double time)
{
     memcpy(_y0,_y,_dimSys*sizeof(double));
}

int Kinsol::check_flag(void *flagvalue, char *funcname, int opt)
{
     int *errflag;

     /* Check if SUNDIALS function returned NULL pointer - no memory allocated */
     if (opt == 0 && flagvalue == NULL) {
          fprintf(stderr, 
               "\nSUNDIALS_ERROR: %s() failed - returned NULL pointer\n\n",
               funcname);
          return(1);
     }

     /* Check if flag < 0 */
     else if (opt == 1) {
          errflag = (int *) flagvalue;
          if (*errflag < 0) {
               fprintf(stderr,
                    "\nSUNDIALS_ERROR: %s() failed with flag = %d\n\n",
                    funcname, *errflag);
               return(1); 
          }
     }

     /* Check if function returned NULL pointer - no memory allocated */
     else if (opt == 2 && flagvalue == NULL) {
          fprintf(stderr,
               "\nMEMORY_ERROR: %s() failed - returned NULL pointer\n\n",
               funcname);
          return(1);
     }

     return(0);
}


