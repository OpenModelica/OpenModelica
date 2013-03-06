#pragma once
#include <System/IMixedSystem.h>                // System interface
#include <System/IEvent.h>                // System interface

/**
Auxiliary  class to handle system events
Implements the Modelica pre,edge,change operators
Holds a help vector for the discrete variables
Holds an event queue to handle all events occured at the same time
*/
typedef boost::function<void (unsigned int)> resetHelpVar_type;
class BOOST_EXTENSION_EVENTHANDLING_DECL EventHandling
{
public:
    EventHandling();
    ~EventHandling(void);
    //Inits the event variables
    void init(IMixedSystem* system,int dim);
    //Returns the help vector
    void giveHelpVars(double* h);
    //sets the help vector
    void setHelpVars(const double* h);
    //returns the dimension of the help vector
    int getDimHelpVars() const;



    //saves a variable in _pre_vars vector
    void save(double var,string key);
    //saves all helpvariables
    void saveH();
    void setHelpVar(unsigned int i,double var);
    const double& operator[](unsigned int i) const;
    //Implementation of the Modelica pre  operator
    double pre(double var,string key);
    //Implementation of the Modelica edge  operator
    bool edge(double var,string key);
    //Implementation of the Modelica change  operator
    bool change(double var,string key);
    //Implementation of the Modelica change  operator
    double sample(double start,double interval);
    //Adds an event to the eventqueue
    void addEvent(long index);
    //removes an event from the eventqueue
    void removeEvent(long index);
    //Handles  all events occured a the same time. Returns true if a second event iteration is needed
    bool IterateEventQueue(bool* events);

  void saveDiscreteVar(double var,string key);
   bool changeDiscreteVar(double var,string key);
    void addTimeEvent(long index,double time);
    void addTimeEvents( event_times_type times);
     event_times_type makePeriodeEvents(double ts,double te,double ti,long index);
    ///returns the vector with all time events
     event_times_type& getTimeEvents();
    resetHelpVar_type  resetHelpVar;
    bool CheckDiscreteValues(bool* values,bool* pre_values,bool* next_values, bool** cur_values,unsigned int size,unsigned int cur_index,unsigned int num_values);
private:
    //Stores all varibales occured before an event
    unordered_map<string,double> _pre_vars;
    //stores all eventes
  unordered_map<string,double> _pre_discrete_vars;
    IMixedSystem* _system;
    //Helpvarsvector for discrete variables
    double* _h;
    //Dimesion of Helpvarsvector
    int _dimH;
     event_times_type _time_events;
};
