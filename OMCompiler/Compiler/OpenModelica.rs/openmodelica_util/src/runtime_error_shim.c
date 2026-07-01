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
 * Runtime error interception shim for evaluated external C functions.
 *
 * Mirror of `OpenModelica_ErrorModule_Modelica{,V}FormatError` in
 * `Compiler/runtime/errorext.cpp`: when the compiler evaluates an external C
 * function (the `-d=gen` dlopen path), a `ModelicaError` / `ModelicaFormatError`
 * call inside it must append a RUNTIME/error message to the compiler's error
 * buffer (so `getErrorString` reports it) instead of only streaming to the
 * simulation log and throwing.
 *
 * The reference compiler achieves this in `Error_registerModelicaFormatError`
 * by rebinding the runtime's `OpenModelica_Modelica{,V}FormatError` function
 * pointers. The Rust port does the same from `dynload::ensure_runtime`, but the
 * `va_list` formatting cannot be expressed in stable Rust — hence this C shim.
 *
 * `omrs_register_modelica_error` stores the runtime's original throwing
 * functions; each shim formats/forwards the message to the Rust error buffer
 * (`omrs_add_runtime_error`) and then calls the original to perform the throw
 * (`MMC_THROW` via the runtime's longjmp), exactly as the C ErrorModule path
 * adds the message and then `MMC_THROW`s.
 */
#include <stdarg.h>
#include <stdio.h>

/* Defined in Rust (ErrorExt.rs): append a RUNTIME/error message to the buffer. */
extern void omrs_add_runtime_error(const char *msg);

/*
 * Position-carrying variant, for `omc_assert` (which passes a FILE_INFO). With
 * an empty filename and zero positions it renders as `Error: <msg>`; otherwise
 * `[file:lineStart:colStart-lineEnd:colEnd:...] Error: <msg>`.
 */
extern void omrs_add_runtime_error_pos(const char *msg, const char *filename,
                                       int sline, int scol, int eline, int ecol,
                                       int read_only);

typedef void (*omrs_err_fn)(const char *);
typedef void (*omrs_verr_fn)(const char *, va_list);

static omrs_err_fn  omrs_orig_error = 0;
static omrs_verr_fn omrs_orig_vformat_error = 0;

/* Replacement for OpenModelica_ModelicaError: report, then throw. */
static void omrs_modelica_error(const char *msg) {
  omrs_add_runtime_error(msg);
  if (omrs_orig_error) {
    omrs_orig_error(msg); /* longjmp/throw — does not return */
  }
}

/* Replacement for OpenModelica_ModelicaVFormatError: format, report, throw. */
static void omrs_modelica_vformat_error(const char *fmt, va_list ap) {
  char buf[8192];
  va_list ap2;
  va_copy(ap2, ap);
  vsnprintf(buf, sizeof(buf), fmt, ap2);
  va_end(ap2);
  omrs_add_runtime_error(buf);
  if (omrs_orig_vformat_error) {
    omrs_orig_vformat_error(fmt, ap); /* longjmp/throw — does not return */
  }
}

/*
 * Install the interception. `err_slot`/`verr_slot` are the addresses of the
 * runtime's `OpenModelica_ModelicaError` / `OpenModelica_ModelicaVFormatError`
 * function-pointer variables (resolved by dlsym in dynload::ensure_runtime).
 * The originals are saved for the throw, then the slots are repointed at the
 * shims. Keeping all function-pointer typing in C avoids expressing `va_list`
 * in Rust. Idempotent only if called once; the caller guards that.
 */
void omrs_install_modelica_error(omrs_err_fn *err_slot, omrs_verr_fn *verr_slot) {
  if (err_slot) {
    omrs_orig_error = *err_slot;
    *err_slot = omrs_modelica_error;
  }
  if (verr_slot) {
    omrs_orig_vformat_error = *verr_slot;
    *verr_slot = omrs_modelica_vformat_error;
  }
}

/*
 * `omc_assert` interception — the analogue of `Error_initAssertionFunctions`,
 * which rebinds the runtime's `omc_assert` to `omc_assert_compiler`: append a
 * RUNTIME/error message (with the assertion's source position) to the buffer
 * and then throw, *without* the default `omc_assert_function`'s stderr print
 * (`[..]Modelica Assert: ..!`).
 *
 * `omrs_file_info` must match the runtime's `FILE_INFO`
 * (util/omc_error.h): a by-value second argument to `omc_assert`.
 */
typedef struct {
  const char *filename;
  int lineStart;
  int colStart;
  int lineEnd;
  int colEnd;
  int readonly;
} omrs_file_info;

typedef void (*omrs_throw_fn)(void * /*threadData*/);
typedef void (*omrs_assert_fn)(void * /*threadData*/, omrs_file_info, const char *, ...);

static omrs_throw_fn omrs_throw = 0;

/* Replacement for omc_assert: report (with position), then throw cleanly. */
static void omrs_omc_assert(void *threadData, omrs_file_info info, const char *msg, ...) {
  char buf[8192];
  va_list ap;
  va_start(ap, msg);
  vsnprintf(buf, sizeof(buf), msg, ap);
  va_end(ap);
  omrs_add_runtime_error_pos(buf, info.filename, info.lineStart, info.colStart,
                             info.lineEnd, info.colEnd, info.readonly);
  if (omrs_throw) {
    omrs_throw(threadData); /* MMC_THROW(_INTERNAL) — does not return, no print */
  }
}

/*
 * `assert_slot` is the address of the runtime's `omc_assert` function-pointer
 * variable; `throw_fn` is the runtime's `omc_throw` (its `omc_throw_function`),
 * used to throw without printing. Resolved by dlsym in dynload::ensure_runtime.
 */
void omrs_install_omc_assert(omrs_assert_fn *assert_slot, omrs_throw_fn throw_fn) {
  omrs_throw = throw_fn;
  if (assert_slot) {
    *assert_slot = omrs_omc_assert;
  }
}
