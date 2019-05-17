#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

/*****************************************************************************/
/**

Abstract interface class for discrete systems in open modelica.

\date     October, 1st, 2008
\author

*/

/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

typedef std::map<double,unsigned long> event_times_type;
class IEvent
{
public:
    virtual ~IEvent()    {};

    /// Provide number (dimension) of zero functions
    virtual int getDimZeroFunc() = 0;
    virtual int getDimClock() = 0;
	virtual double *clockInterval()=0;
	virtual void setIntervalInTimEventData(int clockIdx, double interval) =0;
    virtual void setClock(const bool* tick, const bool* subactive) =0;
    /// Provides current values of root/zero functions
    virtual void getZeroFunc(double* f) = 0;

    virtual void setConditions(bool* c) = 0;
    virtual void getConditions(bool* c) = 0;
    virtual void getClockConditions(bool* c) = 0;
    //Deactivated: virtual void saveDiscreteVars() = 0;
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll() = 0;
    /// Called to handle an event
    virtual void handleEvent(const bool* events) = 0;
    ///Checks if a discrete variable has changed and triggered an event, returns true if a second event iteration is needed
    virtual bool checkForDiscreteEvents() = 0;
    virtual  bool getCondition(unsigned int index) = 0;
    //virtual void initPreVariables(unordered_map<double* const,unsigned int>&,unordered_map<int* const,unsigned int>&,unordered_map<bool* const,unsigned int>&)= 0;
};
/** @} */ // end of coreSystem