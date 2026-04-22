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

/** @defgroup solverCvode Solver.CVode
 *  CVode class wrapper from sundials package
 *  @{
 */
#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>

#include <cvode/cvode.h>
#include <nvector/nvector_serial.h>
#include <sunlinsol/sunlinsol_dense.h>       /* Default dense linear solver */
#ifdef USE_SUNDIALS_LAPACK
  #include <sunlinsol/sunlinsol_lapackdense.h> /* Lapack dense linear solver */
#endif //USE_SUNDIALS_LAPACK
#include <sunlinsol/sunlinsol_spgmr.h>       /* Iterative linear solver */

#ifdef RUNTIME_PROFILING
  #include <Core/Utils/extension/measure_time.hpp>
#endif

#include <Core/Utils/extension/logger.hpp>

/*****************************************************************************/
// Cvode aus dem SUNDIALS-Package
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Cvode Doku


class Cvode
  : public ISolver,  public SolverDefaultImplementation
{
public:

  Cvode(IMixedSystem* system, ISolverSettings* settings);

  virtual ~Cvode();

  // geerbt von Object (in SolverDefaultImplementation)
  //---------------------------------------
  /// Spezielle Solvereinstellungen setzten (default oder user defined)
  virtual void initialize();


  // geerbt von ISolver
  //---------------------------------------
  /// Setzen der Startzeit für die numerische Lösung
  virtual void setStartTime(const double& time)
  {
    SolverDefaultImplementation::setStartTime(time);
  };

  /// Setzen der Endzeit für die numerische Lösung
  virtual void setEndTime(const double& time)
  {
    SolverDefaultImplementation::setEndTime(time);
  };

  /// Setzen der initialen Schrittweite (z.B. auch nach Nullstelle)
  virtual void setInitStepSize(const double& stepSize)
  {
    SolverDefaultImplementation::setInitStepSize(stepSize);
  };

  /// Berechung der numerischen Lösung innerhalb eines gegebenen Zeitintervalls
  virtual void solve(const SOLVERCALL command = UNDEF_CALL);

  /// Liefert den Status des Solvers nach Beendigung der Simulation
  virtual ISolver::SOLVERSTATUS getSolverStatus()
  {
    return (SolverDefaultImplementation::getSolverStatus());
  };

  //// Ausgabe von statistischen Informationen (wird vom SimManager nach Abschluß der Simulation aufgerufen)
  virtual void writeSimulationInfo();
   virtual void setTimeOut(unsigned int time_out);

    virtual void stop();

  virtual int reportErrorMessage(std::ostream& messageStream);
  virtual bool stateSelection();
private:

  // Solveraufruf
  void CVodeCore();

  /// Kapselung der Berechnung der rechten Seite
  int calcFunction(const double& time, const double* y, double* yd);

  // Callback für die rechte Seite
  static int CV_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data);

  // Checks error flags of SUNDIALS
  int check_flag(void *flagvalue, const char *funcname, int opt);

  // Nulltellenfunktion
  void giveZeroVal(const double &t,const double *y,double *zeroValue);
  void writeCVodeOutput(const double &time,const double &h,const int &stp);
  bool isInterrupted();
  // Callback der Nullstellenfunktion
  static int CV_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data);

  // Functions for Coloured Jacobian
  static int CV_JCallback(long int N, realtype t, N_Vector y, N_Vector fy, DlsMat Jac,void *user_data, N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);
  int calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthcol, double* y, N_Vector fy, DlsMat Jac);
  void initializeColoredJac();

  ISolverSettings
    *_cvodesettings;              ///< Input      - Solver settings

  void
    *_cvodeMem,                  ///< Temp      - Memory for the solver
    *_data;                    ///< Temp      - User data. Contains pointer to Cvode

  long int
    _dimSys,                  ///< Input       - (total) Dimension of system (=number of ODE)
    _idid,                    ///< Input, Output  - Status Flag
    _locStps,                  ///< Output      - Number of Steps between two events
     _cv_rt;            ///< Temp    - CVode return flag

  int
    _outStps,                  ///< Output      - Total number of output-steps
    *_zeroSign;


  double
    *_z,            ///< Output      - (Current) State vector
    *_zInit,          ///< Temp      - Initial state vector
    *_zWrite,                   ///< Temp      - Zustand den das System rausschreibt
    *_absTol,          ///         - Vektor für absolute Toleranzen
  *_delta,
  *_deltaInv,
  *_ysave;


  double
    _hOut;            ///< Temp      - Ouput step size for dense output

   unsigned int
    _event_n;
double
  _tLastEvent;

  double
    _tOut,            ///< Output      - Time for dense output
    _tZero,            ///< Temp      - Nullstelle
    _tLastWrite;        ///< Temp      - Letzter Ausgabezeitpunkt

  bool
    _bWritten,                  ///< Temp      - Is output already written
    _zeroFound;




  N_Vector
    _CV_y0,                  ///< Temp      - Initial values in the Cvode Format
    _CV_y,                  ///< Temp      - State in Cvode Format
    _CV_yWrite,        ///< Temp      - Vector for dense out
    _CV_absTol,
    _CV_ySolver;    ///< Temp      - Vector templated used by linear solver

  SUNLinearSolver
    _CV_linSol;     ///< Temp      - Linear solver object used by CVODE

  SUNMatrix
    _CV_J;          ///< Temp      - Matrix template for cloning matrices needed within linear solver


  // Variables for Coloured Jacobians
  int* _colorOfColumn;
  int  _maxColors;
  matrix_t _jacobianA;
  int _jacobianANonzeros;
  int const* _jacobianAIndex;
  int const* _jacobianALeadindex;




  bool _cvode_initialized;


   ISystemProperties* _properties;
   IContinuous* _continuous_system;
   IEvent* _event_system;
   IMixedSystem* _mixed_system;
   ITime* _time_system;

   int _numberOfOdeEvaluations;

   #ifdef RUNTIME_PROFILING
   std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
   MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues, *solveFunctionStartValues, *solveFunctionEndValues;
   MeasureTimeValuesSolver *solverValues;
   #endif
};
/** @} */ // end of solverCvode
