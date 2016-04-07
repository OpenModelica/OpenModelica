/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Newton/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

#include <Solver/Newton/Newton.h>

#include <Core/Math/ILapack.h>     // needed for solution of linear system with Lapack
#include <Core/Math/Constants.h>   // definitializeion of constants like uround

template <typename S, typename T>
static inline void LogSysVec(IAlgLoop* algLoop, S name, T vec[]) {
  if (Logger::getInstance()->isOutput(LC_NLS, LL_DEBUG)) {
    std::stringstream ss;
    ss << "Newton: eq" << to_string(algLoop->getEquationIndex());
    ss << ", time " << algLoop->getSimTime() << ": " << name << " = {";
    for (int i = 0; i < algLoop->getDimReal(); i++)
      ss <<  (i > 0? ", ": "") << vec[i];
    ss << "}";
    Logger::write(ss.str(), LC_NLS, LL_DEBUG);
  }
}

Newton::Newton(IAlgLoop* algLoop, INonLinSolverSettings* settings)
  : _algLoop          (algLoop)
  , _newtonSettings   ((INonLinSolverSettings*)settings)
  , _yNames           (NULL)
  , _yNominal         (NULL)
  , _yMin             (NULL)
  , _yMax             (NULL)
  , _y                (NULL)
  , _yHelp            (NULL)
  , _f                (NULL)
  , _fHelp            (NULL)
  , _iHelp            (NULL)
  , _jac              (NULL)
  , _zeroVec          (NULL)
  , _dimSys           (0)
  , _firstCall        (true)
  , _iterationStatus  (CONTINUE)
{
}

Newton::~Newton()
{
  if (_yNames)   delete []    _yNames;
  if (_yNominal) delete []    _yNominal;
  if (_yMin)     delete []    _yMin;
  if (_yMax)     delete []    _yMax;
  if (_y)        delete []    _y;
  if (_yHelp)    delete []    _yHelp;
  if (_f)        delete []    _f;
  if (_fHelp)    delete []    _fHelp;
  if (_iHelp)    delete []    _iHelp;
  if (_jac)      delete []    _jac;
  if (_zeroVec)  delete []   _zeroVec;
}

void Newton::initialize()
{
  _firstCall = false;

  //(Re-) initializeialization of algebraic loop
  _algLoop->initialize();

  // Dimension of the system (number of variables)
  int
    dimDouble    = _algLoop->getDimReal(),
    dimInt       = 0,
    dimBool      = 0;

  // Check system dimension
  if (dimDouble != _dimSys) {
    _dimSys = dimDouble;

    if (_dimSys > 0) {
      // initialize of vectors of unknowns and residuals
      if (_yNames)   delete []    _yNames;
      if (_yNominal) delete []    _yNominal;
      if (_yMin)     delete []    _yMin;
      if (_yMax)     delete []    _yMax;
      if (_y)        delete []    _y;
      if (_f)        delete []    _f;
      if (_yHelp)    delete []    _yHelp;
      if (_fHelp)    delete []    _fHelp;
      if (_iHelp)    delete []    _iHelp;
      if (_jac)      delete []    _jac;
      if (_zeroVec)  delete []    _zeroVec;

      _yNames       = new const char* [_dimSys];
      _yNominal     = new double[_dimSys];
      _yMin         = new double[_dimSys];
      _yMax         = new double[_dimSys];
      _y            = new double[_dimSys];
      _f            = new double[_dimSys];
      _yHelp        = new double[_dimSys];
      _fHelp        = new double[_dimSys];
      _iHelp        = new long int[_dimSys];
      _jac          = new double[_dimSys*_dimSys];
      _zeroVec      = new double[_dimSys];

      _algLoop->getNamesReal(_yNames);
      _algLoop->getNominalReal(_yNominal);
      _algLoop->getMinReal(_yMin);
      _algLoop->getMaxReal(_yMax);
      _algLoop->getReal(_y);
      memset(_f, 0, _dimSys*sizeof(double));
      memset(_yHelp, 0, _dimSys*sizeof(double));
      memset(_fHelp, 0, _dimSys*sizeof(double));
      memset(_jac, 0, _dimSys*_dimSys*sizeof(double));
      memset(_zeroVec, 0, _dimSys*sizeof(double));
    }
    else {
      _iterationStatus = SOLVERERROR;
    }
  }
  if (Logger::getInstance()->isOutput(LC_NLS, LL_DEBUG)) {
    Logger::write("Newton: eq" + to_string(_algLoop->getEquationIndex())
                  + " initialized", LC_NLS, LL_DEBUG);
    LogSysVec(_algLoop, "names", _yNames);
  }
}

void Newton::solve()
{
  long int
    dimRHS   = 1,        // Dimension of right hand side of linear system (=b)
    info     = 0;        // Retrun-flag of Fortran code
  int
    totSteps = 0;        // Total number of steps taken
  double
    atol = _newtonSettings->getAtol(),
    rtol = _newtonSettings->getRtol();

  // If initialize() was not called yet
  if (_firstCall)
    initialize();

  // Get current values from system
  _algLoop->getReal(_y);

  // Reset status flag
  _iterationStatus = CONTINUE;

  while (_iterationStatus == CONTINUE) {
    // Check stopping criterion
    calcFunction(_y,_f);
    if (totSteps) {
      _iterationStatus = DONE;
      for (int i=0; i<_dimSys; ++i) {
        if (fabs(_f[i]) > atol + fabs(_y[i]) * rtol) {
          _iterationStatus = CONTINUE;
          break;
        }
      }
    }
    if (_iterationStatus == CONTINUE) {
      LogSysVec(_algLoop, "y" + to_string(totSteps), _y);
      if (totSteps < _newtonSettings->getNewtMax()) {
        // Determination of Jacobian (Fortran-format)
        if (_algLoop->isLinear() && !_algLoop->isLinearTearing()) {
          const matrix_t& A = _algLoop->getSystemMatrix();
          const double* jac = A.data().begin();
          memcpy(_jac, jac, _dimSys*_dimSys*sizeof(double));
          dgesv_(&_dimSys, &dimRHS, _jac, &_dimSys, _iHelp, _f, &_dimSys, &info);
          memcpy(_y,_f,_dimSys*sizeof(double));
          _algLoop->setReal(_y);
          if (info != 0)
            throw ModelicaSimulationError(ALGLOOP_SOLVER,
              "error solving linear system (dgesv info: " + to_string(info) + ")");
          else
            _iterationStatus = DONE;
        }
        else if (_algLoop->isLinearTearing()) {
          _algLoop->setReal(_zeroVec);
          _algLoop->evaluate();
          _algLoop->getRHS(_f);

          const matrix_t& A_sparse = _algLoop->getSystemMatrix();
          //m_t A_dense(A_sparse);

          const double* jac = A_sparse.data().begin();

          memcpy(_jac, jac, _dimSys*_dimSys*sizeof(double));
          dgesv_(&_dimSys, &dimRHS, _jac, &_dimSys, _iHelp, _f, &_dimSys, &info);
          for (int i=0; i<_dimSys; i++)
            _y[i]=-_f[i];
          _algLoop->setReal(_y);
          _algLoop->evaluate();
          if (info != 0)
            throw ModelicaSimulationError(ALGLOOP_SOLVER,
              "error solving linear tearing system (dgesv info: " + to_string(info) + ")");
          else
            _iterationStatus = DONE;
        }
        else {
          calcJacobian();

          // Solve linear System
          dgesv_(&_dimSys, &dimRHS, _jac, &_dimSys, _iHelp, _f, &_dimSys, &info);

          if (info != 0)
            throw ModelicaSimulationError(ALGLOOP_SOLVER,
              "error solving nonlinear system (iteration: " + to_string(totSteps)
              + ", dgesv info: " + to_string(info) + ")");

          // Increase counter
          ++ totSteps;

          // New solution
          for (int i=0; i<_dimSys; ++i)
            _y[i] -= _newtonSettings->getDelta() * _f[i];
        }
      }
      else
        throw ModelicaSimulationError(ALGLOOP_SOLVER,
          "error solving nonlinear system (iteration limit: " + to_string(totSteps) + ")");
    }
  }
  LogSysVec(_algLoop, "y*", _y);
}

IAlgLoopSolver::ITERATIONSTATUS Newton::getIterationStatus()
{
  return _iterationStatus;
}

void Newton::calcFunction(const double *y, double *residual)
{
  _algLoop->setReal(y);
  _algLoop->evaluate();
  _algLoop->getRHS(residual);
}

void Newton::stepCompleted(double time)
{

}

void Newton::calcJacobian()
{
  for (int j = 0; j < _dimSys; ++j) {
    // Reset variables for every column
    memcpy(_yHelp, _y, _dimSys*sizeof(double));
    double stepsize = 1e-6 * _yNominal[j];

    // Finite differences
    _yHelp[j] += stepsize;

    calcFunction(_yHelp, _fHelp);

    // Build Jacobian in Fortran format
    for (int i = 0; i < _dimSys; ++i)
      _jac[i + j * _dimSys] = (_fHelp[i] - _f[i]) / stepsize;

    _yHelp[j] -= stepsize;
  }
}

void Newton::restoreOldValues()
{
}

void Newton::restoreNewValues()
{
}

/** @} */ // end of solverNewton
