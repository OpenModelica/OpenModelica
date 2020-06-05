/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
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
  external "C" storeThreadData_t(OpenModelica.threadData(),"threadData");
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
  external "C" createMetaToInt(src,dest); annotation(Library = "omcruntime");
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

function funcIsJitCompiled
  input String fName;
  output Boolean isJitCompiled;
  external "C" isJitCompiled = fIsJitCompiled(fName) annotation(Library="omcruntime");
end funcIsJitCompiled;

annotation(__OpenModelica_Interface="backendInterface");
end EXT_LLVM;
