#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverDgesvSolver
*
*  @{
*/

#include <Core/Math/ILapack.h>
#include <Solver/Dgesv/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Solver/Dgesv/DgesvSolver.h>

#include <iostream>

#include <Core/Utils/numeric/bindings/ublas.hpp>
#include <Core/Utils/numeric/utils.h>

DgesvSolver::DgesvSolver(ILinearAlgLoop* algLoop, ILinSolverSettings* settings)
  : _algLoop            (algLoop)
  , _dimSys             (0)

  , _yNames             (NULL)
  , _yNominal           (NULL)
  , _y                  (NULL)
  , _y0                 (NULL)
  , _y_old              (NULL)
  , _y_new              (NULL)
  , _b                  (NULL)
  , _A                  (NULL)
  , _ihelpArray         (NULL)
  , _zeroVec            (NULL)
  , _iterationStatus    (CONTINUE)
  , _firstCall          (true)
  , _fNominal           (NULL)
{
}

DgesvSolver::~DgesvSolver()
{
  if (_yNames)          delete [] _yNames;
  if (_yNominal)        delete [] _yNominal;
  if (_y)               delete [] _y;
  if (_y0)              delete [] _y0;
  if (_y_old)           delete [] _y_old;
  if (_y_new)           delete [] _y_new;
  if (_b)               delete [] _b;
  if (_A)               delete [] _A;
  if (_ihelpArray)      delete [] _ihelpArray;
  if (_zeroVec)         delete [] _zeroVec;
  if (_fNominal)        delete [] _fNominal;
}

void DgesvSolver::initialize()
{
  _firstCall = false;
  //(Re-) Initialization of algebraic loop
  _algLoop->initialize();

  int dimDouble = _algLoop->getDimReal();
  int ok = 0;

  if (dimDouble != _dimSys) {
    _dimSys = dimDouble;

    if (_dimSys > 0) {
      // Initialization of vector of unknowns
      if (_yNames)         delete [] _yNames;
      if (_yNominal)       delete [] _yNominal;
      if (_y)              delete [] _y;
      if (_y0)             delete [] _y0;
      if (_y_old)          delete [] _y_old;
      if (_y_new)          delete [] _y_new;
      if (_b)              delete [] _b;
      if (_A)              delete [] _A;
      if (_ihelpArray)     delete [] _ihelpArray;
      if (_zeroVec)        delete [] _zeroVec;
      if (_fNominal)       delete [] _fNominal;

      _yNames           = new const char* [_dimSys];
      _yNominal         = new double[_dimSys];
      _y                = new double[_dimSys];
      _y0               = new double[_dimSys];
      _y_old            = new double[_dimSys];
      _y_new            = new double[_dimSys];
      _b                = new double[_dimSys];
      _A                = new double[_dimSys*_dimSys];
      _ihelpArray       = new long int[_dimSys];
      _zeroVec          = new double[_dimSys];
      _fNominal         = new double[_dimSys];

      _algLoop->getNamesReal(_yNames);
      _algLoop->getNominalReal(_yNominal);
      _algLoop->getReal(_y);
      _algLoop->getReal(_y0);
      _algLoop->getReal(_y_new);
      _algLoop->getReal(_y_old);
      memset(_b, 0, _dimSys*sizeof(double));
      memset(_ihelpArray, 0, _dimSys*sizeof(long int));
      memset(_A, 0, _dimSys*_dimSys*sizeof(double));
      memset(_zeroVec, 0, _dimSys*sizeof(double));
    }
    else {
      _iterationStatus = SOLVERERROR;
    }
  }

  LOGGER_WRITE_BEGIN("DgesvSolver: eq" + to_string(_algLoop->getEquationIndex()) +
                     " initialized", LC_LS, LL_DEBUG);
  LOGGER_WRITE_VECTOR("yNames", _yNames, _dimSys, LC_LS, LL_DEBUG);
  LOGGER_WRITE_VECTOR("yNominal", _yNominal, _dimSys, LC_LS, LL_DEBUG);
  LOGGER_WRITE_END(LC_LS, LL_DEBUG);
}

void DgesvSolver::solve()
{
  if (_firstCall) {
    initialize();
  }

  _iterationStatus = CONTINUE;

  LOGGER_WRITE_BEGIN("DgesvSolver: eq" + to_string(_algLoop->getEquationIndex()) +
                     " at time " + to_string(_algLoop->getSimTime()) + ":",
                     LC_LS, LL_DEBUG);

  //use lapack
  long int dimRHS = 1; // Dimension of right hand side of linear system (=_b)
  long int irtrn  = 0; // Return-flag of Fortran code

  if (_algLoop->isLinearTearing())
    _algLoop->setReal(_zeroVec); //if the system is linear Tearing it means that the system is of the form Ax-b=0, so plugging in x=0 yields -b for the left hand side

  _algLoop->evaluate();
  _algLoop->getb(_b);

  const matrix_t& A = _algLoop->getAMatrix();
  const double* Atemp = A.data().begin();

  memcpy(_A, Atemp, _dimSys*_dimSys*sizeof(double));

  std::fill(_fNominal, _fNominal + _dimSys, 1e-6);
  for (int j = 0, idx = 0; j < _dimSys; j++)
    for (int i = 0; i < _dimSys; i++, idx++)
      _fNominal[i] = std::max(std::abs(Atemp[idx]), _fNominal[i]);

  LOGGER_WRITE_VECTOR("fNominal", _fNominal, _dimSys, LC_LS, LL_DEBUG);

  for (int j = 0, idx = 0; j < _dimSys; j++)
    for (int i = 0; i < _dimSys; i++, idx++)
      _A[idx] /= _fNominal[i];

  for (int i = 0; i < _dimSys; i++)
    _b[i] /= _fNominal[i];

  dgesv_(&_dimSys,&dimRHS,_A,&_dimSys,_ihelpArray,_b,&_dimSys,&irtrn);

  if (irtrn != 0) {
    if (_algLoop->isLinearTearing())
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "error solving linear tearing system (dgesv info: " + to_string(irtrn) + ")");
    else
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "error solving linear system (dgesv info: " + to_string(irtrn) + ")");
  }
  else
    _iterationStatus = DONE;


  //we need to revert the sign of y, because the sign of b was changed before.
  if (_algLoop->isLinearTearing()) {
    for (int i = 0; i < _dimSys; i++)
      _y[i] = -_b[i];
  }
  else {
    memcpy(_y,_b,_dimSys*sizeof(double));
  }

  _algLoop->setReal(_y);
  if (_algLoop->isLinearTearing())
    _algLoop->evaluate();//resets the right hand side to zero in the case of linear tearing. Otherwise, the b vector on the right hand side needs no update.

  LOGGER_WRITE_VECTOR("y*", _y, _dimSys, LC_LS, LL_DEBUG);
  LOGGER_WRITE_END(LC_LS, LL_DEBUG);
}

IAlgLoopSolver::ITERATIONSTATUS DgesvSolver::getIterationStatus()
{
  return _iterationStatus;
}

void DgesvSolver::stepCompleted(double time)
{
  memcpy(_y0, _y, _dimSys*sizeof(double));
  memcpy(_y_old, _y_new, _dimSys*sizeof(double));
  memcpy(_y_new, _y, _dimSys*sizeof(double));
}

/**
 *  \brief Restores all algloop variables for a output step
 *  \return Return_Description
 *  \details Details
 */
void DgesvSolver::restoreOldValues()
{
  memcpy(_y, _y_old, _dimSys*sizeof(double));
}


/**
 *  \brief Restores all algloop variables for last output step
 *  \return Return_Description
 *  \details Details
 */
void DgesvSolver::restoreNewValues()
{
  memcpy(_y, _y_new, _dimSys*sizeof(double));
}


/** @} */ // end of solverDgesvSolver
