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

encapsulated package CodegenWasmJitFunctions
" Code generator target `wasm-jit` (selected with +simCodeTarget=wasm-jit), the
  function half of the WebAssembly JIT pipeline used by -d=gen. Instead of
  generating C, building a shared object and dlopen'ing it, the functions are
  lowered to a WebAssembly module that is JIT-compiled and executed in-process.

  This package is a placeholder: the real implementation is hand-written in Rust
  (openmodelica_codegen_wasm_jit), using the `wasm-encoder` crate to emit the
  module and `wasmtime` to JIT and run it. The bodies below exist only so the
  declarations type-check in the MetaModelica sources. "

import SimCodeFunction;
import Values;

function translateFunctions
  " Lower the functions in `fnCode` to a WebAssembly module written to
    <fnCode.name>.wasm. Counterpart of CodegenCFunctions.translateFunctions for
    the C target. Implemented in Rust. "
  input SimCodeFunction.FunctionCode fnCode;
algorithm
end translateFunctions;

function loadAndExecute
  " Instantiate the module <fileName>.wasm with wasmtime, call the exported entry
    for `name`, marshalling `args` in and the result back. Counterpart of
    System.loadLibrary + DynLoad.executeFunction for the C target. Implemented in
    Rust. "
  input String fileName;
  input String name;
  input list<Values.Value> args;
  output Values.Value result = Values.NORETCALL();
algorithm
end loadAndExecute;

annotation(__OpenModelica_Interface="codegen_wasm_jit");
end CodegenWasmJitFunctions;
