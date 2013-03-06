#include "stdafx.h"
#define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
#include <System/EventHandling.h>
#include <System/IContinuous.h>
#include <boost/math/tools/real_cast.hpp>
#include <Math/Functions.h>
#include <sstream>

/**
Constructor
\param system Modelica system object
\param dim Dimenson of help variables
*/
EventHandling::EventHandling()
:_h(NULL)
{
}

EventHandling::~EventHandling(void)
{
    if(_h) delete [] _h;
}
/**
Inits the event variables
*/
void EventHandling::init(IMixedSystem* system,int dim)
{
    _dimH=dim;
    _system=system;
    if(_dimH > 0)
    {
        // Initialize help vars vector
        if(_h) delete [] _h ;
        _h = new double[_dimH];
        memset(_h,0,(_dimH)*sizeof(double));
    }
}
/**
Returns the help vector
*/
void EventHandling::giveHelpVars(double* h)
{
    for(int i=0; i<_dimH; ++i)
    {
        h[i] = _h[i];
    }
}
/**
Sets the help vector
*/
void EventHandling::setHelpVars(const double* h)
{
    for(int i=0; i<_dimH; ++i)
    {
        _h[i] = h[i];
    }
}
/**
Saves all helpvariables
*/
void EventHandling::saveH()
{
    for(int i=0; i<_dimH; ++i)
    {
        std::ostringstream s1;
        s1 << "h" << i  ;
        save(_h[i],s1.str());
    }
}
/**
Returns the dimension of the help vector
*/
int EventHandling::getDimHelpVars() const
{
    return _dimH;
}
void EventHandling::setHelpVar(unsigned int i,double var)
{

  assert(i >= 0 && i < _dimH);
  _h[i]=var;
}
const double& EventHandling::operator[](unsigned int i) const
{
  assert(i >= 0 && i < _dimH);
  //update helpvar before return
  resetHelpVar(i);
  return _h[i];
}
/**
Saves a variable in _pre_vars vector
*/
void EventHandling::save(double var,string key)
{
    _pre_vars[key]=var;
}
/**
Implementation of the Modelica pre  operator
*/
double EventHandling::pre(double var,string key)
{
    return _pre_vars[key];
}
/**
Implementation of the Modelica edge  operator
Returns true for a variable when it  changes from false to true
*/
bool EventHandling::edge(double var,string key)
{
    return var && !pre(var,key);
}
/**
Implementation of the Modelica change  operator
Returns true for a variable when it change value
*/
bool EventHandling::change(double var,string key)
{
    return var && !pre(var,key) || !var && pre(var,key);
}

void EventHandling::saveDiscreteVar(double var,string key)
{
    _pre_discrete_vars[key]=var;
}
bool EventHandling::changeDiscreteVar(double var,string key)
{
    return var && !_pre_discrete_vars[key] || !var && _pre_discrete_vars[key];
}

/**
Implementation of the Modelica change  operator
*/
double EventHandling::sample(double start,double interval)
{
  return 0.0;
}
/**
Handles  all events occured a the same time. These are stored  the eventqueue
*/
bool EventHandling::IterateEventQueue(bool* events)
{
    IContinuous*  countinous_system = dynamic_cast<IContinuous*>(_system);
    IEvent* event_system= dynamic_cast<IEvent*>(_system);
    IMixedSystem* mixed_system= dynamic_cast<IMixedSystem*>(_system);

  bool drestart=false;
  bool crestart=true;
  //store events before handled
  int dimf = event_system->getDimZeroFunc();
  bool* events_before = new bool[dimf];
  memcpy(events_before,events, dimf*sizeof(bool));
  //Handle all events
  countinous_system->update();
  event_system->saveDiscreteVars();
  drestart= event_system->checkForDiscreteEvents();
  event_system->checkConditions(0,true);
  event_system->giveConditions(events);
  //check if new events occured
  crestart = !(std::equal (events, events+dimf,events_before));
  return((drestart||crestart)); //returns true if new events occured
}



void EventHandling::addTimeEvent(long index,double time)
{
   _time_events.insert(make_pair(time,index));
}
void  EventHandling::addTimeEvents( event_times_type times)
{

   event_times_type::iterator iter,iter2;

   for( iter=times.begin();iter!=times.end();++iter)
   {
       //check if time event already exists
      iter2 = find_if( _time_events.begin(), _time_events.end(), floatCompare<double>(iter->first, 1e-10) );
       if(iter2==_time_events.end())
        _time_events.insert(*iter);
   }

}
/**
Checks if the discete variables are changed during the continous system is solved.
pre_values values of discrete varibales before continous system is solved.
next_values values of discrete varibales after continous system is solved.

*/
bool  EventHandling::CheckDiscreteValues(bool* values,bool* pre_values,bool* next_values, bool** cur_values,unsigned int size,unsigned int cur_index,unsigned int num_values)
{

    bool found=true;
    found = (std::equal (next_values, next_values+size,pre_values));
    if(!found)
    {
        //Calculate start index for iteration
        int offset = cur_index * size;

        if((num_values - offset) < 0 )
            return false;

        // calculate end index i_max  for iteration
        int i_max;
        if((offset+size) > num_values)
        {
            i_max = num_values - offset;
        }
        else
        {
            i_max = size;
        }
        //modify discrete variables with new values
        for (int i = 0; i < i_max; i++)
        {
            *cur_values[i] = values[offset + i];
        }
    }
    return found;
}

event_times_type EventHandling::makePeriodeEvents(double ts,double te,double interval,long index)
{
    using namespace boost::math::tools;
    event_times_type periode;
    if((te < ts)||(interval==0.0))
       throw std::runtime_error("wrong make sample parameters");
     double val = ts;
     while(val < te)
     {
         periode.insert(make_pair(real_cast<double>(val),index));
         val += interval;
     }
     return periode;
}

 event_times_type& EventHandling::getTimeEvents()
{
    return _time_events;
}
