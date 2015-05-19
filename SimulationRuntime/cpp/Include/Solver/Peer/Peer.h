
#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Utils/extension/measure_time.hpp>


/*****************************************************************************/
// Peer
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Peer Doku

/*****************************************************************************
Copyright (c) 2014, IWR TU Dresden, All rights reserved
*****************************************************************************/
class Peer
  : public ISolver,  public SolverDefaultImplementation
{
public:

  Peer(IMixedSystem* system, ISolverSettings* settings);

  virtual ~Peer();

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


  virtual int reportErrorMessage(std::ostream& messageStream);
  virtual bool stateSelection();
  virtual void setTimeOut(unsigned int time_out);
    virtual void stop();
private:

  // Solveraufruf
  void PeerCore();

  /// Kapselung der Berechnung der rechten Seite
  int calcFunction(const double& time, const double* y, double* yd);

  // Checks error flags of SUNDIALS
  int check_flag(void *flagvalue, const char *funcname, int opt);

  // Nulltellenfunktion
  void writePeerOutput(const double &time,const double &h,const int &stp);

  //int calcJacobian(double t, long int N, N_Vector fHelp, N_Vector errorWeight, N_Vector jthcol, double* y, N_Vector fy, DlsMat Jac);
  void initializeColoredJac();

  void setcycletime(double cycletime);


  ISolverSettings
    *_peersettings;              ///< Input      - Solver settings

/*
  void
    *_cvodeMem,                  ///< Temp      - Memory for the solver
    *_data;                    ///< Temp      - User data. Contains pointer to Peer

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
    _CV_y0,                  ///< Temp      - Initial values in the Peer Format
    _CV_y,                  ///< Temp      - State in Peer Format
    _CV_yWrite,        ///< Temp      - Vector for dense out
    _CV_absTol;

  // Variables for Coloured Jacobians
  int  _sizeof_sparsePattern_colorCols;
  int* _sparsePattern_colorCols;

  int  _sizeof_sparsePattern_leadindex;
  int* _sparsePattern_leadindex;


  int  _sizeof_sparsePattern_index;
  int* _sparsePattern_index;


  int  _sparsePattern_maxColors;

  bool _cvode_initialized;


   ISystemProperties* _properties;
   IContinuous* _continuous_system;
   IEvent* _event_system;
   IMixedSystem* _mixed_system;
   ITime* _time_system;

   std::vector<MeasureTimeData> measureTimeFunctionsArray;
   MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
*/
};

