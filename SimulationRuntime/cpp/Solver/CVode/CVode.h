
#pragma once

#include "FactoryExport.h"

#include <Solver/SolverDefaultImplementation.h>
#include <cvodes.h>
#include <nvector_serial.h>
#include <cvodes_dense.h>



/*****************************************************************************/
// Cvode aus dem SUNDIALS-Package
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Cvode Doku

/*****************************************************************************
Copyright (c) 2004, Bosch Rexroth AG, All rights reserved
*****************************************************************************/
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
  virtual const ISolver::SOLVERSTATUS getSolverStatus()
  {
    return (SolverDefaultImplementation::getSolverStatus());
  };

  //// Ausgabe von statistischen Informationen (wird vom SimManager nach Abschluß der Simulation aufgerufen)
  virtual void writeSimulationInfo();


  virtual const int reportErrorMessage(ostream& messageStream);
private:

  // Solveraufruf
  void CVodeCore();

  /// Kapselung der Berechnung der rechten Seite
  int calcFunction(const double& time, const double* y, double* yd);

  // Callback für die rechte Seite
  static int CV_fCallback(double t, N_Vector y, N_Vector ydot, void *user_data);

  // Checks error flags of SUNDIALS
  int check_flag(void *flagvalue, char *funcname, int opt);

  // Nulltellenfunktion
  void giveZeroVal(const double &t,const double *y,double *zeroValue);
  void writeCVodeOutput(const double &time,const double &h,const int &stp);
 
  // Callback der Nullstellenfunktion
  static int CV_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data);


  ISolverSettings
    *_cvodesettings;              ///< Input      - Solver settings

  void
    *_cvodeMem,                  ///< Temp      - Memory for the solver
    *_data;                    ///< Temp      - User data. Contains pointer to Cvode

  long int
    _dimSys,                  ///< Input       - (total) Dimension of system (=number of ODE)
    _idid,                    ///< Input, Output  - Status Flag
    _locStps;                  ///< Output      - Number of Steps between two events

  int
    _outStps,                  ///< Output      - Total number of output-steps
    *_zeroSign;


  double
    *_z,            ///< Output      - (Current) State vector
    *_zInit,          ///< Temp      - Initial state vector
    *_zWrite;                   ///< Temp      - Zustand den das System rausschreibt
   
  double
    _hOut;            ///< Temp      - Ouput step size for dense output
   



  double 
    _tOut,            ///< Output      - Time for dense output
    _tZero,            ///< Temp      - Nullstelle
    _tLastWrite;        ///< Temp      - Letzter Ausgabezeitpunkt

  bool
    _bWritten,                  ///< Temp      - Is output already written
    _zeroFound,
    _cv_rt;            ///< Temp    - CVode return flag
   
   

  N_Vector
    _CV_y0,                  ///< Temp      - Initial values in the Cvode Format
    _CV_y,                  ///< Temp      - State in Cvode Format
      _CV_yWrite;                ///< Temp      - Vector for dense out
  bool _cvode_initialized;

   ISystemProperties* _properties; 
   IContinuous* _continuous_system;
   IEvent* _event_system;
   IMixedSystem* _mixed_system;
   ITime* _time_system;
};

