#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>

#include <nvector/nvector_serial.h>   // serial N_Vector types, fcts., macros
// ARKode includieren
//#include <cvode/cvode.h>

/*
*/



/*****************************************************************************/
// Cvode aus dem SUNDIALS-Package
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Cvode Doku

/*****************************************************************************
Copyright (c) 2004, Bosch Rexroth AG, All rights reserved
*****************************************************************************/
class Arkode
  : public ISolver,  public SolverDefaultImplementation
{
public:

  Arkode(IMixedSystem* system, ISolverSettings* settings);

  virtual ~Arkode();

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
  void ArkodeCore();

  /// Kapselung der Berechnung der rechten Seite
  int calcFunction(const double& time, const double* y, double* yd);

  // Callback für die rechte Seite
  //static int CV_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data);
  static int ARK_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data);

  // Checks error flags of SUNDIALS
  int check_flag(void *flagvalue, const char *funcname, int opt);

  // Nulltellenfunktion
  void giveZeroVal(const double &t,const double *y,double *zeroValue);
  void writeArkodeOutput(const double &time,const double &h,const int &stp);
  bool isInterrupted();
  // Callback der Nullstellenfunktion
  static int ARK_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data);

  // Functions for Coloured Jacobian
  //static int CV_JCallback(long int N, realtype t, N_Vector y, N_Vector fy, DlsMat Jac,void *user_data, N_Vector tmp1, N_Vector tmp2, N_Vector tmp3);
  //int calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthcol, double* y, N_Vector fy, DlsMat Jac);
  //void initializeColoredJac();



  ISolverSettings
    *_arkodesettings;              ///< Input      - Solver settings

  void
    *_arkodeMem,                  ///< Temp      - Memory for the solver
    *_data;                    ///< Temp      - User data. Contains pointer to Cvode

  long int
    _dimSys,                  ///< Input       - (total) Dimension of system (=number of ODE)
    _idid,                    ///< Input, Output  - Status Flag
    _locStps,                  ///< Output      - Number of Steps between two events
    _ark_rt;            ///< Temp    - CVode return flag

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
    _ARK_y0,                  ///< Temp      - Initial values in the Cvode Format
    _ARK_y,                  ///< Temp      - State in Cvode Format
    _ARK_yWrite,             ///< Temp      - Vector for dense out
    _ARK_absTol;

  // Variables for Coloured Jacobians
  /*
  int* _colorOfColumn;
  int  _maxColors;
  SparseMatrix _jacobianA;
  int _jacobianANonzeros;
  int const* _jacobianAIndex;
  int const* _jacobianALeadindex;
*/



  bool _arkode_initialized;


   ISystemProperties* _properties;
   IContinuous* _continuous_system;
   IEvent* _event_system;
   IMixedSystem* _mixed_system;
   ITime* _time_system;

   #ifdef RUNTIME_PROFILING
   std::vector<MeasureTimeData> measureTimeFunctionsArray;
   MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues, *solveFunctionStartValues, *solveFunctionEndValues;
   MeasureTimeValuesSolver *solverValues;
   #endif
};

