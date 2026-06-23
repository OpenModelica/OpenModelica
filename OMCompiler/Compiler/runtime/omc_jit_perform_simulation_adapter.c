/*
 * This file belongs to the OpenModelica LLVM JIT path.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet. See OSMC-PL / GNU AGPL conditions in
 * the OpenModelica distribution.
 */

/*
 * Adapter: route the perform_simulation / perform_qss_simulation .inc
 * files through non-prefixed symbols (omc_jit_performSimulation /
 * omc_jit_updateContinuousSystem / omc_jit_performQSSSimulation)
 * compiled into libomcruntime. The JIT's callback table
 * (SimCodeToLLVM.createCallbackTable) points its performSimulation /
 * updateContinuousSystem / performQSSSimulation slots at these
 * symbols; the JIT's DynamicLibrarySearchGenerator finds them
 * in-process and binds.
 *
 * Why an adapter under Compiler/runtime/ and not under
 * SimulationRuntime/c/: the C runtime is a library we link against,
 * not a place to mutate from the LLVM side. This file lives in the
 * LLVM/JIT folder, pulls in the same .inc files CodegenC uses, and
 * exposes the non-prefixed entry points the JIT path needs -- without
 * touching the upstream runtime.
 *
 * Layout: one TU holds both adapter blocks for now. The split into a
 * second file kicks in only when this one passes a few thousand lines
 * (currently a couple dozen, with the bulk of the code arriving via
 * the .inc expansions).
 *
 * The perform_simulation .inc declares prefixedName_updateContinuousSystem
 * with internal linkage (static). We rename it to
 * omc_jit_updateContinuousSystem_inner inside this TU and add a thin
 * external wrapper omc_jit_updateContinuousSystem so the callback
 * table (and external runtime sites in events.c / gbode_main.c /
 * etc.) can resolve the symbol. The QSS .inc has no internal
 * updateContinuousSystem helper, so no inner / wrapper split is
 * needed for the QSS block.
 */

/* Surrounding context the .inc files expect, normally pulled in via
 * the per-model <Model>_model.h. The .inc does not include these
 * itself because CodegenC's wrapping TU always does. */
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation_data.h"
#include "simulation/simulation_info_json.h"
#include "simulation/simulation_runtime.h"
#include "util/omc_error.h"
#include "util/parallel_helper.h"
#include "simulation/jacobian_util.h"
#include "simulation/simulation_omc_assert.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/events.h"
#include "simulation/arrayIndex.h"

/* ===== perform_simulation block ===== */

#define prefixedName_performSimulation       omc_jit_performSimulation
#define prefixedName_updateContinuousSystem  omc_jit_updateContinuousSystem_inner

#include "simulation/solver/perform_simulation.c.inc"

#undef prefixedName_performSimulation
#undef prefixedName_updateContinuousSystem

#ifdef __cplusplus
extern "C" {
#endif

/* External-linkage wrapper that the JIT callback table addresses. */
void omc_jit_updateContinuousSystem(DATA *data, threadData_t *threadData)
{
  omc_jit_updateContinuousSystem_inner(data, threadData);
}

#ifdef __cplusplus
}
#endif

/* ===== perform_qss_simulation block ===== */

#define prefixedName_performQSSSimulation omc_jit_performQSSSimulation

#include "simulation/solver/perform_qss_simulation.c.inc"

#undef prefixedName_performQSSSimulation
