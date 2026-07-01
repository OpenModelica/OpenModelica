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
// itself in C++; Rust only sees the 0/1 result.
//
// `ffi_cif` is opaque here on purpose: declaring `ffi_call` ourselves
// avoids needing libffi's headers at build time — the symbol resolves
// against the libffi that the `libffi-sys` crate builds and links.

extern "C" void ffi_call(void *cif, void (*fn)(), void *rvalue, void **avalue);

extern "C" int omrs_ffi_call_catch(void *cif, void (*fn)(), void *rvalue, void **avalue)
{
  try {
    ffi_call(cif, fn, rvalue, avalue);
    return 0;
  } catch (...) {
    return 1;
  }
}
