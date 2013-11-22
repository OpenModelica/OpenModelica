#pragma once

#include <Math/Functions.h>      
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
    
    
    
    /// Provide number (dimension) of boolean variables
    virtual int getDimBoolean() const;

    /// Provide number (dimension) of states
    virtual int getDimContinuousStates() const;

    /// Provide number (dimension) of integer variables
    virtual int getDimInteger() const;

    /// Provide number (dimension) of real variables
    virtual int getDimReal() const;

    /// Provide number (dimension) of string variables
    virtual int getDimString() const;

    /// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
    virtual int getDimRHS() const;




    /// Provide boolean variables
    virtual void getBoolean(bool* z);

    /// Provide boolean variables
    virtual void getContinuousStates(double* z);

    /// Provide integer variables
    virtual void getInteger(int* z);

    /// Provide real variables
    virtual void getReal(double* z);

    /// Provide real variables
    virtual void getString(std::string* z);

    /// Provide the right hand side
    virtual void getRHS(double* f);


    /// Provide boolean variables
    virtual void setBoolean(const bool* z);

    /// Provide boolean variables
    virtual void setContinuousStates(const double* z);

    /// Provide integer variables
    virtual void setInteger(const int* z);

    /// Provide real variables
    virtual void setReal(const double* z);

    /// Provide real variables
    virtual void setString(const std::string* z);

    /// Provide the right hand side
    virtual void setRHS(const double* f);
    


    /// (Re-) initialize the system of equations
     void initialize();
    /// Set current integration time
     void setTime(const double& t);
    
protected:
     void Assert(bool cond,string msg);
     void Terminate(string msg);
     void intDelay(vector<unsigned int> expr);
     void storeDelay(unsigned int expr_id,double expr_value);
     void storeTime(double time);
     double delay(unsigned int expr_id,double expr_value, double delayTime, double delayMax);
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
        _simTime;        ///< current simulation time (given by the solver) 

    double
        *__z,        ///< "Extended state vector", containing all states and algebraic variables of all types
        *__zDot;       ///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations
    bool   
        * _conditions,    ///< External conditions changed by the solver
        * _time_conditions;
    
    int
         _dimContinuousStates,
         _dimRHS,            ///< Dimension der rechten Seite
         _dimReal,            ///< Anzahl der reelwertigen Variablen
         _dimInteger,            ///< Anzahl der integerwertigen Variablen
         _dimBoolean,            ///< Anzahl der boolwertigen Variablen
         _dimString,          ///< Anzahl der stringwertigen Variablen
         _dimZeroFunc,          ///< Dimension (=Anzahl) Nullstellenfunktion
         _dimTimeEvent,          ///< Dimension (=Anzahl) Time event (start zeit und frequenz)
         _dimAE;        ///< Number (dimension) of algebraic equations (e.g. constraints from an algebraic loop)
    
    int
       * _time_event_counter;
    ostream
        *_outputStream;        ///< Output stream for results

     IContinuous::UPDATETYPE _callType;
      

    bool _initial;    
    SValuesMap _start_values;
    EventHandling _event_handling;
   
    typedef boost::circular_buffer<double> buffer_type;
    map<unsigned int,buffer_type> _delay_buffer;
    buffer_type _time_buffer;
    
};

