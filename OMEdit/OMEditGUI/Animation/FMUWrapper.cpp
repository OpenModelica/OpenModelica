/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */


#include "FMUWrapper.h"
#include "Modeling/MessagesWidget.h"
#include "Util/Helper.h"

SimSettingsFMU::SimSettingsFMU()
                : _callEventUpdate(fmi1_false),
                  _toleranceControlled(fmi1_true),
                  _intermediateResults(fmi1_false),
                  _tstart(0.0),
                  _hdef(0.1),
                  _tend(0.1),
                  _relativeTolerance(0.001),
                  _solver(Solver::EULER_FORWARD),
                  mIterateEvents(true)
{
}

void SimSettingsFMU::setTend(const double t)
{
  _tend = t;
}

void SimSettingsFMU::setTstart(const double t)
{
  _tstart = t;
}

void SimSettingsFMU::setHdef(const double h)
{
  _hdef = h;
}

void SimSettingsFMU::setRelativeTolerance(const double t)
{
  _relativeTolerance = t;
}

double SimSettingsFMU::getTend() const
{
  return _tend;
}

double SimSettingsFMU::getTstart() const
{
  return _tstart;
}

double SimSettingsFMU::getHdef()
{
  return _hdef;
}

double SimSettingsFMU::getRelativeTolerance()
{
  return _relativeTolerance;
}

int SimSettingsFMU::getToleranceControlled() const
{
  return _toleranceControlled;
}

void SimSettingsFMU::setSolver(const Solver& solver)
{
  _solver = solver;
}

int* SimSettingsFMU::getCallEventUpdate()
{
  return &_callEventUpdate;
}

int SimSettingsFMU::getIntermediateResults()
{
  return _intermediateResults;
}

void SimSettingsFMU::setIterateEvents(bool iE)
{
  mIterateEvents = iE;
}

bool SimSettingsFMU::getIterateEvents()
{
  return mIterateEvents;
}
//-------------------------------
// Abstract FMU class
//-------------------------------


FMUWrapperAbstract::FMUWrapperAbstract(){
}

//-------------------------------
// FMU Model Exchange Version 1.0
//-------------------------------

FMUWrapper_ME_1::FMUWrapper_ME_1()
    : FMUWrapperAbstract(),
      mpFMU(nullptr),
      mCallBackFunctions(),
      mFMUdata()
{
}

FMUWrapper_ME_1::~FMUWrapper_ME_1()
{
  // Free memory associated with the FMUData and its context.
  if (mFMUdata._states)
    delete (mFMUdata._states);
  if (mFMUdata._statesDer)
    delete (mFMUdata._statesDer);
  if (mFMUdata._eventIndicators)
    delete (mFMUdata._eventIndicators);
  if (mFMUdata._eventIndicatorsPrev)
    delete (mFMUdata._eventIndicatorsPrev);

  fmi1_import_destroy_dllfmu(mpFMU);
  fmi1_import_free(mpFMU);
}

void FMUWrapper_ME_1::fmi_get_real(unsigned int* valueRef, double* res)
{
  fmi1_import_get_real(mpFMU, valueRef, 1, res);
}

unsigned int FMUWrapper_ME_1::fmi_get_variable_by_name(const char* name)
{
    fmi1_import_variable_t* var = fmi1_import_get_variable_by_name(mpFMU, name);
    return (unsigned int)fmi1_import_get_variable_vr(var);
}

void FMUWrapper_ME_1::load(const std::string& modelFile, const std::string& path, fmi_import_context_t* context)
{
  //Callbackfunctions
  mCallBackFunctions.logger = fmi1_log_forwarding;
  mCallBackFunctions.allocateMemory = calloc;
  mCallBackFunctions.freeMemory = free;

  mpFMU = fmi1_import_parse_xml(context, path.c_str());
  if (!mpFMU)
  {
    std::cout<<"Error parsing XML. Exiting."<<std::endl;
  }
  //chek if its a model excahnge FMU
  if (fmi1_import_get_fmu_kind(mpFMU) != fmi1_fmu_kind_enu_me)
  {
    std::cout<<"Only Model-Exchange FMUs are supported right now."<<std::endl;
  }

  //loadFMU dll
  jm_status_enu_t status = fmi1_import_create_dllfmu(mpFMU, mCallBackFunctions, 1);
  if (status == jm_status_error)
  {
    std::cout<<"Could not create the DLL loading mechanism(C-API test). Exiting."<<std::endl;

  }
}

void FMUWrapper_ME_1::initialize(const std::shared_ptr<SimSettingsFMU> simSettings)
{
  // Initialize data
  mFMUdata._hcur = simSettings->getHdef();
  mFMUdata._tcur = simSettings->getTstart();

  std::cout<<"Version returned from FMU: "<< std::string(fmi1_import_get_version(mpFMU))<<std::endl;
  std::cout<<"Platform type returned: "<< std::string(fmi1_import_get_model_types_platform(mpFMU))<<std::endl;

  // Calloc everything
  mFMUdata._nStates = fmi1_import_get_number_of_continuous_states(mpFMU);
  mFMUdata._nEventIndicators = fmi1_import_get_number_of_event_indicators(mpFMU);
  std::cout<<"n_states: "<< std::to_string(mFMUdata._nStates) << " " << std::to_string(mFMUdata._nEventIndicators)<<std::endl;

  mFMUdata._states = (fmi1_real_t*) calloc(mFMUdata._nStates, sizeof(double));
  mFMUdata._statesDer = (fmi1_real_t*) calloc(mFMUdata._nStates, sizeof(double));
  mFMUdata._eventIndicators = (fmi1_real_t*) calloc(mFMUdata._nEventIndicators, sizeof(double));
  mFMUdata._eventIndicatorsPrev = (fmi1_real_t*) calloc(mFMUdata._nEventIndicators, sizeof(double));
  mFMUdata._stateVRs = (unsigned int*) malloc(mFMUdata._nStates* sizeof(unsigned int));

  // get states to manipulate them
  mFMUdata._fmiStatus = fmi1_import_get_state_value_references(mpFMU, mFMUdata._stateVRs, mFMUdata._nStates);
  if (!mFMUdata._fmiStatus)
  {
  for (unsigned int i=0; i<mFMUdata._nStates; i++)
  {
    fmi1_import_variable_t * stateVar = fmi1_import_get_variable_by_vr(mpFMU, fmi1_base_type_enu_t::fmi1_base_type_real, mFMUdata._stateVRs[i]);
    mFMUdata._stateNames.push_back(fmi1_import_get_variable_name(stateVar));
  }
  }
  else
  {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, QObject::tr("fmi1_import_get_state_value_references returned failure code"+mFMUdata._fmiStatus),
                                                              Helper::scriptingKind, Helper::errorLevel));
  }

  // Instantiate model
  jm_status_enu_t jmstatus = fmi1_import_instantiate_model(mpFMU, "Test ME model instance");
  if (jmstatus == jm_status_error)
  {
    std::cout<<"fmi1_import_instantiate_model failed. Exiting."<<std::endl;
  }

  //initialize
  mFMUdata._fmiStatus = fmi1_import_set_time(mpFMU, simSettings->getTstart());
  try
  {
    mFMUdata._fmiStatus = fmi1_import_initialize(mpFMU, simSettings->getToleranceControlled(), simSettings->getRelativeTolerance(), &mFMUdata._eventInfo);
  }
  catch (std::exception &ex)
  {
    std::cout << __FILE__ << " : " << __LINE__ << " Exception: " << ex.what() << std::endl;
  }
  mFMUdata._fmiStatus = fmi1_import_get_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
  mFMUdata._fmiStatus = fmi1_import_get_event_indicators(mpFMU, mFMUdata._eventIndicatorsPrev, mFMUdata._nEventIndicators);
  mFMUdata._fmiStatus = fmi1_import_set_debug_logging(mpFMU, fmi1_false);

  // Turn on logging in FMI library.
  fmi1_import_set_debug_logging(mpFMU, fmi1_false);
  std::cout<<"FMU::initialize(). Finished."<<std::endl;
}

const FMUData* FMUWrapper_ME_1::getFMUData()
{
  return &mFMUdata;
}

fmi1_import_t* FMUWrapper_ME_1::getFMU()
{
  return mpFMU;
}

void FMUWrapper_ME_1::setContinuousStates()
{
  mFMUdata._fmiStatus = fmi1_import_set_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
}

bool FMUWrapper_ME_1::checkForTriggeredEvent()
{
  for (size_t k = 0; k < mFMUdata._nEventIndicators; ++k)
  {
    if (mFMUdata._eventIndicators[k] * mFMUdata._eventIndicatorsPrev[k] < 0)
    {
      //std::cout<<"Event occurred at "<<std::to_string(mFMUdata._tcur)<<std::endl;
      return true;
    }
  }
  return false;
}

bool FMUWrapper_ME_1::itsEventTime()
{
  return (mFMUdata._eventInfo.upcomingTimeEvent && mFMUdata._tcur == mFMUdata._eventInfo.nextEventTime);
}

void FMUWrapper_ME_1::updateNextTimeStep(const double hdef)
{
  if (mFMUdata._eventInfo.upcomingTimeEvent)
  {
    if (mFMUdata._tcur + hdef < mFMUdata._eventInfo.nextEventTime)
      mFMUdata._hcur = hdef;
    else
      mFMUdata._hcur = mFMUdata._eventInfo.nextEventTime - mFMUdata._tcur;
  }
  else
    mFMUdata._hcur = hdef;

  // Increase with step size
  mFMUdata._tcur += mFMUdata._hcur;
}

void FMUWrapper_ME_1::handleEvents(const int intermediateResults)
{
  //std::cout<<"Handle event at "<<std::to_string(mFMUdata._tcur)<<std::endl;
  mFMUdata._fmiStatus = fmi1_import_eventUpdate(mpFMU, intermediateResults, &mFMUdata._eventInfo);
  mFMUdata._fmiStatus = fmi1_import_get_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
  mFMUdata._fmiStatus = fmi1_import_get_event_indicators(mpFMU, mFMUdata._eventIndicators, mFMUdata._nEventIndicators);
  mFMUdata._fmiStatus = fmi1_import_get_event_indicators(mpFMU, mFMUdata._eventIndicatorsPrev, mFMUdata._nEventIndicators);
}

void FMUWrapper_ME_1::prepareSimulationStep(const double time)
{
  mFMUdata._fmiStatus = fmi1_import_set_time(mpFMU, time);
  mFMUdata._fmiStatus = fmi1_import_get_event_indicators(mpFMU, mFMUdata._eventIndicators, mFMUdata._nEventIndicators);
}

void FMUWrapper_ME_1::setLastStepSize(const double simTimeEnd)
{
  if (mFMUdata._tcur > simTimeEnd - mFMUdata._hcur / 1e16)
  {
    mFMUdata._tcur -= mFMUdata._hcur;
    mFMUdata._hcur = simTimeEnd - mFMUdata._tcur;
    mFMUdata._tcur = simTimeEnd;
  }
}

void FMUWrapper_ME_1::solveSystem()
{
  mFMUdata._fmiStatus = fmi1_import_get_derivatives(mpFMU, mFMUdata._statesDer, mFMUdata._nStates);
}

void FMUWrapper_ME_1::doEulerStep()
{
  for (size_t k = 0; k < mFMUdata._nStates; ++k)
    mFMUdata._states[k] = mFMUdata._states[k] + mFMUdata._hcur * mFMUdata._statesDer[k];
}

void FMUWrapper_ME_1::completedIntegratorStep(int* callEventUpdate)
{
  mFMUdata._fmiStatus = fmi1_import_completed_integrator_step(mpFMU, (char*)callEventUpdate);
}

//-------------------------------
// FMU Model Exchange Version 2.0
//-------------------------------

FMUWrapper_ME_2::FMUWrapper_ME_2()
    : FMUWrapperAbstract(),
      mpFMU(nullptr),
      mCallBackFunctions(),
      mFMUdata()
{
  mFMUdata.terminateSimulation = fmi2_false;
}

FMUWrapper_ME_2::~FMUWrapper_ME_2()
{
  // Free memory associated with the FMUData and its context.
  if (mFMUdata._states)
    delete (mFMUdata._states);
  if (mFMUdata._statesDer)
    delete (mFMUdata._statesDer);
  if (mFMUdata._eventIndicators)
    delete (mFMUdata._eventIndicators);
  if (mFMUdata._eventIndicatorsPrev)
    delete (mFMUdata._eventIndicatorsPrev);

  fmi2_import_destroy_dllfmu(mpFMU);
  fmi2_import_free(mpFMU);
}

void FMUWrapper_ME_2::fmi_get_real(unsigned int* valueRef, double* res)
{
  fmi2_import_get_real(mpFMU, valueRef, 1, res);
}

void FMUWrapper_ME_2::load(const std::string& modelFile, const std::string& path, fmi_import_context_t* context)
{
  //Callbackfunctions
  mCallBackFunctions.logger = fmi2_log_forwarding;
  mCallBackFunctions.allocateMemory = calloc;
  mCallBackFunctions.freeMemory = free;
  mCallBackFunctions.componentEnvironment = mpFMU;
  // parsing
  mpFMU = fmi2_import_parse_xml(context, path.c_str(), 0);
  if (!mpFMU)
  {
    std::cout<<"Error parsing XML. Exiting."<<std::endl;
  }
  //chek if its a model excahnge FMU
  if (fmi2_import_get_fmu_kind(mpFMU) != fmi2_fmu_kind_me)
  {
    std::cout<<"Only Model-Exchange FMUs are supported right now."<<std::endl;
  }
  //loadFMU dll
  jm_status_enu_t status =  fmi2_import_create_dllfmu(mpFMU, fmi2_fmu_kind_me, &mCallBackFunctions);
  if (status == jm_status_error)
  {
    std::cout<<"Could not create the DLL loading mechanism(C-API test). Exiting."<<std::endl;
  }
}

void FMUWrapper_ME_2::initialize(const std::shared_ptr<SimSettingsFMU> simSettings)
{
  // Initialize data
  mFMUdata._hcur = simSettings->getHdef();
  mFMUdata._tcur = simSettings->getTstart();

  std::cout<<"Version returned from FMU: "<< std::string(fmi2_import_get_version(mpFMU))<<std::endl;
  std::cout<<"Platform type returned: "<< std::string(fmi2_import_get_types_platform(mpFMU))<<std::endl;

  // Calloc everything
  mFMUdata._nStates = fmi2_import_get_number_of_continuous_states(mpFMU);
  mFMUdata._nEventIndicators = fmi2_import_get_number_of_event_indicators(mpFMU);
  std::cout<<"n_states: "<< std::to_string(mFMUdata._nStates) << " " << std::to_string(mFMUdata._nEventIndicators)<<std::endl;

  mFMUdata._states = (double*)calloc(mFMUdata._nStates, sizeof(double));
  mFMUdata._statesDer = (double*)calloc(mFMUdata._nStates, sizeof(double));
  mFMUdata._eventIndicators = (double*)calloc(mFMUdata._nEventIndicators, sizeof(double));
  mFMUdata._eventIndicatorsPrev = (double*)calloc(mFMUdata._nEventIndicators, sizeof(double));
  mFMUdata._stateVRs = (unsigned int*) malloc(mFMUdata._nStates*sizeof(unsigned int));
  mFMUdata._stateNames = {};

  // initialize variables
  std::string stateVarName = "";
  std::string derVarName = "";

  //set state VRs and Names
  fmi2_import_variable_list_t* derVariables = fmi2_import_get_derivatives_list(mpFMU);
  mFMUdata._stateVRs =  (unsigned int*)fmi2_import_get_value_referece_list(derVariables);
  for (unsigned int i=0;i<mFMUdata._nStates;i++){
    fmi2_import_variable_t *derVar = fmi2_import_get_variable_by_vr(mpFMU, fmi2_base_type_enu_t::fmi2_base_type_real, mFMUdata._stateVRs[i]);
    derVarName = std::string(fmi2_import_get_variable_name(derVar));
    if (derVarName.size() >= 5){
      fmi2_import_variable_t * stateVar = (fmi2_import_variable_t*)fmi2_import_get_real_variable_derivative_of(fmi2_import_get_variable_as_real(derVar));
      stateVarName = std::string(fmi2_import_get_variable_name(stateVar));
      //std::cout<<" state "<<i<<" : "<<stateVarName<<std::endl;
      mFMUdata._stateNames.push_back(stateVarName);
      mFMUdata._stateVRs[i] = (unsigned int)fmi2_import_get_variable_vr(fmi2_import_get_variable_by_name(mpFMU, stateVarName.c_str()));
    }
  }

  // Instantiate model
  jm_status_enu_t jmstatus = fmi2_import_instantiate(mpFMU, "Test ME model instance",fmi2_model_exchange,0,0);
  if (jmstatus == jm_status_error)
  {
    std::cout<<"fmi2_import_instantiate_model failed. Exiting."<<std::endl;
  }

  //initialize
  mFMUdata.fmiStatus2 = fmi2_import_setup_experiment(mpFMU, simSettings->getToleranceControlled(), simSettings->getRelativeTolerance(), simSettings->getTstart(), fmi2_false, 0.0);

  try
  {
    mFMUdata.fmiStatus2 = fmi2_import_enter_initialization_mode(mpFMU);
  mFMUdata.fmiStatus2 = fmi2_import_exit_initialization_mode(mpFMU);
  }
  catch (std::exception &ex)
  {
    std::cout << __FILE__ << " : " << __LINE__ << " Exception: " << ex.what() << std::endl;
  }
  /*
  tcur = tstart;
  hcur = hdef;
  callEventUpdate = fmi2_false;

  eventInfo.newDiscreteStatesNeeded           = fmi2_false;
  eventInfo.terminateSimulation               = fmi2_false;
  eventInfo.nominalsOfContinuousStatesChanged = fmi2_false;
  eventInfo.valuesOfContinuousStatesChanged   = fmi2_true;
  eventInfo.nextEventTimeDefined              = fmi2_false;
  eventInfo.nextEventTime                     = -0.0;
  */

  //set logger
  mFMUdata.fmiStatus2 = fmi2_import_set_debug_logging(mpFMU, fmi2_false,0,0);
  printf("fmi2_import_set_debug_logging:  %s\n", fmi2_status_to_string(mFMUdata.fmiStatus2));
  //fmi2_import_set_debug_logging(mpFMU, fmi2_true, 0, 0);

  //fmiExitInitializationMode leaves FMU in event mode
  do_event_iteration(mpFMU, &mFMUdata.eventInfo2);
  fmi2_import_enter_continuous_time_mode(mpFMU);

  mFMUdata.fmiStatus2 = fmi2_import_get_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
  mFMUdata.fmiStatus2 = fmi2_import_get_event_indicators(mpFMU, mFMUdata._eventIndicatorsPrev, mFMUdata._nEventIndicators);

  std::cout<<"FMU::initialize(). Finished."<<std::endl;
}

void FMUWrapper_ME_2::do_event_iteration(fmi2_import_t *fmu, fmi2_event_info_t *eventInfo)
{
  eventInfo->newDiscreteStatesNeeded = fmi2_true;
  eventInfo->terminateSimulation     = fmi2_false;
  while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation) {
    fmi2_import_new_discrete_states(fmu, eventInfo);
  }
}

const FMUData* FMUWrapper_ME_2::getFMUData()
{
  return &mFMUdata;
}

fmi2_import_t* FMUWrapper_ME_2::getFMU()
{
  return mpFMU;
}

void FMUWrapper_ME_2::setContinuousStates()
{
  mFMUdata.fmiStatus2 = fmi2_import_set_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
}

bool FMUWrapper_ME_2::checkForTriggeredEvent()
{
  for (size_t k = 0; k < mFMUdata._nEventIndicators; ++k)
  {
    if (mFMUdata._eventIndicators[k] * mFMUdata._eventIndicatorsPrev[k] < 0)
    {
      //std::cout<<"Event occurred at "<<std::to_string(mFMUdata._tcur)<<std::endl;
      return true;
    }
  }
  return false;
}

bool FMUWrapper_ME_2::itsEventTime()
{
  return (mFMUdata.eventInfo2.nextEventTimeDefined && mFMUdata._tcur == mFMUdata.eventInfo2.nextEventTime);
}

void FMUWrapper_ME_2::updateNextTimeStep(const double hdef)
{
  double tlast = mFMUdata._tcur;
  mFMUdata._tcur += hdef;
  if (mFMUdata.eventInfo2.nextEventTimeDefined && (mFMUdata._tcur >= mFMUdata.eventInfo2.nextEventTime)) {
    mFMUdata._tcur = mFMUdata.eventInfo2.nextEventTime;
  }
  mFMUdata._hcur = mFMUdata._tcur - tlast;
}

void FMUWrapper_ME_2::handleEvents(const int intermediateResults)
{
  //std::cout<<"Handle event at "<<std::to_string(mFMUdata._tcur)<<std::endl;
  mFMUdata.fmiStatus2 = fmi2_import_enter_event_mode(mpFMU);
  do_event_iteration(mpFMU, &mFMUdata.eventInfo2);
  mFMUdata.fmiStatus2 = fmi2_import_enter_continuous_time_mode(mpFMU);
  mFMUdata.fmiStatus2 = fmi2_import_get_continuous_states(mpFMU, mFMUdata._states, mFMUdata._nStates);
  mFMUdata.fmiStatus2 = fmi2_import_get_event_indicators(mpFMU, mFMUdata._eventIndicators, mFMUdata._nEventIndicators);
}

void FMUWrapper_ME_2::prepareSimulationStep(const double time)
{
  mFMUdata.fmiStatus2 = fmi2_import_set_time(mpFMU, time);
  mFMUdata.fmiStatus2 = fmi2_import_get_event_indicators(mpFMU, mFMUdata._eventIndicators, mFMUdata._nEventIndicators);
}

void FMUWrapper_ME_2::setLastStepSize(const double simTimeEnd)
{
  if (mFMUdata._tcur > simTimeEnd - mFMUdata._hcur / 1e16)
  {
    mFMUdata._tcur -= mFMUdata._hcur;
    mFMUdata._hcur = simTimeEnd - mFMUdata._tcur;
    mFMUdata._tcur = simTimeEnd;
  }
}

void FMUWrapper_ME_2::solveSystem()
{
  mFMUdata.fmiStatus2 = fmi2_import_get_derivatives(mpFMU, mFMUdata._statesDer, mFMUdata._nStates);
}

void FMUWrapper_ME_2::doEulerStep()
{
  for (size_t k = 0; k < mFMUdata._nStates; ++k)
    mFMUdata._states[k] = mFMUdata._states[k] + mFMUdata._hcur * mFMUdata._statesDer[k];
}

void FMUWrapper_ME_2::completedIntegratorStep(int* callEventUpdate)
{
  mFMUdata.fmiStatus2 = fmi2_import_completed_integrator_step(mpFMU, fmi2_true, (fmi2_boolean_t*)callEventUpdate, &mFMUdata.terminateSimulation);
}

unsigned int FMUWrapper_ME_2::fmi_get_variable_by_name(const char* name)
{
    fmi2_import_variable_t* var = fmi2_import_get_variable_by_name(mpFMU, name);
    return (unsigned int)fmi2_import_get_variable_vr(var);
}
