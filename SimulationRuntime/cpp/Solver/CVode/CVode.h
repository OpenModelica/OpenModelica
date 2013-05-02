
#pragma once

#define BOOST_EXTENSION_SOLVER_DECL BOOST_EXTENSION_EXPORT_DECL

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
class ICVodeSettings;

class Cvode
  : public IDAESolver,  public SolverDefaultImplementation
{
public:

  Cvode(IMixedSystem* system, ISolverSettings* settings);

  virtual ~Cvode();

  // geerbt von Object (in SolverDefaultImplementation)
  //---------------------------------------
  /// Spezielle Solvereinstellungen setzten (default oder user defined)
  virtual void init();


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

  /*/// Liefert den Zeitpunkt des letzten erfolgreichen Zeitschrittes (kann ~= tend sein)
  virtual const double& getCurrentTime()
  {
  return (SolverDefaultImplementation::getCurrentTime());
  };*/

  /// Liefert den Status des Solvers nach Beendigung der Simulation
  virtual const IDAESolver::SOLVERSTATUS getSolverStatus()
  {
    return (SolverDefaultImplementation::getSolverStatus());
  };

  /*/// Liefert Anzahl der Schritte im Zeitintervall
  virtual void giveNumberOfSteps(int& totStps, int& accStps, int& rejStps)
  {
  SolverDefaultImplementation::giveNumberOfSteps(totStps, accStps, rejStps);
  };

  /// Liefert Anzahl der Schritte der Nullstellensuche und die Anzahl der Nullstellen im gesamten Integrationsintervall
  virtual void giveZeroSteps(int& zeroSearchStps, int& numberOfZeros)
  {
  SolverDefaultImplementation::giveZeroSteps(zeroSearchStps,numberOfZeros);
  };*/


  /*/// Veranlasst, dass die Ausgaberoutine des Solvers (writeSolverOutput) nach jedem Schritt aufgerufen wird
  virtual void activateSolverOutput(const bool& flag)
  {
  SolverDefaultImplementation::activateSolverOutput(flag);
  };

  /// Output-Stream, in den die Ausgabe des Solvers erfolgen soll, setzen
  virtual void setOutputStream(ostream& outputStream)
  {
  SolverDefaultImplementation::setOutputStream(outputStream);
  };
  */
  //// Ausgabe von statistischen Informationen (wird vom SimManager nach Abschluß der Simulation aufgerufen)
  virtual void writeSimulationInfo();

  /// Anfangszustand (und entsprechenden Zeitpunkt) des Systems (als Kopie) speichern
  virtual void saveInitState();

  /// Anfangszustand (und entsprechenden Zeitpunkt) zurück ins System kopieren
  virtual void restoreInitState();

  /// Letzten gültigen Zustand (und entsprechenden Zeitpunkt) des Systems (als Kopie) speichern
  virtual void saveLastSuccessfullState();

  /// Letzten gültigen Zustand  (und entsprechenden Zeitpunkt) zurück ins System kopieren
  virtual void restoreLastSuccessfullState();

  /// speichert den Zustand (und entsprechenden Zeitpunkt) des Systems (als Kopie) nach einem "großen Schritt" bei partitionierter Integration
  virtual void saveLargeStepState();

  /// liefert den normierten Fehler zwischen aktuellem Zustand und Zustand nach einem "großen Schritt" bei partitionierter Integration
  virtual void giveScaledError(const double& h, double& error);

  /// Approximation höherer Ordnung des Zustandes berechnen und in System kopieren

  virtual void refineCurrentState(const double& r);
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
  void doTimeEvents();
  // Callback der Nullstellenfunktion
  static int CV_ZerofCallback(double t, N_Vector y, double *zeroval, void *user_data);


  ICVodeSettings
    *_cvodesettings;        ///< Input      - Solver settings

  void
    *_cvodeMem,            ///< Temp      - Memory for the solver
    *_data;              ///< Temp      - User data. Contains pointer to Cvode

  long int
    _dimSys,            ///< Input       - (total) Dimension of system (=number of ODE)
    _idid,              ///< Input, Output  - Status Flag
    _locStps;            ///< Output      - Number of Steps between two events

  int
    _outStps,            ///< Output      - Total number of output-steps
    _updateCalls,          ///< Output      - Total number of update calls
    *_zeroSign;


  double
    *_z,              ///< Output      - (Current) State vector
    *_z0,              ///< Temp      - (Old) state vector at left border of intervall (last step)
    *_z1,              ///< Temp      - (New) state vector at right border of intervall (last step)
    *_zInit,            ///< Temp      - Initial state vector
    *_zLastSucess,          ///< Temp      - State vector of last successfull step
    *_zLargeStep,          ///< Temp      - State vector of "large step" (used by "coupling step size controller" of SimManger)
    *_zWrite,            ///< Temp      - Zustand den das System rausschreibt
    *_f0,
    *_f1;

  double
    _hOut,              ///< Temp      - Ouput step size for dense output
    _hZero,              ///< Temp      - Downscale of step size to approach the zero crossing
    _hUpLim,            ///< Temp       - Maximal step size
    _hZeroCrossing,          ///< Temp       - Stores the current step size (at the time the zero crossing occurs)
    _hUpLimZeroCrossing;      ///< Temp       - Stores the upper limit of the step size (at the time the zero crossing occurs), because it is changed for zero search



  double
    _tOut,              ///< Output      - Time for dense output
    _tHelp,              ///< Temp      - Help variable
    _tLastZero,           ///< Temp      - Stores the time of the last zero (not last zero crossing!)
    _tRealInitZero,          ///< Temp      - Time of the very first zero in all zero functions
    _doubleZeroDistance,      ///< Temp      - In case of two zeros in one intervall (doubleZero): distance between zeros
    _tZero,              ///< Temp      - Nullstelle
    _tLastWrite;          ///< Temp      - Letzter Ausgabezeitpunkt

  bool
    _doubleZero,          ///< Temp      - Flag to denote two zeros in intervall
    _zeroFound,            ///< Temp      - Flag to denote a root in he last step
    _bWritten,            ///< Temp      - Is output already written
    *_Cond,
    *_zeroInit;

  N_Vector
    _CV_y0,            ///< Temp      - Initial values in the Cvode Format
    _CV_y,            ///< Temp      - State in Cvode Format
      _CV_yWrite;          ///< Temp      - Vector for dense out
  bool _cvode_initialized;
};

