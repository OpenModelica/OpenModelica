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
import Error;

function translateModel
  " Lower the model in `simCode` to a WebAssembly module written to
    <simCode.fileNamePrefix>.wasm and stash the prepared model in-process for the
    later runSimulation. Counterpart of CodegenC.translateModel for the C target.
    Implemented in Rust. "
  input SimCode.SimCode simCode;
algorithm
  Error.addInternalError("CodegenWasmJit.translateModel: the wasm-jit target is only implemented in the Rust omc build", sourceInfo());
  fail();
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
  " Force the model's wasm modules to finish JIT-compiling and resolve its
    external \"C\" implementations, building the Include C sources. Called from
    buildModel's compile phase (the wasm-jit counterpart of compiling the C
    executable) so the compile cost is attributed to timeCompile rather than
    timeSimulation. Implemented in Rust; fails if an external \"C\"
    implementation is unavailable. "
  input String fileNamePrefix;
algorithm
  Error.addInternalError("CodegenWasmJit.finishCompile: the wasm-jit target is only implemented in the Rust omc build", sourceInfo());
  fail();
end finishCompile;

function emitStandalone
  " The `wasm` simCodeTarget (vs in-process `wasm-jit`): lower the model and
    merge it with the wasip1 runtime into a self-contained WASI command module
    written to <simCode.fileNamePrefix>.wasm, runnable with
    `wasmtime run <prefix>.wasm --dir .::.`. Implemented in Rust. "
  input SimCode.SimCode simCode;
algorithm
  Error.addInternalError("CodegenWasmJit.emitStandalone: the wasm target is only implemented in the Rust omc build", sourceInfo());
  fail();
end emitStandalone;

function translateFmu
  " Lower the model in `simCode` to the WebAssembly kernel a wasm FMU is built
    around and keep it in-process, without writing an FMU: the wasm counterpart of
    the C target generating the FMU sources without building them
    (translateModelFMU). The buildModelFMU that follows links an adapter onto this
    kernel rather than translating the model a second time, and unless the model
    has external \"C\" the kernel is also registered as the prepared simulation
    model, so `simulate` runs the very module the FMU will carry. Implemented in
    Rust. "
  input SimCode.SimCode simCode;
  input String fmuType "me, cs or me_cs: a pure Co-Simulation kernel embeds a different driver";
  input String simulationFlagsJson "--fmiFlags as CodegenFMU renders it, empty when there are none";
algorithm
  Error.addInternalError("CodegenWasmJit.translateFmu: the wasm FMU target is only implemented in the Rust omc build", sourceInfo());
  fail();
end translateFmu;

function emitMeFmu
  " wasm Model-Exchange export: lower the model, link it with the
    model-agnostic ME adapter into an fmi-ls-wasm component
    (wit_component::Linker, pure Rust — no external wasm-merge), and write the
    self-contained `.fmu` ZIP (`modelDescription` + binaries/wasm32-wasip2/<id>.wasm)
    to `fmuPath`. Host-free, so it also works in the browser omc.
    `modelDescription` is CodegenFMU2's or CodegenFMU3's XML; its value references
    are resolved at run time through the vr table the emitter puts in the model's
    metadata blob. Implemented in Rust. "
  input SimCode.SimCode simCode;
  input String fmuPath;
  input String guid;
  input String modelDescription;
  input String lsDaeManifest "fmi-ls-dae's manifest for a --daeMode model, empty for none";
  input String documentationDir "directory shipped as documentation/ (index.html and the images it references); empty for none";
  input String terminalsDir "directory shipped as terminalsAndIcons/ (the XML and the rendered icons); empty for none";
  input String simulationFlagsJson "--fmiFlags as CodegenFMU renders it, empty when there are none";
algorithm
  Error.addInternalError("CodegenWasmJit.emitMeFmu: the wasm FMU target is only implemented in the Rust omc build", sourceInfo());
  fail();
end emitMeFmu;

function emitCsFmu
  " wasm Co-Simulation export: as emitMeFmu, but the component embeds the
    simulation driver (the FMU integrates itself between the importer's
    communication points). Implemented in Rust. "
  input SimCode.SimCode simCode;
  input String fmuPath;
  input String guid;
  input String modelDescription;
  input String lsDaeManifest "fmi-ls-dae's manifest for a --daeMode model, empty for none";
  input String documentationDir "directory shipped as documentation/ (index.html and the images it references); empty for none";
  input String terminalsDir "directory shipped as terminalsAndIcons/ (the XML and the rendered icons); empty for none";
  input String simulationFlagsJson "--fmiFlags as CodegenFMU renders it, empty when there are none";
algorithm
  Error.addInternalError("CodegenWasmJit.emitCsFmu: the wasm FMU target is only implemented in the Rust omc build", sourceInfo());
  fail();
end emitCsFmu;

function emitMeCsFmu
  " wasm me_cs export: one component exporting both the Model-Exchange and
    Co-Simulation interfaces (a single binary and modelIdentifier). Implemented in
    Rust. "
  input SimCode.SimCode simCode;
  input String fmuPath;
  input String guid;
  input String modelDescription;
  input String lsDaeManifest "fmi-ls-dae's manifest for a --daeMode model, empty for none";
  input String documentationDir "directory shipped as documentation/ (index.html and the images it references); empty for none";
  input String terminalsDir "directory shipped as terminalsAndIcons/ (the XML and the rendered icons); empty for none";
  input String simulationFlagsJson "--fmiFlags as CodegenFMU renders it, empty when there are none";
algorithm
  Error.addInternalError("CodegenWasmJit.emitMeCsFmu: the wasm FMU target is only implemented in the Rust omc build", sourceInfo());
  fail();
end emitMeCsFmu;

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

function fmuCsSolvers
  " The `method=` values a Co-Simulation wasm FMU can integrate with: the solvers
    the driver linked into the component carries. `buildModelFMU` folds an accepted
    method into the FMU's `resources/<prefix>_flags.json`, the only channel the
    component reads its solver from. Empty without the Rust export. Implemented in Rust. "
  output list<String> methods;
algorithm
  methods := {};
end fmuCsSolvers;

annotation(__OpenModelica_Interface="codegen_wasm_jit");
end CodegenWasmJit;
