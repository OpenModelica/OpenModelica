#include "stdafx.h"
#include "Kinsol.h"
#include "KinsolSettings.h"

#include <Math/ILapack.h>        // needed for solution of linear system with Lapack
#include <Math/Constants.h>    // definition of constants like uround

Kinsol::Kinsol(IAlgLoop* algLoop, INonLinSolverSettings* settings)
: _algLoop      (algLoop)
, _kinsolSettings  ((INonLinSolverSettings*)settings)
, _y        (NULL)
, _yHelp      (NULL)
, _f        (NULL)
, _fHelp      (NULL)
, _jac        (NULL)
, _dimSys      (0)
, _firstCall    (true)
, _iterationStatus  (CONTINUE)
{
  _data = ((void*)this);
}

Kinsol::~Kinsol()
{
  if(_y)     delete []  _y;
  if(_yHelp)  delete []  _yHelp;
  if(_f)    delete []  _f;
  if(_fHelp)  delete []  _fHelp;
  if(_jac)  delete []  _jac;

  N_VDestroy_Serial(_Kin_y);
  N_VDestroy_Serial(_Kin_yScale);
  N_VDestroy_Serial(_Kin_fScale);

  KINFree(&_kinMem);
}

void Kinsol::init()
{
  int idid;

  _firstCall = false;

  //(Re-) Initialization of algebraic loop
  _algLoop->init();

  // Dimension of the system (number of variables)
  int
    dimDouble  = _algLoop->getDimVars(),
    dimInt    = 0,
    dimBool    = 0;

  // Check system dimension
  if (dimDouble != _dimSys)
  {
    _dimSys = dimDouble;

    if(_dimSys > 0)
    {
      // Initialization of vector of unknowns
      if(_y)     delete []  _y;
      if(_f)    delete []  _f;
      if(_yHelp)  delete []  _yHelp;
      if(_fHelp)  delete []  _fHelp;
      if(_jac)  delete []  _jac;

      _y      = new double[_dimSys];
      _f      = new double[_dimSys];
      _yHelp    = new double[_dimSys];
      _fHelp    = new double[_dimSys];
      _jac    = new double[_dimSys*_dimSys];

      _algLoop->giveVars(_y);
      memset(_f,0,_dimSys*sizeof(double));
      memset(_yHelp,0,_dimSys*sizeof(double));
      memset(_fHelp,0,_dimSys*sizeof(double));
      memset(_jac,0,_dimSys*_dimSys*sizeof(double));  // Wird nur benötigt, falls symbolisch vorhanden
      for (int i=0;i<_dimSys;i++)
        _yHelp[i] = 1;

      _Kin_y = N_VMake_Serial(_dimSys, _y);
      _Kin_yScale = N_VMake_Serial(_dimSys, _yHelp);
      _Kin_fScale = N_VMake_Serial(_dimSys, _yHelp);
      _kinMem = KINCreate();

      //Set Options
      idid = KINSetNumMaxIters(_kinMem, _kinsolSettings->getNewtMax());
      idid = KINInit(_kinMem, kin_fCallback, _Kin_y);
       if (check_flag(&idid, "KINInit", 1))
        throw std::invalid_argument("Kinsol::init()");
      idid = KINSetUserData(_kinMem, _data);
      if (check_flag(&idid, "KINSetUserData", 1))
         throw std::invalid_argument("Kinsol::init()");
      idid = KINDense(_kinMem, _dimSys);
      //idid = KINSpgmr(_kinMem,0);
      if (check_flag(&idid, "KINSpgmr", 1))
        throw std::invalid_argument("Kinsol::init()");
    }
    else
    {
      _iterationStatus = SOLVERERROR;
    }
  }


}

void Kinsol::solve(const IContinuous::UPDATE command)
{
  long int
    dimRHS  = 1,          // Dimension of right hand side of linear system (=b)
    irtrn  = 0;          // Retrun-flag of Fortran code
  int idid;
  if(_algLoop->isLinear())
  {
    //calcFunction(_yHelp,_fHelp);
    _algLoop->giveAMatrix(_jac);
    dgesv_(&_dimSys,&dimRHS,_jac,&_dimSys,_fHelp,_f,&_dimSys,&irtrn);
    memcpy(_y,_f,_dimSys*sizeof(double));
    _algLoop->setVars(_y);
    _iterationStatus = DONE;
  }
  else
  {


    idid = KINSol(_kinMem, _Kin_y, KIN_LINESEARCH, _Kin_yScale, _Kin_yScale);
    if (check_flag(&idid, "KINSol", 1))
      throw std::invalid_argument("Kinsol::solve()");
  }

}

IAlgLoopSolver::ITERATIONSTATUS Kinsol::getIterationStatus()
{
  return _iterationStatus;
}


void Kinsol::calcFunction(const double *y, double *residual)
{
  _algLoop->setVars(y);
  _algLoop->update(IContinuous::CONTINOUS);
  _algLoop->giveRHS(residual);
}

int Kinsol::kin_fCallback(N_Vector y,N_Vector fval, void *user_data)
{
  ((Kinsol*) user_data)->calcFunction(NV_DATA_S(y),NV_DATA_S(fval));

  return(0);
}



void Kinsol::calcJacobian()
{
  for(int j=0; j<_dimSys; ++j)
  {
    // Reset variables for every column
    memcpy(_yHelp,_y,_dimSys*sizeof(double));

    // Finite difference
    _yHelp[j] += 1e-6;

    calcFunction(_yHelp,_fHelp);

    // Build Jacobian in Fortran format
    for(int i=0; i<_dimSys; ++i)
      _jac[i+j*_dimSys] = (_fHelp[i] - _f[i]) / 1e-6;
  }

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

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INonLinSolverSettings*> > >()
    ["Kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["KinsolSettings"].set<KinsolSettings>();
 }
