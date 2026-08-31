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

#pragma once

#include "FactoryExport.h"

#include <Core/Solver/SolverDefaultImplementation.h>
#include <Core/Utils/extension/measure_time.hpp>


/*****************************************************************************/
// Peer
// BDF-Verfahren für steife und nicht-steife ODEs
// Dokumentation siehe offizielle Peer Doku


#if defined(USE_MPI) || defined(USE_OPENMP)
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





  // Nulltellenfunktion
  void writePeerOutput(const double &time,const double &h,const int &stp);
  void evalJ(const double& t, const double* z, double* T, IContinuous *continuousSystem, ITime *timeSystem, double fac=1);
  void evalF(const double& t, const double* z, double* f, IContinuous *continuousSystem, ITime *timeSystem);
  void evalD(const double& t, const double* y, double* T, IContinuous *continuousSystem, ITime *timeSystem);
  void setcycletime(double cycletime);
  void ros2(double * y, double& tstart, double tend, IContinuous *continuousSystem, ITime *timeSystem);

  ISolverSettings
    *_peersettings;              ///< Input      - Solver settings

  long int
    _dimSys;                 ///< Input       - (total) Dimension of system (=number of ODE)


    int
        _rstages,
        _rank,
        _size,
        _reuseJacobi,
        _numThreads;

    long int
        *_P;

    double
        *_G,
        *_E,
        *_Theta,
        *_c,
        *_F,
        *_y,
        *_Y1,
        *_Y2,
        *_Y3,
        *_T,
        _h,
        _hOut;



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
   IContinuous* _continuous_system[5];
//   IEvent* _event_system;
//   IMixedSystem* _mixed_system;
   ITime* _time_system[5];

//   std::vector<MeasureTimeData> measureTimeFunctionsArray;
//   MeasureTimeValues *measuredFunctionStartValues, *measuredFunctionEndValues;

};
#else
class Peer : public ISolver, public SolverDefaultImplementation
{
public:
    Peer(IMixedSystem* system, ISolverSettings* settings) : ISolver(), SolverDefaultImplementation(system, settings)
    {
        throw std::runtime_error("Peer solver is not available.");
    }

    virtual void setStartTime(const double& time)
    {
    }

    virtual void setEndTime(const double& time)
    {
    }

    virtual void setInitStepSize(const double& stepSize)
    {
    }

    virtual void initialize()
    {
    }

    virtual bool stateSelection()
    {
        throw std::runtime_error("Peer solver is not available.");
    }

    virtual void solve(const SOLVERCALL command = UNDEF_CALL)
    {
    }

    virtual SOLVERSTATUS getSolverStatus()
    {
        return UNDEF_STATUS;
    }

    virtual void setTimeOut(unsigned int time_out)
    {
    }


    virtual void stop()
    {
    }

    virtual void writeSimulationInfo()
    {
    }
};
#endif
