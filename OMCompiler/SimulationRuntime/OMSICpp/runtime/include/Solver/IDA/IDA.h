
#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>
#include <idas/idas.h>
#include <nvector/nvector_serial.h>
#include <sundials/sundials_direct.h>
#include <idas/idas_dense.h>


#ifdef RUNTIME_PROFILING
  #include <Core/Utils/extension/measure_time.hpp>
#endif

#include <Core/Utils/extension/logger.hpp>

/*****************************************************************************/
// IDA aus dem SUNDIALS-Package
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle IDA Doku

/*****************************************************************************
Copyright (c) 2004, Bosch Rexroth AG, All rights reserved
*****************************************************************************/
class Ida
  : public ISolver,  public SolverDefaultImplementation
{
public:

  Ida(IMixedSystem* system, ISolverSettings* settings);

  virtual ~Ida();

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
  void IDACore();

  /// Kapselung der Berechnung der rechten Seite
  int calcFunction(const double& time, const double* y,double *yp, double* res);

  // Callback für die rechte Seite
  static int rhsFunctionCB(double t, N_Vector y, N_Vector ydot, N_Vector, void *user_data);
  static void errOutputIDA(int error_code, const char *module, const char *function,    char *msg, void *userData);
  // Checks error flags of SUNDIALS
  int check_flag(void *flagvalue, const char *funcname, int opt);

  // Nulltellenfunktion
  void giveZeroVal(const double &t,const double *y,const double *yp,double *zeroValue);
  void writeIDAOutput(const double &time,const double &h,const int &stp);
  bool isInterrupted();
  // Callback der Nullstellenfunktion
  static int zeroFunctionCB(double t, N_Vector y, N_Vector yp, double *zeroval, void *user_data);

  // Functions for Coloured Jacobian
  static int jacobianFunctionCB(long int N, realtype t, N_Vector y, N_Vector fy, DlsMat Jac,void *user_data, N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);
  int calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthcol, double* y, N_Vector fy, DlsMat Jac);




  ISolverSettings
    *_idasettings;              ///< Input      - Solver settings

  void
    *_idaMem,                  ///< Temp      - Memory for the solver
    *_data;                    ///< Temp      - User data. Contains pointer to ida

  long int
    _dimSys,                  ///< Input       - (total) Dimension of system (=number of ODE)
	_dimStates,
	_dimAE,
    _idid,                    ///< Input, Output  - Status Flag
    _locStps,                  ///< Output      - Number of Steps between two events
     _cv_rt;            ///< Temp    - ida return flag

  int
    _outStps,                  ///< Output      - Total number of output-steps
    *_zeroSign;


  double
    /*old state vector
	*_z,               ///< Output      - (Current) State vector
    *_zInit,          ///< Temp      - Initial state vector
    *_zWrite,         ///< Temp      - Zustand den das System rausschreibt
	*/
    *_absTol,         ///         - Vektor für absolute Toleranzen
    *_delta,
    *_deltaInv,
    *_ysave,
    *_y,                  ///< Output      - (Current) State vector and dae vars vector
	*_yInit,
	*_yWrite,
	*_ypWrite,
    *_yp,   			     ///< Output      - (Current) Derivatives for State vector and dae vars vector
	*_dae_res;
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
    _CV_y0,                  ///< Temp      - Initial values in the ida Format
    _CV_y,                  ///< Temp      - State in ida Format
    _CV_yp,    ///<Temp   - Stateders in ida Format
    _CV_yWrite,        ///< Temp      - Vector for dense out
    _CV_ypWrite,
    _CV_absTol;

  // Variables for Coloured Jacobians
  int* _colorOfColumn;
  int  _maxColors;
  matrix_t _jacobianA;
  int _jacobianANonzeros;
  int const* _jacobianAIndex;
  int const* _jacobianALeadindex;


  bool _ida_initialized;


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

