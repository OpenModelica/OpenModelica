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
