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

// C++ exception barrier for FFI.callFunction (see src/FFI.rs).
//
// The reference compiler wraps its ffi_call in `try { ... } catch (...) {
// MMC_THROW(); }` (Compiler/runtime/ffi_omc.cpp) so an external function
// that throws — e.g. the testsuite's `exception1_ext`, which does
// `throw std::runtime_error(...)` — turns into an ordinary MetaModelica
// failure. A foreign exception must never unwind through a Rust frame
// (that aborts the process), so the try/catch has to wrap the `ffi_call`
// itself in C++; Rust only sees the result.
//
// A ModelicaError in the external function ends in the C runtime's
// longjmp to the thread's jump buffer, which this thread does not have.
// For the duration of the call, the runtime's two error slots point here
// instead: the message goes to omc's error buffer, as in the reference
// compiler, and the call returns 2.
//
// `ffi_cif` is opaque here on purpose: declaring `ffi_call` ourselves
// avoids needing libffi's headers at build time — the symbol resolves
// against the libffi that the `libffi-sys` crate builds and links.

#include <csetjmp>
#include <cstdarg>
#include <cstdio>

extern "C" void ffi_call(void *cif, void (*fn)(), void *rvalue, void **avalue);
extern "C" void omrs_add_runtime_error(const char *msg);

typedef void (*omrs_err_fn)(const char *);
typedef void (*omrs_verr_fn)(const char *, va_list);

static thread_local std::jmp_buf *omrs_ffi_jump = nullptr;

static void omrs_ffi_error(const char *msg)
{
  omrs_add_runtime_error(msg);
  std::longjmp(*omrs_ffi_jump, 1);
}

static void omrs_ffi_vformat_error(const char *fmt, va_list ap)
{
  char buf[8192];
  vsnprintf(buf, sizeof(buf), fmt, ap);
  omrs_add_runtime_error(buf);
  std::longjmp(*omrs_ffi_jump, 1);
}

static int omrs_ffi_call_jump(void *cif, void (*fn)(), void *rvalue, void **avalue)
{
  std::jmp_buf jump;
  if (setjmp(jump) != 0) {
    return 2;
  }
  omrs_ffi_jump = &jump;
  try {
    ffi_call(cif, fn, rvalue, avalue);
    return 0;
  } catch (...) {
    return 1;
  }
}

extern "C" int omrs_ffi_call_catch(void *cif, void (*fn)(), void *rvalue, void **avalue,
                                   omrs_err_fn *err_slot, omrs_verr_fn *verr_slot)
{
  omrs_err_fn saved_err = err_slot ? *err_slot : nullptr;
  omrs_verr_fn saved_verr = verr_slot ? *verr_slot : nullptr;
  if (err_slot) *err_slot = omrs_ffi_error;
  if (verr_slot) *verr_slot = omrs_ffi_vformat_error;

  int status = omrs_ffi_call_jump(cif, fn, rvalue, avalue);

  omrs_ffi_jump = nullptr;
  if (err_slot) *err_slot = saved_err;
  if (verr_slot) *verr_slot = saved_verr;
  return status;
}
