/** @addtogroup coreSystem
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/System/EventHandling.h>
#include <Core/System/SystemDefaultImplementation.h>
#include <Core/System/AlgLoopSolverFactory.h>
#include <Core/System/SimObjects.h>

template <class T>
void InitVars<T>::setStartValue(T& variable,T val,bool overwriteOldValue)
{
  //only add a start value if it was not already defined
  if(!_start_values.count(&variable) || overwriteOldValue)
    _start_values[&variable] = val;
  else
    LOGGER_WRITE("SystemDefaultImplementation: start value for variable is already defined",LC_INIT,LL_DEBUG);
};

template <class T>
T& InitVars<T>::getGetStartValue(T& variable)
{
  return _start_values[&variable];
};


bool greaterTime( pair<unsigned int,double> t1, double t2)
{
  return t1.second > t2;
}

SystemDefaultImplementation::SystemDefaultImplementation(shared_ptr<IGlobalSettings> globalSettings,string modelName,
														 size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
  : _simTime        (0.0)
  , __daeResidual(NULL)
  , _conditions      (NULL)
  , _time_conditions    (NULL)
  , _dimContinuousStates  (0)
  , _dimRHS        (0)
  , _dimReal        (0)
  , _dimInteger      (0)
  , _dimBoolean      (0)
  , _dimString      (0)
  , _dimZeroFunc      (0)
  , _dimTimeEvent      (0)
  , _dimClock        (0)
  , _dimAE        (0)
  , _timeEventData  (NULL)
  , _currTimeEvents (NULL)
  , _clockInterval  (NULL)
  , _clockShift     (NULL)
  , _clockTime      (NULL)
  , _clockCondition (NULL)
  , _clockStart     (NULL)
  , _clockSubactive (NULL)
  , _outputStream(NULL)
  , _callType        (IContinuous::UNDEF_UPDATE)
  , _initial        (false)
  , _delay_max      (0.0)
  , _start_time      (0.0)
  , _terminal        (false)
  , _terminate      (false)
  , _global_settings    (globalSettings)
  , _conditions0(NULL)
  , _event_system(NULL)
  , _modelName(modelName)
  , _freeVariablesLock(false)
, _omsu(NULL)
{

       _simObjects = shared_ptr<ISimObjects>(new SimObjects(globalSettings->getRuntimeLibrarypath(),globalSettings->getRuntimeLibrarypath(),globalSettings));
      _simObjects->LoadSimVars(_modelName,dim_real,  dim_int,  dim_bool,dim_string, dim_pre_vars, dim_z,  z_i);
	  __z   = _simObjects->getSimVars(modelName)->getStateVector();
     __zDot = _simObjects->getSimVars(modelName)->getDerStateVector();
}



SystemDefaultImplementation::SystemDefaultImplementation(shared_ptr<IGlobalSettings> globalSettings, string modelName, omsi_t* omsu)
	: _simTime(0.0)
	, __daeResidual(NULL)
	, _conditions(NULL)
	, _time_conditions(NULL)
	, _dimContinuousStates(0)
	, _dimRHS(0)
	, _dimReal(0)
	, _dimInteger(0)
	, _dimBoolean(0)
	, _dimString(0)
	, _dimZeroFunc(0)
	, _dimTimeEvent(0)
	, _dimClock(0)
	, _dimAE(0)
	, _timeEventData(NULL)
	, _currTimeEvents(NULL)
	, _clockInterval(NULL)
	, _clockShift(NULL)
	, _clockTime(NULL)
	, _clockCondition(NULL)
	, _clockStart(NULL)
	, _clockSubactive(NULL)
	, _outputStream(NULL)
	, _callType(IContinuous::UNDEF_UPDATE)
	, _initial(false)
	, _delay_max(0.0)
	, _start_time(0.0)
	, _terminal(false)
	, _terminate(false)
	, _global_settings(globalSettings)
	, _conditions0(NULL)
	, _event_system(NULL)
	, _modelName(modelName)
	, _freeVariablesLock(false)
	, _omsu(omsu)
{
	_simObjects = shared_ptr<ISimObjects>(new SimObjects(globalSettings->getRuntimeLibrarypath(), globalSettings->getRuntimeLibrarypath(), globalSettings));
	_simObjects->LoadSimVars(_modelName, _omsu);
	__z = _simObjects->getSimVars(modelName)->getStateVector();
	__zDot = _simObjects->getSimVars(modelName)->getDerStateVector();
}

SystemDefaultImplementation::SystemDefaultImplementation(shared_ptr<IGlobalSettings> globalSettings)
: _simTime        (0.0)
  , __daeResidual(NULL)
  , _conditions      (NULL)
  , _time_conditions    (NULL)
  , _dimContinuousStates  (0)
  , _dimRHS        (0)
  , _dimReal        (0)
  , _dimInteger      (0)
  , _dimBoolean      (0)
  , _dimString      (0)
  , _dimZeroFunc      (0)
  , _dimTimeEvent      (0)
  , _dimClock        (0)
  , _dimAE        (0)
  , _timeEventData  (NULL)
  , _currTimeEvents (NULL)
  , _clockInterval  (NULL)
  , _clockShift     (NULL)
  , _clockTime      (NULL)
  , _clockCondition (NULL)
  , _clockStart     (NULL)
  , _clockSubactive (NULL)
  , _outputStream(NULL)
  , _callType        (IContinuous::UNDEF_UPDATE)
  , _initial        (false)
  , _delay_max      (0.0)
  , _start_time      (0.0)
  , _terminal        (false)
  , _terminate      (false)
  , _global_settings    (globalSettings)
  , _conditions0(NULL)
  , _event_system(NULL)
{

	_simObjects = shared_ptr<ISimObjects>(new SimObjects(globalSettings->getRuntimeLibrarypath(), globalSettings->getRuntimeLibrarypath(), globalSettings));
}

SystemDefaultImplementation::SystemDefaultImplementation(SystemDefaultImplementation& instance)
  : _simTime        (0.0)
  , _simObjects (shared_ptr<ISimObjects>(instance.getSimObjects()->clone()))
  , __z          (_simObjects->getSimVars(instance.getModelName())->getStateVector())
  , __zDot        (_simObjects->getSimVars(instance.getModelName())->getDerStateVector())
  , __daeResidual(NULL)
  , _conditions      (NULL)
  , _time_conditions    (NULL)
  , _dimContinuousStates  (0)
  , _dimRHS        (0)
  , _dimReal        (0)
  , _dimInteger      (0)
  , _dimBoolean      (0)
  , _dimString      (0)
  , _dimZeroFunc      (0)
  , _dimTimeEvent      (0)
  , _dimClock        (0)
  , _dimAE        (0)
  , _timeEventData  (NULL)
  , _currTimeEvents (NULL)
  , _clockInterval  (NULL)
  , _clockShift     (NULL)
  , _clockTime      (NULL)
  , _clockCondition (NULL)
  , _clockStart     (NULL)
  , _clockSubactive (NULL)
  , _outputStream(NULL)
  , _callType        (IContinuous::UNDEF_UPDATE)
  , _initial        (false)
  , _delay_max      (0.0)
  , _start_time      (0.0)
  , _terminal        (false)
  , _terminate      (false)
  , _global_settings    (instance.getGlobalSettings())
  , _conditions0(NULL)
  , _event_system(NULL)
  , _modelName(instance.getModelName())
  , _freeVariablesLock(false)
{
}

/*
template<class T>
T SystemDefaultImplementation::getStartValue(T variable,string key)
{
try
{
return boost::any_cast<T>(_start_values[key]);
}
catch(const boost::bad_any_cast & ex)
{
std::runtime_error("No such start value");
}
}
*/
SystemDefaultImplementation::~SystemDefaultImplementation()
{
  /*
  changed: is handled in SimVars class
  if(__z) delete [] __z;
  if(__zDot) delete [] __zDot;
  */
  if(_conditions) delete [] _conditions ;
  if(_time_conditions) delete [] _time_conditions ;
  if(_timeEventData) delete [] _timeEventData;
  if(_currTimeEvents) delete [] _currTimeEvents;
  if(_conditions0) delete [] _conditions0;
  if(_clockInterval) delete [] _clockInterval;
  if(_clockShift) delete [] _clockShift;
  if(_clockTime) delete [] _clockTime;
  if(_clockCondition) delete [] _clockCondition;
  if(_clockStart) delete [] _clockStart;
  if(_clockSubactive) delete [] _clockSubactive;
  if(__daeResidual) delete [] __daeResidual;
}

void SystemDefaultImplementation::Assert(bool cond,const string& msg)
{
  if(!cond)
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,msg);
}

void SystemDefaultImplementation::Terminate(string msg)
{
  cerr << "Model terminate() at " << _simTime << std::endl;
  cerr << "Message: " << msg << std::endl;
  _terminate = true;
}

int SystemDefaultImplementation::getDimBoolean() const
{
  return _dimBoolean;
}

int SystemDefaultImplementation::getDimContinuousStates() const
{
  return _dimContinuousStates;
}

int SystemDefaultImplementation::getDimAE() const
{
  return _dimAE;
}

int SystemDefaultImplementation::getDimInteger() const
{
  return _dimInteger;
}

int SystemDefaultImplementation::getDimReal() const
{
  return _dimReal;
}

int SystemDefaultImplementation::getDimString() const
{
  return _dimString;
}

int SystemDefaultImplementation::getDimClock() const
{
  return _dimClock;
}

void SystemDefaultImplementation::setIntervalInTimEventData(int clockIdx, double interval)
{
    _timeEventData[_dimTimeEvent-_dimClock+clockIdx].second = interval;
}

/// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int SystemDefaultImplementation::getDimRHS() const
{
  return _dimRHS;
};


/// (Re-) initialize the system of equations
void SystemDefaultImplementation::initialize()
{
  _callType = IContinuous::CONTINUOUS;

  /*
  changed: is handled in SimVars class
  if((_dimContinuousStates) > 0)
  {
    // Initialize "extended state vector"
    if(__z) delete [] __z ;
    if(__zDot) delete [] __zDot;

    __z = new double[_dimContinuousStates];
    __zDot = new double[_dimContinuousStates];

    memset(__z,0,(_dimContinuousStates)*sizeof(double));
    memset(__zDot,0,(_dimContinuousStates)*sizeof(double));
  }
  */

  if(_dimZeroFunc > 0)
  {
    if(_conditions) delete [] _conditions ;
    if(_conditions0) delete [] _conditions0 ;
    _conditions = new bool[_dimZeroFunc];
    _conditions0= new bool[_dimZeroFunc];

    memset(_conditions,false,(_dimZeroFunc)*sizeof(bool));
  _event_system = dynamic_cast<IEvent*>(this);
  }
  if(_dimTimeEvent > 0)
  {
    if(_time_conditions) delete [] _time_conditions ;
    _time_conditions = new bool[_dimTimeEvent];
    memset(_time_conditions,false,(_dimTimeEvent)*sizeof(bool));
  }
  if (_dimClock > 0)
  {
    if (_clockInterval) delete [] _clockInterval;
    _clockInterval = new double [_dimClock];
    if (_clockShift) delete [] _clockShift;
    _clockShift = new double [_dimClock];
    if (_clockTime) delete [] _clockTime;
    _clockTime = new double [_dimClock];
    if (_clockCondition) delete [] _clockCondition;
    _clockCondition = new bool [_dimClock];
    memset(_clockCondition,false,(_dimClock)*sizeof(bool));
    if (_clockStart) delete [] _clockStart;
    _clockStart = new bool [_dimClock];
    if (_clockSubactive) delete [] _clockSubactive;
    _clockSubactive = new bool [_dimClock];
  }
  if(_dimRHS>0)
  {
    if (__daeResidual) delete [] __daeResidual;
      __daeResidual = new double [_dimRHS];
  }
  _start_time = 0.0;
  _terminal = false;
  _terminate = false;
};

/// Set current integration time
void SystemDefaultImplementation::setTime(const double& t)
{
  _simTime = t;
};

// Get current integration time
double SystemDefaultImplementation::getTime()
{
  return _simTime;
}

/// Set status of independent variables
void SystemDefaultImplementation::setFreeVariablesLock(bool freeVariablesLock)
{
  _freeVariablesLock = freeVariablesLock;
}

// Get status of independent variables
bool SystemDefaultImplementation::getFreeVariablesLock()
{
  return _freeVariablesLock;
}

/// getter for variables of different types
void SystemDefaultImplementation::getBoolean(bool* z)
{
  for(int i=0; i< _dimBoolean; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::getReal(double* z)
{
  for(int i=0; i< _dimReal; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::getInteger(int* z)
{
  for(int i=0; i< _dimInteger; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }

};

void SystemDefaultImplementation::getString(string* z)
{
  for(int i=0; i< _dimString; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }

};

void SystemDefaultImplementation::getClock(bool* z)
{
  for(int i = _dimTimeEvent - _dimClock; i < _dimTimeEvent; i++) {
    z[i] = _time_conditions[i];
  }
}

double *SystemDefaultImplementation::clockInterval()
{
  return _clockInterval;
}

double *SystemDefaultImplementation::clockShift()
{
  return _clockShift;
}

void SystemDefaultImplementation::getContinuousStates(double* z)
{
  std::copy(__z ,__z + _dimContinuousStates, z);
}

shared_ptr<IGlobalSettings> SystemDefaultImplementation::getGlobalSettings()
{
    return _global_settings;
}

shared_ptr<ISimObjects> SystemDefaultImplementation::getSimObjects()
{
  return _simObjects;
}

string SystemDefaultImplementation::getModelName() const
{
  return _modelName;
}

shared_ptr<ISimData> SystemDefaultImplementation::getSimData()
{
    return _simObjects->getSimData(_modelName);
}

shared_ptr<ISimVars> SystemDefaultImplementation::getSimVars()
{
    return _simObjects->getSimVars(_modelName);
}

bool SystemDefaultImplementation::isConsistent()
{
  if(_dimZeroFunc > 0)
  {
     getConditions(_conditions0);
    IContinuous::UPDATETYPE pre_call_type=_callType;
    _callType = IContinuous::DISCRETE;
    for(int i=0;i<_dimZeroFunc;i++)
    {
      _event_system->getCondition(i);
    }
    bool isConsistent =  std::equal (_conditions, _conditions+_dimZeroFunc,_conditions0);
    _callType = pre_call_type;
    setConditions(_conditions0);
    return isConsistent;
  }
  else
    return true;
}

void SystemDefaultImplementation::setConditions(bool* c)
{
  memcpy(_conditions,c,_dimZeroFunc*sizeof(bool));
}

void SystemDefaultImplementation::getConditions(bool* c)
{
  memcpy(c,_conditions,_dimZeroFunc*sizeof(bool));
}
void SystemDefaultImplementation::getClockConditions(bool* c)
{
  memcpy(c,_clockCondition,_dimClock*sizeof(bool));
}
/// setter for variables of different types

void SystemDefaultImplementation::setBoolean(const bool* z)
{
  for(int i=0; i< _dimBoolean; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::setInteger(const int* z)
{
  for(int i=0; i< _dimInteger; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::setString(const string* z)
{
  for(int i=0; i< _dimString; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::setReal(const double* z)
{
  for(int i=0; i< _dimReal; ++i)
  {
    //z[i] = __z[i];
    // TODO: insert Code here
  }
};

void SystemDefaultImplementation::setClock(const bool* tick, const bool* subactive)
{
  for (int i = 0; i < _dimClock; i++) {
    _time_conditions[_dimTimeEvent - _dimClock + i] = tick[i];
    _clockSubactive[i] = subactive[i];
  }
}

void SystemDefaultImplementation::setContinuousStates(const double* z)
{
  std::copy(z ,z + _dimContinuousStates,__z);
  /*for(int i=0; i<_dimContinuousStates; ++i)
  {
  __z[i] = z[i];
  }*/

};

void SystemDefaultImplementation::setStateDerivatives(const double* f)
{
  std::copy(f ,f + _dimContinuousStates, __zDot);
  /*for(int i=0; i<_dimRHS; ++i)
  {
  __zDot[i] = f[i];
  }*/
};


/// Provide the right hand side (according to the index)
void SystemDefaultImplementation::getRHS(double* f)
{
  std::copy(__zDot, __zDot+_dimContinuousStates, f);
  //     for(int i=0; i<_dimRHS; ++i)
  //      f[i] = __zDot[i];
};

void SystemDefaultImplementation::getResidual(double* f)
{
   std::copy(__daeResidual, __daeResidual+_dimRHS, f);
}

void  SystemDefaultImplementation::intDelay(vector<unsigned int> expr, vector<double> delay_max)
{
  FOREACH(unsigned int expr_id, expr)
  {
    buffer_type delay_buffer;
    _delay_buffer[expr_id]=delay_buffer;
  }
  vector<double>::iterator iter = std::max_element(delay_max.begin(),delay_max.end());
  _delay_max =  *iter;
}

void SystemDefaultImplementation::storeDelay(unsigned int expr_id, double expr_value, double time)
{
  map<unsigned int,buffer_type>::iterator iter;
  if ((iter = _delay_buffer.find(expr_id)) != _delay_buffer.end()) {
    iter->second.push_back(expr_value);
  }
  else
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"invalid delay expression id");
}

void SystemDefaultImplementation::storeTime(double time)
{
  // delete up to last value < time - _delay_max
  buffer_type::iterator first = _time_buffer.begin();
  buffer_type::iterator pos = find_if(first, _time_buffer.end(),
                                      bind2nd(std::greater_equal<double>(),
                                              time - _delay_max));
  if (pos != first && --pos != first) {
    difference_type n = std::distance(first, pos);
    _time_buffer.erase(first, first + n);
    map<unsigned int, buffer_type>::iterator iter;
    for (iter = _delay_buffer.begin(); iter != _delay_buffer.end(); iter++) {
      first = iter->second.begin();
      iter->second.erase(first, first + n);
    }
  }
  // store new value
  _time_buffer.push_back(time);
}

double SystemDefaultImplementation::delay(unsigned int expr_id,double expr_value,double delayTime, double delayMax)
{
  map<unsigned int,buffer_type>::iterator iter;
  //find buffer for delay expression
  if((iter = _delay_buffer.find(expr_id))!=_delay_buffer.end())
  {
    if(delayTime < 0.0)
    {
      throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"Negative delay requested");
    }
    if(_time_buffer.size()==0) //occurs in the initialization phase
    {

      return expr_value;
    }
    if(_simTime<=_start_time)
      return expr_value;

    double ts; //difference of current time and delay time
    double tl; //last buffer entry
    double res0, res1, t0, t1;

    if(_simTime <=  delayTime)
    {
      res0 = iter->second[0];
      return res0;
    }
    else //time > delay time
    {
      ts = _simTime -delayTime;

      tl = _time_buffer.back();
      if(ts > tl)
      {
        t0 = tl;
        res0=iter->second.back();
        t1=_simTime;
        res1=expr_value;
      }
      else
      {
        //find posion in value buffer for queried time
        buffer_type::iterator pos = find_if(_time_buffer.begin(),_time_buffer.end(),bind2nd(std::greater_equal<double>(),ts));

        if(pos!=_time_buffer.end())
        {
          buffer_type::iterator first = _time_buffer.begin(); // first time entry
          difference_type index = std::distance(first, pos); //index of found time
          t1 = *pos;
          res1 = iter->second[index];
          if(index == 0)
            return res1;
          t0 = _time_buffer[index-1];
          res0 = iter->second[index-1];
        }
        else
        {
          throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"time not found in delay buffer");
        }
      }
      if(t0==ts)//found exact time
        return res0;
      else if(t1==ts)
        return res1;
      else //linear interpolation
      {
        double timedif = t1 - t0;
        double dt0 = t1 - ts;
        double dt1 = ts - t0;
        double res2 = (res0 * dt0 + res1 * dt1) / timedif;
        return res2;
      }
    }
  }
  else
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"invalid delay expression id");
}

double& SystemDefaultImplementation::getRealStartValue(double& key)
{
  return _real_start_values.getGetStartValue(key);
}

bool& SystemDefaultImplementation::getBoolStartValue(bool& var)
{
  return _bool_start_values.getGetStartValue(var);
}

int& SystemDefaultImplementation::getIntStartValue(int& var)
{
  return _int_start_values.getGetStartValue(var);
}
string& SystemDefaultImplementation::getStringStartValue(string& var)
{
  return _string_start_values.getGetStartValue(var);
}

void SystemDefaultImplementation::setRealStartValue(double& var, double val, bool overwriteOldValue)
{
  var = val;
  _real_start_values.setStartValue(var, val, overwriteOldValue);
}

void SystemDefaultImplementation::setRealStartValue(BaseArray<double>& avar, double val, bool overwriteOldValue)
{
  double *varp = avar.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, i++) {
    *varp = val;
    _real_start_values.setStartValue(*varp, val, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setRealStartValue(BaseArray<double>& avar, const BaseArray<double>& aval, bool overwriteOldValue)
{
  double *varp = avar.getData();
  const double *valp = aval.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, valp++, i++) {
    *varp = *valp;
    _real_start_values.setStartValue(*varp, *valp, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setBoolStartValue(bool& var, bool val, bool overwriteOldValue)
{
  var = val;
  _bool_start_values.setStartValue(var, val, overwriteOldValue);
}

void SystemDefaultImplementation::setBoolStartValue(BaseArray<bool>& avar, bool val, bool overwriteOldValue)
{
  bool *varp = avar.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, i++) {
    *varp = val;
    _bool_start_values.setStartValue(*varp, val, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setBoolStartValue(BaseArray<bool>& avar, const BaseArray<bool>& aval, bool overwriteOldValue)
{
  bool *varp = avar.getData();
  const bool *valp = aval.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, valp++, i++) {
    *varp = *valp;
    _bool_start_values.setStartValue(*varp, *valp, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setIntStartValue(int& var, int val, bool overwriteOldValue)
{
  var = val;
  _int_start_values.setStartValue(var, val, overwriteOldValue);
}

void SystemDefaultImplementation::setIntStartValue(BaseArray<int>& avar, int val, bool overwriteOldValue)
{
  int *varp = avar.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, i++) {
    *varp = val;
    _int_start_values.setStartValue(*varp, val, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setIntStartValue(BaseArray<int>& avar, const BaseArray<int>& aval, bool overwriteOldValue)
{
  int *varp = avar.getData();
  const int *valp = aval.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, valp++, i++) {
    *varp = *valp;
    _int_start_values.setStartValue(*varp, *valp, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setStringStartValue(string& var, string val, bool overwriteOldValue)
{
  var = val;
  _string_start_values.setStartValue(var, val, overwriteOldValue);
}

void SystemDefaultImplementation::setStringStartValue(BaseArray<string>& avar, string val, bool overwriteOldValue)
{
  string *varp = avar.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, i++) {
    *varp = val;
    _string_start_values.setStartValue(*varp, val, overwriteOldValue);
  }
}

void SystemDefaultImplementation::setStringStartValue(BaseArray<string>& avar, const BaseArray<string>& aval, bool overwriteOldValue)
{
  string *varp = avar.getData();
  const string *valp = aval.getData();
  size_t nel = avar.getNumElems();
  for (size_t i = 0; i < nel; varp++, valp++, i++) {
    *varp = *valp;
    _string_start_values.setStartValue(*varp, *valp, overwriteOldValue);
  }
}

/**
    Computes whether time event conditions are active at current time
    @param The current time
*/
void SystemDefaultImplementation::computeTimeEventConditions(double currTime)
{
  for (int i=0; i< _dimTimeEvent; i++)
  {
    if (std::abs(_currTimeEvents[i] - currTime) <= 1e4*UROUND)
    {
      _time_conditions[i] = true;
    }
    else
    {
      _time_conditions[i] = false;
    }
  }
}

/**
    Sets all time event conditions to false
*/
void SystemDefaultImplementation::resetTimeConditions()
{
  for (int i=0; i< _dimTimeEvent; i++)
  {
  _time_conditions[i] = false;
  }
}

/**
    Computes the next time events for each time event sampler
    @param The current Time
    @param The definition of the time event samplers (starttime, intervall)
    @param An array of the next time events for each sampler
    @return the closest time event
*/
double SystemDefaultImplementation::computeNextTimeEvents(double currTime, std::pair<double, double>* timeEventPairs)
{
  double closestTimeEvent = std::numeric_limits<double>::max();
  double nextTimeEvent = 0;
  double pastIntervalls;

  for (  int timerIdx = 0; timerIdx < _dimTimeEvent ; timerIdx++)
  {
    //the time event samples started already
    if(timeEventPairs[timerIdx].first <= currTime)
    {
      pastIntervalls = std::floor((currTime - timeEventPairs[timerIdx].first + 1e4*UROUND) / timeEventPairs[timerIdx].second);
      _currTimeEvents[timerIdx] = timeEventPairs[timerIdx].first + (pastIntervalls) * timeEventPairs[timerIdx].second;
      nextTimeEvent = _currTimeEvents[timerIdx] + timeEventPairs[timerIdx].second;
    }
    else
    {
      nextTimeEvent = timeEventPairs[timerIdx].first;
      _currTimeEvents[timerIdx] = 1.0;
    }
    closestTimeEvent = std::min(closestTimeEvent, nextTimeEvent);
  }
  return closestTimeEvent;
}

/** @} */ // end of coreSystem

/*
template int SystemDefaultImplementation::getStartValue(int variable,string key);
template double SystemDefaultImplementation::getStartValue(double variable,string key);
template bool SystemDefaultImplementation::getStartValue(bool variable,string key);
*/
