#ifndef OIS_FMI2_ME_H
#define OIS_FMI2_ME_H
#include "fmi2Functions.h"

#ifdef __cplusplus
extern "C" {
#endif


struct fmi2_me_t
{
    //OSI data structur
	omsi_t                        osi;
    //Model exchange or co simulation fmu
	fmi2Type                     fmu_type;
    //Name of fmu
	fmi2String                   fmu_instance_name;
    //GUID of fmu
	fmi2String                   fmu_GUID;

	const fmi2CallbackFunctions* fmi_functions;


};



fmi2Status omsi_fmi2_set_debug_logging(fmi2Component c,fmi2Boolean  loggingOn,size_t nCategories,const fmi2String categories[]);




//fmi2Instantiate
fmi2Component omsi_fmi2_instantiate(fmi2String instanceName,
                               fmi2Type   fmuType,
                               fmi2String fmuGUID,
                               fmi2String fmuResourceLocation,
                               const fmi2CallbackFunctions* functions,
                               fmi2Boolean                  visible,
                               fmi2Boolean                  loggingOn);

//fmi2FreeInstance
void omsi_fmi2_free_instance(fmi2Component c);

//fmi2SetupExperiment
fmi2Status omsi_fmi2_setup_experiment(fmi2Component c,
                                 fmi2Boolean   toleranceDefined,
                                 fmi2Real      tolerance,
                                 fmi2Real      startTime,
                                 fmi2Boolean   stopTimeDefined,
                                 fmi2Real      stopTime);

//fmi2EnterInitializationMode
fmi2Status omsi_fmi2_enter_initialization_mode(fmi2Component c);

//fmi2ExitInitializationMode
fmi2Status omsi_fmi2_exit_initialization_mode(fmi2Component c);

//fmi2Terminate
fmi2Status omsi_fmi2_terminate(fmi2Component c);

//fmi2Reset
fmi2Status omsi_fmi2_reset(fmi2Component c);

//fmi2GetReal
fmi2Status omsi_fmi2_get_real(fmi2Component c, const fmi2ValueReference vr[],
                         size_t nvr, fmi2Real value[]);

//fmi2GetInteger
fmi2Status omsi_fmi2_get_integer(fmi2Component c, const fmi2ValueReference vr[],
                            size_t nvr, fmi2Integer value[]);

//fmi2GetBoolean
fmi2Status omsi_fmi2_get_boolean(fmi2Component c, const fmi2ValueReference vr[],
                            size_t nvr, fmi2Boolean value[]);

//fmi2GetString
fmi2Status omsi_fmi2_get_string(fmi2Component c, const fmi2ValueReference vr[],
                           size_t nvr, fmi2String value[]);

//fmi2SetReal
fmi2Status omsi_fmi2_set_real(fmi2Component c, const fmi2ValueReference vr[],
                         size_t nvr, const fmi2Real value[]);

//fmi2SetInteger
fmi2Status omsi_fmi2_set_integer(fmi2Component c, const fmi2ValueReference vr[],
                            size_t nvr, const fmi2Integer value[]);

//fmi2SetBoolean
fmi2Status omsi_fmi2_set_boolean(fmi2Component c, const fmi2ValueReference vr[],
                            size_t nvr, const fmi2Boolean value[]);

//fmi2SetString
fmi2Status omsi_fmi2_set_string(fmi2Component c, const fmi2ValueReference vr[],
                          size_t nvr, const fmi2String value[]);


//fmi2GetFMUstate
fmi2Status omsi_fmi2_get_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate);

//fmi2SetFMUstate
fmi2Status omsi_fmi2_set_fmu_state(fmi2Component c, fmi2FMUstate FMUstate);

//fmi2FreeFMUstate
fmi2Status omsi_fmi2_free_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate);

//fmi2SerializedFMUstateSize
fmi2Status omsi_fmi2_serialized_fmu_state_size(fmi2Component c, fmi2FMUstate FMUstate,
                                          size_t* size);

//fmi2SerializeFMUstate
fmi2Status omsi_fmi2_serialize_fmu_state(fmi2Component c, fmi2FMUstate FMUstate,
                                    fmi2Byte serializedState[], size_t size);

//fmi2DeSerializeFMUstate
fmi2Status omsi_fmi2_de_serialize_fmu_state(fmi2Component c,
                                       const fmi2Byte serializedState[],
                                       size_t size, fmi2FMUstate* FMUstate);

//fmi2GetDirectionalDerivative
fmi2Status omsi_fmi2_get_directional_derivative(fmi2Component c,
                const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
                const fmi2ValueReference vKnown_ref[],   size_t nKnown,
                const fmi2Real dvKnown[], fmi2Real dvUnknown[]);

//fmi2EnterEventMode
fmi2Status omsi_fmi2_enter_event_mode(fmi2Component c);

//fmi2NewDiscreteStates
fmi2Status omsi_fmi2_new_discrete_state(fmi2Component  c,
                                   fmi2EventInfo* fmiEventInfo);
//fmi2EnterContinuousTimeMode
fmi2Status omsi_fmi2_enter_continuous_time_mode(fmi2Component c);

//fmi2CompletedIntegratorStep
fmi2Status omsi_fmi2_completed_integrator_step(fmi2Component c,
                                          fmi2Boolean   noSetFMUStatePriorToCurrentPoint,
                                          fmi2Boolean*  enterEventMode,
                                          fmi2Boolean*  terminateSimulation);

										  fmi2Status fmi2_get_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate);

fmi2Status omsi_fmi2_get_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate);
fmi2Status omsi_fmi2_set_fmu_state(fmi2Component c, fmi2FMUstate FMUstate);
fmi2Status omsi_fmi2_free_fmu_state(fmi2Component c, fmi2FMUstate* FMUstate);
fmi2Status omsi_fmi2_serialized_fmu_state_size(fmi2Component c, fmi2FMUstate FMUstate,size_t* size);
fmi2Status omsi_fmi2_serialize_fmu_state(fmi2Component c, fmi2FMUstate FMUstate,fmi2Byte serializedState[], size_t size);


//fmi2SetTime
fmi2Status omsi_fmi2_set_time(fmi2Component c, fmi2Real time);

//fmi2SetContinuousStates
fmi2Status omsi_fmi2_set_continuous_states(fmi2Component c, const fmi2Real x[],
                                      size_t nx);

//fmi2GetDerivatives
fmi2Status omsi_fmi2_get_derivatives(fmi2Component c, fmi2Real derivatives[], size_t nx);

//fmi2GetEventIndicators
fmi2Status omsi_fmi2_get_event_indicators(fmi2Component c,
                                     fmi2Real eventIndicators[], size_t ni);
//fmi2GetContinuousStates
fmi2Status omsi_fmi2_get_continuous_states(fmi2Component c, fmi2Real x[], size_t nx);

//fmi2GetNominalsOfContinuousStates
fmi2Status omsi_fmi2_get_nominals_of_continuous_states(fmi2Component c,
                                                  fmi2Real x_nominal[],
                                                  size_t nx);


fmi2Component omsi_fmi2_me_instantiate(
                               fmi2String    instanceName,
                               fmi2Type      fmuType,
                               fmi2String    fmuGUID,
                               fmi2String    fmuResourceLocation,
                               const fmi2CallbackFunctions* functions,
                               fmi2Boolean                  visible,
                               fmi2Boolean                  loggingOn);


void omsi_fmi2_me_free_instance(fmi2Component c);


fmi2Status omsi_fmi2_get_clock(fmi2Component c,const fmi2Integer clockIndex[],size_t nClockIndex, fmi2Boolean tick[]);
fmi2Status omsi_fmi2_get_interval(fmi2Component c, const fmi2Integer clockIndex[],size_t nClockIndex, fmi2Real interval[]);
fmi2Status omsi_fmi2_set_clock(fmi2Component c, const fmi2Integer clockIndex[], size_t nClockIndex, const fmi2Boolean tick[],const fmi2Boolean subactive[]);
fmi2Status omsi_fmi2_set_interval(fmi2Component c,const fmi2Integer clockIndex[],size_t nClockIndex, const fmi2Real interval[]);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
