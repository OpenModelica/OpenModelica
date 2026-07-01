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
#include "util/real_array.h"
#include "util/generic_array.h"

/* ===== relationhysteresis wrapper =====
 *
 * runtime relationhysteresis() is static inline in model_help.h, so the
 * JIT-emitted IR cannot reach it directly. Wrap it with an exported
 * symbol whose function-pointer args (op_w / op_w_zc) are picked from
 * an op-code, so SCTL emits one extern call per relation regardless of
 * the operator. Op codes:
 *   0 = Less, 1 = LessEq, 2 = Greater, 3 = GreaterEq
 * Other values are a programmer bug -- the wrapper falls through to
 * zero (the relation reads as false) and the runtime continues with
 * whatever state it had. */
#include "simulation/solver/model_help.h"
#include "simulation/solver/nonlinearSystem.h"
#include "simulation/solver/linearSystem.h"

/* Linear tearing system, any unknown count >= 1. SCTL emits one call to
 * this per SES_LINEAR; mirrors CodegenC's equationLinear body (a length-N
 * stack array aux_x seeded from each iteration variable's old realVars
 * value, one solve_linear_system call, throw on failure, write-back).
 * The matrix-setup callbacks (setA / setb / analytic Jacobian columns)
 * are populated by the still-clang'd _03lsy.c at startup via
 * data->callback->initialLinearSystem, so this adapter does no LS
 * bookkeeping -- it only threads the iteration variables through the
 * aux_x exchange buffer.
 *
 * varSlots points at a length-n const int64 array of flat realVars[]
 * indices (one per iteration variable, in the same order
 * CodegenC's `aux_x[i]` literal initializer uses). SCTL emits the
 * array as a private constant LLVM global per system; the runtime
 * never frees it.
 *
 * n is bounded by AUX_X_STACK_MAX so the local array stays on the
 * stack; the runtime throws if a model ever exceeds it. The bound is
 * generous (MultiBody loops in MSL top out well below) but visible. */
#define OMC_JIT_AUX_X_STACK_MAX 128

int omc_jit_solve_linear_system_n(DATA *data, threadData_t *threadData,
                                  int sysIndex, int n,
                                  const int64_t *varSlots)
{
  if (n > OMC_JIT_AUX_X_STACK_MAX) {
    throwStreamPrint(threadData,
      "omc_jit_solve_linear_system_n: size %d exceeds compiled-in cap %d",
      n, OMC_JIT_AUX_X_STACK_MAX);
  }
  double aux_x[OMC_JIT_AUX_X_STACK_MAX];
  int i, retValue;
  for (i = 0; i < n; ++i) {
    aux_x[i] = data->localData[0]->realVars[varSlots[i]];
  }
  retValue = solve_linear_system(data, threadData, sysIndex, &aux_x[0]);
  if (retValue > 0) {
    throwStreamPrint(threadData,
      "Solving linear system %d failed. For more information use -lv LOG_LS.",
      sysIndex);
  }
  for (i = 0; i < n; ++i) {
    data->localData[0]->realVars[varSlots[i]] = aux_x[i];
  }
  return retValue;
}

/* Nonlinear tearing system, any iteration-variable count >= 1. Mirrors
 * the linear adapter pattern; the iteration-variable exchange goes
 * through the runtime's nlsxOld / nlsx arrays (each pre-sized to the
 * system's `nUnknowns` by initializeNonlinearSystems), not a local
 * stack buffer. */
int omc_jit_solve_nonlinear_system_n(DATA *data, threadData_t *threadData,
                                     int sysIndex, int n,
                                     const int64_t *varSlots)
{
  NONLINEAR_SYSTEM_DATA *const nls =
      &(data->simulationInfo->nonlinearSystemData[sysIndex]);
  int i, retValue;
  for (i = 0; i < n; ++i) {
    nls->nlsxOld[i] = data->localData[0]->realVars[varSlots[i]];
  }
  retValue = solve_nonlinear_system(data, threadData, sysIndex);
  if (retValue > 0) {
    throwStreamPrint(threadData,
      "Solving non-linear system %d failed. For more information use -lv LOG_NLS.",
      sysIndex);
  }
  for (i = 0; i < n; ++i) {
    data->localData[0]->realVars[varSlots[i]] = nls->nlsx[i];
  }
  return retValue;
}

void omc_jit_relationhysteresis(DATA *data, modelica_boolean *res,
                                double exp1, double exp2,
                                double exp1_nominal, double exp2_nominal,
                                int index, int op_code)
{
  switch (op_code) {
    case 0: relationhysteresis(data, res, exp1, exp2, exp1_nominal, exp2_nominal, index, Less,      LessZC);      break;
    case 1: relationhysteresis(data, res, exp1, exp2, exp1_nominal, exp2_nominal, index, LessEq,    LessEqZC);    break;
    case 2: relationhysteresis(data, res, exp1, exp2, exp1_nominal, exp2_nominal, index, Greater,   GreaterZC);   break;
    case 3: relationhysteresis(data, res, exp1, exp2, exp1_nominal, exp2_nominal, index, GreaterEq, GreaterEqZC); break;
    default: *res = 0; break;
  }
}

/* omc_jit_zc_value: the gout value the solver root-finds for a single zero
 * crossing, mirroring CodegenC's function_ZeroCrossings body
 *   gout[index] = <op>ZC(exp1, exp2, exp1_nominal, exp2_nominal,
 *                        storedRelations[index]) ? 1 : -1;
 * The op_code maps the same way as omc_jit_relationhysteresis
 * (0=Less, 1=LessEq, 2=Greater, 3=GreaterEq). Returning the hysteresis
 * +1/-1 step (rather than the raw continuous residual lhs-rhs) is what
 * makes the JIT detect state events inside the tolZC band exactly as the
 * C path does -- the raw residual fired events at the exact crossing,
 * which diverged every event-model trace (e.g. BouncingBall). */
double omc_jit_zc_value(DATA *data, double exp1, double exp2,
                        double exp1_nominal, double exp2_nominal,
                        int index, int op_code)
{
  modelica_boolean dir = data->simulationInfo->storedRelations[index];
  modelica_boolean r;
  switch (op_code) {
    case 0: r = LessZC(exp1, exp2, exp1_nominal, exp2_nominal, dir);      break;
    case 1: r = LessEqZC(exp1, exp2, exp1_nominal, exp2_nominal, dir);    break;
    case 2: r = GreaterZC(exp1, exp2, exp1_nominal, exp2_nominal, dir);   break;
    case 3: r = GreaterEqZC(exp1, exp2, exp1_nominal, exp2_nominal, dir); break;
    default: r = 0; break;
  }
  return r ? 1.0 : -1.0;
}

/* omc_jit_array_call2_real: lower a SES_ARRAY_CALL_ASSIGN of the shape
 *   <realVars array> = fn(<const real vector>, <const real vector>)
 * where fn returns a real_array (by value) -- e.g. the MultiBody
 *   world.z_label.R_lines = Frames.TransformationMatrices.from_nxy(n_x, n_y).
 * SCTL passes the constant operand data as plain double buffers (it built
 * them as IR globals), the model function as a raw pointer (resolved from
 * <Model>_functions.c against omcruntime), and the destination as the flat
 * realVars start slot plus the 2-D shape. We wrap the operands in stack
 * real_array descriptors, call fn through the pointer (clang owns the
 * struct-by-value ABI), then copy the result into the realVars block --
 * byte-for-byte the body CodegenC emits with real_array_create +
 * real_array_copy_data. The operand and result data stay contiguous in
 * realVars exactly as the C path lays them out. */
/* omc_jit_assert: the runtime side of a STMT_ASSERT lowered by SCTL.
 * SCTL evaluates the assert condition (a modelica_boolean) and passes it
 * plus the static assert message; if the condition is false we throw,
 * matching CodegenC's `if (!cond) omc_assert(..., msg)`. Using
 * throwStreamPrint keeps the contract simple (no FILE_INFO/equation-index
 * plumbing); the message text is the model's own assert string. */
void omc_jit_assert(threadData_t *threadData, modelica_boolean cond,
                    const char *msg)
{
  if (!cond) {
    throwStreamPrint(threadData, "%s", msg);
  }
}

void omc_jit_array_call2_real(DATA *data, threadData_t *threadData,
                              void *fnptr,
                              const modelica_real *a_data, int a_len,
                              const modelica_real *b_data, int b_len,
                              int destSlot, int destNdims,
                              int destD0, int destD1)
{
  typedef real_array (*fn2_t)(threadData_t *, real_array, real_array);
  fn2_t fn = (fn2_t) fnptr;
  _index_t adims[1]; _index_t bdims[1];
  real_array a; real_array b; real_array dst;
  adims[0] = (_index_t) a_len;
  bdims[0] = (_index_t) b_len;
  a.ndims = 1; a.dim_size = adims; a.data = (void *) a_data; a.flexible = 0;
  b.ndims = 1; b.dim_size = bdims; b.data = (void *) b_data; b.flexible = 0;
  real_array_create(&dst, &data->localData[0]->realVars[destSlot],
                    destNdims, (_index_t) destD0, (_index_t) destD1);
  real_array_copy_data(fn(threadData, a, b), dst);
}

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

/* ===== main() runtime adapter ===== */

#include "meta/meta_modelica_segv.h"
#include "util/rtclock.h"
#include "gc/omc_gc.h"

/* The omc_assert function-pointer globals + the
 * omc_assert_simulation pair are declared in
 * simulation_omc_assert.h, already pulled in via the top includes.
 * omc_alloc_interface is declared in gc/omc_gc.h. */

static int omc_jit_rml_execution_failed(void)
{
  fflush(NULL);
  fprintf(stderr, "[omc_jit_main_runtime] execution failed\n");
  return 1;
}

/* Parse the guid= line out of <prefix>_init.xml so the adapter can set
 * modelData->modelGUID to the value SerializeInitXML wrote (the
 * simulation runtime cross-checks the two and aborts on mismatch).
 *
 * The native path solves this by having CodegenC's setupDataStruc bake
 * the same UUID into both the .c source (via SerializeInitXML's
 * shared `guid` argument) and the .xml metadata. The LLVM JIT path
 * never sees that UUID -- the SCTL main shim runs after the XML is
 * already on disk, and pushing the UUID through Global state from the
 * C codegen case would couple the two paths. Reading the XML here
 * keeps the coordination local to the LLVM tree.
 *
 * Returns a pointer into a static buffer (one-model-per-JIT-session
 * is the assumption today; if the cache grows beyond that this needs
 * to become per-model storage). Empty string on parse failure -- the
 * runtime will then assert with a clear "GUID does not match"
 * message rather than crash. */
static const char *omc_jit_read_guid_from_xml(const char *const xmlPath)
{
  static char guidBuf[64];
  guidBuf[0] = '\0';
  FILE *const f = fopen(xmlPath, "r");
  if (!f) {
    fprintf(stderr,
            "[omc_jit_main_runtime] cannot open '%s' to read GUID\n",
            xmlPath);
    return guidBuf;
  }
  char line[2048];
  while (fgets(line, sizeof(line), f)) {
    /* Look for a line of the form:  guid = "..."  with any spacing.
     * The XML the OMC SerializeInitXML emits matches this shape;
     * a full XML parser is overkill for one field. */
    const char *const k = strstr(line, "guid");
    if (!k) continue;
    const char *eq = strchr(k, '=');
    if (!eq) continue;
    const char *const q1 = strchr(eq, '"');
    if (!q1) continue;
    const char *const q2 = strchr(q1 + 1, '"');
    if (!q2) continue;
    const size_t n = (size_t)(q2 - q1 - 1);
    if (n >= sizeof(guidBuf)) break;
    memcpy(guidBuf, q1 + 1, n);
    guidBuf[n] = '\0';
    break;
  }
  fclose(f);
  return guidBuf;
}

/* Single-call entry the SCTL main shim invokes. Handles the whole
 * CodegenC main() body that is impractical to lift line-by-line into
 * IR (MMC_TRY_TOP / MMC_TRY_STACK setjmp dance, omc_assert global
 * function-pointer reassignments, MMC_INIT + omc_alloc_interface.init,
 * _main_initRuntimeAndSimulation + _main_SimulationRuntime call
 * sequence). SCTL's main alloca's the three structs, wires
 * modelData / simulationInfo, and tail-calls this. Returns the
 * simulation runtime's exit status. */
int omc_jit_main_runtime(int argc, char **argv,
                         MODEL_DATA *modelData, SIMULATION_INFO *simInfo,
                         void (*setupDataStruc)(DATA *, threadData_t *),
                         const char *modelName,
                         const char *modelFilePrefix,
                         const char *infoJsonFile)
{
  /* CodegenC's setupDataStruc sets these inline; the JIT path passes
   * them as args so SCTL can emit the string constants as private IR
   * globals. modelDataXml.fileName and modelGUID are load-bearing:
   * solver_main reads the _info.json from the former and asserts the
   * latter against the value in <prefix>_init.xml. We read the GUID
   * out of the XML here so the runtime check always succeeds without
   * the SCTL bitcode having to know what SerializeInitXML wrote. */
  modelData->modelName = modelName;
  modelData->modelFilePrefix = modelFilePrefix;
  modelData->modelFileName = "<jit>";
  modelData->resultFileName = NULL;
  modelData->modelDir = "";
  {
    char xmlPath[1024];
    snprintf(xmlPath, sizeof(xmlPath), "%s_init.xml", modelFilePrefix);
    modelData->modelGUID = omc_jit_read_guid_from_xml(xmlPath);
  }
  modelData->initXMLData = NULL;
  /* The main-shim allocas MODEL_DATA without zeroing and setupDataStruc
   * leaves modelDataXml alone, so its bookkeeping fields (nEquations,
   * functionNames, equationInfo, modelInfoXml, ...) are stack garbage.
   * modelInfoInit -- reached the moment a linear/nonlinear solver runs
   * its solution check -- assumes those are zero and callocs from them,
   * so clear the struct before wiring the load-bearing fileName. */
  memset(&modelData->modelDataXml, 0, sizeof(modelData->modelDataXml));
  modelData->modelDataXml.infoXMLData = NULL;
  modelData->modelDataXml.fileName = infoJsonFile;
  modelData->resourcesDir = NULL;
  modelData->runTestsuite = 0;
  modelData->linearizationDumpLanguage = OMC_LINEARIZE_DUMP_LANGUAGE_MODELICA;

  omc_assert = omc_assert_simulation;
  omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;
  omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
  omc_assert_warning = omc_assert_warning_simulation;
  omc_terminate = omc_terminate_simulation;
  omc_throw = omc_throw_simulation;

  measure_time_flag = 0;
  compiledInDAEMode = 0;
  compiledWithSymSolver = 0;

  MMC_INIT(0);
  omc_alloc_interface.init();

  int res = 0;
  DATA data;
  data.modelData = modelData;
  data.simulationInfo = simInfo;

  {
    MMC_TRY_TOP()
    MMC_TRY_STACK()

    setupDataStruc(&data, threadData);
    res = _main_initRuntimeAndSimulation(argc, argv, &data, threadData);
    if (res == 0) {
      res = _main_SimulationRuntime(argc, argv, &data, threadData);
    }

    MMC_ELSE()
    res = omc_jit_rml_execution_failed();
    MMC_CATCH_STACK()
    MMC_CATCH_TOP(res = omc_jit_rml_execution_failed());
  }

  fflush(NULL);
  return res;
}
