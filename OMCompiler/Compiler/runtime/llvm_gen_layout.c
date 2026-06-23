/*
 * This file is part of OpenModelica.
 *
 * Field offsets into the C runtime's DATA / SIMULATION_DATA /
 * SIMULATION_INFO structs, computed at OMC build time via offsetof().
 * Used by llvm_gen.cpp's createInlined* helpers to emit GEP / load
 * chains directly into model functions, replacing the runtime-helper
 * calls (omc_jit_get_real_var, omc_jit_set_real_param, ...) that
 * SimCodeToLLVM previously emitted.
 *
 * Inlining matters because:
 *   - The LLVM optimizer can fold redundant loads (the realVars base
 *     pointer is hoisted once per function instead of reloaded per
 *     access).
 *   - There is no per-access function-call overhead.
 *   - The generated IR matches what CodegenC produces byte-for-byte,
 *     so optimization profiles do not skew.
 *
 * Exposing offsets via extern const variables keeps the inlining
 * code in llvm_gen.cpp portable: the C runtime owns the struct layout
 * (simulation_data.h), this file owns the offsets, and the LLVM
 * emission code only sees integers.
 */

/* Header lives at OMCompiler/SimulationRuntime/c/simulation_data.h; the
 * include path is added in OMCompiler/Compiler/runtime/CMakeLists.txt
 * specifically for this file. */
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "llvm_gen_layout.h"

const size_t omc_layout_DATA_localData      = offsetof(DATA, localData);
const size_t omc_layout_DATA_simulationInfo = offsetof(DATA, simulationInfo);

const size_t omc_layout_SD_timeValue        = offsetof(SIMULATION_DATA, timeValue);
const size_t omc_layout_SD_realVars         = offsetof(SIMULATION_DATA, realVars);
const size_t omc_layout_SD_integerVars      = offsetof(SIMULATION_DATA, integerVars);
const size_t omc_layout_SD_booleanVars      = offsetof(SIMULATION_DATA, booleanVars);

const size_t omc_layout_SI_realVarsIndex    = offsetof(SIMULATION_INFO, realVarsIndex);
const size_t omc_layout_SI_integerVarsIndex = offsetof(SIMULATION_INFO, integerVarsIndex);
const size_t omc_layout_SI_booleanVarsIndex = offsetof(SIMULATION_INFO, booleanVarsIndex);
const size_t omc_layout_SI_realParamsIndex  = offsetof(SIMULATION_INFO, realParamsIndex);
const size_t omc_layout_SI_realParameter    = offsetof(SIMULATION_INFO, realParameter);
const size_t omc_layout_SI_booleanParameter = offsetof(SIMULATION_INFO, booleanParameter);
const size_t omc_layout_SI_relations        = offsetof(SIMULATION_INFO, relations);
const size_t omc_layout_SI_extObjs          = offsetof(SIMULATION_INFO, extObjs);

/* Callback function-pointer struct (openmodelica_func.h). One offset per
 * field so llvm_gen.cpp can lay out the IR-side @<Model>_callback global
 * with byte-padded gaps that match the C struct exactly, without
 * duplicating struct layout knowledge inside the LLVM emitter. The total
 * size goes through omc_layout_callback_total so the IR initializer's
 * trailing padding adds up to sizeof(struct OpenModelicaGeneratedFunctionCallbacks).
 *
 * Field ordering here mirrors the declaration order in openmodelica_func.h.
 * Adding a new field upstream is the only change required to keep the IR
 * emitter in sync -- a new line here plus a new entry in the C++ field
 * descriptor table. */
const size_t omc_layout_callback_total = sizeof(struct OpenModelicaGeneratedFunctionCallbacks);

#define OMC_CB_OFFSET(field) \
  const size_t omc_layout_callback_##field = \
      offsetof(struct OpenModelicaGeneratedFunctionCallbacks, field)

OMC_CB_OFFSET(performSimulation);
OMC_CB_OFFSET(performQSSSimulation);
OMC_CB_OFFSET(updateContinuousSystem);
OMC_CB_OFFSET(callExternalObjectDestructors);
OMC_CB_OFFSET(initialNonLinearSystem);
OMC_CB_OFFSET(initialLinearSystem);
OMC_CB_OFFSET(initialMixedSystem);
OMC_CB_OFFSET(initializeStateSets);
OMC_CB_OFFSET(initializeDAEmodeData);
OMC_CB_OFFSET(getDAG_ODE);
OMC_CB_OFFSET(functionODE);
OMC_CB_OFFSET(functionAlgebraics);
OMC_CB_OFFSET(functionDAE);
OMC_CB_OFFSET(functionLocalKnownVars);
OMC_CB_OFFSET(input_function);
OMC_CB_OFFSET(input_function_init);
OMC_CB_OFFSET(input_function_updateStartValues);
OMC_CB_OFFSET(data_function);
OMC_CB_OFFSET(output_function);
OMC_CB_OFFSET(setc_function);
OMC_CB_OFFSET(setb_function);
OMC_CB_OFFSET(function_storeDelayed);
OMC_CB_OFFSET(function_storeSpatialDistribution);
OMC_CB_OFFSET(function_initSpatialDistribution);
OMC_CB_OFFSET(updateBoundVariableAttributes);
OMC_CB_OFFSET(functionInitialEquations);
OMC_CB_OFFSET(homotopyMethod);
OMC_CB_OFFSET(functionInitialEquations_lambda0);
OMC_CB_OFFSET(functionRemovedInitialEquations);
OMC_CB_OFFSET(updateBoundParameters);
OMC_CB_OFFSET(checkForAsserts);
OMC_CB_OFFSET(function_ZeroCrossingsEquations);
OMC_CB_OFFSET(function_ZeroCrossings);
OMC_CB_OFFSET(function_updateRelations);
OMC_CB_OFFSET(zeroCrossingDescription);
OMC_CB_OFFSET(relationDescription);
OMC_CB_OFFSET(function_initSample);
OMC_CB_OFFSET(INDEX_JAC_A);
OMC_CB_OFFSET(INDEX_JAC_ADJ);
OMC_CB_OFFSET(INDEX_JAC_B);
OMC_CB_OFFSET(INDEX_JAC_C);
OMC_CB_OFFSET(INDEX_JAC_D);
OMC_CB_OFFSET(INDEX_JAC_F);
OMC_CB_OFFSET(INDEX_JAC_H);
OMC_CB_OFFSET(initialAnalyticJacobianA);
OMC_CB_OFFSET(initialAnalyticJacobianADJ);
OMC_CB_OFFSET(initialAnalyticJacobianB);
OMC_CB_OFFSET(initialAnalyticJacobianC);
OMC_CB_OFFSET(initialAnalyticJacobianD);
OMC_CB_OFFSET(initialAnalyticJacobianF);
OMC_CB_OFFSET(initialAnalyticJacobianH);
OMC_CB_OFFSET(functionJacA_column);
OMC_CB_OFFSET(functionJacADJ_column);
OMC_CB_OFFSET(functionJacB_column);
OMC_CB_OFFSET(functionJacC_column);
OMC_CB_OFFSET(functionJacD_column);
OMC_CB_OFFSET(functionJacF_column);
OMC_CB_OFFSET(functionJacH_column);
OMC_CB_OFFSET(getDAG_JacA);
OMC_CB_OFFSET(linear_model_frame);
OMC_CB_OFFSET(linear_model_datarecovery_frame);
OMC_CB_OFFSET(mayer);
OMC_CB_OFFSET(lagrange);
OMC_CB_OFFSET(getInputVarIndicesInOptimization);
OMC_CB_OFFSET(pickUpBoundsForInputsInOptimization);
OMC_CB_OFFSET(setInputData);
OMC_CB_OFFSET(getTimeGrid);
OMC_CB_OFFSET(symbolicInlineSystems);
OMC_CB_OFFSET(function_initSynchronous);
OMC_CB_OFFSET(function_updateSynchronous);
OMC_CB_OFFSET(function_equationsSynchronous);
OMC_CB_OFFSET(inputNames);
OMC_CB_OFFSET(dataReconciliationInputNames);
OMC_CB_OFFSET(dataReconciliationUnmeasuredVariables);
OMC_CB_OFFSET(read_simulation_info);
OMC_CB_OFFSET(read_input_fmu);
OMC_CB_OFFSET(initialPartialFMIDER);
OMC_CB_OFFSET(functionJacFMIDER_column);
OMC_CB_OFFSET(INDEX_JAC_FMIDER);
OMC_CB_OFFSET(initialPartialFMIDERINIT);
OMC_CB_OFFSET(functionJacFMIDERINIT_column);
OMC_CB_OFFSET(INDEX_JAC_FMIDERINIT);

#undef OMC_CB_OFFSET
