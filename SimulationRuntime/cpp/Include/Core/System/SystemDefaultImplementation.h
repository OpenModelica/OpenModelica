#pragma once
#define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
#include <System/IMixedSystem.h>          // System interface
#include <System/IContinuous.h>          // System interface
#include <System/IEvent.h>              // System interface
#include <System/ISystemProperties.h>          // System Properties interface
#include <System/ISystemInitialization.h>          // System Initialization interface
#include <SimulationSettings/IGlobalSettings.h>
#include <Math/Functions.h>  // Include for use of abs
#include <System/EventHandling.h>




/*****************************************************************************/
/**

Services, which can be used by systems.
Implementation of standart functions (e.g. giveRHS(...), etc.).
Provision of member variables used by all systems.

Note:
The order of variables in the extended state vector perserved (see: "Sorting
variables by using the index" in "Design proposal for a general solver interface
for Open Modelica", September, 10 th, 2008


\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

typedef boost::unordered_map<std::string, boost::any> SValuesMap;

class BOOST_EXTENSION_SYSTEM_DECL SystemDefaultImplementation
{
public:
    SystemDefaultImplementation(IGlobalSettings& globalSettings);

    ~SystemDefaultImplementation();

    /// Provide number (dimension) of variables according to the index
     int getDimVars() const    ;


    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
     int getDimRHS() const;


    /// (Re-) initialize the system of equations
     void init();
    /// Set current integration time
     void setTime(const double& t);


    /// Provide variables with given index to the system
    void giveVars(double* z);

    /// Set variables with given index to the system
    void setVars(const double* z);

    /// Provide the right hand side (according to the index)
    void giveRHS(double* f);
    // Member variables

protected:
     void Assert(bool cond,string msg);
     void Terminate(string msg);
    template<class T>
    T getStartValue(T variable,string key)
    {
  try
  {
      return boost::any_cast<T>(_start_values[key]);
  }
  catch(const boost::bad_any_cast & ex)
  {
      std::runtime_error("No such start value");
  }
    };
    double
  time;                ///< current simulation time (given by the solver)

    double
  *__z,        ///< "Extended state vector", containing all states and algebraic variables of all types
  *__zDot;       ///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations
    bool
  * _conditions;        ///< External conditions changed by the solver
    int
  _dimFunc,                        ///< Dimension der rechten Seite
  _dimVars,                        ///< Dimesion des Zustandsvektors
  _dimZeroFunc,                    ///< Dimension (=Anzahl) Nullstellenfunktion
  _dimTimeEvent,                    ///< Dimension (=Anzahl) Time event (start zeit und frequenz)
       _dimAE;          ///< Number (dimension) of algebraic equations (e.g. constraints from an algebraic loop)

    ostream
  *_outputStream;        ///< Output stream for results




    bool _initial;
    SValuesMap _start_values;
    EventHandling _event_handling;
private:
    int
  _dimODE;            ///< Total number (dimension) of all order ordinary differential equations (first and second order)

};

