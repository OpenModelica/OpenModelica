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
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadRealVar;

function genWriteRealVar
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genWriteRealVar;

function genReadRealParam
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadRealParam;

function genWriteRealParam
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genWriteRealParam;

function genWriteBoolParam
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genWriteBoolParam;

function genReadTime
  input String dataArgName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadTime;

function genZcSet
  input String goutArgName;
  input Integer idx;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genZcSet;

function genRelationSet
  input String dataArgName;
  input Integer idx;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genRelationSet;

function genCallExternalObjectDestructors
  input String modelName;
  output Integer status = 1;
end genCallExternalObjectDestructors;

function setLinkonceOdr
  input String fname;
  output Integer status = 1;
end setLinkonceOdr;

function genSetupDataStrucShell
  input String modelName;
  output Integer status = 1;
end genSetupDataStrucShell;

function genCallbackTable
  input String modelName;
  input Integer isFmu;
  input Integer hasNlsSystems;
  input Integer hasLsSystems;
  input Integer hasMsSystems;
  input Integer hasInitialLambda0;
  input Integer homotopyMethodCode;
  output Integer status = 1;
end genCallbackTable;

annotation(__OpenModelica_Interface="backend");
end EXT_LLVM;
