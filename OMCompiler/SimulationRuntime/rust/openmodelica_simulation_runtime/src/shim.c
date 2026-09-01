/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/* setjmp/longjmp and va_list formatting for the Rust simulation runtime.
 *
 * Two things Rust cannot express: `setjmp`, whose frame must be a C frame the
 * jump can return into, and C varargs. The `omc_assert_*` entry points are
 * therefore defined here and hand the formatted message to Rust
 * (src/support.rs); build.rs names them for the linker, since a cdylib exports
 * only the symbols Rust itself defines.
 *
 * Deliberately includes no OpenModelica header: the layouts it needs come from
 * Rust as offsets (`omr_td_off_*`, filled from `offset_of!` in abi.rs) or, for
 * `FILE_INFO`, as a copy of the mirror. tests/abi_layout.rs checks both.
 */

#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

/* Byte offsets inside threadData_t, from the Rust mirror. */
extern const size_t omr_td_off_mmc_jumper;
extern const size_t omr_td_off_global_jumper;
extern const size_t omr_td_off_sim_jumper;
extern const size_t omr_td_off_error_stage;

#define TD_PTR(td, off) (*(void **)((char *)(td) + (off)))
#define TD_INT(td, off) (*(int *)((char *)(td) + (off)))

/* Which buffer the Rust side asks us to jump to. */
enum { OMR_JMP_NONE = 0, OMR_JMP_SIMULATION = 1, OMR_JMP_GLOBAL = 2 };

/* Rust: the message no jump buffer could carry; ends the process. */
extern void omr_fatal(const char *msg);

/* Leave through one of `threadData`'s jump buffers. Does not return unless the
 * caller asked for no jump at all.
 */
void omr_jump(void *threadData, int where) {
  void *buf = NULL;
  if (!threadData) {
    omr_fatal("an assertion fired outside a model call");
    abort();
  }
  switch (where) {
    case OMR_JMP_SIMULATION: buf = TD_PTR(threadData, omr_td_off_sim_jumper); break;
    case OMR_JMP_GLOBAL:
      buf = TD_PTR(threadData, omr_td_off_global_jumper);
      if (!buf) buf = TD_PTR(threadData, omr_td_off_mmc_jumper);
      break;
    default: return;
  }
  if (!buf) {
    omr_fatal("an assertion fired with no jump buffer installed");
    abort();
  }
  longjmp(*(jmp_buf *)buf, 1);
}

/* The `stdout` the generated code and libOpenModelicaRuntimeC buffer through: a
 * macro over a differently-named object on each libc, so Rust cannot name it. */
FILE *omr_stdout(void) { return stdout; }

/* `vsnprintf` into a fresh buffer the caller frees. */
static char *omr_vformat(const char *msg, va_list ap) {
  va_list copy;
  va_copy(copy, ap);
  int n = vsnprintf(NULL, 0, msg, copy);
  va_end(copy);
  if (n < 0) return NULL;
  char *buf = (char *)malloc((size_t)n + 1);
  if (!buf) return NULL;
  vsnprintf(buf, (size_t)n + 1, msg, ap);
  return buf;
}

/* Call `f(data, threadData)` with `threadData`'s simulation jump buffer pointed
 * here, so an assertion inside the model returns control rather than unwinding
 * through Rust. Returns what `f` returned, or -1 if the jump was taken.
 */
int omr_protected_call(int (*f)(void *, void *), void *data, void *threadData, int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    rc = f(data, threadData);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* `omr_protected_call` for the entry points that take one extra argument. */
int omr_protected_call1(int (*f)(void *, void *, long), void *data, void *threadData, long arg,
                        int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    rc = f(data, threadData, arg);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* Ditto for `function_ZeroCrossings(data, threadData, double* gout)`. */
int omr_protected_call_zc(int (*f)(void *, void *, double *), void *data, void *threadData,
                          double *gout, int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    rc = f(data, threadData, gout);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* `residualFunc` under `threadData`'s simulation jump buffer. The generated
 * residual reports a violated assertion by longjmp; the nonlinear solver needs it
 * back as a rejected trial, and the jump has to land in a C frame.
 */
int omr_protected_residual(void (*f)(void *, const double *, double *, const int *), void *user,
                           const double *x, double *r, const int *flag, void *threadData,
                           int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc = 0;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    f(user, x, r, flag);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* `solveContinuousPart` / `updateIterationExps` under `threadData`'s simulation
 * jump buffer: the mixed solver's search has to survive a failed equation set the
 * way C's does, and the jump has to land in a C frame.
 */
int omr_protected_call_data(void (*f)(void *), void *data, void *threadData, int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc = 0;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    f(data);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* `residualFuncConstraints` -- a casual tearing set's residual, which returns 1
 * for a violated local constraint. `-1` still means the jump was taken. */
int omr_protected_residual_con(int (*f)(void *, const double *, double *, const int *), void *user,
                               const double *x, double *r, const int *flag, void *threadData,
                               int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc = 0;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    rc = f(user, x, r, flag);
    if (rc == -1) {
      rc = 1; /* keep -1 for "the jump was taken" */
    }
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* Run `thunk(ctx)` under `threadData`'s simulation jump buffer. Every model call
 * made from inside a Rust frame needs one: a `longjmp` past those frames would
 * skip the solver's own bookkeeping and land at whatever catch is open further
 * out, which is not where C's would land. Returns 0, or -1 if the jump was taken.
 */
int omr_protected(void (*thunk)(void *), void *ctx, void *threadData, int stage) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_sim_jumper);
  int saved_stage = TD_INT(threadData, omr_td_off_error_stage);
  int rc = 0;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_sim_jumper) = &buf;
    TD_INT(threadData, omr_td_off_error_stage) = stage;
    thunk(ctx);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_sim_jumper) = saved_jb;
  TD_INT(threadData, omr_td_off_error_stage) = saved_stage;
  return rc;
}

/* C's `MMC_TRY_INTERNAL(globalJumpBuffer)` around `_main_SimulationRuntime`: a
 * model error nothing absorbed ends the run here, as it does in C, rather than
 * unwinding to the generated `main`'s top-level catch -- which prints
 * "Execution failed!", a line C never reaches.
 */
int omr_protected_global(void (*thunk)(void *), void *ctx, void *threadData) {
  jmp_buf buf;
  void *saved_jb = TD_PTR(threadData, omr_td_off_global_jumper);
  int rc = 0;
  if (setjmp(buf) == 0) {
    TD_PTR(threadData, omr_td_off_global_jumper) = &buf;
    thunk(ctx);
  } else {
    rc = -1;
  }
  TD_PTR(threadData, omr_td_off_global_jumper) = saved_jb;
  return rc;
}

/* The `omc_assert_*` entry points, split the way C's own
 * simulation/simulation_omc_assert.c splits them. */

/* Mirrors `FILE_INFO` in src/abi.rs; the entry points take it by value. */
typedef struct {
  const char *filename;
  int lineStart;
  int colStart;
  int lineEnd;
  int colEnd;
  int readonly;
} omr_file_info;

void omr_file_info_layout(size_t *out) {
  out[0] = sizeof(omr_file_info);
  out[1] = offsetof(omr_file_info, filename);
  out[2] = offsetof(omr_file_info, lineStart);
  out[3] = offsetof(omr_file_info, colStart);
  out[4] = offsetof(omr_file_info, lineEnd);
  out[5] = offsetof(omr_file_info, colEnd);
  out[6] = offsetof(omr_file_info, readonly);
}

/* Rust: report the message, and -- for an assertion -- which buffer to jump to. */
extern int omr_assert_report(void *threadData, const omr_file_info *info, const char *text);
extern void omr_assert_warning_report(const omr_file_info *info, const char *text);
extern void omr_terminate_report(const omr_file_info *info, const char *text);

#ifdef _WIN32
#define OMR_EXPORT __declspec(dllexport)
#else
#define OMR_EXPORT
#endif

static void omr_va_assert(void *threadData, const omr_file_info *info, const char *msg, va_list ap) {
  char *text = omr_vformat(msg, ap);
  int target = omr_assert_report(threadData, info, text ? text : msg);
  free(text);
  omr_jump(threadData, target);
}

static void omr_va_assert_warning(const omr_file_info *info, const char *msg, va_list ap) {
  char *text = omr_vformat(msg, ap);
  omr_assert_warning_report(info, text ? text : msg);
  free(text);
}

OMR_EXPORT void omc_assert_simulation(void *threadData, omr_file_info info, const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  omr_va_assert(threadData, &info, msg, ap);
  va_end(ap);
  abort(); /* omr_jump does not return; silences the noreturn warning */
}

OMR_EXPORT void omc_assert_simulation_withEquationIndexes(void *threadData, omr_file_info info,
                                                          const int *indexes, const char *msg, ...) {
  va_list ap;
  (void)indexes;
  va_start(ap, msg);
  omr_va_assert(threadData, &info, msg, ap);
  va_end(ap);
  abort();
}

OMR_EXPORT void omc_assert_warning_simulation(omr_file_info info, const char *msg, ...) {
  va_list ap;
  va_start(ap, msg);
  omr_va_assert_warning(&info, msg, ap);
  va_end(ap);
}

OMR_EXPORT void omc_assert_warning_simulation_withEquationIndexes(omr_file_info info,
                                                                  const int *indexes,
                                                                  const char *msg, ...) {
  va_list ap;
  (void)indexes;
  va_start(ap, msg);
  omr_va_assert_warning(&info, msg, ap);
  va_end(ap);
}

OMR_EXPORT void omc_terminate_simulation(omr_file_info info, const char *msg, ...) {
  va_list ap;
  char *text;
  va_start(ap, msg);
  text = omr_vformat(msg, ap);
  va_end(ap);
  omr_terminate_report(&info, text ? text : msg);
  free(text);
}
