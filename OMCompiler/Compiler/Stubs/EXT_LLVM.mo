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

encapsulated package EXT_LLVM

function initGen<T>
  input T t;
algorithm
  assert(false, getInstanceName());
end initGen;

function getLLVMToolsDir
  "Stub. The real EXT_LLVM lives in OMCompiler/Compiler/LLVM/EXT_LLVM.mo
   and routes to the C++ omc_getLLVMToolsDir helper compiled into omcruntime.
   When omc is built without LLVM JIT support the C side returns an empty
   string; we mirror that here without linking against the C symbol."
  output String dir = "";
end getLLVMToolsDir;

function runModelViaJIT
  "Stub. CevalScriptBackend.runModelViaLLVMJIT guards every call with a
   getLLVMToolsDir check, so this stub returning non-zero (failure) just
   tells the caller to fall back to the legacy buildModel path when the
   LLVM JIT was not compiled in."
  input String bitcodePath;
  input String runtimeLib;
  input String modelName;
  input String logFile;
  output Integer status = 1;
end runModelViaJIT;

function genReadRealVar
  "Stub. The real implementation lives in OMCompiler/Compiler/LLVM/
   EXT_LLVM.mo and inlines the DATA->localData[0]->realVars[...]
   chain via createInlinedReadRealVar in omcruntime. The stub is
   never called because SimCodeToLLVM (the only caller) is itself
   stubbed out when OPENMODELICA_LLVM_JIT is OFF."
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadRealVar;

annotation(__OpenModelica_Interface="backend");
end EXT_LLVM;
