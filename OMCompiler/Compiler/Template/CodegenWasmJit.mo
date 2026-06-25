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

encapsulated package CodegenWasmJit
" Code generator target `wasm-jit`, the simulation half of the WebAssembly
  pipeline (counterpart of CodegenC for the C target).

  Lowers the SimCode equation systems to a single WebAssembly model module (the
  numerical right-hand sides) that is JIT-compiled and run in-process with
  wasmtime, integrating with a forward-Euler solver and writing the MATLAB v4
  result file. Unlike the C target, no metadata is serialized to XML/JSON: the
  host holds the SimCode-derived data in memory.

  The implementation is hand-written in Rust (openmodelica_codegen_wasm_jit);
  the declarations below exist only so the calls type-check in the MetaModelica
  sources. "

import SimCode;

function translateModel
  " Lower the model in `simCode` to a WebAssembly module written to
    <simCode.fileNamePrefix>.wasm and stash the prepared model in-process for the
    later runSimulation. Counterpart of CodegenC.translateModel for the C target.
    Implemented in Rust. "
  input SimCode.SimCode simCode;
algorithm
end translateModel;

function runSimulation
  " Run the prepared model (built by translateModel) in-process with a
    forward-Euler solver and write the result file. Returns 0 on success, 1 on
    failure (matching the exit code of the C target's executable). Implemented in
    Rust. "
  input String fileNamePrefix;
  input String resultFile;
  input String simflags;
  output Integer status;
algorithm
  status := 0;
end runSimulation;

function finishCompile
  " Force the model's wasm modules to finish JIT-compiling. Called from
    buildModel's compile phase (the wasm-jit counterpart of compiling the C
    executable) so the compile cost is attributed to timeCompile rather than
    timeSimulation. Implemented in Rust. "
  input String fileNamePrefix;
algorithm
end finishCompile;

function emitStandalone
  " The `wasm` simCodeTarget (vs in-process `wasm-jit`): lower the model and
    merge it with the wasip1 runtime into a self-contained WASI command module
    written to <simCode.fileNamePrefix>.wasm, runnable with
    `wasmtime run <prefix>.wasm --dir .::.`. Implemented in Rust. "
  input SimCode.SimCode simCode;
algorithm
end emitStandalone;

function runSimulationWasmtime
  " Run the standalone module (built by emitStandalone) in a wasmtime subprocess;
    its _start writes the result file. Returns 0 on success, 1 on failure.
    Implemented in Rust. "
  input String fileNamePrefix;
  input String resultFile;
  input String simflags;
  output Integer status;
algorithm
  status := 0;
end runSimulationWasmtime;

annotation(__OpenModelica_Interface="codegen_wasm_jit");
end CodegenWasmJit;
