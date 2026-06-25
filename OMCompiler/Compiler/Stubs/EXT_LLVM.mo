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

function genSelectReal
  input String condName;
  input String thenName;
  input String elseName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genSelectReal;

function genReadRealVarPre
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadRealVarPre;

function genReadBoolVarPre
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadBoolVarPre;

function genSelectBool
  input String condName;
  input String thenName;
  input String elseName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genSelectBool;

function genBoolFcmp
  input String aName;
  input String bName;
  input String dstName;
  input Integer opCode;
algorithm
  assert(false, getInstanceName());
end genBoolFcmp;

function genSetNeedToIterate
  input String dataArgName;
  input String condName;
algorithm
  assert(false, getInstanceName());
end genSetNeedToIterate;

function genSetNeedToIterateZero
  input String dataArgName;
algorithm
  assert(false, getInstanceName());
end genSetNeedToIterateZero;

function genSetDiscreteCall
  input String dataArgName;
  input Integer value;
algorithm
  assert(false, getInstanceName());
end genSetDiscreteCall;

function genDelay
  input String dataArgName;
  input String threadDataArgName;
  input Integer exprNumber;
  input String valName;
  input String dtName;
  input String dmaxName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genDelay;

function genSolveNonlinearN
  input String dataArgName;
  input String threadDataArgName;
  input Integer sysIndex;
  input list<Integer> varSlots;
  input String arrName;
algorithm
  assert(false, getInstanceName());
end genSolveNonlinearN;

function genSolveLinearN
  input String dataArgName;
  input String threadDataArgName;
  input Integer sysIndex;
  input list<Integer> varSlots;
  input String arrName;
algorithm
  assert(false, getInstanceName());
end genSolveLinearN;

function genReadIntVar
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadIntVar;

function genReadIntVarPre
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadIntVarPre;

function genStoreIntVar
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genStoreIntVar;

function genReadIntParamReal
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadIntParamReal;

function genReadIntParam
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadIntParam;

function genWriteIntParam
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genWriteIntParam;

function genIntConst
  input Integer value;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genIntConst;

function genIntBinop
  input String aName;
  input String bName;
  input String dstName;
  input Integer opCode;
algorithm
  assert(false, getInstanceName());
end genIntBinop;

function genSelectInt
  input String condName;
  input String thenName;
  input String elseName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genSelectInt;

function functionDefined
  input String fname;
  output Boolean defined = false;
end functionDefined;

function genReadBoolVar
  input String dataArgName;
  input Integer slot;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genReadBoolVar;

function genStoreBoolVar
  input String dataArgName;
  input Integer slot;
  input String srcName;
algorithm
  assert(false, getInstanceName());
end genStoreBoolVar;

function genBoolConst
  input Integer value;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genBoolConst;

function genRelationHysteresisBool
  input String dataArgName;
  input String dstName;
  input String exp1Name;
  input String exp2Name;
  input Real nom1;
  input Real nom2;
  input Integer zcIndex;
  input Integer opCode;
algorithm
  assert(false, getInstanceName());
end genRelationHysteresisBool;

function genZcValue
  input String dataArgName;
  input String dstName;
  input String exp1Name;
  input String exp2Name;
  input Real nom1;
  input Real nom2;
  input Integer zcIndex;
  input Integer opCode;
algorithm
  assert(false, getInstanceName());
end genZcValue;

function genBoolBinop
  input String aName;
  input String bName;
  input String dstName;
  input Integer isOr;
algorithm
  assert(false, getInstanceName());
end genBoolBinop;

function genBoolNot
  input String aName;
  input String dstName;
algorithm
  assert(false, getInstanceName());
end genBoolNot;

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

function genSetupDataStrucFull
  input String modelName;
  input list<Integer> counters;
  output Integer status = 1;
end genSetupDataStrucFull;

function genMainShim
  input String modelName;
  output Integer status = 1;
end genMainShim;

function genCallbackTable
  input String modelName;
  input Integer isFmu;
  input Integer hasNlsSystems;
  input Integer hasLsSystems;
  input Integer hasMsSystems;
  input Integer hasInitialLambda0;
  input Integer homotopyMethodCode;
  input Integer idxJacA;
  input Integer idxJacADJ;
  input Integer idxJacB;
  input Integer idxJacC;
  input Integer idxJacD;
  input Integer idxJacF;
  input Integer idxJacH;
  output Integer status = 1;
end genCallbackTable;

annotation(__OpenModelica_Interface="backend");
end EXT_LLVM;
