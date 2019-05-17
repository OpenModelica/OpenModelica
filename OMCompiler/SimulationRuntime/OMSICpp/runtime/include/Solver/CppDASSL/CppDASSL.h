
#pragma once

#include "FactoryExport.h"
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Utils/extension/measure_time.hpp>
#include <Solver/CppDASSL/dassl.h>

#if defined(USE_OPENMP)
/*****************************************************************************/
// Peer
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Peer Doku

/*****************************************************************************
Copyright (c) 2014, IWR TU Dresden, All rights reserved
*****************************************************************************/

class CppDASSL
  : public ISolver,  public SolverDefaultImplementation
{
public:

  CppDASSL(IMixedSystem* system, ISolverSettings* settings);

  virtual ~CppDASSL();

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





  // Nulltellenfunktion
  void writeCppDASSLOutput(const double &time,const double &h,const int &stp);

  ISolverSettings
    *_cppdasslsettings;              ///< Input      - Solver settings

  dassl
    dasslSolver;

  double
    *_y,
    *_yp,
    _hOut;
  int
    _dimSys,               ///< Input       - (total) Dimension of system (=number of ODE)
    _dimZeroFunc,
    *_jroot,
    _numThreads;
  void
    *_data;

  static int res(const double* t, const double* y, const double* yprime, double* cj, double* delta, int* ires, void *par);
  int calcFunction(const double* t, const double* y, const double* yprime, double* cj, double* delta, int* ires);
  static int zeroes(const int* NEQ, const double* T, const double* Y, const double* YP, int* NRT, double* RVAL, void *par);
  void giveZeroVal(const double &t, const double *y, double *zeroValue);
  // Variables for Coloured Jacobians
//  int  _sizeof_sparsePattern_colorCols;
//  int* _sparsePattern_colorCols;
//
//  int  _sizeof_sparsePattern_leadindex;
//  int* _sparsePattern_leadindex;
//
//
//  int  _sizeof_sparsePattern_index;
//  int* _sparsePattern_index;
//
//
//  int  _sparsePattern_maxColors;
//
//  bool _cvode_initialized;


//   ISystemProperties* _properties;
   vector<IContinuous*> _continuous_systems;
//   IEvent* _event_system;
//   IMixedSystem* _mixed_system;
   vector<ITime*> _time_systems;
   IEvent* _event_system;
   vector<IMixedSystem*> _mixed_systems;
   vector<IStateSelection*> _state_selections;
//   std::vector<MeasureTimeData> measureTimeFunctionsArray;
//   MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;
   DynArrayDim2<int> _matrix;
   double* _states;

};
#else
class CppDASSL : public ISolver, public SolverDefaultImplementation
{
public:
	CppDASSL(IMixedSystem* system, ISolverSettings* settings) : ISolver(), SolverDefaultImplementation(system, settings)
	{
		throw std::runtime_error("CppDASSL solver is not available.");
	}

	virtual void setStartTime(const double& time)
	{}

	virtual void setEndTime(const double& time)
	{}

	virtual void setInitStepSize(const double& stepSize)
	{}

	virtual void initialize()
	{}

	virtual bool stateSelection()
	{
		throw std::runtime_error("Peer solver is not available.");
	}

	virtual void solve(const SOLVERCALL command = UNDEF_CALL)
	{}

	virtual SOLVERSTATUS getSolverStatus()
	{ return UNDEF_STATUS; }

	/* virtual void setTimeOut(unsigned int time_out)
	{} */
    virtual void setTimeOut(double time_out)
	{}

	virtual void stop()
	{}

	virtual void writeSimulationInfo()
	{}

};
#endif
