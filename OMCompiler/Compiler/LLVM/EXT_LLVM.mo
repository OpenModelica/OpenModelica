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

/* Wrappers to external C functions */
encapsulated package EXT_LLVM
" file:        EXT_LLVM.mo
  package:     EXT_LLVM
  description: External functions to call the C/C++ functions present in llvm_gen.cpp these functions
               in turn calls the LLVM C++ API for LLVM IR generation.
  author: John Tinnerholm
"
import Values;

/*Calls for steering function generation */
function initGen
  input String name;
  external "C" initGen(name) annotation(Library = "omcruntime");
end initGen;

function setOptSettings
  input Boolean optimise;
  external "C" setOptSettings(optimise) annotation(Library = "omcruntime");
end setOptSettings;

function startFuncGen
  "Start generating a single function, called when generation of a new function begins."
  input String name;
  external "C" startFuncGen(name) annotation(Library = "omcruntime");
end startFuncGen;

function finnishGen
  external "C" finishGen() annotation(Library = "omcruntime");
end finnishGen;

function runJIT
  "Runs the compiled IR returns a Values.Value"
  input list<Values.Value> inArgs;
  output Values.Value val "The value that the JIT calculated.";
  external val=runJIT(inArgs) annotation(Library = "omcruntime",Include = "void *runJIT(void*);");
end runJIT;

function jitCompile
  "Compiles the generated IR"
  external "C" jitCompile() annotation(Library = "omcruntime");
end jitCompile;

function jitFinalizeNoEntry
  "Phase 5: materialize the current module and confirm fName resolves.
   Returns 0 on success, non-zero otherwise. Does not invoke fName."
  input String fName;
  output Integer status;
  external "C" status = jitFinalizeNoEntry(fName) annotation(Library = "omcruntime");
end jitFinalizeNoEntry;

function jitInvokeFunctionODE
  "Phase 6: call a JIT-compiled <Model>_functionODE against a
   fabricated DATA*. realVarsIn is the flat scalar realVars buffer
   in the absolute-slot layout used by SimCodeToLLVM. Returns the
   updated buffer, or an empty list on failure."
  input String fName;
  input Integer nStates;
  input Integer nAlgs;
  input Integer nParams;
  input list<Real> realVarsIn;
  output list<Real> realVarsOut;
  external "C" realVarsOut = jitInvokeFunctionODE_mm(fName, nStates, nAlgs, nParams, realVarsIn)
    annotation(Library = "omcruntime");
end jitInvokeFunctionODE;


/*End of calls steering function generation*/

/* Calls related to functions */
function genFunctionArg
  "Generates the parameters for each call when called. These calls are placed in a vector.
  The vector is cleared when a new function shall be generated."
  input Integer ty;
  input String name;
  external "C" createFunctionProtArg(ty,name) annotation(Library = "omcruntime");
end genFunctionArg;

function genCallArg
  "Prepairs the call vector before the call is taking place, should be called once for each parameter."
  input String name;
  external "C" createCallArg(name) annotation(Library = "omcruntime");
end genCallArg;

function genCallArgConstInt
  input Integer I;
  external "C" createCallArgConstInt(I) annotation(Library = "omcruntime", Include = "int createCallArgConstInt(const int64_t src);");
end genCallArgConstInt;

function genReadRealVar
  "Inline  data->localData[0]->realVars[slot]  read into dstName.
   See createInlinedReadRealVar in omcruntime."
  input String dataArgName;
  input Integer slot;
  input String dstName;
  external "C" createInlinedReadRealVar(dataArgName, slot, dstName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedReadRealVar(const char *dataArgName, const int64_t slot, const char *dstName);");
end genReadRealVar;

function genWriteRealVar
  "Inline  data->localData[0]->realVars[slot] = <src>  store. src is
   the symtab name of the double alloca holding the value."
  input String dataArgName;
  input Integer slot;
  input String srcName;
  external "C" createInlinedWriteRealVar(dataArgName, slot, srcName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedWriteRealVar(const char *dataArgName, const int64_t slot, const char *srcName);");
end genWriteRealVar;

function genReadRealParam
  "Inline  data->simulationInfo->realParameter[slot]  read."
  input String dataArgName;
  input Integer slot;
  input String dstName;
  external "C" createInlinedReadRealParam(dataArgName, slot, dstName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedReadRealParam(const char *dataArgName, const int64_t slot, const char *dstName);");
end genReadRealParam;

function genWriteRealParam
  "Inline  data->simulationInfo->realParameter[slot] = <src>  store."
  input String dataArgName;
  input Integer slot;
  input String srcName;
  external "C" createInlinedWriteRealParam(dataArgName, slot, srcName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedWriteRealParam(const char *dataArgName, const int64_t slot, const char *srcName);");
end genWriteRealParam;

function genWriteBoolParam
  "Inline  data->simulationInfo->booleanParameter[slot] = <src>  store.
   modelica_boolean is a 32-bit int (openmodelica_types.h)."
  input String dataArgName;
  input Integer slot;
  input String srcName;
  external "C" createInlinedWriteBoolParam(dataArgName, slot, srcName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedWriteBoolParam(const char *dataArgName, const int64_t slot, const char *srcName);");
end genWriteBoolParam;

function genReadTime
  "Inline  data->localData[0]->timeValue  read into dstName."
  input String dataArgName;
  input String dstName;
  external "C" createInlinedReadTime(dataArgName, dstName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedReadTime(const char *dataArgName, const char *dstName);");
end genReadTime;

function genZcSet
  "Inline  gout[idx] = <src>  for the zero-crossings buffer
   argument. goutArgName is the symtab name of the gout function
   argument (typically \"gout\")."
  input String goutArgName;
  input Integer idx;
  input String srcName;
  external "C" createInlinedZcSet(goutArgName, idx, srcName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedZcSet(const char *goutArgName, const int64_t idx, const char *srcName);");
end genZcSet;

function genRelationSet
  "Inline  data->simulationInfo->relations[idx] = (src > 0.0) ? 1 : 0
   for updateRelations bodies. modelica_boolean is the C runtime's
   32-bit int."
  input String dataArgName;
  input Integer idx;
  input String srcName;
  external "C" createInlinedRelationSet(dataArgName, idx, srcName)
    annotation(Library = "omcruntime",
               Include = "int createInlinedRelationSet(const char *dataArgName, const int64_t idx, const char *srcName);");
end genRelationSet;

function genCallbackTable
  "Emit the <Model>_callback global into the active module as a packed,
   byte-padded constant struct matching openmodelica_func.h's
   OpenModelicaGeneratedFunctionCallbacks layout. Linkage is linkonce_odr
   so the IR coexists with CodegenC's strong copy until <Model>.c gets
   suppressed. The flags follow the conditionals woven into the C
   template's initializer: isFmu zeroes the simulation-driving entries
   (FMUs supply their own driver); hasNls / hasLs / hasMs gate the
   matching initial<Sys>System pointers; hasInitialLambda0 gates the
   functionInitialEquations_lambda0 slot; homotopyMethodCode is the
   HOMOTOPY_METHOD enum value to bake in."
  input String modelName;
  input Integer isFmu;
  input Integer hasNlsSystems;
  input Integer hasLsSystems;
  input Integer hasMsSystems;
  input Integer hasInitialLambda0;
  input Integer homotopyMethodCode;
  output Integer status;
  external "C" status = createCallbackTable(modelName, isFmu, hasNlsSystems, hasLsSystems, hasMsSystems, hasInitialLambda0, homotopyMethodCode)
    annotation(Library = "omcruntime",
               Include = "int createCallbackTable(const char *modelName, int isFmu, int hasNlsSystems, int hasLsSystems, int hasMsSystems, int hasInitialLambda0, int homotopyMethodCode);");
end genCallbackTable;

function genSetupDataStrucFull
  "Emit the full <Model>_setupDataStruc body: the two pointer wires
   from the shell variant plus the canonical sequence of MODEL_DATA
   integer counter stores. `counters` carries the per-model n<X>
   values in the order declared by omc_modeldata_int_offsets[] in
   llvm_gen_layout.c -- emitSetupDataStrucBlock builds the list in
   exactly that order. Returns 0 on success, non-zero on length
   mismatch / duplicate / missing module."
  input String modelName;
  input list<Integer> counters;
  output Integer status;
  external "C" status = createSetupDataStrucFull(modelName, counters)
    annotation(Library = "omcruntime",
               Include = "int createSetupDataStrucFull(const char *modelName, void *counters);");
end genSetupDataStrucFull;

function genSetupDataStrucShell
  "Emit a linkonce_odr  <Model>_setupDataStruc(DATA*, threadData_t*)
   wiring just  threadData->localRoots[SIMULATION_DATA] = data  and
   data->callback = &<Model>_callback. The remaining modelData scalar
   / string stores stay with CodegenC until the full setupDataStruc
   lift lands; with linkonce_odr the CodegenC strong copy wins at
   llvm-link today regardless. Returns 0 on success."
  input String modelName;
  output Integer status;
  external "C" status = createSetupDataStrucShell(modelName)
    annotation(Library = "omcruntime",
               Include = "int createSetupDataStrucShell(const char *modelName);");
end genSetupDataStrucShell;

function genMainShim
  "Emit  int main(int argc, char **argv)  whose body alloca's
   MODEL_DATA + SIMULATION_INFO on the stack, materialises the four
   model-identifier strings (modelName, prefix, GUID, _info.json
   path) as private IR globals, and tail-calls omc_jit_main_runtime
   in the libomcruntime adapter. modelGuid is the SerializeInitXML
   guid the CodegenC setupDataStruc would have written; passing it in
   keeps the SCTL bitcode parallel to the C-driver bitcode for the
   same build. Returns 0 on success."
  input String modelName;
  input String modelGuid;
  output Integer status;
  external "C" status = createMainShim(modelName, modelGuid)
    annotation(Library = "omcruntime",
               Include = "int createMainShim(const char *modelName, const char *modelGuid);");
end genMainShim;

function setLinkonceOdr
  "Flip a function's linkage in the active module to linkonce_odr.
   Used after emitStub to mark stubs in <Model>.c that intentionally
   coexist with the CodegenC-emitted strong version of the same
   symbol: llvm-link picks one definition, both are ODR-equivalent,
   no duplicate-symbol error. Position the IR for the day CodegenC
   stops emitting these stubs."
  input String fname;
  output Integer status;
  external "C" status = setFunctionLinkonceOdr(fname)
    annotation(Library = "omcruntime",
               Include = "int setFunctionLinkonceOdr(const char *fname);");
end setLinkonceOdr;

function genCallExternalObjectDestructors
  "Emit the whole  <Model>_callExternalObjectDestructors  function into
   the active module as one IR function (signature + body). The body
   matches CodegenC's no-extObj-vars shape:

       if (data->simulationInfo->extObjs) {
         free(data->simulationInfo->extObjs);
         data->simulationInfo->extObjs = NULL;
       }

   Self-contained: does not interact with the partial-function IRBuilder
   used by startFuncGen/genFunctionArg/..., so SCTL just calls it once
   and the catalog mechanism displaces _01exo.c. Modelica-side caller
   must restrict use to models with extObjInfo.vars == {} (HelloWorld
   today). Returns 0 on success."
  input String modelName;
  output Integer status;
  external "C" status = createCallExternalObjectDestructors(modelName)
    annotation(Library = "omcruntime",
               Include = "int createCallExternalObjectDestructors(const char *modelName);");
end genCallExternalObjectDestructors;

function genCallArgMmcJumpr
  "Fetches the mmc_jmpr from threadData & adds it to the arg vector."
  external "C" createCallArgMmcJmpr() annotation(Library="omcruntime");
end genCallArgMmcJumpr;


function genCallArgAddr
  "Functions as genCallArg, however, passes the address of the argument.
  Used to call special functions in the OMC runtime."
  input String name;
  external "C" createCallArgAddr(name) annotation(Library = "omcruntime");
end genCallArgAddr;

function addThreadData_t
  "Adds a thread_data t argument to a prototype function"
  input Integer ty;
  input String name;
  external "C" createFunctionProtArg(ty,name) annotation(Library = "omcruntime");
end addThreadData_t;

function storeThreadData_t
  "Stores the thread data which is fetched from the OMC itself"
  external "C" storeThreadData_t(OpenModelica.threadData(), "threadData");
end storeThreadData_t;

function addTypeDescription
  "Adds a type_description t argument to a prototype function"
  input Integer ty;
  input String name;
  external "C" createFunctionProtArg(ty,name) annotation(Library = "omcruntime");
end addTypeDescription;

function genFunctionType
  "Set the function type for the function that is currently generated
   Arguments must first be generated before this function is called.
   Otherwise the function prototype will contain zero elements."
  input Integer ty;
  input String structName ="";
  external "C" createFunctionType(ty,structName) annotation(Library = "omcruntime");
end genFunctionType;

function genFunctionPrototype
  "Generates the function prototype, e.g a signature in the active LLVM module."
  input String name;
  external "C" createFunctionPrototype(name) annotation(Library = "omcruntime");
end genFunctionPrototype;

function genFunctionBody
  "Creates the body for the function in memory.
  The IR builder can insert instructions into the function after a call to this function has been made."
  input String name;
  external "C" createFunctionBody(name) annotation(Library = "omcruntime");
end genFunctionBody;

function genCall
  input String name "The name of the function.";
  input Integer functionTy "The type of the function.";
  input String dest "The destination variable for the call.";
  input Boolean assignment "If the function call shall result in an assignment or not.";
  input Boolean isVariadic = false "Is the call variadic or not, some external functions are. Default value is false.";
  external "C" createCall(name,functionTy,dest,assignment,isVariadic) annotation(Library ="omcruntime");
end genCall;

function genLongJmp
  external "C" createLongJmp() annotation (Library="omcruntime");
end genLongJmp;

/*Calls related to the construction and maintenance of basic blocks. */
function setNewActiveBlock
  "Sets the current block we are inserting to.
  If no block with the specified identifier is present a new one is created. "
  input Integer id "Id of the basic block to be constructed";
  external "C" setNewActiveBlock(id) annotation(Library = "omcruntime");
end setNewActiveBlock;

function genGoto
  "Generates a goto to a basic block with the specified id."
  input Integer id;
  external "C" createGoto(id) annotation(Library = "omcruntime");
end genGoto;

function genBranch
  "Generate a LLVM branch instruction"
  input String condition;
  input Integer onTrue;
  input Integer onFalse;
  external "C" createBranch(condition,onTrue,onFalse);
end genBranch;

function genSwitch
  "Generates an LLVM switch instruction."
  input String conditionVar;
  input Integer numCases;
  external "C" createSwitch(conditionVar,numCases) annotation(Library = "omcruntime");
end genSwitch;

function addCaseToSwitch
  "Adds a switch statement to the switch instruction that is currently created"
  input Integer onVal "The value for on which we switch.";
  input Integer dest "To BB ID";
  external "C" addCaseToSwitch(onVal,dest) annotation(Library = "omcruntime");
end addCaseToSwitch;

function genReturn
  input String retVar "The variable the function returns.";
  external "C" createReturn(retVar) annotation(Library = "omcruntime");
end genReturn;

function genReturnZero
  "Special function. Creates a ret instruction that returns 0."
  external "C" createReturnZero() annotation(Library = "omcruntime");
end genReturnZero;

function genReturnNullPtr
  "Emit `ret ptr null` for a function whose declared return type is a
   pointer (the pointer counterpart of genReturnZero). The pointer
   type is inferred from the current function so the IR matches the
   declared signature."
  external "C" createReturnNullPtr() annotation(Library = "omcruntime");
end genReturnNullPtr;

function genReturnVoid
  "Creates a simple void instruction."
  external "C" createReturnVoid() annotation(Library="omcruntime");
end genReturnVoid;

function genExit
  "Generates a exit basic block."
  input Integer exitId;
  external "C" createExit(exitId) annotation(Library = "omcruntime");
end genExit;

function genNop
  algorithm
  print("WHAT IS THE POINT GENERATING A NOP?\n");
end genNop;

/*End of calls related to basic blocks.*/

/*External calls for generating unary operators */
function genIUminus
  "Generates a unary minus for Integers."
  input String src;
  input String dest;
  external "C" createIUminus(src,dest) annotation(Library = "omcruntime");
end genIUminus;

function genRUminus
  "Generates a unary minus for Reals."
  input String src;
  input String dest;
  external "C" createDUminus(src,dest) annotation(Library = "omcruntime");
end genRUminus;

function genNot
  "Generates a not for booleans."
  input String src;
  input String dest;
  external "C" createNot(src,dest) annotation(Library = "omcruntime");
end genNot;

function genModelicaIntToModelicaReal
  input String src;
  input String dest;
  external "C" createIntToDouble(src,dest) annotation(Library = "omcruntime");
end genModelicaIntToModelicaReal;

function genModelicaRealToModelicaInt
  input String src;
  input String dest;
  external "C" createDoubleToInt(src,dest) annotation(Library = "omcruntime");
end genModelicaRealToModelicaInt;

function genModelicaIntToModelicaBoolean
  input String src;
  input String dest;
  external "C" createIntToBool(src,dest) annotation(Library = "omcruntime");
end genModelicaIntToModelicaBoolean;

function genModelicaBooleanToModelicaInt
  input String src;
  input String dest;
  external "C" createBoolToInt(src,dest) annotation(Library = "omcruntime");
end genModelicaBooleanToModelicaInt;

function genModelicaIntToModelicaMeta
  input String src;
  input String dest;
  external "C" createIntToMeta(src,dest) annotation(Library = "omcruntime");
end genModelicaIntToModelicaMeta;

function genModelicaMetaToModelicaInt
  input String src;
  input String dest;
  external "C" createMetaToInt(src,dest) annotation(Library = "omcruntime");
end genModelicaMetaToModelicaInt;

function genModelicaRealToModelicaBoolean
  input String src;
  input String dest;
  external "C" createDoubleToBool(src,dest) annotation(Library = "omcruntime");
end genModelicaRealToModelicaBoolean;

function genModelicaBooleanToModelicaReal
  input String src;
  input String dest;
  external "C" createBoolToDouble(src,dest) annotation(Library = "omcruntime");
end genModelicaBooleanToModelicaReal;

function genModelicaRealToModelicaMeta
  input String src;
  input String dest;
  external "C" createDoubleToMeta(src,dest) annotation(Library = "omcruntime");
end genModelicaRealToModelicaMeta;

function genModelicaMetaToModelicaReal
  input String src;
  input String dest;
  external "C" createMetaToDouble(src,dest) annotation(Library = "omcruntime");
end genModelicaMetaToModelicaReal;

/*End of unary operations. */

/*External calls for generating binary operators. */
function genPow
  input String lhs;
  input String rhs;
  input String dest;
  external "C" createPow(lhs,rhs,dest) annotation(Library="omcruntime");
end genPow;

/*Binary operations related to integers*/
function genIAdd
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIAdd(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIAdd;

function genISub
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createISub(lhs,rhs,dest) annotation(Library = "omcruntime");
end genISub;

function genIMul
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIMul(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIMul;

function genIDiv
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIDiv(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIDiv;

function genILess
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createILess(lhs,rhs,dest) annotation(Library = "omcruntime");
end genILess;

function genILessEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createILessEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genILessEq;

function genIGreater
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIGreater(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIGreater;

function genIGreaterEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIGreaterEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIGreaterEq;

function genIEqual
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createIEqual(lhs,rhs,dest) annotation(Library = "omcruntime");
end genIEqual;

function genINequal
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createINequal(lhs,rhs,dest) annotation(Library = "omcruntime");
end genINequal;

/*Binary operations for booleans*/
function genBLess
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBLess(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBLess;

function genBLessEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBLessEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBLessEq;

function genBGreater
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBGreater(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBGreater;

function genBGreaterEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBGreaterEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBGreaterEq;

function genBEqual
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBEqual(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBEqual;

function genBNequal
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createBNequal(lhs,rhs,dest) annotation(Library = "omcruntime");
end genBNequal;

/*Binary operations related to reals*/
function genRAdd
  "Creates an add instruction"
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDAdd(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRAdd;

function genRSub
  "Creates a fsub instruction"
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDSub(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRSub;

function genRMul
  "Creates a fmul instruction"
  input String dest "Destination variable.";
  input String lhs "left operand.";
  input String rhs "right operand.";
  external "C" createDMul(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRMul;

function genRDiv
  input String dest "Desination variable.";
  input String lhs "left operand";
  input String rhs "right operand";
  external "C" createDDiv(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRDiv;

function genRLess
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDLess(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRLess;

function genRLessEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDLessEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRLessEq;

function genRGreater
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDGreater(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRGreater;

function genRGreaterEq
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDGreaterEq(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRGreaterEq;

function genREqual
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDEqual(lhs,rhs,dest) annotation(Library = "omcruntime");
end genREqual;

function genRNequal
  input String dest;
  input String lhs;
  input String rhs;
  external "C" createDNequal(lhs,rhs,dest) annotation(Library = "omcruntime");
end genRNequal;

/*Alloca calls, used for local declarations */

function genAllocaModelicaInt
  input String name;
  input Boolean isVolatile;
  external "C" allocaInt(name, isVolatile) annotation(Library = "omcruntime");
end genAllocaModelicaInt;

function genAllocaModelicaBool
  input String name;
  input Boolean isVolatile;
  external "C" allocaBoolean(name, isVolatile) annotation(Library = "omcruntime");
end genAllocaModelicaBool;

function genAllocaModelicaReal
  input String name;
  input Boolean isVolatile;
  external "C" allocaDouble(name,isVolatile) annotation(Library = "omcruntime");
end genAllocaModelicaReal;

function genAllocaModelicaMetaTy
  input String name;
  external "C" allocaInt8PtrTy(name) annotation(Library = "omcruntime");
end genAllocaModelicaMetaTy;

function genAllocaModelicaMetaTyPtr
  input String name;
  external "C" allocaInt8PtrPtrTy(name) annotation(Library = "omcruntime");
end genAllocaModelicaMetaTyPtr;

/*Store instructions */
function genStoreVarInst
  input String src;
  input String dest;
  external "C" createStoreVarInst(src,dest) annotation(Library = "omcruntime");
end genStoreVarInst;

function genStoreToPTR
  input String src;
  input String dest;
  external "C" createStoreToPtr(src,dest) annotation(Library = "omcruntime");
end genStoreToPTR;

function genStoreLiteralInt
  input Integer src;
  input String dest;
  external "C" storeLiteralInt(src,dest) annotation(Library = "omcruntime", Include = "int storeLiteralInt(int64_t src, const char *dest);");
end genStoreLiteralInt;

function genStoreLiteralReal
  input Real src;
  input String dest;
  external "C" storeLiteralReal(src,dest) annotation(Library = "omcruntime" ,Include = "int storeLiteralReal(double src, const char *dest);");
end genStoreLiteralReal;

function genStoreLiteralBoolean
  input Boolean src;
  input String dest;
  external "C" storeLiteralBoolean(src,dest) annotation(Library = "omcruntime");
end genStoreLiteralBoolean;

function genStoreFromMmcJumpr
  "Write the content of mmc_jumpr field in the threadData struct to dest."
  input String dest;
  external "C" createStoreFromMmcJumpr(dest) annotation(Library="omcruntime");
end genStoreFromMmcJumpr;

/*Load instructions */
function genLoad
  input String src;
  external "C" createLoadInst(src) annotation(Library = "omcruntime");
end genLoad;

/* List and tuple related */
function genMmcCons
  input String valueVar;
  external "C" createMmcCons(valueVar) annotation(Library="omcruntime");
end genMmcCons;

function genLst
  "Generates mmc list with name varname"
  input String lstName "The name of the list";
  external "C" createLst(lstName) annotation(Library="omcruntime");
end genLst;

function startGenLst
  external "C" startGenLst() annotation(Library="omcruntime");
end startGenLst;

function createStructElement
  input Integer ty "Type of the struct element";
  external "C" createStructElement(ty) annotation(Library="omcruntime");
end createStructElement;

function createStructSignature
  input String name;
  external "C" createStructSignature(name) annotation(Library="omcruntime");
end createStructSignature;

function createStruct
  input String name;
  external "C" createStruct(name) annotation(Library="omcruntime");
end createStruct;

/*
   LLVM arrays (These arrays represent basic arrays in the C-runtime).
   They should only be used to generate declarations or signatures if needed.
*/

function genCStrArray
  "Generates a char * arr [fields] array"
  input String name;
  input Integer fields;
  external "C" createCStrArray(name,fields) annotation(Library="omcruntime");
end genCStrArray;

function genGvarCStr
  "Generates a global C style string array"
  input String name;
  external "C" createGVarCStr(name) annotation(Library="omcruntime");
end genGvarCStr;

function addToLLVMStrArray
  "Not implemented"
  input String elem;
  external "C" addToLLVMStrArray(elem) annotation(Library="omcruntime");
end addToLLVMStrArray;

function assignIntArr //For some reason templates could not be used...
  "TODO:Not implemented"
  input Integer[:] inArr;
  input String dest;
end assignIntArr;

function assignRealArr //For some reason templates could not be used...
  "TODO:Not implemented"
  input Real[:] inArr;
  input String dest;
end assignRealArr;

function genGlobalStructFieldConstant
  "Fills a vector of llvm::Constant*. These variables must be created
  before invoing this function."
  input String name;
  external "C" createGlobalStructFieldConstant(name) annotation(Library="omcruntime");
end genGlobalStructFieldConstant;

function genGlobalStructConstant
  "Creates a struct, with the fields specified by the calls to genGlobalStructFieldConstant."
  input String structName;
  input String name "Name of the struct variable";
  external "C" createGlobalStructConstant(structName,name) annotation(Library="omcruntime");
end genGlobalStructConstant;

function storeValToStruct
    input String varName;
  input String structName;
  input Integer idx0;
    input Integer idx1;
  external "C" createStoreToStruct(varName,structName,idx0,idx1) annotation(Library="omcruntime");
end storeValToStruct;

function storeValFromStruct
  input String varName;
  input String structName;
  input Integer idx0 "First index in an LLVM GEP Instruction";
  input Integer idx1 "Second index in an LLVM GEP Instruction";
  external "C" createStoreFromStruct(varName,structName,idx0,idx1) annotation(Library="omcruntime");
end storeValFromStruct;

function getDoubleFromPtr
  "Index a pointer variable with idx0 get a real at that posistion."
  input String src;
  input String dest;
  input Integer idx0 "Index for LLVM GEP instruction";
  external "C" createGetDoubleFromPtr(src,dest,idx0) annotation(Library="omcruntime");
end getDoubleFromPtr;

function storeDoubleToPtr
  "Index a pointer variable with idx0 and idx0, store a double at that posistion."
  input Real src;
  input String dest;
  input Integer idx0 "Index for LLVM GEP instruction";
  external "C" createStoreDoubleToPtr(src,dest,idx0) annotation(Library="omcruntime");
end storeDoubleToPtr;

function storeDVarToPtr
  "Index a pointer variable with idx0 and idx0, store a double at that posistion."
  input String src;
  input String dest;
  input Integer idx0 "Index for LLVM GEP instruction";
  external "C" createStoreDVarToPtr(src,dest,idx0) annotation(Library="omcruntime");
end storeDVarToPtr;

function genStringConstant
  "Creates a string constant and store it at dest."
  input String str;
  input String dest;
  external "C" createStringConstant(str,dest);
end genStringConstant;

/*Utility*/
function dumpIR
  "Dumps generated LLVM IR to the terminal window"
  external "C" dumpIR() annotation(Library = "omcruntime");
end dumpIR;

function writeBitcodeToFile
  "Serialise the current in-memory LLVM module to <path> as bitcode.
   Used while SimCodeToLLVM is growing so the partial in-memory module
   can be inspected (llvm-dis) and, in this transition window, merged
   with clang-emitted bitcode by llvm-link. Returns 0 on success."
  input String path;
  output Integer status;
  external "C" status = writeBitcodeToFile(path) annotation(Library = "omcruntime");
end writeBitcodeToFile;

function stashCurrentModuleAsBitcode
  "Move the current in-memory module's bitcode bytes into a
   process-global buffer that omc_runModelViaJIT consumes via
   parseBitcode + addIRModule before processing its file argument.
   This is the in-memory replacement for the <prefix>_sctl.bc disk
   hop used during the SimCodeToLLVM transition. Returns 0 on
   success."
  output Integer status;
  external "C" status = stashCurrentModuleAsBitcode() annotation(Library = "omcruntime");
end stashCurrentModuleAsBitcode;

function funcIsJitCompiled
  input String fName;
  output Boolean isJitCompiled;
  external "C" isJitCompiled = fIsJitCompiled(fName) annotation(Library="omcruntime");
end funcIsJitCompiled;

/* Model simulation via LLVM JIT (see -d=jitSimulate). */

function getLLVMToolsDir
  "Absolute path of the LLVM tools directory omc was configured against
   (clang, llvm-link). Empty string if omc was built without LLVM JIT."
  output String dir;
  external "C" dir = omc_getLLVMToolsDir() annotation(Library="omcruntime");
end getLLVMToolsDir;

function runModelViaJIT
  "JIT-compile a model's pre-linked LLVM bitcode with ORC and run its main()
   in-process, resolving the simulation runtime from runtimeLib. The model's
   stdout/stderr are captured to logFile (as the native executable would).
   Returns the model's exit status (0 == success)."
  input String bitcodePath;
  input String runtimeLib;
  input String modelName;
  input String logFile;
  output Integer status;
  external "C" status = omc_runModelViaJIT(bitcodePath, runtimeLib, modelName, logFile) annotation(Library="omcruntime");
end runModelViaJIT;

annotation(__OpenModelica_Interface="backend");
end EXT_LLVM;
