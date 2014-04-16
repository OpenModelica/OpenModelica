#include "stdafx.h"
#include "FactoryExport.h"
#include <System/EventHandling.h>
#include <Math/Functions.h>


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
void EventHandling::initialize(IEvent* system,int dim)
{
    _dimH=dim;
    _event_system=system;
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
void EventHandling::getHelpVars(double* h)
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
    return var != pre(var, key);
}

void EventHandling::saveDiscreteVar(double var,string key)
{
    _pre_discrete_vars[key]=var;
}
bool EventHandling::changeDiscreteVar(double var,string key)
{
    return var != _pre_discrete_vars[key];
}


/**
Handles  all events occured a the same time. These are stored  the eventqueue
*/

bool EventHandling::IterateEventQueue(bool& state_vars_reinitialized)
{
    IContinuous*  countinous_system = dynamic_cast<IContinuous*>(_event_system);
    IMixedSystem* mixed_system= dynamic_cast<IMixedSystem*>(_event_system);

    //save discrete varibales
    _event_system->saveDiscreteVars(); // store values of discrete vars vor next check

    unsigned int dim = _event_system->getDimZeroFunc();
    bool* conditions0 = new bool[dim];
    bool* conditions1 = new bool[dim];
    _event_system->getConditions(conditions0);
    //Handle all events

    state_vars_reinitialized =     countinous_system->evaluate();


    //check if discrete variables changed
    bool drestart= _event_system->checkForDiscreteEvents();


    _event_system->getConditions(conditions1);
    bool crestart = !std::equal (conditions1, conditions1+dim,conditions0);
    delete[] conditions0;
    delete [] conditions1;
    return((drestart||crestart)); //returns true if new events occured
}

/*
bool EventHandling::checkConditions(const bool* events, bool all)
 {
       IEvent* event_system= dynamic_cast<IEvent*>(_system);
       int dim = event_system->getDimZeroFunc();
       bool* conditions0 = new bool[dim];
       bool* conditions1 = new bool[dim];
       event_system->getConditions(conditions0);

       for(int i=0;i<dim;i++)
       {
         if(all||events[i])
            getCondition(i);
       }
       event_system->getConditions(conditions1);
       return !std::equal (conditions1, conditions1+dim,conditions0);

}
*/

