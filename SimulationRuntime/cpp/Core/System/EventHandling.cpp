#include <Core/Modelica.h>
#include "FactoryExport.h"
#include <Core/System/IEvent.h>
#include <Core/System/EventHandling.h>
#include <Core/Math/Functions.h>


/**
Constructor
\param system Modelica system object
\param dim Dimenson of help variables
*/
EventHandling::EventHandling() : _countinous_system(NULL), _mixed_system(NULL), _conditions0(NULL), _conditions1(NULL)
//:_h(NULL)
{
}

EventHandling::~EventHandling(void)
{
   // if(_h) delete [] _h;
  if(_conditions0)
    delete[] _conditions0;
  if(_conditions1)
    delete[] _conditions1;
}
/**
Inits the event variables
*/
void EventHandling::initialize(IEvent* system,int dim,init_prevars_type init_prevars)
{
   // _dimH=dim;
    _event_system=system;
    _countinous_system = dynamic_cast<IContinuous*>(_event_system);
    _mixed_system= dynamic_cast<IMixedSystem*>(_event_system);

    init_prevars(_pre_vars_idx,_pre_discrete_vars_idx);
    _pre_vars.resize((boost::extents[_pre_vars_idx.size()]));
    _pre_discrete_vars.resize((boost::extents[_pre_discrete_vars_idx.size()]));
    /*if(_dimH > 0)
    {
        // Initialize help vars vector
        if(_h) delete [] _h ;
        _h = new double[_dimH];
        memset(_h,0,(_dimH)*sizeof(double));
    }
    */
    if(_conditions0)
      delete[] _conditions0;
    if(_conditions1)
      delete[] _conditions1;

    _conditions0 = new bool[_event_system->getDimZeroFunc()];
    _conditions1 = new bool[_event_system->getDimZeroFunc()];
}
/**
Returns the help vector
*/
/*
void EventHandling::getHelpVars(double* h)
{
    for(int i=0; i<_dimH; ++i)
    {
        h[i] = _h[i];
    }
}
*/
/**
Sets the help vector
*/
/*
void EventHandling::setHelpVars(const double* h)
{
    for(int i=0; i<_dimH; ++i)
    {
        _h[i] = h[i];
    }
}
*/
/**
Saves all helpvariables
*/
/*
void EventHandling::saveH()
{
    for(int i=0; i<_dimH; ++i)
    {
        std::ostringstream s1;
        s1 << "h" << i  ;
        save(_h[i],s1.str());
    }
}
*/
/**
Returns the dimension of the help vector
*/
/*
int EventHandling::getDimHelpVars() const
{
    return _dimH;
}

void EventHandling::setHelpVar(unsigned int i,double var)
{

  assert(i >= 0 && i < _dimH);
  _h[i]=var;
}
*/
/*
const double& EventHandling::operator[](unsigned int i) const
{
  assert(i >= 0 && i < _dimH);

  return _h[i];
}
*/
void EventHandling::savePreVars(double vars[], unsigned int n)
{
   _pre_vars.assign(vars,vars+n);
}

void EventHandling::saveDiscretPreVars(double vars [], unsigned int n)
{
    _pre_discrete_vars.assign(vars,vars+n);
}
/**
Saves a variable in _pre_vars vector
*/

void EventHandling::save(double var,string key)
{
    unsigned int i = _pre_vars_idx[key];
    _pre_vars[i]=var;
}

/**
Implementation of the Modelica pre  operator
*/
double EventHandling::pre(double var,string key)
{
    unsigned int i = _pre_vars_idx[key];
    return _pre_vars[i];

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
     unsigned int i = _pre_discrete_vars_idx[key];
    _pre_discrete_vars[i]=var;

}
bool EventHandling::changeDiscreteVar(double var,string key)
{
   unsigned int i = _pre_discrete_vars_idx[key];
   return var != _pre_discrete_vars[i];

}


/**
Handles all events occurred a the same time.
*/

bool EventHandling::IterateEventQueue(bool& state_vars_reinitialized)
{
    //save discrete varibales
    _event_system->saveDiscreteVars(); // store values of discrete vars vor next check

    unsigned int dim = _event_system->getDimZeroFunc();

    _event_system->getConditions(_conditions0);
    //Handle all events

  state_vars_reinitialized = _countinous_system->evaluateConditions();
    //state_vars_reinitialized = evaluateAll();
    //_countinous_system->evaluateODE();
    //state_vars_reinitialized = _countinous_system->evaluateConditions();

    //check if discrete variables changed
    bool drestart= _event_system->checkForDiscreteEvents(); //discrete time conditions


    _event_system->getConditions(_conditions1);
    bool crestart = !std::equal (_conditions1, _conditions1+dim,_conditions0);

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

