/** @defgroup solverDASSL Solver.DASSL
 *  DASSL wrapper accessing Cdaskr from OMCompiler/3rdParty
 *  @{
 */

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 */

#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>

#ifdef RUNTIME_PROFILING
  #include <Core/Utils/extension/measure_time.hpp>
#endif

class DASSL
  : public ISolver,  public SolverDefaultImplementation
{
public:

  DASSL(IMixedSystem* system, ISolverSettings* settings);

  virtual ~DASSL();

  /// initialize solver (and settings through base class SolverDefaultImplementation)
  virtual void initialize();


  virtual void setStartTime(const double& time)
  {
    SolverDefaultImplementation::setStartTime(time);
  }

  virtual void setEndTime(const double& time)
  {
    SolverDefaultImplementation::setEndTime(time);
  }

  virtual void setInitStepSize(const double& stepSize)
  {
    SolverDefaultImplementation::setInitStepSize(stepSize);
  }

  /// call solver
  virtual void solve(const SOLVERCALL command = UNDEF_CALL);

  virtual ISolver::SOLVERSTATUS getSolverStatus()
  {
    return (SolverDefaultImplementation::getSolverStatus());
  }

  virtual void writeSimulationInfo();

  virtual void setTimeOut(unsigned int time_out);

  virtual void stop();

  virtual bool stateSelection();

private:

  // solver call
  void DASSLCore();

  /// evaluate right hand side of ODE
  int calcFunction(const double& time, const double* y, double* yp);

  // callback for right hand side
  static int _res(double *t, double *y, double *yp, double *cj,
	                double *delta, int *ires, double *rpar, int *ipar);

  // roots
  int calcRoots(double t, const double *y, double *zeroValue);

  // callback for roots
  static int _rt(int *neq, double *t, double *y, double *yp,
                 int *nrt, double *rval, double *rpar, int *ipar);

  bool isInterrupted();

  // Jacobian
  static int _jac(double *t, double *y, double *yp, double *delta,
                  double *pd, double *cj, double *h, double *wt, double *rpar, int *ipar);
  int calcJacobian(double t, double *y, double *yp, double *delta,
                   double *pd, double cj, double h, double *wt);

  int
    _idid,
    *_zeroSign,     ///< vector of signs of zero crossings
    *_info,         ///< solver configuration
    *_iwork,        ///< integer work array
    *_iworkAcc,     ///< accumulated statistics from iwork
    _liw,           ///< length of iwork
    _lrw;           ///< length of rwork

  double
    *_rwork,        ///< real work array
    *_y,            ///< state vector
    *_yPrime,       ///< state derivatives
    *_rtol,         ///< vector of relative tolerances
    *_atol,         ///< vector of absolute tolerances
    *_yJac,         ///< states for Jacobian evaluation
    *_dyJac,        ///< deltas for Jacobian evaluation
    *_fJac,         ///< function results for Jacobian evaluation
    _tLastEvent;    ///< last event time point

  unsigned int
    _event_n;       ///< event counter

  bool
    _zeroFound;     ///< event detection

  // Variables for Coloured Jacobians
  int  _maxColors;

  ISystemProperties* _properties;
  IContinuous* _continuous_system;
  IEvent* _event_system;
  IMixedSystem* _mixed_system;
  ITime* _time_system;

  #ifdef RUNTIME_PROFILING
  std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
  MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues, *solveFunctionStartValues, *solveFunctionEndValues;
  MeasureTimeValuesSolver *solverValues;
  #endif
};
/** @} */ // end of solverDASSL
