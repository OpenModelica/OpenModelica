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
 * jump can return into, and `va_copy` around a double `vsnprintf`. Everything
 * else -- including the `omc_assert_*` entry points the generated code names --
 * is Rust; nothing here is exported from the library.
 *
 * Deliberately includes no OpenModelica header: the one layout it needs comes
 * from Rust as offsets (`omr_td_off_*`, filled from `offset_of!` in abi.rs, which
 * tests/abi_layout.rs checks against the real headers).
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

/* `vsnprintf` into a fresh buffer the caller frees with `omr_free`. */
char *omr_vformat(const char *msg, va_list ap) {
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

void omr_free(void *p) { free(p); }

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
