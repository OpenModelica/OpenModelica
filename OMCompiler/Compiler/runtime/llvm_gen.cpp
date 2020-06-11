/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/* Author: John Tinnerholm */

#include "llvm_gen.hpp"
#include "llvm_gen_modelica_constants.h"
#include "llvm_gen_util.hpp"

/* The program currently being generated. */
extern std::unique_ptr<Program> program;

/*Used for construction of binary instructions among other things to reduce
 * bloat. */
using namespace std::placeholders;

extern "C" {
/* Dump the textual representation of LLVM IR*/
void dumpIR() {
  // OBS!, cannot link llvm 5 to dump see
  // https://stackoverflow.com/questions/46367910/llvm-5-0-linking-error-with-llvmmoduledump
  DBG("Calling dumpIR\n");
  if (!program->module) {
    /*Avoiding segfault with an error message.*/
    fprintf(stderr, "Cannot dumpIR no LLVM module is present\n");
    return;
  }
  program->module->print(llvm::errs(), nullptr);
}

int jitCompile() {
  /* Make sure that the LLVM IR is well-formed before execution.*/
  verifyFunctionDumpIROnError();
  program->jit->addModule(std::move(program->module));
  auto symbol{program->jit->findSymbol("top_level_expression")};
  auto targetAdress{symbol.getAddress()};
  unsigned long adress;

  if (!targetAdress) {
    fprintf(stderr,
            "Failed JIT compilation, no top level expression in module\n");
    return 1;
  }

  /*Get the address of the compiled to level expression. Assign said address to
   * FP.*/
  adress = targetAdress.get();
  program->top_level_func =
      reinterpret_cast<modelica_metatype (*)(modelica_metatype)>(adress);

  return 0;
}

modelica_boolean fIsJitCompiled(const char *fName) {
  auto symbol{program->jit->findSymbol(fName)};
  if (!symbol) {
    return false;
  }
  return true;
}

modelica_metatype run_jit_internal(modelica_metatype (*top_level_func)(modelica_metatype), modelica_metatype args);
modelica_metatype runJIT(modelica_metatype valLst) {
  DBG("Calling run JIT with argument:%s\n", anyString(valLst));
  void *valuePtr = run_jit_internal(program->top_level_func, valLst);
  return valuePtr;
}

/*Init neccessary global variables  */
void initGen(const char *name) {
  DBG("Calling initGen\n");
  /*Sets some global variables in LLVM, important program crashes without these
   * lines...*/
  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmPrinter();
  llvm::InitializeNativeTargetAsmParser();

  /*Create the global program variable. This class holds data to keep state when
   we switch between Modelica and the C/C++ context.*/
  program.reset(new Program(name));
  /*Some functions and aggregate structures need to be declared before codegen*/
  generateInitialRuntimeSignatures();
  /*
    TODO: Some strange issues with this approach.
    Almost works for most tests (Alot of the tests run with it),
    will not waste more time on it however.
    If there it is possible to do this and include all these functions we can
    have inlined calls
    for example mmc_mk_cons, increasing performance by a fair bit.
    Maybe generate llvm IR when starting the compiler and move around the JIT so
    that an eventual JIT always have access to these functions.
   */
  // if (false) {
  //    llvm::SMDiagnostic Err = llvm::SMDiagnostic();
  //    printf("BEFORE LOADING\n");
  //    program->module  =
  //    llvm::parseIRFile("SOME_FILE_PATH_TO_PRECOMPILED_BITCODE/llvm_gen_wrappers.bc"
  //                                         ,Err
  //                                         ,program->context);
  //    if(!program->module) {
  //      Err.print("llvmParse error",llvm::errs());
  //    }
  // }
}

/*
  Value decided by the jit_no_opt_flag. Add more flags and extend this here
  for more control over what optimisations shall be conducted.
*/

void setOptSettings(const modelica_boolean b) { program->shallOptimize = b; }

/*Called when generation of a single function is complete. */
void finishGen() {
  verifyFunctionDumpIROnError();
  program->runOptimizations();
  verifyFunctionDumpIROnError();
}
/*Executed when we encounter the first function Sets up in memory codegen*/
void startFuncGen(const char *name) {
  /*Set the function we are currently generating, std::make_unique is introduced
   * in C++14 */
  std::shared_ptr<Function> func = program->functions[name];

  if (!func) {
    func = std::shared_ptr<Function>(
        new Function(llvm::make_unique<FunctionPrototype>()));
    program->functions[name] = func;
  }
  program->currentFunc = func;
}

int createExit(const modelica_integer exitId) {
  DBG("Calling create exit with exitId:%ld\n", exitId);
  /*Block have to be created here aswell since midcode can specify branches to
   * this point*/
  std::string label{"label_" + std::to_string(exitId)};
  llvm::Function *f{
      program->module->getFunction(program->currentFunc->getName())};

  llvm::BasicBlock *bb;

  if (!program->currentFunc->blockMap[label]) {
    bb = llvm::BasicBlock::Create(program->context, label, f);
    program->currentFunc->blockMap[label] = bb;
    program->builder.SetInsertPoint(bb);
    return 0;
  }

  bb = program->currentFunc->blockMap[label];
  program->builder.SetInsertPoint(bb);

  return 0;
}

/*Executed when a basic block is encountered,
we either create a new block or fetch an existing from the blockMap*/
int setNewActiveBlock(const modelica_integer id) {
  DBG("Setting new active block with id:%d\n", id);
  // Just to keep Simon and patricks codegen similar to mine
  std::string label{"label_" + std::to_string(id)};
  llvm::Function *f{program->currentFunc->getLLVMFunc()};
  llvm::BasicBlock *insertBlck;

  // In some cases for instance if statements the blocks are already created
  if (!program->currentFunc->blockMap[label]) {
    insertBlck = llvm::BasicBlock::Create(program->context, label, f);
    program->currentFunc->blockMap[label] = insertBlck;
  }

  insertBlck = program->currentFunc->blockMap[label];
  program->builder.SetInsertPoint(insertBlck);

  if (program->currentFunc->imValMngr->switchNeedsDefaultBB()) {
    program->currentFunc->imValMngr->setDefaultBBForSwiInst(insertBlck);
  }

  return 0;
}

int createGoto(const modelica_integer id) {
  std::string label{"label_" + std::to_string(id)};
  llvm::Function *f{
      program->module->getFunction(program->currentFunc->getName())};
  llvm::BasicBlock *bb;

  if (!program->currentFunc->blockMap[label]) {
    bb = llvm::BasicBlock::Create(program->context, label, f);
    program->currentFunc->blockMap[label] = bb;
    program->builder.CreateBr(bb);
    return 0;
  }

  bb = program->currentFunc->blockMap[label];
  program->builder.CreateBr(bb);

  DBG("Done generating goto for :label_%ld\n", id);

  return 0;
}

int createBranch(const char *conditionVar, const modelica_integer onTrue,
                 const modelica_integer onFalse) {
  std::string onTrueLabel{"label_" + std::to_string(onTrue)};
  std::string onFalseLabel{"label_" + std::to_string(onFalse)};

  llvm::Function *f{
      program->module->getFunction(program->currentFunc->getName())};
  Variable *condVariable{program->currentFunc->symTab[conditionVar].get()};
  llvm::Value *cond{condVariable->getAllocaInst()};

  cond = program->builder.CreateLoad(cond, condVariable->isVolatile(),
                                     cond->getName());

  llvm::BasicBlock *onTrueBB;
  llvm::BasicBlock *onFalseBB;

  if (!program->currentFunc->blockMap[onTrueLabel]) {
    onTrueBB = llvm::BasicBlock::Create(program->context, onTrueLabel, f);
    program->currentFunc->blockMap[onTrueLabel] = onTrueBB;
  } else {
    onTrueBB = program->currentFunc->blockMap[onTrueLabel];
  }

  if (!program->currentFunc->blockMap[onFalseLabel]) {
    onFalseBB = llvm::BasicBlock::Create(program->context, onFalseLabel, f);
    program->currentFunc->blockMap[onFalseLabel] = onFalseBB;
  } else {
    onFalseBB = program->currentFunc->blockMap[onFalseLabel];
  }

  DBG("on true label:%ld on false label:%d\n", onTrue, onFalse);
  /* Create the branch instruction. */
  program->builder.CreateCondBr(cond, onTrueBB, onFalseBB);

  return 0;
}

/*Creates a switch skeleton*/
int createSwitch(const char *condVar, const modelica_integer numCases) {
  return program->currentFunc->imValMngr->createSwitch(
      createLoadInst(condVar), numCases, program->builder);
}

int addCaseToSwitch(const modelica_integer onVal, const modelica_integer dest) {
  std::string destBBLabel{"label_" + std::to_string(dest)};
  llvm::BasicBlock *destBB;
  llvm::Function *f{
      program->module->getFunction(program->currentFunc->getName())};

  /*If the basic block does not exist. Create a new block.*/
  if (!(destBB = program->currentFunc->blockMap[destBBLabel])) {
    destBB = llvm::BasicBlock::Create(program->context, destBBLabel, f);
    program->currentFunc->blockMap[destBBLabel] = destBB;
  }

  auto constantInt{llvm::ConstantInt::get(
      llvm::Type::getIntNTy(program->context, NBITS_MODELICA_INTEGER), onVal, true)};
  /*Add the  case to the switch instruction*/
  program->currentFunc->imValMngr->getSwiInst()->addCase(constantInt, destBB);

  return 0;
}

/* creates the arguments for the function prototype that is currently being
 * processed */
int createFunctionProtArg(const uint8_t type, const char *name) {
  /* Adds the argument to the prototypes argument vector, then name said
     argument.
     When nameArgument is called it is placed in a vector holding the names of
     the function
     parameters.
   */
  llvm::Type *ty = {getLLVMType(type, name)};

  if (!ty) {
    fprintf(stderr,
            "Tried to generate a function argument: %s with an invalid type. Type was: %s\n", name, getModelicaLLVMTypeString(type));
    MMC_THROW();
    }
  program->currentFunc->getPrototypeArgs().push_back(ty);
  program->nameArgument(name);

  return 0;
}
/* Creates the function type for the function prototype for the function that is
 * currently generated */
int createFunctionType(uint8_t type,
                       const char *structName /*To fetch the correct struct*/) {
  DBG("Calling createFunctionType type: %s structName: %s \n", getModelicaLLVMTypeString(type), structName);
  program->currentFunc->setPrototypeFunctionType(
      llvm::FunctionType::get(getLLVMType(type, structName),
                              program->currentFunc->getPrototypeArgs(), false));
  return 0;
}

/*Creates the function and names the arguments */
int createFunctionPrototype(const char *name) {
  // The prototype is now available in the module via getName.
  program->currentFunc->setLLVMFunction(llvm::Function::Create(
      program->currentFunc->getPrototypeFunctionType(),
      llvm::Function::ExternalLinkage, name, program->module.get()));
  /* Set the name of the arguments for consistency with MidCode representation
   */
  size_t indx = 0;
  for (auto &i : program->currentFunc->getLLVMFunc()->args()) {
    i.setName(program->currentFunc->getArgNames().at(indx));
    ++indx;
  }

  return 0;
}

/* Call starts by an external call from genEntry this function first
  fetch the function by name, given by genEntry and proceeds by generating the
  first basic block,
  that is the entry of the function. */
int createFunctionBody(const char *name) {
  llvm::Function *f{program->module->getFunction(name)};
  /* Assert that the function is in the symbol table of the module. */
  assert(f != nullptr);
  /* Generate the entry point to this function */
  llvm::BasicBlock *bb{llvm::BasicBlock::Create(program->context, "entry", f)};
  program->builder.SetInsertPoint(bb);
  program->currentFunc->blockMap["entry"] = bb;

  /*Add function arguments to the stack.*/
  for (auto &a : f->args()) {
    llvm::AllocaInst *ai{createAllocaInst(a.getName(), a.getType())};
    llvm::StoreInst *si{program->builder.CreateStore(&a, ai)};
    si->setAlignment(ai->getAlignment());
    program->currentFunc->symTab[a.getName()] =
        llvm::make_unique<Variable>(ai, false);
  }

  return 0;
}
/* Gets the address of the variable and pass it,
   these variables have to be located on the stack or heap.*/
int createCallArgAddr(const char *name) {
  DBG("Create callArgAddr name:%s line: %d of file:%s\n", name, __LINE__,
      __FILE__);
  /* First look for a global with that name, then look at the per function
   * symtab */
  if (program->globalConstants.count(name)) {
    program->currentFunc->callArgs.push_back(program->globalConstants[name]);
    return 0;
  } else if (program->currentFunc->symTab.count(name)) {
    program->currentFunc->callArgs.push_back(
        program->currentFunc->symTab[name]->getAllocaInst());
    return 0;
  }
  fprintf(stderr, "llvm_gen:Failure to resolve:%s\n", name);
  MMC_THROW();
}

/*Adds a named argument to the callArgs vector. */
int createCallArg(const char *name) {
  DBG("Create callAarg name:%s line: %d of file:%s\n", name, __LINE__,
      __FILE__);
  llvm::Value *v{createLoadInst(name)};
  DBG("We have a Value in createCallArg\n");
  program->currentFunc->callArgs.push_back(v);
  DBG("Before returning zero\n");
  return 0;
}

/*
   Fetch mmc_jumper from threadData struct (I do not know the signature of the
   threadData struct
   in the llvm context.)
*/

int createCallArgMmcJmpr() {
  // Returns a modelica_metatype no arguments.
  auto ft = llvm::FunctionType::get(getLLVMType(MODELICA_METATYPE),
                                    std::vector<llvm::Type *>(), false);

  llvm::Function *f = program->module->getFunction("get_mmc_jumper");

  // If the function is not declared, make a new one.
  if (!f) {
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage,
                               "get_mmc_jumper", program->module.get());
  }

  llvm::Value *mmc_jumper{program->builder.CreateCall(f, {})};
  // Add the result of the call to the callArgs vector.
  program->currentFunc->callArgs.push_back(mmc_jumper);

  return 0;
}

/*Adds a constant integer arg to the callArgs vector.*/
int createCallArgConstInt(const int64_t arg) {
  llvm::Value *v{llvm::ConstantInt::get(
      llvm::Type::getIntNTy(program->context, NBITS_MODELICA_INTEGER), arg, true)};
  program->currentFunc->callArgs.push_back(v);
  return 0;
}

/* Creates a call instruction, note that the argument that is passed to this
   external call should
    already be placed in the call_args vector */
int createCall(const char *name, const uint8_t functionTy, const char *dest,
               modelica_boolean assignment, modelica_boolean isVariadic) {
  DBG("Generating call! %s %d\n", name, functionTy);
  llvm::Function *f{program->module->getFunction(name)};
  /* f == nullptr is also the case when we are dealing with an external call to
     a compiled function present somewhere in the compiler.
     This call should be of two types, a void function used for side effects, or
     a function returning a specific value.
     For the first case we will generate a declaration for the function with the
     correct parameters so that the Execution
     engine of the JIT can locate it at a later stage. For the second option we
     will generate a function prototype of
     the same type as the variable we assign the call to.
  */
  /* Attempting to generate function for an external call. */
  if (!f) {
    // We need a vector of Type*, convert callArgs into one such vector.
    std::vector<llvm::Type *> args;
    for (auto v : program->currentFunc->callArgs) {
      args.push_back(v->getType());
    }
    DBG("Before creating createExternalCallDecl call\n");
    f = createExternalCallDecl(name, functionTy, args, isVariadic);
    if (!f) {
      fprintf(stderr, "Error calling external function:%s \n", name);
      MMC_THROW();
    }
  }
  /* If the call that is generated is supposed to assign to a variable. */
  if (assignment) {
    llvm::Value *s = program->builder.CreateCall(
        f, program->currentFunc->callArgs, "calltmp");
    createStoreInst(s, dest);
    program->currentFunc->callArgs.clear();
    return 0;
  }
  // Otherwise, simply make the call.
  program->builder.CreateCall(f, program->currentFunc->callArgs);
  program->currentFunc->callArgs.clear();
  return 0;
}

/*
  This is handled by it's own for now. The reason being that I cannot overload
  the createCall function and expose it to the MetaModelica environment.
*/

int createLongJmp() {
  llvm::Function *f{program->module->getFunction("longjmp")};

  if (!f) {
    std::vector<llvm::Type *> args{getLLVMType(MODELICA_METATYPE),
                                   getLLVMType(MODELICA_INTEGER)};
    llvm::FunctionType *ft{llvm::FunctionType::get(
        llvm::Type::getVoidTy(program->context), args, false)};
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage, "longjmp",
                               program->module.get());
    /*Set attributes so that LLVM does not optimise away the function during opt
     * phase.*/
    llvm::Attribute attr{
        llvm::Attribute::get(program->context, "noinline", "true")};
    std::vector<llvm::Attribute> attrs{attr};
    f->addAttributes(0, llvm::AttributeSet::get(program->context, attrs));
  }

  program->builder.CreateCall(f, program->currentFunc->callArgs);
  program->currentFunc->callArgs.clear();

  return 0;
}

/*Allocation of local declarations on the stack */

/*Allocates a llvm::Type integer on the stack with nBits in size. Observe that
 the size of integer in the top level expression is 64 bits but when it is
 unboxed it is 63 = (62) + signed bit. A 63 bit representation was tried, but it
 led to difficulties in codegen since
 type casts had to be made each time a lib function was to be called.
 The createAllocaInst is defined in llvm_gen_util.hpp, it can be extended to
 force allocation of x bytes for the different types.
*/
int allocaInt(const char *name, const bool isVolatile) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, llvm::Type::getIntNTy(program->context, NBITS_MODELICA_INTEGER))};
  program->currentFunc->symTab[alloci->getName()] =
      llvm::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

int allocaBoolean(const char *name, const bool isVolatile) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, llvm::Type::getIntNTy(program->context, 1))};
  program->currentFunc->symTab[alloci->getName()] =
      llvm::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

/*Allocates a modelica real, a double in LLVM IR*/
int allocaDouble(const char *name, const bool isVolatile) {
  llvm::AllocaInst *alloci{createAllocaInst(name, getLLVMType(MODELICA_REAL))};
  program->currentFunc->symTab[alloci->getName()] =
      llvm::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

/*For modelica_metatype and so forth 8 bits in size, however they will function
  as void pointers to differentiate
  between pointers to concrete types.
*/
int allocaInt8PtrTy(const char *name) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, getLLVMType(MODELICA_METATYPE))};
  program->currentFunc->symTab[alloci->getName()] =
      llvm::make_unique<Variable>(alloci, false);
  return 0;
}

/*Allocates a pointer to a pointer of type i8 (idented for modelica_metatype*)*/
int allocaInt8PtrPtrTy(const char *name) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, getLLVMType(MODELICA_METATYPE_PTR))};
  program->currentFunc->symTab[alloci->getName()] =
      llvm::make_unique<Variable>(alloci, false);
  return 0;
}

/*Stores the result of src at dest.*/
int createStoreVarInst(const char *src, const char *dest) {
  DBG("Calling store var instruction src:%s to dest:%s \n", src, dest);
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::AllocaInst *s{srcVariable->getAllocaInst()};
  llvm::Value *lv{
      program->builder.CreateLoad(s, srcVariable->isVolatile(), s->getName())};
  createStoreInst(lv, dest);
  return 0;
}

/*
  Special case to handle writes to pointers.
  we will have a pointer to a pointer in llvm IR.
  Thus to write the value to this pointer we have to
  use two loads, this is not the case with the regular store
  var instruction.
*/
int createStoreToPtr(const char *src, const char *dest) {
  DBG("Calling createStoreToPTR\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  Variable *destVariable{program->currentFunc->symTab[dest].get()};

  llvm::Value *s{srcVariable->getAllocaInst()};
  llvm::Value *d{destVariable->getAllocaInst()};
  s = program->builder.CreateLoad(s, srcVariable->isVolatile(), s->getName());
  d = program->builder.CreateLoad(d, destVariable->isVolatile(), d->getName());
  program->builder.CreateStore(s, d, srcVariable->isVolatile() ||
                                         destVariable->isVolatile());
  return 0;
}

int createStoreFromMmcJumpr(const char *dest) {
  llvm::Function *f{
      createExternalCallDecl("get_mmc_jumper", MODELICA_METATYPE, {})};
  llvm::Value *s{program->builder.CreateCall(f, {})};
  createStoreInst(s, dest);
  return 0;
}

/*Store instructions for literals*/
int storeLiteralInt(const int64_t src, const char *dest) {
  llvm::Value *s{llvm::ConstantInt::get(
      llvm::Type::getIntNTy(program->context, NBITS_MODELICA_INTEGER), src, true)};
  createStoreInst(s, dest);
  return 0;
}

int storeLiteralReal(const double src, const char *dest) {
  DBG("Storing litteral modelica_real:%lf\n", src);
  llvm::Value *s{
      llvm::ConstantFP::get(llvm::Type::getDoubleTy(program->context), src)};
  createStoreInst(s, dest);
  return 0;
}

int storeLiteralBoolean(const modelica_boolean src, const char *dest) {
  DBG("Storing litteral modelica_boolean:%d\n", src);
  llvm::Value *s{
      llvm::ConstantInt::get(llvm::Type::getInt1Ty(program->context), src)};
  createStoreInst(s, dest);
  return 0;
}

/* Stores the address of a 64 bit pointer variable.
(The pointer variables are passed arround as i8 for compatability with C but
they are infact 8 bytes big)*/
int storeLiteralIntForPtrTy(const std::uintptr_t addr, const char *dest) {
  DBG("Calling storeLiteralIntForPtrTy  with address of addr:%lu and dest:%s\n",
      addr, dest);
  const int sizeOfPtrInBits =
      64; // Might need a different constant for a different system.
  llvm::Value *ival{llvm::ConstantInt::get(
      llvm::Type::getIntNTy(program->context, sizeOfPtrInBits), addr,
      /*Not signed.*/ false)};
  llvm::Value *pval{program->builder.CreateIntToPtr(
      ival, llvm::Type::getInt8PtrTy(program->context), "pointerTMP")};
  // program->builder.CreateStore(pval,program->currentFunc->symTab[dest]);
  createStoreInst(pval, dest);
  return 0;
}

/*Store thread_data_t*/
int storeThreadData_t(void *threadData, const char *threadDataID) {
  DBG("Calling storeThreadData_t with address of threadData:%p and dest "
      "name:%s\n",
      threadData, threadDataID);
  uintptr_t puint = reinterpret_cast<std::uintptr_t>(threadData);
  storeLiteralIntForPtrTy(puint, threadDataID);
  return 0;
}

/*Handles return for a single variable*/
int createReturn(const char *retVar) {
  DBG("Calling create return with retVariable: %s \n", retVar);
  Variable *returnVariable{program->currentFunc->symTab[retVar].get()};
  llvm::Value *ret = returnVariable->getAllocaInst();
  ret = program->builder.CreateLoad(ret, returnVariable->isVolatile(),
                                    ret->getName());
  program->builder.CreateRet(ret);
  return 0;
}

void createReturnVoid() {
  DBG("Calling createReturnVoid\n");
  program->builder.CreateRetVoid();
}

/*This function creates a llvm ret instruction that only returns zero.*/
int createReturnZero() {
  DBG("Calling createReturnZero\n");
  llvm::Value *retVal{llvm::ConstantInt::get(
      llvm::Type::getInt64Ty(program->context), 0, true)};
  program->builder.CreateRet(retVal);
  return 0;
}

/*Unary operators */
int createIUminus(const char *src, const char *dest) {
  DBG("Creating i64 Uminus\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::Value *s{srcVariable->getAllocaInst()};
  s = program->builder.CreateLoad(s, srcVariable->isVolatile(), s->getName());
  s = program->builder.CreateNeg(s, "negI64temp");
  createStoreInst(s, dest);
  return 0;
}

int createDUminus(const char *src, const char *dest) {
  DBG("Creating DUminus\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::Value *s{srcVariable->getAllocaInst()};
  s = program->builder.CreateLoad(s, srcVariable->isVolatile(), s->getName());
  s = program->builder.CreateFNeg(s, "negDtemp");
  createStoreInst(s, dest);
  return 0;
}

int createNot(const char *src, const char *dest) {
  DBG("Creating  NOT\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::Value *s{srcVariable->getAllocaInst()};
  s = program->builder.CreateLoad(s, srcVariable->isVolatile(), s->getName());
  s = program->builder.CreateNot(s, "notTmp");
  createStoreInst(s, dest);
  return 0;
}
/* Instructions performing the casts specified by the MOVE in MidCode.
   Not all casts are detected by MidCode However.*/

int createIntToDouble(const char *src, const char *dest) {
  DBG("Calling createIntToDouble with %s %s\n", src, dest);
  DBG("Calling createIntToDouble with %s %s\n", src, dest);
  // Passing the appropriate builder function call, this is done to avoid
  // dublication.
  auto f{std::bind(&llvm::IRBuilder<>::CreateSIToFP, &program->builder, _1, _2,
                   "intDoubleTmp")};
  return castXTypeToYType(src, dest, llvm::Type::getDoubleTy(program->context),
                          f);
}

int createDoubleToInt(const char *src, const char *dest) {
  DBG("Calling createDoubleToInt with %s %s\n", src, dest);
  auto f{std::bind(&llvm::IRBuilder<>::CreateFPToSI, &program->builder, _1, _2,
                   "doubleToIntTmp")};
  return castXTypeToYType(src, dest, llvm::Type::getInt64Ty(program->context),
                          f);
  ;
}

// For some stupid reason bind does not work with CreateIntCast, ugly but will
// not waste more time with it, see commented line.
int createIntToBool(const char *src, const char *dest) {
  // auto f
  // {std::bind(&llvm::IRBuilder<>::CreateIntCast,&program->builder,_1,_2,true,"intToBool")};
  DBG("Calling createIntToBool with %s %s\n", src, dest);
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  Variable *destVariable{program->currentFunc->symTab[dest].get()};

  llvm::Value *s{srcVariable->getAllocaInst()};
  llvm::Value *d{destVariable->getAllocaInst()};
  llvm::Value *res{program->builder.CreateIntCast(
      s, llvm::Type::getInt1Ty(program->context), true, "intToBoolTmp")};
  program->builder.CreateStore(res, d, srcVariable->isVolatile() ||
                                           destVariable->isVolatile());
  return 0;
}

int createBoolToInt(const char *src, const char *dest) {
  DBG("Calling createBoolToInt\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  Variable *destVariable{program->currentFunc->symTab[dest].get()};

  llvm::Value *s{srcVariable->getAllocaInst()};
  llvm::Value *d{destVariable->getAllocaInst()};
  llvm::Value *res{program->builder.CreateIntCast(
      s, llvm::Type::getInt64Ty(program->context), true, "boolToIntTmp")};
  program->builder.CreateStore(res, d, srcVariable->isVolatile() ||
                                           destVariable->isVolatile());
  return 0;
}

int createIntToMeta(const char *src, const char *dest) {
  DBG("createIntToMeta %s %s", src, dest);
  auto f{std::bind(&llvm::IRBuilder<>::CreateIntToPtr, &program->builder, _1,
                   _2, "intToMetaTmp")};
  return castXTypeToYType(src, dest, llvm::Type::getInt8PtrTy(program->context),
                          f);
  ;
}

int createMetaToInt(const char *src, const char *dest) {
  DBG("createMetaToInt %s %s", src, dest);
  auto f{std::bind(&llvm::IRBuilder<>::CreatePtrToInt, &program->builder, _1,
                   _2, "intToMetaTmp")};
  return castXTypeToYType(src, dest, llvm::Type::getInt64Ty(program->context),
                          f);
  ;
}

int createDoubleToBool(const char *src, const char *dest) {
  DBG("createDoubleToBool %s %s", src, dest);
  auto f{std::bind(&llvm::IRBuilder<>::CreateFPToSI, &program->builder, _1, _2,
                   "doubleToBoolTmp")};
  return castXTypeToYType(src, dest, llvm::Type::getInt1Ty(program->context),
                          f);
  ;
}

int createBoolToDouble(const char *src, const char *dest) {
  DBG("createBoolToDouble %s %s\n", src, dest);
  auto f{std::bind(&llvm::IRBuilder<>::CreateFPToSI, &program->builder, _1, _2,
                   "boolToDouble")};
  return castXTypeToYType(src, dest, llvm::Type::getDoubleTy(program->context),
                          f);
  ;
}
// TODO, this function will be called if the situation arises (MidToLLVM.mo will
// call it if it would occur)
int createMetaToDouble(const char *src, const char *dest) {
  DBG("CONVERTING A METATYPE TO DOUBLE DOES NOT SEEM TO BE "
      "SUPPORTED,INVESTIGATE\n");
  return 0;
}
// TODO Same as above.
int createDoubleToMeta(const char *src, const char *dest) {
  DBG("CONVERTING A DOUBLE TO META DOES NOT SEEM TO BE "
      "SUPPORTED,INVESTIGATE\n");
  return 0;
}

/*Functions to create binary instructions */
int createPow(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling create pow\n");
  llvm::Value *l, *r, *d;
  llvm::Function *f;
  binopInit(lhs, rhs, dest, l, r, d);

  if (!(f = program->module->getFunction("pow"))) {
    llvm::FunctionType *ft{
        llvm::FunctionType::get(llvm::Type::getDoubleTy(program->context),
                                {l->getType(), r->getType()}, false)};
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage, "pow",
                               program->module.get());
  }

  llvm::Value *res{program->builder.CreateCall(f, {l, r}, "calltmp")};
  program->builder.CreateStore(res, d);

  return 0;
}

/*Considering a modelica integer is 32 bits on windows some macros might be
 * needed for the functions below*/
int createIAdd(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating IADD\n");
  auto f{std::bind(&llvm::IRBuilder<>::CreateAdd, &program->builder, _1, _2, _3,
                   false, false)};
  return createBinop(lhs, rhs, dest, "addI64Tmp", f);
}

int createISub(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating ISUB\n");
  auto f{std::bind(&llvm::IRBuilder<>::CreateSub, &program->builder, _1, _2, _3,
                   false, false)};
  return createBinop(lhs, rhs, dest, "subI64tmp", f);
}

int createIMul(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating IMUL\n");
  auto f{std::bind(&llvm::IRBuilder<>::CreateMul, &program->builder, _1, _2, _3,
                   false, false)};
  return createBinop(lhs, rhs, dest, "mulI64tmp", f);
}
// N.b result is a double.
int createIDiv(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating IDiv");
  auto f{std::bind(&llvm::IRBuilder<>::CreateSDiv, &program->builder, _1, _2,
                   _3, false)};
  return createBinop(lhs, rhs, dest, "divI64Rmp", f);
}
// TODO refactor these below later with some tweaking we can also use
// createBinop for them aswell.
int createILess(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating ILess\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_SLT, l, r, "lessItmp")};
  createStoreInst(res, dest);
  return 0;
}

int createILessEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating ILESSEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateICmp(llvm::ICmpInst::ICMP_SLE, l, r,
                                               "lessEqItmp")};
  createStoreInst(res, dest);
  return 0;
}

int createIGreater(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating IGREATER\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateICmp(llvm::ICmpInst::ICMP_SGT, l, r,
                                               "greaterItmp")};
  createStoreInst(res, dest);
  return 0;
}

int createIGreaterEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("CREATING IGREATEREQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateICmp(llvm::ICmpInst::ICMP_SGE, l, r,
                                               "greaterItmp")};
  createStoreInst(res, dest);
  return 0;
}

int createIEqual(const char *lhs, const char *rhs, const char *dest) {
  DBG("CREATING IEQUAL\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_EQ, l, r, "eqItmp")};
  createStoreInst(res, dest);
  return 0;
}

int createINequal(const char *lhs, const char *rhs, const char *dest) {
  DBG("CREATING INEQUAL\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_NE, l, r, "neqItmp")};
  createStoreInst(res, dest);
  return 0;
}

/*For modelica_Reals */
int createDAdd(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDAddwith: lhs=%s and rhs=%s dest=%s\n", lhs, rhs, dest);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFAdd(l, r, "addDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDSub(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDSub with: lhs=%s and rhs=%s\n", lhs, rhs);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFSub(l, r, "subDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDMul(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDMul with: lhs=%s and rhs=%s\n", lhs, rhs, dest);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFMul(l, r, "mulDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDDiv(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDDiv with: lhs=%s and rhs=%s\n", lhs, rhs);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFDiv(l, r, "divDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDLess(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDLESS with: lhs=%s and rhs=%s\n", lhs, rhs);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateFCmp(llvm::FCmpInst::FCMP_ULT, l, r, "lessDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDLessEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling createDLESSEQ with: lhs=%s and rhs=%s\n", lhs, rhs);
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFCmp(llvm::ICmpInst::FCMP_ULE, l, r,
                                               "lessEqDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDEqual(const char *lhs, const char *rhs, const char *dest) {
  DBG("CREATING DEQUAL\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateFCmp(llvm::ICmpInst::FCMP_UEQ, l, r, "eqDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDNequal(const char *lhs, const char *rhs, const char *dest) {
  DBG("Creating DNequal\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateFCmp(llvm::ICmpInst::FCMP_UNE, l, r, "neqDtmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDGreater(const char *lhs, const char *rhs, const char *dest) {
  DBG("creatingDGREATER\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFCmp(llvm::ICmpInst::FCMP_UGT, l, r,
                                               "greaterI64tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createDGreaterEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("CreatingDGreaterEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateFCmp(llvm::ICmpInst::FCMP_UGE, l, r,
                                               "greaterEQI64tmp")};
  createStoreInst(res, dest);
  return 0;
}
/* For modelica_booleans, observe since llvm uses 2's-complement and a
   modelica_boolean is represented in llvm
   with a i1, the unsigned comparision instructions are used for booleans.
*/
int createBGreater(const char *lhs, const char *rhs, const char *dest) {
  DBG("CreateBooleanGreater\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateICmp(llvm::ICmpInst::ICMP_UGT, l, r,
                                               "greaterI8tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createBGreaterEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("CreateBGreaterEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{program->builder.CreateICmp(llvm::ICmpInst::ICMP_UGE, l, r,
                                               "greaterEQI8tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createBLess(const char *lhs, const char *rhs, const char *dest) {
  DBG("CallingBLess\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_ULT, l, r, "lessI1tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createBLessEq(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling bLessEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_ULE, l, r, "lessI1tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createBEqual(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling bEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_EQ, l, r, "EqI1tmp")};
  createStoreInst(res, dest);
  return 0;
}

int createBNequal(const char *lhs, const char *rhs, const char *dest) {
  DBG("Calling bLessEQ\n");
  llvm::Value *l, *r, *d;
  binopInit(lhs, rhs, dest, l, r, d);
  llvm::Value *res{
      program->builder.CreateICmp(llvm::ICmpInst::ICMP_NE, l, r, "EqI1tmp")};
  createStoreInst(res, dest);
  return 0;
}


/*
  Set value to nullptr prepare generation of a new list in the function
  currently being created.
*/
void startGenLst() {
  llvm::Value *cdr {program->currentFunc->imValMngr->getCdr()};
  if (cdr) {
    cdr->deleteValue();
  }
}

// Assigns cdr to the lstName variable that is present in the symtab.
int createLst(const char *lstName) {
  DBG("CreateMmcCons\n");
  // Assign the value of the pointer that points to lstName in the symbol table
  Variable *lstVariable{program->currentFunc->symTab[lstName].get()};
  llvm::Value *lst{lstVariable->getAllocaInst()};
  llvm::Value *cdr {program->currentFunc->imValMngr->getCdr()};
  program->builder.CreateStore(cdr, lst, lstVariable->isVolatile());
  return 0;
}

// TODO refactor this...
int createMmcCons(
  const char *carElement /*This refeers to a mmc already created.*/) {
  DBG("CreateMmcCons\n");
  /*Fetch the arguments*/
  llvm::FunctionType *ft;
  llvm::Function *f;
  llvm::Value *cdr {program->currentFunc->imValMngr->getCdr()};
  /*Creates the first, (really last cell) ugly special case.*/
  if (!cdr) {
    /*Load the carElement*/
    Variable *carElementVariable{
        program->currentFunc->symTab[carElement].get()};
    llvm::Value *ce = carElementVariable->getAllocaInst();
    /*Load instruction to set the alignment*/
    llvm::LoadInst *ceL = program->builder.CreateLoad(
        ce, carElementVariable->isVolatile(), ce->getName());
    ceL->setAlignment(8);
    ce = ceL;
    std::vector<llvm::Value *> args{ce};
    std::vector<llvm::Type *> argTys{ce->getType()};
    ft = llvm::FunctionType::get(getLLVMType(MODELICA_METATYPE), argTys, false);
    /*This ensures that the function is not created twice. */
    f = program->module->getFunction("mmc_mk_cons_last_elem");
    if (!f) {
      DBG("Last element is inserted\n");
      f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage,
                                 "mmc_mk_cons_last_elem",
                                 program->module.get());
    }
    // Call it
    cdr = program->builder.CreateCall(f, args);
    program->currentFunc->imValMngr->setCdr(cdr);
    return 0;
  }
  /*The other case when we have a cdr.*/
  Variable *carElementVariable{program->currentFunc->symTab[carElement].get()};
  llvm::Value *ce{carElementVariable->getAllocaInst()};
  llvm::LoadInst *ceL{program->builder.CreateLoad(
      ce, carElementVariable->isVolatile(), ce->getName())};
  ceL->setAlignment(8);
  ce = ceL;
  std::vector<llvm::Value *> args{ce, cdr};
  std::vector<llvm::Type *> argTys{ce->getType(), cdr->getType()};
  ft = llvm::FunctionType::get(getLLVMType(MODELICA_METATYPE), argTys, false);
  f = program->module->getFunction("mmc_mk_cons_wrapper");

  if (!f) {
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage,
                               "mmc_mk_cons_wrapper", program->module.get());
  }

  cdr = program->builder.CreateCall(f, args);
  program->currentFunc->imValMngr->setCdr(cdr);
  return 0;
}

/*Functions relating to LLVM structs. Used for generation of tuples and
uniontypes (That are then sent to the OMC for creation
).*/
int createStructElement(const uint8_t ty) {
  program->currentFunc->imValMngr->getStructField().push_back(getLLVMType(ty));
  return 0;
}

/*Creates the signature for a llvm struct*/
int createStructSignature(const char *sName) {
  DBG("Calling createStructSignature for:%s \n", sName);
  /*Get the sField. The destructor will be called automatically at the end of
   * this function*/
  std::vector<llvm::Type *> sField =
      program->currentFunc->imValMngr->getStructField();

  if (!sField.size()) {
    fprintf(stderr, "Attempted to create struct signature without a field\n");
    dumpIR();
    return 1;
  }

  /*Check if the struct already exists */
  llvm::StructType *structTy = program->module->getTypeByName(sName);

  if (!structTy) {
    structTy = llvm::StructType::create(program->context, sName);
  }

  if (structTy->isOpaque()) {
    structTy->setBody(sField, false);
  }

  return 0;
}

/*
  Creates a struct of type structName, adds the struct to the alloca map.
  The signature must be called before calling this function.
*/
int createStruct(const char *structName) {
  DBG("Calling Create struct with structName: %s \n", structName);
  llvm::StructType *sType{program->module->getTypeByName(structName)};
  if (!sType) {
    fprintf(stderr, "Attempted to create struct without signature for: %s \n", structName);
    MMC_THROW();
    return 1;
  }

  llvm::AllocaInst *structAi{createAllocaInst(structName, sType)};

  DBG("after call to createAllocaInst\n");
  program->currentFunc->symTab[structName] =
      llvm::make_unique<Variable>(structAi, false);
  return 0;
}

/*The variables should already exist in the global scope*/
int createGlobalStructFieldConstant(const char *varName) {
  DBG("Calling:%s, parameter:%s\n", __FUNCTION__, varName);
  llvm::GlobalVariable *c{program->globalConstants[std::string(varName)]};

  if (!c) {
    fprintf(stderr, "Cannot invoke createGlobalStructFieldConstant with "
                    "unallocated variable:%s\n",
            varName);
    dumpIR();
    MMC_THROW();
  }

  program->globalStructField.push_back(c);

  return 0;
}

/*The indent of this function is to generate LLVM IR for structs created in the
 * global context, with global variables.*/
int createGlobalStructConstant(const char *structTypeName, const char *name) {
  DBG("structTypeName:%s name:%s file:%s function:%s line%d\n", structTypeName,
      name, __FILE__, __FUNCTION__, __LINE__);
  std::vector<llvm::GlobalVariable *> field = program->globalStructField;
  std::vector<llvm::Constant *> gepField;

  for (const auto &llvmC : field) {
    llvm::Constant *idx0{
        llvm::ConstantInt::get(llvm::Type::getInt32Ty(program->context), 0)};
    /*TODO: Add if stmt here to check if we are dealing with an aggregate glb
     * var or not (only works for aggregates)*/
    const std::vector<llvm::Constant *> indices{idx0, idx0};
    auto ty = llvmC->getType()
                  ->getElementType(); /* We must get the encapsulated type*/
    llvm::Constant *gep =
        llvm::ConstantExpr::getGetElementPtr(ty, llvmC, indices);
    gepField.push_back(gep);
  }

  DBG("Creating gvArStruct\n");
  llvm::GlobalVariable *gvarStruct = new llvm::GlobalVariable(
      *program->module.get(), program->module->getTypeByName(structTypeName),
      false,
      llvm::GlobalValue::ExternalLinkage, // TODO: See over this.
      0, name);
  DBG("gvarStructCreated\n");
  // TODO: Figure out alignment. (Problems?)
  llvm::Constant *constStruct = llvm::ConstantStruct::get(
      program->module->getTypeByName(structTypeName), gepField);
  gvarStruct->setInitializer(constStruct);
  program->globalConstants[name] = gvarStruct;
  program->globalStructField.clear();
  return 0;
}

/*Stores a double at an array at index idx0*/
int createStoreDoubleToPtr(double src, const char *dest, const uint8_t idx0) {
  llvm::Value *vIdx0{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx0, false)};
  llvm::Value *sV{
      llvm::ConstantFP::get(llvm::Type::getDoubleTy(program->context), src)};
  llvm::Value *dV{createLoadInst(dest)};
  llvm::Value *gep{program->builder.CreateInBoundsGEP(dV, vIdx0, "gepTmp")};
  // All these functions of similar type can look the same, just add the right
  // bitcast in a later refactor.
  gep = program->builder.CreateBitCast(
      gep, llvm::Type::getDoublePtrTy(program->context));
  program->builder.CreateStore(sV, gep);
  return 0;
}

/*Stores a double variable at an array indexed with idx0*/
int createStoreDVarToPtr(const char *src, const char *dest,
                         const uint8_t idx0) {
  llvm::Value *sV{createLoadInst(src)};
  llvm::Value *dV{createLoadInst(dest)};
  llvm::Value *vIdx0{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx0, false)};
  llvm::Value *gep{program->builder.CreateInBoundsGEP(dV, vIdx0, "geptmp")};
  gep = program->builder.CreateBitCast(
      gep, llvm::Type::getDoublePtrTy(program->context));
  program->builder.CreateStore(sV, gep);
  return 0;
}

/*Fetches a double from an array and stores it at the variable dest.*/
int createGetDoubleFromPtr(const char *src, const char *dest,
                           const uint8_t idx0) {
  Variable *doubleVariable{program->currentFunc->symTab[dest].get()};
  llvm::Value *dV{doubleVariable->getAllocaInst()};
  llvm::Value *vIdx0{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx0, false)};
  llvm::Value *sV = createLoadInst(src);
  llvm::Value *gep{program->builder.CreateInBoundsGEP(sV, vIdx0, "geptmp")};
  gep = program->builder.CreateBitCast(
      gep, llvm::Type::getDoublePtrTy(program->context));
  llvm::LoadInst *li = program->builder.CreateLoad(gep);
  li->setAlignment(8);
  program->builder.CreateStore(li, dV, doubleVariable->isVolatile());
  return 0;
}

/*For N dimensional structs, store to the fields of the structs using idx0 and
 * idx1 for indexing.*/
int createStoreToStruct(const char *varName, const char *structName,
                        const uint8_t idx0, const uint8_t idx1) {
  DBG("Calling createStoreToStruct varName:%s to struct:%s", varName,
      structName);
  Variable *structVariable{program->currentFunc->symTab[structName].get()};
  llvm::Value *sv{structVariable->getAllocaInst()};

  if (!sv) {
    fprintf(stderr, "Error no struct named:%s\n", structName);
    dumpIR();
    MMC_THROW();
  }

  llvm::Value *vIdx0{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx0, false)};
  llvm::Value *vIdx1{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx1, false)};
  /*Indices for the GEP instruction*/
  std::vector<llvm::Value *> indexVec{vIdx0, vIdx1};
  Variable *retVariable{program->currentFunc->symTab[varName].get()};
  llvm::Value *retVar{retVariable->getAllocaInst()};
  retVar = createLoadInst(varName);
  llvm::Value *structElem{
      program->builder.CreateInBoundsGEP(sv, indexVec, "gepTmp")};
  program->builder.CreateStore(retVar, structElem, retVariable->isVolatile());

  return 0;
}

/*Takes a value from the struct and store it at the variable that is referenced
 * by varName*/
int createStoreFromStruct(const char *varName, const char *structName,
                          const uint8_t idx0, const uint8_t idx1) {
  Variable *sourceVariable{program->currentFunc->symTab[structName].get()};
  llvm::AllocaInst *sv{sourceVariable->getAllocaInst()};

  if (!sv) {
    fprintf(stderr,
            "No variable named:%s in struct dest:%s in file:%s at line:%d\n",
            varName, structName, __FILE__, __LINE__);

    MMC_THROW();
  }

  /*Indices for the GEP instruction*/
  llvm::Value *vIdx0{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx0, false)};
  llvm::Value *vIdx1{llvm::ConstantInt::get(
      llvm::Type::getInt32Ty(program->context), idx1, false)};
  std::vector<llvm::Value *> indexVec{vIdx0, vIdx1};
  // Create GEP instruction.
  llvm::Value *structElem{
      program->builder.CreateInBoundsGEP(sv, indexVec, "gepTmp")};
  // TODO: Can probably be added to the allignment function in utils.
  llvm::LoadInst *structElemL =
      program->builder.CreateLoad(structElem, structElem->getName());
  structElemL->setAlignment(sv->getAlignment());
  structElem = structElemL;
  /*Create the variable we store the value from the struct to.*/
  Variable *variable{program->currentFunc->symTab[varName].get()};
  llvm::Value *var{variable->getAllocaInst()};
  structElem = program->builder.CreateStore(structElem, var,
                                            sourceVariable->isVolatile());

  return 0;
}

int createGVarCStr(const char *origName) {
  /* + 1 to include the terminator for the C strings. */
  llvm::GlobalVariable *gStr = new llvm::GlobalVariable(
      *program->module.get(),
      llvm::ArrayType::get(
          /*i8, regular chars*/ llvm::Type::getInt8Ty(program->context),
          strlen(origName) + 1),
      true, llvm::GlobalValue::PrivateLinkage, 0);
  auto cs =
      llvm::ConstantDataArray::getString(program->context, origName, true);
  gStr->setAlignment(1);
  gStr->setInitializer(cs);
  /*TODO: Gvar to the global variables map (Observe that this might lead to
   * scope problem if a variable would have the same name as a string with gbl_
   * prefix)*/
  program->globalConstants[std::string(origName)] = gStr;

  return 0;
}

/*Creates a 2 dimensional array containing strings*/
int createCStrArray(const char *name, const modelica_integer fields) {
  DBG("function:%s file:%s line:%d name:%s fields:%ld\n", __FUNCTION__,
      __FILE__, __LINE__, name, fields);
  /*Fetch the strings that we are going to make an array from (the destructor
   * will clear it when this func exits)*/
  std::vector<std::string> llvmStrArr{program->llvmStrArray};
  DBG("llvmStrArr fetched\n");
  std::vector<llvm::Constant *> gepArray; // Holds GEP instructions (The char
                                          // array should be an array of such
                                          // insts)
  /*Generate all substring arrays*/
  for (const auto &s : program->llvmStrArray) {
    // Note IR builder cannot be used to generate global variables!!.
    llvm::GlobalVariable *gStr = new llvm::GlobalVariable(
        *program->module.get(),
        llvm::ArrayType::get(getLLVMType(MODELICA_METATYPE),
                             s.length() +
                                 1) //+ 1 to include CString terminator.
        ,
        true, llvm::GlobalValue::PrivateLinkage, 0);
    gStr->setAlignment(
        1); // These are C style strings (char*), not Modelica strings.
    llvm::Constant *strCData =
        llvm::ConstantDataArray::getString(program->context, s, true);
    gStr->setInitializer(strCData); // Initialize the Gvar.
    llvm::Constant *idx0{
        llvm::ConstantInt::get(llvm::Type::getInt32Ty(program->context), 0)};
    llvm::Constant *idx1{
        llvm::ConstantInt::get(llvm::Type::getInt32Ty(program->context), 0)};
    std::vector<llvm::Constant *> indices{idx0, idx1};
    llvm::Constant *gep = llvm::ConstantExpr::getGetElementPtr(
        strCData->getType(), gStr, indices);
    gepArray.push_back(gep);
  }

  DBG("Before creation of gvarStrArray\n");
  /* Create an array of array of strings (Consisting of GEP instructions) */
  llvm::GlobalVariable *gvarStrArray = new llvm::GlobalVariable(
      *program->module.get(),
      llvm::ArrayType::get(getLLVMType(MODELICA_METATYPE), fields), true,
      llvm::GlobalValue::PrivateLinkage, 0, name);
  DBG("Global created creating const array\n");
  llvm::Constant *constArray = llvm::ConstantArray::get(
      llvm::ArrayType::get(getLLVMType(MODELICA_METATYPE), fields),
      /*The string arrays*/ gepArray);
  DBG("constArray created setting alignment\n");
  gvarStrArray->setAlignment(fields * 8);
  gvarStrArray->setInitializer(constArray);
  /* Save the global variabel in our global variable map*/
  program->globalConstants[name] = gvarStrArray;
  program->llvmStrArray.clear();

  return 0;
}

/*Adds data to a temporary array for later array creation*/
int addToLLVMStrArray(const char *elem) {
  DBG("function:%s file:%s line:%d variable:%s", __FUNCTION__, __FILE__,
      __LINE__, elem);
  program->llvmStrArray.push_back(elem);
  return 0;
}

/* Creates a Modelica_String, the GlobalStringPtr will be reduced to private
 * linkage by LLVM-opt */
int createStringConstant(const char *str, char *dest) {
  DBG("Calling createStringConstant\n");
  llvm::Value *strPointer = program->builder.CreateGlobalStringPtr(str);
  const std::vector<llvm::Value *> args{strPointer};
  const std::vector<llvm::Type *> argTypes{getLLVMType(MODELICA_METATYPE)};
  const char *fName = "mmc_mk_scon_wrapper";
  llvm::Function *f{program->module->getFunction(fName)};
  llvm::FunctionType *ft{
      llvm::FunctionType::get(getLLVMType(MODELICA_METATYPE), argTypes, false)};
  DBG("createStringConstant string:%s dest:%s file:%s line:%d\n", str, dest,
      __FILE__, __LINE__);

  if (!f) {
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage, fName,
                               program->module.get());
  }

  llvm::Value *res{program->builder.CreateCall(f, args)};
  createStoreInst(res, dest);

  return 0;
}

} /* end extern "C" */
