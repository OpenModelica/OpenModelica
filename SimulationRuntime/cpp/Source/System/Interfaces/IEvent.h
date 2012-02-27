#pragma once


/*****************************************************************************/
/**

Abstract interface class for discrete systems in open modelica.

\date     October, 1st, 2008
\author   

*/

/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/


//typedef boost::function<void (void)> update_events_type;
typedef std::map<double,unsigned long/*,std::less_equal<double>*/ > event_times_type;
class IEvent
{
public:

	virtual ~IEvent()	{};

	/// Provide number (dimension) of zero functions
	virtual int getDimZeroFunc() /*const*/ = 0;

	/// Provides current values of root/zero functions
	virtual void giveZeroFunc(double* f,const double& eps) = 0;
	virtual void giveConditions(bool* c) = 0;
	virtual void setConditions(bool* c) = 0;
	virtual void checkConditions(unsigned int, bool all) = 0;
	virtual void saveConditions() = 0;
	//Saves all variables before an event is handled, is needed for the pre, edge and change operator
	virtual void saveAll() = 0;
	/// Called to handle all  events occured at same time 
	virtual void handleSystemEvents(const bool* events) = 0;
	/// Called to handle an event 
	virtual void handleEvent(unsigned long index) = 0;
	///Checks if a discrete variable has changed and triggered an event, returns true if a second event iteration is needed
	virtual bool checkForDiscreteEvents() = 0;	
	//returns the vector with all time events
	virtual event_times_type getTimeEvents() = 0;
	
	
};
