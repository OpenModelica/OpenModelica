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
 * Self-contained MetaModelica-ABI replacement for embedding the Rust omc port
 * (libOpenModelicaCompiler.so) in OMEdit, used when OMEdit is built with
 * -DOMC_RUST_ABI. It deliberately does NOT include any OpenModelica MMC runtime
 * header: the Rust port has its own runtime and garbage collector, so the real
 * mmc value constructors and MMC_STRINGDATA (which allocate through the OMC
 * Boehm GC) and the setjmp-based MMC_TRY/MMC_INIT machinery must not run.
 * Instead this header provides the small slice of that ABI OMEdit's command path
 * uses, backed by a trivial malloc-boxed value and no-op control-flow macros,
 * plus the C declarations of the Rust embedding entry points.
 *
 * OMEdit's mainstream init/sendCommand bodies therefore compile unchanged; only
 * the includes and the in-memory JSON-walk fast path are gated on OMC_RUST_ABI.
 */
#ifndef OMC_RUST_EMBEDDING_H
#define OMC_RUST_EMBEDDING_H

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Benign, MMC-free omc runtime metadata OMEdit pulled in transitively through
 * meta_modelica.h (the umbrella runtime header). These headers have no MMC value
 * representation or GC dependency, so they are included directly rather than
 * replaced: the simulation command-line flag table (FLAG_*, used by OMEdit's
 * simulation dialogs). */
#include "util/simulation_options.h"

/* ─────────────────────────── boxed value ──────────────────────────────────
 * A minimal tagged box standing in for the MMC `modelica_metatype` values
 * OMEdit builds/reads on the command path: a NIL/CONS list spine plus string
 * leaves. Allocated with malloc (no GC); the embedding shims in the cdylib free
 * the boxes they receive/return, so no value outlives a single command. */
typedef struct OmcRtBox {
  int tag;                 /* OMCRT_* */
  char *s;                 /* OMCRT_SCON: owned, NUL-terminated string */
  struct OmcRtBox *head;   /* OMCRT_CONS: list head */
  struct OmcRtBox *tail;   /* OMCRT_CONS: list tail */
} OmcRtBox;

#define OMCRT_NIL  0
#define OMCRT_CONS 1
#define OMCRT_SCON 2

/* MMC's generic value type: a void* tagged pointer (here an OmcRtBox*). */
typedef void *modelica_metatype;

static inline void *mmc_mk_nil(void)
{
  OmcRtBox *b = (OmcRtBox *) malloc(sizeof(OmcRtBox));
  b->tag = OMCRT_NIL; b->s = NULL; b->head = NULL; b->tail = NULL;
  return b;
}

static inline void *mmc_mk_cons(void *head, void *tail)
{
  OmcRtBox *b = (OmcRtBox *) malloc(sizeof(OmcRtBox));
  b->tag = OMCRT_CONS; b->s = NULL;
  b->head = (OmcRtBox *) head; b->tail = (OmcRtBox *) tail;
  return b;
}

static inline void *mmc_mk_scon(const char *s)
{
  OmcRtBox *b = (OmcRtBox *) malloc(sizeof(OmcRtBox));
  b->tag = OMCRT_SCON; b->head = NULL; b->tail = NULL;
  b->s = strdup(s ? s : "");
  return b;
}

/* Extract the C string from a boxed string. Mirrors the MMC macro's role on the
 * command path (where `reply_str` is always a string box). */
#define MMC_STRINGDATA(x) (((OmcRtBox *)(x))->s)

/* Stack-trace dump used by OMEdit's MMC_TRY_STACK overflow handler. With the
 * no-op control-flow macros below that handler is dead code, so a self-contained
 * no-op keeps it compiling/linking without the MMC runtime. */
static inline void printStacktraceMessages(void) {}

/* djb2 string hash matching `stringHashDjb2` (meta_modelica_builtin.c), but
 * reading the replacement box instead of an MMC string. The exact value only
 * needs to be deterministic within a run (OMEdit uses it for a temp filename). */
static inline long stringHashDjb2(void *boxed)
{
  const char *str = MMC_STRINGDATA(boxed);
  unsigned long hash = 5381;
  int c;
  while ((c = (unsigned char) *str++)) {
    hash = ((hash << 5) + hash) + (unsigned long) c; /* hash * 33 + c */
  }
  return (long) hash;
}

/* ───────────────────── thread data / callbacks ────────────────────────────
 * The Rust backend keeps its own per-thread state, so `threadData` is only a
 * carrier for the plot/loadModel callbacks OMEdit installs. The embedding shim
 * (`omc_Main_handleCommand`) forwards these to the cdylib's callback registry
 * before each command. `OpenModelicaScriptingAPIQtABI.h` declares
 * `typedef struct threadData_s threadData_t;` (opaque); this completes the tag.
 * Layout-compatible with the C runtime's PlotCallback / LoadModelCallback. */
typedef void (*OMCPlotCallback)(void *p, int externalWindow,
  const char *filename, const char *title, const char *grid, const char *plotType,
  const char *logX, const char *logY, const char *xLabel, const char *yLabel,
  const char *x1, const char *x2, const char *y1, const char *y2,
  const char *curveWidth, const char *curveStyle, const char *legendPosition,
  const char *footer, const char *autoScale, const char *variables);
typedef void (*OMCLoadModelCallback)(void *p, const char *modelName);

struct threadData_s {
  void *plotClassPointer;
  OMCPlotCallback plotCB;
  void *loadModelClassPointer;
  OMCLoadModelCallback loadModelCB;
};
typedef struct threadData_s threadData_t;

/* ──────────────────────── control-flow macros ─────────────────────────────
 * The Rust shims never longjmp (they trap panics internally and return a
 * status), so the MMC try/catch machinery becomes plain block structure that
 * always runs the try body and never the handler. The brace nesting matches the
 * real macros so OMEdit's bodies bracket correctly; `MMC_TRY_TOP` declares
 * `threadData` exactly as the real macro does. */
#define MMC_INIT(...)              ((void) 0)
#define MMC_TRY_TOP() { threadData_t threadDataOnStack = {}; threadData_t *threadData = &threadDataOnStack; (void) threadData; {
#define MMC_TRY_TOP_INTERNAL()     { {
#define MMC_CATCH_TOP(...)         } if (0) { __VA_ARGS__; } }
#define MMC_TRY_STACK()            { if (1) {
#define MMC_ELSE()                 } else {
#define MMC_CATCH_STACK()          } }

#ifdef __cplusplus
extern "C" {
#endif

/* ───────────────── simulation log-stream metadata ─────────────────────────
 * Non-MMC declarations OMEdit's getLogStreamNames() needs; normally from
 * omc_error.h (which also pulls in the MMC runtime, hence not included here).
 * The enum must match the runtime's exactly: the OMC_LOG_STREAM_NAME/DESC arrays
 * (defined in libomcruntime, still linked) are indexed by these values. */
enum OMC_LOG_STREAM
{
  OMC_LOG_UNKNOWN = 0,
  OMC_LOG_STDOUT,
  OMC_LOG_ASSERT,

  OMC_LOG_DASSL,
  OMC_LOG_DASSL_STATES,
  OMC_LOG_DEBUG,
  OMC_LOG_DELAY,
  OMC_LOG_DIVISION,
  OMC_LOG_DSS,
  OMC_LOG_DSS_JAC,
  OMC_LOG_DT,
  OMC_LOG_DT_CONS,
  OMC_LOG_EVENTS,
  OMC_LOG_EVENTS_V,
  OMC_LOG_GBODE,
  OMC_LOG_GBODE_V,
  OMC_LOG_GBODE_NLS,
  OMC_LOG_GBODE_NLS_V,
  OMC_LOG_GBODE_STATES,
  OMC_LOG_INIT,
  OMC_LOG_INIT_HOMOTOPY,
  OMC_LOG_INIT_V,
  OMC_LOG_IPOPT,
  OMC_LOG_IPOPT_FULL,
  OMC_LOG_IPOPT_JAC,
  OMC_LOG_IPOPT_HESSE,
  OMC_LOG_IPOPT_ERROR,
  OMC_LOG_JAC,
  OMC_LOG_LS,
  OMC_LOG_LS_V,
  OMC_LOG_MIXED,
  OMC_LOG_MOO,
  OMC_LOG_NLS,
  OMC_LOG_NLS_V,
  OMC_LOG_NLS_HOMOTOPY,
  OMC_LOG_NLS_JAC,
  OMC_LOG_NLS_JAC_TEST,
  OMC_LOG_NLS_JAC_SUMS,
  OMC_LOG_NLS_NEWTON_DIAGNOSTICS,
  OMC_LOG_NLS_DERIVATIVE_TEST,
  OMC_LOG_NLS_SVD,
  OMC_LOG_NLS_SVD_V,
  OMC_LOG_NLS_RES,
  OMC_LOG_NLS_EXTRAPOLATE,
  OMC_LOG_RES_INIT,
  OMC_LOG_RT,
  OMC_LOG_SIMULATION,
  OMC_LOG_SOLVER,
  OMC_LOG_SOLVER_V,
  OMC_LOG_SOLVER_CONTEXT,
  OMC_LOG_SOTI,
  OMC_LOG_SPATIALDISTR,
  OMC_LOG_STATS,
  OMC_LOG_STATS_V,
  OMC_LOG_SUCCESS,
  OMC_LOG_SYNCHRONOUS,
  OMC_LOG_ZEROCROSSINGS,

  OMC_SIM_LOG_MAX
};

extern const int firstOMCErrorStream;
extern const char *OMC_LOG_STREAM_NAME[OMC_SIM_LOG_MAX];
extern const char *OMC_LOG_STREAM_DESC[OMC_SIM_LOG_MAX];
extern const char *OMC_LOG_STREAM_DETAILED_DESC[OMC_SIM_LOG_MAX];

/* ──────────────────── Rust embedding entry points ─────────────────────────
 * Implemented in the cdylib (csrc/mmc_compat.c over the Rust omc_compiler_*
 * ABI). Signatures match the MMC `omc_Main_*` the stock OMEdit calls, so its
 * init/sendCommand bodies are unchanged. */
void *omc_Main_init(void *threadData, void *args);
int   omc_Main_handleCommand(void *threadData, void *imsg, void **omsg);
void  omc_System_initGarbageCollector(void *threadData);
void  omc_Main_setWindowsPaths(threadData_t *threadData, void *inOMHome);

/* ───────────── in-memory model-instance JSON walker (issue #15219) ─────────
 * Implemented in Rust (openmodelica_backend_main::ModelInstanceReference).
 * `ModelInstanceReference_get`/`_release` are declared by OMEdit itself; here we
 * add the typed walker over the boxed JSON value the handle refers to. Node
 * kinds match `OmcJsonKind`. All pointers stay valid until the handle is
 * released. */
typedef enum {
  OMC_JSON_OBJECT      = 0,
  OMC_JSON_LIST_OBJECT = 1,
  OMC_JSON_ARRAY       = 2,
  OMC_JSON_LIST        = 3,
  OMC_JSON_STRING      = 4,
  OMC_JSON_INTEGER     = 5,
  OMC_JSON_NUMBER      = 6,
  OMC_JSON_TRUE        = 7,
  OMC_JSON_FALSE       = 8,
  OMC_JSON_NULL        = 9
} OmcJsonKind;

typedef struct OmcJsonIter OmcJsonIter;

int          omc_json_kind(const void *node);
const char  *omc_json_string(const void *node, size_t *len);
int64_t      omc_json_integer(const void *node);
double       omc_json_number(const void *node);
OmcJsonIter *omc_json_iter_new(const void *node);
int          omc_json_iter_at_end(const OmcJsonIter *it);
const void  *omc_json_iter_value(const OmcJsonIter *it);
const char  *omc_json_iter_key(const OmcJsonIter *it, size_t *len);
void         omc_json_iter_advance(OmcJsonIter *it);
void         omc_json_iter_free(OmcJsonIter *it);

#ifdef __cplusplus
}
#endif

#endif /* OMC_RUST_EMBEDDING_H */
