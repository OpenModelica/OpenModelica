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
#include <stddef.h>

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
