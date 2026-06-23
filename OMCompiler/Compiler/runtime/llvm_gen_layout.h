/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * Layout offsets exported by llvm_gen_layout.c.
 *
 * Single source of truth for the byte offsets the LLVM emission code
 * uses when chasing field accesses in the C runtime's DATA /
 * SIMULATION_DATA / SIMULATION_INFO structs and when composing the
 * <Model>_callback global. Keeping the extern declarations in a header
 * lets llvm_gen_layout.c (the definition site) and llvm_gen.cpp (the
 * sole consumer) share a single list -- so adding a new field offset
 * is one edit in the header plus one edit in the .c.
 *
 * No transitive includes here: the file only declares  extern const
 * size_t  variables, so callers do not pull in <simulation_data.h>
 * just by including this header.
 */

#ifndef OMC_LLVM_GEN_LAYOUT_H
#define OMC_LLVM_GEN_LAYOUT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* DATA / SIMULATION_DATA / SIMULATION_INFO field offsets. Consumed by
 * the createInlined* helpers in llvm_gen.cpp. */
extern const size_t omc_layout_DATA_localData;
extern const size_t omc_layout_DATA_simulationInfo;

extern const size_t omc_layout_SD_timeValue;
extern const size_t omc_layout_SD_realVars;
extern const size_t omc_layout_SD_integerVars;
extern const size_t omc_layout_SD_booleanVars;

extern const size_t omc_layout_SI_realVarsIndex;
extern const size_t omc_layout_SI_integerVarsIndex;
extern const size_t omc_layout_SI_booleanVarsIndex;
extern const size_t omc_layout_SI_realParamsIndex;
extern const size_t omc_layout_SI_realParameter;
extern const size_t omc_layout_SI_booleanParameter;
extern const size_t omc_layout_SI_relations;
extern const size_t omc_layout_SI_extObjs;

/* DATA.callback (pointer to the OpenModelicaGeneratedFunctionCallbacks
 * struct) + threadData_s.localRoots[] (void* array) + the int slot
 * index reserved for SIMULATION_DATA. The setupDataStruc emitter
 * wires data->callback and threadData->localRoots[SIMULATION_DATA]
 * directly via these. */
extern const size_t omc_layout_DATA_callback;
extern const size_t omc_layout_DATA_modelData;
extern const size_t omc_layout_TD_localRoots;
extern const int    omc_value_LOCAL_ROOT_SIMULATION_DATA;

/* Struct sizes for stack allocation inside the main() shim. The shell
 * alloca's DATA, MODEL_DATA, SIMULATION_INFO on the stack with these
 * exact byte counts so the JIT module does not need to know the C
 * struct shapes in any other form. */
extern const size_t omc_sizeof_DATA;
extern const size_t omc_sizeof_MODEL_DATA;
extern const size_t omc_sizeof_SIMULATION_INFO;

/* MODEL_DATA int-counter offsets used by the full setupDataStruc
 * body. The single ordered table omc_modeldata_int_offsets[] lets the
 * Modelica side pass one flat list<Integer> rather than 30+ separate
 * extern arguments; the C++ emitter zips it against the offsets and
 * emits one store per field. omc_modeldata_int_count is sizeof(table)
 * over sizeof(size_t). The field order is fixed and documented in
 * llvm_gen_layout.c -- keep `emitSetupDataStrucBlock` in lock-step. */
extern const size_t omc_modeldata_int_offsets[];
extern const size_t omc_modeldata_int_count;

/* Callback function-pointer struct (OpenModelicaGeneratedFunctionCallbacks)
 * total size and per-field byte offsets. Consumed by createCallbackTable
 * in llvm_gen.cpp. */
extern const size_t omc_layout_callback_total;
extern const size_t omc_layout_callback_performSimulation;
extern const size_t omc_layout_callback_performQSSSimulation;
extern const size_t omc_layout_callback_updateContinuousSystem;
extern const size_t omc_layout_callback_callExternalObjectDestructors;
extern const size_t omc_layout_callback_initialNonLinearSystem;
extern const size_t omc_layout_callback_initialLinearSystem;
extern const size_t omc_layout_callback_initialMixedSystem;
extern const size_t omc_layout_callback_initializeStateSets;
extern const size_t omc_layout_callback_initializeDAEmodeData;
extern const size_t omc_layout_callback_getDAG_ODE;
extern const size_t omc_layout_callback_functionODE;
extern const size_t omc_layout_callback_functionAlgebraics;
extern const size_t omc_layout_callback_functionDAE;
extern const size_t omc_layout_callback_functionLocalKnownVars;
extern const size_t omc_layout_callback_input_function;
extern const size_t omc_layout_callback_input_function_init;
extern const size_t omc_layout_callback_input_function_updateStartValues;
extern const size_t omc_layout_callback_data_function;
extern const size_t omc_layout_callback_output_function;
extern const size_t omc_layout_callback_setc_function;
extern const size_t omc_layout_callback_setb_function;
extern const size_t omc_layout_callback_function_storeDelayed;
extern const size_t omc_layout_callback_function_storeSpatialDistribution;
extern const size_t omc_layout_callback_function_initSpatialDistribution;
extern const size_t omc_layout_callback_updateBoundVariableAttributes;
extern const size_t omc_layout_callback_functionInitialEquations;
extern const size_t omc_layout_callback_homotopyMethod;
extern const size_t omc_layout_callback_functionInitialEquations_lambda0;
extern const size_t omc_layout_callback_functionRemovedInitialEquations;
extern const size_t omc_layout_callback_updateBoundParameters;
extern const size_t omc_layout_callback_checkForAsserts;
extern const size_t omc_layout_callback_function_ZeroCrossingsEquations;
extern const size_t omc_layout_callback_function_ZeroCrossings;
extern const size_t omc_layout_callback_function_updateRelations;
extern const size_t omc_layout_callback_zeroCrossingDescription;
extern const size_t omc_layout_callback_relationDescription;
extern const size_t omc_layout_callback_function_initSample;
extern const size_t omc_layout_callback_INDEX_JAC_A;
extern const size_t omc_layout_callback_INDEX_JAC_ADJ;
extern const size_t omc_layout_callback_INDEX_JAC_B;
extern const size_t omc_layout_callback_INDEX_JAC_C;
extern const size_t omc_layout_callback_INDEX_JAC_D;
extern const size_t omc_layout_callback_INDEX_JAC_F;
extern const size_t omc_layout_callback_INDEX_JAC_H;
extern const size_t omc_layout_callback_initialAnalyticJacobianA;
extern const size_t omc_layout_callback_initialAnalyticJacobianADJ;
extern const size_t omc_layout_callback_initialAnalyticJacobianB;
extern const size_t omc_layout_callback_initialAnalyticJacobianC;
extern const size_t omc_layout_callback_initialAnalyticJacobianD;
extern const size_t omc_layout_callback_initialAnalyticJacobianF;
extern const size_t omc_layout_callback_initialAnalyticJacobianH;
extern const size_t omc_layout_callback_functionJacA_column;
extern const size_t omc_layout_callback_functionJacADJ_column;
extern const size_t omc_layout_callback_functionJacB_column;
extern const size_t omc_layout_callback_functionJacC_column;
extern const size_t omc_layout_callback_functionJacD_column;
extern const size_t omc_layout_callback_functionJacF_column;
extern const size_t omc_layout_callback_functionJacH_column;
extern const size_t omc_layout_callback_getDAG_JacA;
extern const size_t omc_layout_callback_linear_model_frame;
extern const size_t omc_layout_callback_linear_model_datarecovery_frame;
extern const size_t omc_layout_callback_mayer;
extern const size_t omc_layout_callback_lagrange;
extern const size_t omc_layout_callback_getInputVarIndicesInOptimization;
extern const size_t omc_layout_callback_pickUpBoundsForInputsInOptimization;
extern const size_t omc_layout_callback_setInputData;
extern const size_t omc_layout_callback_getTimeGrid;
extern const size_t omc_layout_callback_symbolicInlineSystems;
extern const size_t omc_layout_callback_function_initSynchronous;
extern const size_t omc_layout_callback_function_updateSynchronous;
extern const size_t omc_layout_callback_function_equationsSynchronous;
extern const size_t omc_layout_callback_inputNames;
extern const size_t omc_layout_callback_dataReconciliationInputNames;
extern const size_t omc_layout_callback_dataReconciliationUnmeasuredVariables;
extern const size_t omc_layout_callback_read_simulation_info;
extern const size_t omc_layout_callback_read_input_fmu;
extern const size_t omc_layout_callback_initialPartialFMIDER;
extern const size_t omc_layout_callback_functionJacFMIDER_column;
extern const size_t omc_layout_callback_INDEX_JAC_FMIDER;
extern const size_t omc_layout_callback_initialPartialFMIDERINIT;
extern const size_t omc_layout_callback_functionJacFMIDERINIT_column;
extern const size_t omc_layout_callback_INDEX_JAC_FMIDERINIT;

#ifdef __cplusplus
}
#endif

#endif /* OMC_LLVM_GEN_LAYOUT_H */
