/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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

#include <algorithm>

Newton::Newton(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop)
  :AlgLoopSolverDefaultImplementation()
   ,_algLoop          (algLoop)
  , _newtonSettings   ((INonLinSolverSettings*)settings)
  , _yNames           (NULL)
  , _yNominal         (NULL)
  , _yMin             (NULL)
  , _yMax             (NULL)
  , _y                (NULL)
  , _yHelp            (NULL)
  , _yTest            (NULL)
  , _fNominal         (NULL)
  , _f                (NULL)
  , _fHelp            (NULL)
  , _fTest            (NULL)
  , _iHelp            (NULL)
  , _jHelp            (NULL)
  , _jac              (NULL)
  , _firstCall        (true)
  , _iterationStatus  (CONTINUE)
  , _lc               (LC_NLS)
  , _sparse           (false)
  , _analyticJacobian (false)
#if defined(USE_KLU)
  , _kluSymbolic      (NULL)
  , _kluNumeric       (NULL)
#endif
{
	if (_algLoop)
	{
		AlgLoopSolverDefaultImplementation::initialize(_algLoop->getDimZeroFunc(),_algLoop->getDimReal());
	}
	else
	{
		throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
	}
}

Newton::~Newton()
{
  if (_yNames)   delete []    _yNames;
  if (_yNominal) delete []    _yNominal;
  if (_yMin)     delete []    _yMin;
  if (_yMax)     delete []    _yMax;
  if (_y)        delete []    _y;
  if (_yHelp)    delete []    _yHelp;
  if (_yTest)    delete []    _yTest;
  if (_fNominal) delete []    _fNominal;
  if (_f)        delete []    _f;
  if (_fHelp)    delete []    _fHelp;
  if (_fTest)    delete []    _fTest;
  if (_iHelp)    delete []    _iHelp;
  if (_jHelp)    delete []    _jHelp;
  if (_jac)      delete []    _jac;
  freeSparsity();
}

void Newton::initialize()
{
  _firstCall = false;

  //(Re-) initializeialization of algebraic loop
   if(_algLoop)
    _algLoop->initialize();
  else
	 throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");


    _dimSys    = _algLoop->getDimReal();

    if (_dimSys > 0) {
      // initialize of vectors of unknowns and residuals
      if (_yNames)   delete []    _yNames;
      if (_yNominal) delete []    _yNominal;
      if (_yMin)     delete []    _yMin;
      if (_yMax)     delete []    _yMax;
      if (_y)        delete []    _y;
      if (_fNominal) delete []    _fNominal;
      if (_f)        delete []    _f;
      if (_yHelp)    delete []    _yHelp;
      if (_yTest)    delete []    _yTest;
      if (_fHelp)    delete []    _fHelp;
      if (_fTest)    delete []    _fTest;
      if (_iHelp)    delete []    _iHelp;
      if (_jHelp)    delete []    _jHelp;
      if (_jac)      delete []    _jac;

      _yNames       = new const char* [_dimSys];
      _yNominal     = new double[_dimSys];
      _yMin         = new double[_dimSys];
      _yMax         = new double[_dimSys];
      _y            = new double[_dimSys];
      _fNominal     = new double[_dimSys];
      _f            = new double[_dimSys];
      _yHelp        = new double[_dimSys];
      _yTest        = new double[_dimSys];
      _fHelp        = new double[_dimSys];
      _fTest        = new double[_dimSys];
      _iHelp        = new long int[_dimSys];
      _jHelp        = new long int[_dimSys];
      _jac          = NULL;

      _algLoop->getNamesReal(_yNames);
      _algLoop->getNominalReal(_yNominal);
      _algLoop->getMinReal(_yMin);
      _algLoop->getMaxReal(_yMax);

      initializeSparsity();
      // the dense Jacobian is quadratic in the size, with a sparsity pattern it is only
      // allocated for the fallback
      if (!_sparse)
        _jac = new double[_dimSys*_dimSys];
    }



  LOGGER_WRITE_BEGIN("Newton: eq" + to_string(_algLoop->getEquationIndex()) +
                     " initialized", _lc, LL_DEBUG);
  LOGGER_WRITE_VECTOR("yNames", _yNames, _dimSys, _lc, LL_DEBUG);
  LOGGER_WRITE_VECTOR("yNominal", _yNominal, _dimSys, _lc, LL_DEBUG);
  LOGGER_WRITE_END(_lc, LL_DEBUG);
}
void Newton::solve( shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER, "solve for single instance is not supported");
}

void Newton::solve( )
{


  if(!_algLoop)
    throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
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

  // Get current values and residuals from system
  _algLoop->getReal(_y);
  _algLoop->evaluate();
  _algLoop->getRHS(_f);

  // Reset status flag
  _iterationStatus = CONTINUE;

  LOGGER_WRITE_BEGIN("Newton: eq" + to_string(_algLoop->getEquationIndex()) +
                     " at time " + to_string(_algLoop->getSimTime()) + ":",
                     _lc, LL_DEBUG);

  while (_iterationStatus == CONTINUE) {
    if (totSteps >= _newtonSettings->getNewtMax()) {
      LOGGER_WRITE_END(_lc, LL_DEBUG);
      throw ModelicaSimulationError(ALGLOOP_SOLVER,
        "error solving nonlinear system (iteration limit: " + to_string(totSteps) + ")");
    }

    // Newton step for non-linear system
      LOGGER_WRITE_VECTOR("y" + to_string(totSteps), _y, _dimSys, _lc, LL_DEBUG);
      LOGGER_WRITE_VECTOR("f" + to_string(totSteps), _f, _dimSys, _lc, LL_DEBUG);

      bool sparseJac = _sparse && calcSparseJacobian(_fNominal);
      if (!sparseJac) {
        if (!_jac)
          _jac = new double[_dimSys*_dimSys];
        calcJacobian(_jac, _fNominal);
      }

      // Initialize line search function
      double phi = 0.0;
      for (int i = 0; i < _dimSys; i++) {
        _f[i] /= _fNominal[i];
        phi += _f[i] * _f[i];
      }

      bool solved = sparseJac && solveSparse();
      if (sparseJac && !solved)
        sparseToDense(); // fall back to Lapack, which also handles singular Jacobians

      double det;
      if (solved) {
        info = 0;
      }
      else if (_dimSys == 1 && (det = _jac[0]) != 0.0) {
        det = _jac[0];
        _f[0] /= det;
        info = 0;
      }
      else if (_dimSys == 2 && (det = _jac[0]*_jac[3] - _jac[1]*_jac[2]) != 0.0) {
        det = _jac[0]*_jac[3] - _jac[1]*_jac[2];
        double f0 = (_f[0]*_jac[3] - _f[1]*_jac[2]) / det;
        _f[1] = (_jac[0]*_f[1] - _jac[1]*_f[0]) / det;
        _f[0] = f0;
        info = 0;
      }
      else {
        // Solve linear system
        dgesv_(&_dimSys, &dimRHS, _jac, &_dimSys, _iHelp, _f, &_dimSys, &info);
      }

      if (info > 0) {
        long int info2 = 0;
        double scale = 0.0;
        dgetc2_(&_dimSys, _jac, &_dimSys, _iHelp, _jHelp, &info2);
        dgesc2_(&_dimSys, _jac, &_dimSys, _f, _iHelp, _jHelp, &scale);
        // limit change of y by f to yNominal in case of singular Jacobian
        for (int i = 0; i < _dimSys; i++) {
          _f[i] = std::min(_yNominal[i], std::max(-_yNominal[i], _f[i]));
        }
        LOGGER_WRITE("total pivoting: dgesv/dgetc2 infos: " + to_string(info) + "/" + to_string(info2) +
                     ", dgesc2 scale: " + to_string(scale), _lc, LL_DEBUG);
      }
      else if (info < 0) {
        LOGGER_WRITE_END(_lc, LL_DEBUG);
        throw ModelicaSimulationError(ALGLOOP_SOLVER,
          "error solving nonlinear system (iteration: " + to_string(totSteps)
          + ", dgesv info: " + to_string(info) + ")");
      }

      // Increase counter
      ++ totSteps;

      // New iterate
      double lambda = 1.0; // step size
      double alpha = 1e-4; // guard for sufficient decrease
      // first find a feasible step
      while (true) {
        for (int i = 0; i < _dimSys; i++) {
          _yHelp[i] = _y[i] - lambda * _f[i] /** _yNominal[i]*/;
          _yHelp[i] = std::min(_yMax[i], std::max(_yMin[i], _yHelp[i]));
        }
        // evaluate function
        try {
          calcFunction(_yHelp, _fHelp);
        }
        catch (ModelicaSimulationError& ex) {
          if (lambda < 1e-10) {
            LOGGER_WRITE_END(_lc, LL_DEBUG);
            throw;
          }
          // reduce step size
          lambda *= 0.5;
          continue;
        }
        break;
      }
      // check stopping criterion
      _iterationStatus = DONE;
      for (int i = 0; i < _dimSys; i++) {
        if (std::abs(_fHelp[i]) > atol + rtol * _fNominal[i]) {
          _iterationStatus = CONTINUE;
          break;
        }
      }
      // second do line search with quadratic approximation of phi(lambda)
      // C.T.Kelley: Solving Nonlinear Equations with Newton's Method,
      // no 1 in Fundamentals of Algorithms, SIAM 2003. ISBN 0-89871-546-6.
      double phiHelp = 0.0;
      for (int i = 0; i < _dimSys; i++) {
        _fHelp[i] /= _fNominal[i];
        phiHelp += _fHelp[i] * _fHelp[i];
      }
      while (_iterationStatus == CONTINUE) {
        // test half step that also serves as max bound for step reduction
        double lambdaTest = 0.5*lambda;
        for (int i = 0; i < _dimSys; i++) {
          _yTest[i] = _y[i] - lambdaTest * _f[i] /** _yNominal[i]*/;
          _yTest[i] = std::min(_yMax[i], std::max(_yMin[i], _yTest[i]));
        }
        calcFunction(_yTest, _fTest);
        double phiTest = 0.0;
        for (int i = 0; i < _dimSys; i++) {
          _fTest[i] /= _fNominal[i];
          phiTest += _fTest[i] * _fTest[i];
        }
        // check for sufficient decrease of phiHelp
        // and no further decrease with phiTest
        // otherwise minimize quadratic approximation of phi(lambda)
        if (phiHelp > (1.0 - alpha * lambda) * phi ||
            phiTest < (1.0 - alpha * lambda) * phiHelp) {
          long int n = 3;
          long int ipiv[3];
          double bx[] = {phi, phiTest, phiHelp};
          double A[] = {1.0, 1.0, 1.0,
                        0.0, lambdaTest, lambda,
                        0.0, lambdaTest*lambdaTest, lambda*lambda};
          dgesv_(&n, &dimRHS, A, &n, ipiv, bx, &n, &info);
          lambda = std::max(0.1*lambda, -0.5*bx[1]/bx[2]);
          if (lambda >= lambdaTest) {
            // upper bound 0.5*lambda
            lambda = lambdaTest;
            std::copy(_yTest, _yTest + _dimSys, _yHelp);
            std::copy(_fTest, _fTest + _dimSys, _fHelp);
            phiHelp = phiTest;
          }
          else {
            for (int i = 0; i < _dimSys; i++) {
              _yHelp[i] = _y[i] - lambda * _f[i] /** _yNominal[i]*/;
              _yHelp[i] = std::min(_yMax[i], std::max(_yMin[i], _yHelp[i]));
            }
            calcFunction(_yHelp, _fHelp);
            phiHelp = 0.0;
            for (int i = 0; i < _dimSys; i++) {
              _fHelp[i] /= _fNominal[i];
              phiHelp += _fHelp[i] * _fHelp[i];
            }
          }
          LOGGER_WRITE("lambda = " + to_string(lambda) +
                       ", phi = " + to_string(phi) +
                       " --> " + to_string(phiHelp),
                       _lc, LL_DEBUG);
        }
        // check for stalled step control
        if (!(lambda >= 1e-10) || !isfinite(phi)) {
          LOGGER_WRITE_END(_lc, LL_DEBUG);
          throw ModelicaSimulationError(ALGLOOP_SOLVER,
            "can't get sufficient decrease of solution"
            ", lambda = " + to_string(lambda) + ", phi = " + to_string(phi));
        }
        // check for sufficient decrease
        // (also break for very small lambda and try a small step instead
        //  -- avoid "sufficient decrease" errors, still have iteration limit)
        if (phiHelp <= (1.0 - alpha * lambda) * phi || (lambda < alpha && isfinite(phiHelp)))
          break;
      }
      // take iterate
      std::copy(_yHelp, _yHelp + _dimSys, _y);
      for (int i = 0; i < _dimSys; i++)
        _f[i] = _fHelp[i] * _fNominal[i];
      phi = phiHelp;
  } // end while

  LOGGER_WRITE_VECTOR("y*", _y, _dimSys, _lc, LL_DEBUG);
  LOGGER_WRITE_END(_lc, LL_DEBUG);
}

INonLinearAlgLoopSolver::ITERATIONSTATUS Newton::getIterationStatus()
{
  return _iterationStatus;
}

void Newton::calcFunction(const double *y, double *residual)
{
   if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  _algLoop->setReal(y);
  _algLoop->evaluate();
  _algLoop->getRHS(residual);
}

void Newton::initializeSparsity()
{
  freeSparsity();
  std::vector<std::pair<int, int> > entries;
  if (!_algLoop->getSparsityPattern(entries))
    return;

  // an analytic Jacobian is preferred, see calcJacobian
  try {
    const matrix_t& A = _algLoop->getSystemMatrix();
    _analyticJacobian = A.size1() == _dimSys && A.size2() == _dimSys;
  }
  catch (ModelicaSimulationError& ex) {
    _analyticJacobian = false;
  }
  if (_analyticJacobian)
    return;

  // compressed column format: sort by column, then row
  for (size_t k = 0; k < entries.size(); k++) {
    if (entries[k].first < 0 || entries[k].first >= _dimSys || entries[k].second < 0 || entries[k].second >= _dimSys) {
      LOGGER_WRITE("Newton: eq" + to_string(_algLoop->getEquationIndex()) + " sparsity pattern out of range, using dense Jacobian", _lc, LL_WARNING);
      return;
    }
    std::swap(entries[k].first, entries[k].second);
  }
  std::sort(entries.begin(), entries.end());
  entries.erase(std::unique(entries.begin(), entries.end()), entries.end());

  // small or dense systems are solved faster with the dense Jacobian
  int nnz = entries.size();
  if (_dimSys < 10 || nnz > 0.2 * _dimSys * _dimSys)
    return;

  _colPtr.assign(_dimSys + 1, 0);
  _rowIdx.resize(nnz);
  _jacValues.assign(nnz, 0.0);
  for (int k = 0; k < nnz; k++) {
    _colPtr[entries[k].first + 1]++;
    _rowIdx[k] = entries[k].second;
  }
  for (int j = 0; j < _dimSys; j++)
    _colPtr[j + 1] += _colPtr[j];

  // greedy coloring: columns of the same color share no row, so they can be perturbed together
  std::vector<std::vector<int> > rowCols(_dimSys);
  for (int j = 0; j < _dimSys; j++)
    for (int k = _colPtr[j]; k < _colPtr[j + 1]; k++)
      rowCols[_rowIdx[k]].push_back(j);
  std::vector<int> color(_dimSys, -1);
  std::vector<int> forbidden; // forbidden[c] == j: color c is used by a neighbor of column j
  for (int j = 0; j < _dimSys; j++) {
    for (int k = _colPtr[j]; k < _colPtr[j + 1]; k++)
      for (size_t l = 0; l < rowCols[_rowIdx[k]].size(); l++) {
        int c = color[rowCols[_rowIdx[k]][l]];
        if (c >= 0)
          forbidden[c] = j;
      }
    int c = 0;
    while (c < (int)forbidden.size() && forbidden[c] == j)
      c++;
    if (c == (int)forbidden.size()) {
      forbidden.push_back(-1);
      _colorCols.push_back(std::vector<int>());
    }
    color[j] = c;
    _colorCols[c].push_back(j);
  }

#if defined(USE_KLU)
  klu_defaults(&_kluCommon);
  _kluSymbolic = klu_analyze(_dimSys, &_colPtr[0], &_rowIdx[0], &_kluCommon);
#endif
  _sparse = true;
  LOGGER_WRITE("Newton: eq" + to_string(_algLoop->getEquationIndex()) + " uses a sparse Jacobian with "
               + to_string(nnz) + " non-zeros and " + to_string(_colorCols.size()) + " colors", _lc, LL_INFO);
}

void Newton::freeSparsity()
{
#if defined(USE_KLU)
  if (_kluNumeric)
    klu_free_numeric(&_kluNumeric, &_kluCommon);
  if (_kluSymbolic)
    klu_free_symbolic(&_kluSymbolic, &_kluCommon);
#endif
  _sparse = false;
  _analyticJacobian = false;
  _colPtr.clear();
  _rowIdx.clear();
  _jacValues.clear();
  _colorCols.clear();
}

bool Newton::calcSparseJacobian(double *fNominal)
{
  if (_analyticJacobian)
    return false;
  std::fill(fNominal, fNominal + _dimSys, 1e2 * _newtonSettings->getAtol());
  std::copy(_y, _y + _dimSys, _yHelp);
  double rtol = _newtonSettings->getRtol();

  // finite differences, all columns of a color at once
  for (size_t c = 0; c < _colorCols.size(); c++) {
    const std::vector<int>& cols = _colorCols[c];
    for (size_t l = 0; l < cols.size(); l++)
      _yHelp[cols[l]] += 1e2 * rtol * _yNominal[cols[l]];

    calcFunction(_yHelp, _fHelp);

    for (size_t l = 0; l < cols.size(); l++) {
      int j = cols[l];
      double stepsize = 1e2 * rtol * _yNominal[j];
      for (int k = _colPtr[j]; k < _colPtr[j + 1]; k++) {
        int i = _rowIdx[k];
        double value = (_fHelp[i] - _f[i]) / stepsize;
        if (!isfinite(value))
          value = 0.0; // remove infinite element in favor of potential singularity
        _jacValues[k] = value;
        fNominal[i] = std::max(std::abs(value), fNominal[i]);
      }
      _yHelp[j] = _y[j];
    }
  }

  // Scale Jacobian
  for (int k = 0; k < (int)_jacValues.size(); k++)
    _jacValues[k] /= fNominal[_rowIdx[k]];
  return true;
}

bool Newton::solveSparse()
{
#if defined(USE_KLU)
  if (!_kluSymbolic)
    return false;
  // reuse the pivoting of the last factorization unless it became inaccurate
  if (_kluNumeric) {
    if (!klu_refactor(&_colPtr[0], &_rowIdx[0], &_jacValues[0], _kluSymbolic, _kluNumeric, &_kluCommon)
        || !klu_rgrowth(&_colPtr[0], &_rowIdx[0], &_jacValues[0], _kluSymbolic, _kluNumeric, &_kluCommon)
        || _kluCommon.rgrowth < 1e-3)
      klu_free_numeric(&_kluNumeric, &_kluCommon);
  }
  if (!_kluNumeric)
    _kluNumeric = klu_factor(&_colPtr[0], &_rowIdx[0], &_jacValues[0], _kluSymbolic, &_kluCommon);
  if (!_kluNumeric)
    return false; // singular
  return klu_solve(_kluSymbolic, _kluNumeric, _dimSys, 1, _f, &_kluCommon) != 0;
#else
  return false;
#endif
}

void Newton::sparseToDense()
{
  if (!_jac)
    _jac = new double[_dimSys*_dimSys];
  std::fill(_jac, _jac + _dimSys * _dimSys, 0.0);
  for (int j = 0; j < _dimSys; j++)
    for (int k = _colPtr[j]; k < _colPtr[j + 1]; k++)
      _jac[j * _dimSys + _rowIdx[k]] = _jacValues[k];
}

void Newton::stepCompleted(double time)
{

}

void Newton::calcJacobian(double *jac, double *fNominal)
{
  if(!_algLoop)
      throw ModelicaSimulationError(ALGLOOP_SOLVER, "algloop system is not initialized");
  const double *Adata = NULL;
  std::fill(fNominal, fNominal + _dimSys, 1e2 * _newtonSettings->getAtol());

  // Use analytic Jacobian if available
  try {
    const matrix_t& A = _algLoop->getSystemMatrix();
    if (A.size1() == _dimSys && A.size2() == _dimSys) {
      Adata = A.data().begin();
      std::copy(Adata, Adata + _dimSys * _dimSys, jac);
      for (int j = 0, idx = 0; j < _dimSys; j++)
        for (int i = 0; i < _dimSys; i++, idx++) {
          if (!isfinite(jac[idx]))
            jac[idx] = 0.0; // remove infinite element in favor of potential singularity
          fNominal[i] = std::max(std::abs(jac[idx]) /** _yNominal[j]*/, fNominal[i]);
        }
    }
  }
  catch (ModelicaSimulationError& ex) {
    LOGGER_WRITE("Analytic Jacobian failed for eq" +
                 to_string(_algLoop->getEquationIndex()) + " at time " +
                 to_string(_algLoop->getSimTime()) + ": " + ex.what(),
                 _lc, LL_WARNING);
  }

  // Alternatively apply finite differences
  if (Adata == NULL) {
    for (int j = 0; j < _dimSys; j++) {
      // Reset variables for every column
      std::copy(_y, _y + _dimSys, _yHelp);
      double stepsize = 1e2 * _newtonSettings->getRtol() * _yNominal[j];

      // Finite differences
      _yHelp[j] += stepsize;

      calcFunction(_yHelp, _fHelp);

      // Build Jacobian in Fortran format
      for (int i = 0, idx = j * _dimSys; i < _dimSys; i++, idx++) {
        jac[idx] = (_fHelp[i] - _f[i]) / stepsize;
        if (!isfinite(jac[idx]))
          jac[idx] = 0.0; // remove infinite element in favor of potential singularity
        fNominal[i] = std::max(std::abs(jac[idx]) /** _yNominal[j]*/, fNominal[i]);
      }

      _yHelp[j] -= stepsize;
    }
  }

  // Scale Jacobian
  LOGGER_WRITE_VECTOR("fNominal", fNominal, _dimSys, _lc, LL_DEBUG);
  for (int j = 0, idx = 0; j < _dimSys; j++)
    for (int i = 0; i < _dimSys; i++, idx++)
      //jac[idx] *= _yNominal[j] / fNominal[i];
      jac[idx] /= fNominal[i];
}
bool* Newton::getConditionsWorkArray()
{
	return AlgLoopSolverDefaultImplementation::getConditionsWorkArray();

}
bool* Newton::getConditions2WorkArray()
{

	return AlgLoopSolverDefaultImplementation::getConditions2WorkArray();
 }


 double* Newton::getVariableWorkArray()
 {

	return AlgLoopSolverDefaultImplementation::getVariableWorkArray();

 }
void Newton::restoreOldValues()
{
}

void Newton::restoreNewValues()
{
}

/** @} */ // end of solverNewton
