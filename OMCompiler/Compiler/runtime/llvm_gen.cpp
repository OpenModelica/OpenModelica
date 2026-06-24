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

/* Author: John Tinnerholm */

#include "llvm_gen.hpp"
#include "llvm_gen_layout.h"
#include "llvm_gen_modelica_constants.h"
#include "llvm_gen_util.hpp"

#include <llvm/Bitcode/BitcodeReader.h>
#include <llvm/Bitcode/BitcodeWriter.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Support/raw_ostream.h>

#include <vector>
#include <fstream>
#include <unordered_map>

/* For redirecting the in-process model's stdout/stderr to its log file
 * (the native executable path does the same via shell redirection). */
#include <fcntl.h>
#include <unistd.h>

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

/* Write the current in-memory LLVM module to <path> as bitcode. The
 * counterpart of dumpIR() but in machine-readable form; used while
 * SimCodeToLLVM is being grown so its in-memory module can be merged
 * with the C-derived bitcode by llvm-link, and so a user can inspect
 * the IR with llvm-dis. Returns 0 on success. */
int writeBitcodeToFile(const char *path) {
  if (!path || !path[0]) return 1;
  if (!program || !program->module) {
    fprintf(stderr, "writeBitcodeToFile: no module to serialise\n");
    return 2;
  }
  std::error_code ec;
  llvm::raw_fd_ostream out(path, ec, llvm::sys::fs::OF_None);
  if (ec) {
    fprintf(stderr, "writeBitcodeToFile: cannot open '%s': %s\n",
            path, ec.message().c_str());
    return 3;
  }
  llvm::WriteBitcodeToFile(*program->module, out);
  out.flush();
  return 0;
}

/* ------------------------------------------------------------------------ *
 * Inlined DATA-struct accessors emitted directly into model functions.
 *
 * Layout offsets come from llvm_gen_layout.c (which uses offsetof() on
 * the runtime DATA / SIMULATION_DATA / SIMULATION_INFO definitions),
 * so this file does not need to mirror the struct shape in C++ -- the
 * C runtime is the single source of truth.
 *
 * Every createInlined* primitive emits its GEP / load / store chain
 * into the current builder insert point, registering the result alloca
 * (if any) under the requested name in the per-function symtab. They
 * compose: emitReadRealVar in SimCodeToLLVM.mo calls a sequence of
 * these to inline the chain that the omc_jit_get_real_var runtime
 * helper previously wrapped.
 * ------------------------------------------------------------------------ */

/* Helper: load (i8-typed) pointer offset `bytes` past `basePtr`, then
 * load a pointer value at that address. Used to chain through the
 * DATA struct's nested pointer fields. Returns the LoadInst whose
 * value is the loaded pointer. */
static llvm::Value *emitGEPLoadPtr(llvm::Value *const basePtr,
                                   const size_t byteOffset) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Type *const i8 = llvm::Type::getInt8Ty(program->context);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Value *const gep = b.CreateGEP(
      i8, basePtr, llvm::ConstantInt::get(i64, byteOffset), "");
  llvm::Type *const ptrTy = llvm::PointerType::getUnqual(program->context);
  return b.CreateLoad(ptrTy, gep, "");
}

/* Helper: dereference `basePtr` (treated as a pointer-to-pointer) once.
 * Equivalent to *(void**)basePtr. */
static llvm::Value *emitLoadPtr(llvm::Value *const basePtr) {
  llvm::Type *const ptrTy = llvm::PointerType::getUnqual(program->context);
  return program->builder.CreateLoad(ptrTy, basePtr, "");
}

/* Helper: load symtab entry (requires the entry to be an alloca already
 * registered by allocaDouble / createFunctionBody arg-registration). */
static llvm::Value *loadFromSymtab(const char *const name) {
  Variable *const v = program->currentFunc->symTab[name].get();
  if (!v) {
    fprintf(stderr,
            "loadFromSymtab: no Variable named '%s' in symboltable\n", name);
    MMC_THROW();
  }
  llvm::AllocaInst *const ai = v->getAllocaInst();
  if (!ai) {
    fprintf(stderr, "loadFromSymtab: '%s' has no AllocaInst\n", name);
    MMC_THROW();
  }
  return program->builder.CreateLoad(ai->getAllocatedType(), ai,
                                     v->isVolatile(), ai->getName());
}

/* createInlinedReadRealVar: emit the GEP / load chain that returns
 *
 *   data->localData[0]->realVars[slot]
 *
 * directly into the active function body. Stores the resulting double
 * into the alloca registered under `dstName` (caller is responsible
 * for allocaDouble(dstName) before this call). `dataArgName` is the
 * symtab name of the DATA* argument (typically "data").
 *
 * Note: SCTL passes the flat realVars[] slot via absoluteSlot(...,
 * subIndex), so we index `realVars[slot]` directly. We do NOT go
 * through data->simulationInfo->realVarsIndex[slot] -- that
 * indirection is what CodegenC does to translate from a SimVar's
 * array-relative index to the flat one, but SCTL already resolved
 * the flat index at codegen time. Skipping the indirection also
 * means the inlined chain stays valid in Pass 1's smoke test, where
 * the fabricated DATA struct has data->simulationInfo == NULL.
 *
 * Replaces the omc_jit_get_real_var runtime helper -- the IR is
 * now visible to LLVM's optimizer so common subexpressions across
 * accesses (the realVars base pointer) can be hoisted. */
/* Local helper: emit the load-pointer chain that resolves
 *
 *   data->localData[0]->realVars
 *
 * leaving the realVars pointer as the returned llvm::Value. Used by
 * both read and write accessors for realVars. */
static llvm::Value *emitChainToRealVars(llvm::Value *const dataPtr) {
  llvm::Value *const localDataPP =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_localData);
  llvm::Value *const sd = emitLoadPtr(localDataPP);
  return emitGEPLoadPtr(sd, omc_layout_SD_realVars);
}

/* Local helper: emit the load-pointer chain that resolves
 *
 *   data->localData[0]->booleanVars
 *
 * leaving the booleanVars pointer (a modelica_boolean* == i32*) as the
 * returned llvm::Value. Mirror of emitChainToRealVars for the discrete
 * boolean buffer. */
static llvm::Value *emitChainToBoolVars(llvm::Value *const dataPtr) {
  llvm::Value *const localDataPP =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_localData);
  llvm::Value *const sd = emitLoadPtr(localDataPP);
  return emitGEPLoadPtr(sd, omc_layout_SD_booleanVars);
}

/* Local helper: store a value into the alloca registered under
 * `dstName` (the requested name, matching the symtab-key rule). */
static void storeIntoSymtab(const char *const dstName,
                            llvm::Value *const val) {
  Variable *const dstVar = program->currentFunc->symTab[dstName].get();
  if (!dstVar) {
    fprintf(stderr,
            "storeIntoSymtab: dst '%s' not in symtab\n", dstName);
    MMC_THROW();
  }
  llvm::AllocaInst *const dstAi = dstVar->getAllocaInst();
  program->builder.CreateStore(val, dstAi);
}

extern "C" int createInlinedReadRealVar(const char *const dataArgName,
                                        const int64_t slot,
                                        const char *const dstName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const realVars = emitChainToRealVars(dataPtr);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const valAddr = b.CreateGEP(
      dbl, realVars, llvm::ConstantInt::get(i64, slot), "");
  llvm::Value *const val = b.CreateLoad(dbl, valAddr, "");
  storeIntoSymtab(dstName, val);
  return 0;
}

/* createInlinedWriteRealVar: emit
 *
 *   data->localData[0]->realVars[slot] = <srcName>;
 *
 * Replaces the omc_jit_set_real_var runtime helper. srcName is the
 * symtab name of the double-alloca holding the value to write. */
extern "C" int createInlinedWriteRealVar(const char *const dataArgName,
                                         const int64_t slot,
                                         const char *const srcName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const realVars = emitChainToRealVars(dataPtr);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const valAddr = b.CreateGEP(
      dbl, realVars, llvm::ConstantInt::get(i64, slot), "");
  llvm::Value *const src = loadFromSymtab(srcName);
  b.CreateStore(src, valAddr);
  return 0;
}

/* createInlinedReadRealParam: emit
 *
 *   data->simulationInfo->realParameter[slot]
 *
 * into the dst alloca. Mirrors the omc_jit_get_real_param helper. */
extern "C" int createInlinedReadRealParam(const char *const dataArgName,
                                          const int64_t slot,
                                          const char *const dstName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const simInfo =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_simulationInfo);
  llvm::Value *const realParameter =
      emitGEPLoadPtr(simInfo, omc_layout_SI_realParameter);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const valAddr = b.CreateGEP(
      dbl, realParameter, llvm::ConstantInt::get(i64, slot), "");
  llvm::Value *const val = b.CreateLoad(dbl, valAddr, "");
  storeIntoSymtab(dstName, val);
  return 0;
}

/* createInlinedWriteRealParam: emit
 *
 *   data->simulationInfo->realParameter[slot] = <srcName>;
 *
 * Mirrors the omc_jit_set_real_param helper. */
extern "C" int createInlinedWriteRealParam(const char *const dataArgName,
                                           const int64_t slot,
                                           const char *const srcName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const simInfo =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_simulationInfo);
  llvm::Value *const realParameter =
      emitGEPLoadPtr(simInfo, omc_layout_SI_realParameter);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const valAddr = b.CreateGEP(
      dbl, realParameter, llvm::ConstantInt::get(i64, slot), "");
  llvm::Value *const src = loadFromSymtab(srcName);
  b.CreateStore(src, valAddr);
  return 0;
}

/* createInlinedWriteBoolParam: emit
 *
 *   data->simulationInfo->booleanParameter[slot] = (src != 0.0);
 *
 * modelica_boolean is a 32-bit int (openmodelica_types.h:106). SCTL's
 * call sites stage Modelica Booleans through a double alloca (the
 * DAE.BCONST arm in emitExp materialises 0.0 / 1.0), so we mirror
 * the runtime omc_jit_set_bool_param coercion: fcmp ONE against 0.0
 * to get an i1, zero-extend to i32, store. */
extern "C" int createInlinedWriteBoolParam(const char *const dataArgName,
                                           const int64_t slot,
                                           const char *const srcName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const simInfo =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_simulationInfo);
  llvm::Value *const boolParam =
      emitGEPLoadPtr(simInfo, omc_layout_SI_booleanParameter);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const i32 = llvm::Type::getInt32Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const valAddr = b.CreateGEP(
      i32, boolParam, llvm::ConstantInt::get(i64, slot), "");
  llvm::Value *const srcDbl = loadFromSymtab(srcName);
  llvm::Value *const zero = llvm::ConstantFP::get(dbl, 0.0);
  llvm::Value *const cmp = b.CreateFCmpONE(srcDbl, zero, "");
  llvm::Value *const cast = b.CreateZExt(cmp, i32, "");
  b.CreateStore(cast, valAddr);
  return 0;
}

/* createInlinedZcSet: emit
 *
 *   gout[idx] = src;
 *
 * where gout is a double* function argument (the third arg of the
 * model's _function_ZeroCrossings entry). Replaces omc_jit_zc_set. */
extern "C" int createInlinedZcSet(const char *const goutArgName,
                                  const int64_t idx,
                                  const char *const srcName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const goutPtr = loadFromSymtab(goutArgName);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const slotAddr = b.CreateGEP(
      dbl, goutPtr, llvm::ConstantInt::get(i64, idx), "");
  llvm::Value *const src = loadFromSymtab(srcName);
  b.CreateStore(src, slotAddr);
  return 0;
}

/* createInlinedRelationSet: emit
 *
 *   data->simulationInfo->relations[idx] = (residual > 0.0) ? 1 : 0;
 *
 * src arrives as the double residual; we map > 0.0 to 1 and <= 0.0 to
 * 0, matching omc_jit_relation_set's coercion. relations[] is an
 * array of modelica_boolean (int / i32). */
extern "C" int createInlinedRelationSet(const char *const dataArgName,
                                        const int64_t idx,
                                        const char *const srcName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const simInfo =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_simulationInfo);
  llvm::Value *const relations =
      emitGEPLoadPtr(simInfo, omc_layout_SI_relations);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const i32 = llvm::Type::getInt32Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const slotAddr = b.CreateGEP(
      i32, relations, llvm::ConstantInt::get(i64, idx), "");
  llvm::Value *const srcDbl = loadFromSymtab(srcName);
  llvm::Value *const zero = llvm::ConstantFP::get(dbl, 0.0);
  llvm::Value *const cmp = b.CreateFCmpOGT(srcDbl, zero, "");
  llvm::Value *const cast = b.CreateZExt(cmp, i32, "");
  b.CreateStore(cast, slotAddr);
  return 0;
}

/* createInlinedBoolDiscreteFromRelation: emit the body of a discrete
 * boolean equation of the shape
 *
 *   booleanVars[boolSlot] = relationhysteresis(exp1 <op> exp2)
 *
 * i.e. the IR equivalent of CodegenC's
 *
 *   modelica_boolean tmp;
 *   relationhysteresis(data, &tmp, exp1, exp2, nom1, nom2, zcIndex, Op, OpZC);
 *   data->localData[0]->booleanVars[booleanVarsIndex[boolSlot]] = tmp;
 *
 * The runtime's own relationhysteresis is `static inline` in
 * model_help.h and thus unreachable from emitted IR, so this calls the
 * external-linkage wrapper omc_jit_relationhysteresis (defined in
 * omc_jit_perform_simulation_adapter.c) which switches on opCode
 * (0=Less, 1=LessEq, 2=Greater, 3=GreaterEq) and forwards to the static
 * inline with the matching op_w / op_w_zc function pointers.
 *
 * exp1Name / exp2Name are the symtab names of double allocas holding the
 * already-lowered relation operands; nom1 / nom2 are the literal nominal
 * scale factors for those operands. The DynamicLibrarySearchGenerator
 * resolves omc_jit_relationhysteresis against omcruntime in-process. */
extern "C" int createInlinedBoolDiscreteFromRelation(
    const char *const dataArgName, const int64_t boolSlot,
    const char *const exp1Name, const char *const exp2Name,
    const double nom1, const double nom2, const int64_t zcIndex,
    const int64_t opCode) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Module &mod = *program->module;
  llvm::Type *const i32 = llvm::Type::getInt32Ty(program->context);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Type *const voidTy = llvm::Type::getVoidTy(program->context);
  llvm::PointerType *const ptrTy =
      llvm::PointerType::getUnqual(program->context);

  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  /* modelica_boolean (i32) result slot the wrapper writes through. */
  llvm::AllocaInst *const resAlloca = b.CreateAlloca(i32, nullptr, "");
  llvm::Value *const e1 = loadFromSymtab(exp1Name);
  llvm::Value *const e2 = loadFromSymtab(exp2Name);

  llvm::FunctionType *const fnTy = llvm::FunctionType::get(
      voidTy, {ptrTy, ptrTy, dbl, dbl, dbl, dbl, i32, i32}, false);
  llvm::FunctionCallee const fn =
      mod.getOrInsertFunction("omc_jit_relationhysteresis", fnTy);
  b.CreateCall(fn, {dataPtr, resAlloca, e1, e2,
                    llvm::ConstantFP::get(dbl, nom1),
                    llvm::ConstantFP::get(dbl, nom2),
                    llvm::ConstantInt::get(i32, zcIndex),
                    llvm::ConstantInt::get(i32, opCode)});

  llvm::Value *const resVal = b.CreateLoad(i32, resAlloca, "");
  llvm::Value *const boolVars = emitChainToBoolVars(dataPtr);
  llvm::Value *const slotAddr = b.CreateGEP(
      i32, boolVars, llvm::ConstantInt::get(i64, boolSlot), "");
  b.CreateStore(resVal, slotAddr);
  return 0;
}

/* createInlinedReadTime: emit
 *
 *   data->localData[0]->timeValue
 *
 * into the dst alloca. Mirrors omc_jit_get_time. timeValue is the
 * first field of SIMULATION_DATA so this collapses to two
 * pointer-chases plus a double load. */
extern "C" int createInlinedReadTime(const char *const dataArgName,
                                     const char *const dstName) {
  llvm::IRBuilder<> &b = program->builder;
  llvm::Value *const dataPtr = loadFromSymtab(dataArgName);
  llvm::Value *const localDataPP =
      emitGEPLoadPtr(dataPtr, omc_layout_DATA_localData);
  llvm::Value *const sd = emitLoadPtr(localDataPP);
  llvm::Type *const i8 = llvm::Type::getInt8Ty(program->context);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(program->context);
  llvm::Type *const dbl = llvm::Type::getDoubleTy(program->context);
  llvm::Value *const tvAddr = b.CreateGEP(
      i8, sd, llvm::ConstantInt::get(i64, omc_layout_SD_timeValue), "");
  llvm::Value *const val = b.CreateLoad(dbl, tvAddr, "");
  storeIntoSymtab(dstName, val);
  return 0;
}

/* Emit  void <modelName>_callExternalObjectDestructors(DATA*, threadData_t*)
 * into the active module as a complete standalone function. Counterpart of
 * CodegenC's functionCallExternalObjectDestructors template for the
 * no-extObj-vars case:
 *
 *   void <M>_callExternalObjectDestructors(DATA *data, threadData_t *td) {
 *     void *ext = data->simulationInfo->extObjs;
 *     if (ext) {
 *       free(ext);
 *       data->simulationInfo->extObjs = NULL;
 *     }
 *   }
 *
 * Self-contained: builds its own basic blocks and IRBuilder. Does not touch
 * program->currentFunc / program->builder beyond a local IRBuilder, so SCTL
 * can call this between regular function emissions without conflict. The
 * modelName-prefixed symbol matches CodegenC's <M>_callExternalObjectDestructors
 * so callers binding through the function pointer table see the same name. */
extern "C" int createCallExternalObjectDestructors(const char *const modelName) {
  if (!program || !program->module) {
    fprintf(stderr, "createCallExternalObjectDestructors: no active module\n");
    return 1;
  }
  llvm::LLVMContext &ctx = program->context;
  llvm::Module &mod = *program->module;

  llvm::Type *const voidTy = llvm::Type::getVoidTy(ctx);
  llvm::Type *const i8 = llvm::Type::getInt8Ty(ctx);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(ctx);
  llvm::PointerType *const ptrTy = llvm::PointerType::getUnqual(ctx);

  llvm::FunctionType *const freeTy =
      llvm::FunctionType::get(voidTy, {ptrTy}, false);
  llvm::FunctionCallee const freeFn = mod.getOrInsertFunction("free", freeTy);

  llvm::FunctionType *const fnTy =
      llvm::FunctionType::get(voidTy, {ptrTy, ptrTy}, false);
  const std::string symName =
      std::string(modelName) + "_callExternalObjectDestructors";
  if (mod.getFunction(symName)) {
    fprintf(stderr,
            "createCallExternalObjectDestructors: '%s' already defined\n",
            symName.c_str());
    return 2;
  }
  llvm::Function *const fn = llvm::Function::Create(
      fnTy, llvm::Function::ExternalLinkage, symName, mod);
  llvm::Function::arg_iterator argIt = fn->arg_begin();
  llvm::Argument *const dataArg = &*argIt++;
  dataArg->setName("data");
  (&*argIt)->setName("threadData");

  llvm::BasicBlock *const entryBB = llvm::BasicBlock::Create(ctx, "entry", fn);
  llvm::BasicBlock *const doFreeBB = llvm::BasicBlock::Create(ctx, "do_free", fn);
  llvm::BasicBlock *const doneBB = llvm::BasicBlock::Create(ctx, "done", fn);

  llvm::IRBuilder<> b(entryBB);
  /* simInfo = data->simulationInfo */
  llvm::Value *const siGep = b.CreateGEP(
      i8, dataArg, llvm::ConstantInt::get(i64, omc_layout_DATA_simulationInfo), "");
  llvm::Value *const simInfo = b.CreateLoad(ptrTy, siGep, "");
  /* extObjsAddr = &simInfo->extObjs */
  llvm::Value *const extObjsAddr = b.CreateGEP(
      i8, simInfo, llvm::ConstantInt::get(i64, omc_layout_SI_extObjs), "");
  llvm::Value *const extObjs = b.CreateLoad(ptrTy, extObjsAddr, "");
  llvm::Value *const isNonNull = b.CreateICmpNE(
      extObjs, llvm::ConstantPointerNull::get(ptrTy), "");
  b.CreateCondBr(isNonNull, doFreeBB, doneBB);

  b.SetInsertPoint(doFreeBB);
  b.CreateCall(freeFn, {extObjs});
  b.CreateStore(llvm::ConstantPointerNull::get(ptrTy), extObjsAddr);
  b.CreateBr(doneBB);

  b.SetInsertPoint(doneBB);
  b.CreateRetVoid();

  return 0;
}

/* Flip a named function's linkage to linkonce_odr. Used by SCTL to mark
 * a stub that intentionally coexists with a CodegenC-emitted strong
 * version of the same symbol -- when both arrive at llvm-link the
 * strong (external) definition wins and ours is discarded, but our IR
 * is positioned to take over once CodegenC stops emitting that symbol.
 * Returns 0 on success, non-zero if the function is not present in the
 * active module (caller likely passed a typo). */
extern "C" int setFunctionLinkonceOdr(const char *const fname) {
  if (!program || !program->module) {
    fprintf(stderr, "setFunctionLinkonceOdr: no active module\n");
    return 1;
  }
  llvm::Function *const fn = program->module->getFunction(fname);
  if (!fn) {
    fprintf(stderr, "setFunctionLinkonceOdr: function '%s' not in module\n",
            fname);
    return 2;
  }
  fn->setLinkage(llvm::GlobalValue::LinkOnceODRLinkage);
  return 0;
}

/* ------------------------------------------------------------------------ *
 * Callback function-pointer struct emission.
 *
 * Emits  @<Model>_callback = linkonce_odr global  matching the C struct
 * `struct OpenModelicaGeneratedFunctionCallbacks` declared in
 * openmodelica_func.h. The layout is taken straight from
 * llvm_gen_layout.c's `omc_layout_callback_<field>` offsetof exports,
 * so the IR initializer always tracks the runtime header without
 * duplicating struct knowledge here.
 *
 * Encoding strategy: a packed anonymous struct whose elements alternate
 *   [pad x i8] zeroinitializer
 *   <typed field value at offset O>
 * with the trailing pad sized so the total struct equals
 * omc_layout_callback_total. linkonce_odr lets the global coexist with
 * the CodegenC-emitted `<Model>_callback` until that template emission
 * goes away.
 * ------------------------------------------------------------------------ */

namespace {

struct CbField {
  size_t offset;
  llvm::Constant *value;
};

static llvm::Constant *cbFnPtr(llvm::Module &mod, const std::string &sym) {
  /* All callback function pointers carry void(...) signatures at the
   * IR level -- opaque pointers strip the parameter types from the
   * function-pointer constants, and the real signatures live on the
   * call sites in CodegenC bitcode. getOrInsertFunction with a stable
   * shared FunctionType keeps the symbol unique without forcing us to
   * reproduce 70 individual function-pointer signatures here. */
  llvm::LLVMContext &ctx = mod.getContext();
  llvm::FunctionType *const fnTy = llvm::FunctionType::get(
      llvm::Type::getVoidTy(ctx), /*isVarArg=*/false);
  llvm::FunctionCallee callee = mod.getOrInsertFunction(sym, fnTy);
  return llvm::cast<llvm::Constant>(callee.getCallee());
}

static llvm::Constant *cbNullPtr(llvm::LLVMContext &ctx) {
  return llvm::ConstantPointerNull::get(llvm::PointerType::getUnqual(ctx));
}

static llvm::Constant *cbI32(llvm::LLVMContext &ctx, int v) {
  return llvm::ConstantInt::get(llvm::Type::getInt32Ty(ctx), v, /*signed=*/true);
}

static void cbAddPtr(std::vector<CbField> &out, size_t offset,
                     llvm::Module &mod, const std::string &symOrEmpty,
                     bool isNull) {
  out.push_back({offset, isNull ? cbNullPtr(mod.getContext())
                                : cbFnPtr(mod, symOrEmpty)});
}

static void cbAddI32(std::vector<CbField> &out, size_t offset,
                     llvm::LLVMContext &ctx, int value) {
  out.push_back({offset, cbI32(ctx, value)});
}

} // anonymous namespace

extern "C" int createCallbackTable(const char *const modelName,
                                   const int isFmu,
                                   const int hasNlsSystems,
                                   const int hasLsSystems,
                                   const int hasMsSystems,
                                   const int hasInitialLambda0,
                                   const int homotopyMethodCode) {
  if (!program || !program->module) {
    fprintf(stderr, "createCallbackTable: no active module\n");
    return 1;
  }
  llvm::LLVMContext &ctx = program->context;
  llvm::Module &mod = *program->module;
  const std::string p(modelName);

  std::vector<CbField> fields;

  /* Function-pointer fields. The `isFmu` flag and the four "has*" flags
   * mirror the conditionals CodegenC weaves into the .c initializer.
   * isFmu == true clears the simulation-driving entries; the FMI
   * runtime supplies its own driver.
   *
   * The three solver-driver slots
   * (performSimulation / performQSSSimulation / updateContinuousSystem)
   * point at the non-prefixed omc_jit_* adapters defined in
   * omc_jit_perform_simulation_adapter.c rather than at per-model
   * <Model>_*. That way SCTL does not have to emit 600 lines of
   * solver IR per model, and the CodegenC <Model>.c suppression
   * (roadmap step 8) does not lose these symbols. */
  cbAddPtr(fields, omc_layout_callback_performSimulation,
           mod, "omc_jit_performSimulation",      isFmu);
  cbAddPtr(fields, omc_layout_callback_performQSSSimulation,
           mod, "omc_jit_performQSSSimulation",   isFmu);
  cbAddPtr(fields, omc_layout_callback_updateContinuousSystem,
           mod, "omc_jit_updateContinuousSystem", isFmu);
  cbAddPtr(fields, omc_layout_callback_callExternalObjectDestructors,
           mod, p + "_callExternalObjectDestructors", false);
  cbAddPtr(fields, omc_layout_callback_initialNonLinearSystem,
           mod, p + "_initialNonLinearSystem", !hasNlsSystems);
  cbAddPtr(fields, omc_layout_callback_initialLinearSystem,
           mod, p + "_initialLinearSystem",    !hasLsSystems);
  cbAddPtr(fields, omc_layout_callback_initialMixedSystem,
           mod, p + "_initialMixedSystem",     !hasMsSystems);
  cbAddPtr(fields, omc_layout_callback_initializeStateSets,
           mod, p + "_initializeStateSets",    false);
  cbAddPtr(fields, omc_layout_callback_initializeDAEmodeData,
           mod, p + "_initializeDAEmodeData",  false);
  cbAddPtr(fields, omc_layout_callback_getDAG_ODE,
           mod, p + "_ODE_DAG",                false);
  cbAddPtr(fields, omc_layout_callback_functionODE,
           mod, p + "_functionODE",            false);
  cbAddPtr(fields, omc_layout_callback_functionAlgebraics,
           mod, p + "_functionAlgebraics",     false);
  cbAddPtr(fields, omc_layout_callback_functionDAE,
           mod, p + "_functionDAE",            false);
  cbAddPtr(fields, omc_layout_callback_functionLocalKnownVars,
           mod, p + "_functionLocalKnownVars", false);
  cbAddPtr(fields, omc_layout_callback_input_function,
           mod, p + "_input_function",         false);
  cbAddPtr(fields, omc_layout_callback_input_function_init,
           mod, p + "_input_function_init",    false);
  cbAddPtr(fields, omc_layout_callback_input_function_updateStartValues,
           mod, p + "_input_function_updateStartValues", false);
  cbAddPtr(fields, omc_layout_callback_data_function,
           mod, p + "_data_function",          false);
  cbAddPtr(fields, omc_layout_callback_output_function,
           mod, p + "_output_function",        false);
  cbAddPtr(fields, omc_layout_callback_setc_function,
           mod, p + "_setc_function",          false);
  cbAddPtr(fields, omc_layout_callback_setb_function,
           mod, p + "_setb_function",          false);
  cbAddPtr(fields, omc_layout_callback_function_storeDelayed,
           mod, p + "_function_storeDelayed",  false);
  cbAddPtr(fields, omc_layout_callback_function_storeSpatialDistribution,
           mod, p + "_function_storeSpatialDistribution", false);
  cbAddPtr(fields, omc_layout_callback_function_initSpatialDistribution,
           mod, p + "_function_initSpatialDistribution",  false);
  cbAddPtr(fields, omc_layout_callback_updateBoundVariableAttributes,
           mod, p + "_updateBoundVariableAttributes", false);
  cbAddPtr(fields, omc_layout_callback_functionInitialEquations,
           mod, p + "_functionInitialEquations", false);

  /* homotopyMethod is HOMOTOPY_METHOD enum -- a plain int. The caller
   * passes the runtime's numeric value (0 = LOCAL_EQUIDISTANT, ...). */
  cbAddI32(fields, omc_layout_callback_homotopyMethod, ctx, homotopyMethodCode);

  cbAddPtr(fields, omc_layout_callback_functionInitialEquations_lambda0,
           mod, p + "_functionInitialEquations_lambda0", !hasInitialLambda0);
  cbAddPtr(fields, omc_layout_callback_functionRemovedInitialEquations,
           mod, p + "_functionRemovedInitialEquations", false);
  cbAddPtr(fields, omc_layout_callback_updateBoundParameters,
           mod, p + "_updateBoundParameters",  false);
  cbAddPtr(fields, omc_layout_callback_checkForAsserts,
           mod, p + "_checkForAsserts",        false);
  cbAddPtr(fields, omc_layout_callback_function_ZeroCrossingsEquations,
           mod, p + "_function_ZeroCrossingsEquations", false);
  cbAddPtr(fields, omc_layout_callback_function_ZeroCrossings,
           mod, p + "_function_ZeroCrossings", false);
  cbAddPtr(fields, omc_layout_callback_function_updateRelations,
           mod, p + "_function_updateRelations", false);
  cbAddPtr(fields, omc_layout_callback_zeroCrossingDescription,
           mod, p + "_zeroCrossingDescription", false);
  cbAddPtr(fields, omc_layout_callback_relationDescription,
           mod, p + "_relationDescription",    false);
  cbAddPtr(fields, omc_layout_callback_function_initSample,
           mod, p + "_function_initSample",    false);

  /* The seven INDEX_JAC_* fields are const ints; CodegenC reads them
   * from <Model>_INDEX_JAC_* macros that expand to 0, 1, ... For
   * HelloWorld there is no analytic Jacobian, so the runtime never
   * indexes through them -- zero is the safe sentinel either way. */
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_A,   ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_ADJ, ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_B,   ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_C,   ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_D,   ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_F,   ctx, 0);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_H,   ctx, 0);

  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianA,
           mod, p + "_initialAnalyticJacobianA",   false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianADJ,
           mod, p + "_initialAnalyticJacobianADJ", false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianB,
           mod, p + "_initialAnalyticJacobianB",   false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianC,
           mod, p + "_initialAnalyticJacobianC",   false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianD,
           mod, p + "_initialAnalyticJacobianD",   false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianF,
           mod, p + "_initialAnalyticJacobianF",   false);
  cbAddPtr(fields, omc_layout_callback_initialAnalyticJacobianH,
           mod, p + "_initialAnalyticJacobianH",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacA_column,
           mod, p + "_functionJacA_column",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacADJ_column,
           mod, p + "_functionJacADJ_column", false);
  cbAddPtr(fields, omc_layout_callback_functionJacB_column,
           mod, p + "_functionJacB_column",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacC_column,
           mod, p + "_functionJacC_column",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacD_column,
           mod, p + "_functionJacD_column",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacF_column,
           mod, p + "_functionJacF_column",   false);
  cbAddPtr(fields, omc_layout_callback_functionJacH_column,
           mod, p + "_functionJacH_column",   false);
  cbAddPtr(fields, omc_layout_callback_getDAG_JacA,
           mod, p + "_JacA_DAG",              false);
  cbAddPtr(fields, omc_layout_callback_linear_model_frame,
           mod, p + "_linear_model_frame",    false);
  cbAddPtr(fields, omc_layout_callback_linear_model_datarecovery_frame,
           mod, p + "_linear_model_datarecovery_frame", false);
  cbAddPtr(fields, omc_layout_callback_mayer,
           mod, p + "_mayer",                 false);
  cbAddPtr(fields, omc_layout_callback_lagrange,
           mod, p + "_lagrange",              false);
  cbAddPtr(fields, omc_layout_callback_getInputVarIndicesInOptimization,
           mod, p + "_getInputVarIndicesInOptimization", false);
  cbAddPtr(fields, omc_layout_callback_pickUpBoundsForInputsInOptimization,
           mod, p + "_pickUpBoundsForInputsInOptimization", false);
  cbAddPtr(fields, omc_layout_callback_setInputData,
           mod, p + "_setInputData",          false);
  cbAddPtr(fields, omc_layout_callback_getTimeGrid,
           mod, p + "_getTimeGrid",           false);
  cbAddPtr(fields, omc_layout_callback_symbolicInlineSystems,
           mod, p + "_symbolicInlineSystem",  false);
  cbAddPtr(fields, omc_layout_callback_function_initSynchronous,
           mod, p + "_function_initSynchronous",    false);
  cbAddPtr(fields, omc_layout_callback_function_updateSynchronous,
           mod, p + "_function_updateSynchronous",  false);
  cbAddPtr(fields, omc_layout_callback_function_equationsSynchronous,
           mod, p + "_function_equationsSynchronous", false);
  cbAddPtr(fields, omc_layout_callback_inputNames,
           mod, p + "_inputNames",            false);
  cbAddPtr(fields, omc_layout_callback_dataReconciliationInputNames,
           mod, p + "_dataReconciliationInputNames", false);
  cbAddPtr(fields, omc_layout_callback_dataReconciliationUnmeasuredVariables,
           mod, p + "_dataReconciliationUnmeasuredVariables", false);

  /* FMI fields. read_simulation_info / read_input_fmu only matter for
   * Model-Exchange FMUs; the JIT-simulate path is always non-FMU
   * today, so NULL is correct here. The FMIDER jacobian fields take
   * the same treatment -- the runtime only consults them when
   * modelStructure carries the corresponding partial derivatives. */
  cbAddPtr(fields, omc_layout_callback_read_simulation_info, mod, "", true);
  cbAddPtr(fields, omc_layout_callback_read_input_fmu,       mod, "", true);
  cbAddPtr(fields, omc_layout_callback_initialPartialFMIDER, mod, "", true);
  cbAddPtr(fields, omc_layout_callback_functionJacFMIDER_column, mod, "", true);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_FMIDER, ctx, -1);
  cbAddPtr(fields, omc_layout_callback_initialPartialFMIDERINIT, mod, "", true);
  cbAddPtr(fields, omc_layout_callback_functionJacFMIDERINIT_column, mod, "", true);
  cbAddI32(fields, omc_layout_callback_INDEX_JAC_FMIDERINIT, ctx, -1);

  /* Compose the packed struct, padding the gaps between named offsets
   * with i8 zeros so the total size equals
   * omc_layout_callback_total. fields are added in declaration order,
   * so a stable sort by offset is a safety net rather than a
   * requirement. */
  std::sort(fields.begin(), fields.end(),
            [](const CbField &a, const CbField &b) { return a.offset < b.offset; });

  llvm::Type *const i8Ty = llvm::Type::getInt8Ty(ctx);
  std::vector<llvm::Type *> elemTys;
  std::vector<llvm::Constant *> elemVals;
  size_t cursor = 0;
  auto sizeOfConst = [&](llvm::Constant *const c) -> size_t {
    llvm::Type *const t = c->getType();
    if (t->isPointerTy()) return 8;
    if (t->isIntegerTy()) return (t->getIntegerBitWidth() + 7) / 8;
    fprintf(stderr,
            "createCallbackTable: unsupported field type, cannot size\n");
    return 0;
  };
  for (const CbField &f : fields) {
    if (f.offset < cursor) {
      fprintf(stderr,
              "createCallbackTable: field offset %zu < cursor %zu "
              "(layout mismatch)\n",
              f.offset, cursor);
      return 2;
    }
    if (f.offset > cursor) {
      const size_t pad = f.offset - cursor;
      llvm::ArrayType *const padTy = llvm::ArrayType::get(i8Ty, pad);
      elemTys.push_back(padTy);
      elemVals.push_back(llvm::ConstantAggregateZero::get(padTy));
      cursor = f.offset;
    }
    elemTys.push_back(f.value->getType());
    elemVals.push_back(f.value);
    cursor += sizeOfConst(f.value);
  }
  if (cursor < omc_layout_callback_total) {
    const size_t pad = omc_layout_callback_total - cursor;
    llvm::ArrayType *const padTy = llvm::ArrayType::get(i8Ty, pad);
    elemTys.push_back(padTy);
    elemVals.push_back(llvm::ConstantAggregateZero::get(padTy));
  } else if (cursor > omc_layout_callback_total) {
    fprintf(stderr,
            "createCallbackTable: composed size %zu exceeds layout total %zu\n",
            cursor, omc_layout_callback_total);
    return 3;
  }

  llvm::StructType *const stTy =
      llvm::StructType::get(ctx, elemTys, /*isPacked=*/true);
  llvm::Constant *const init = llvm::ConstantStruct::get(stTy, elemVals);
  const std::string globalName = p + "_callback";
  if (mod.getNamedGlobal(globalName)) {
    fprintf(stderr,
            "createCallbackTable: '%s' already defined\n", globalName.c_str());
    return 4;
  }
  new llvm::GlobalVariable(mod, stTy, /*isConstant=*/false,
                           llvm::GlobalValue::LinkOnceODRLinkage, init,
                           globalName);
  return 0;
}

/* ------------------------------------------------------------------------ *
 * setupDataStruc full body emission.
 *
 * Builds on the shell (callback + localRoots wires) by emitting the
 * full sequence of  data->modelData->n<Counter> = <Value>  stores in
 * the canonical order declared in llvm_gen_layout.c's
 * omc_modeldata_int_offsets[]. The Modelica side passes the matching
 * 41 counter values as a flat list<Integer>; the helper walks the
 * MMC list and the offset table in lock-step, emitting one i64 store
 * per (offset, value) pair.
 *
 * Skips: assertStreamPrint(threadData, ...), the modelName / modelGUID
 * string assignments (diagnostic), the XML data pointers (NULL is
 * correct for runtime-from-file mode), the OpenModelica_updateUriMapping
 * call with the resource literal (resource lookups are inactive for
 * the JIT simulate path today), modelDataXml.* (the runtime
 * populates these via the on-disk _info.json read), and the
 * linearizationDumpLanguage enum store (defaults are fine for ODE
 * simulation).
 *
 * Returns 0 on success.
 * ------------------------------------------------------------------------ */

namespace {

/* Walk a MetaModelica `list<Integer>` pulling out small fixnums as
 * `long`. The MMC encoding tags fixnums in the low bits so
 * MMC_UNTAGFIXNUM yields the underlying long. Returns the number of
 * elements appended. */
static size_t collectMmcIntList(void *lst, std::vector<long> &out) {
  size_t n = 0;
  while (lst && MMC_GETHDR(lst) == MMC_CONSHDR) {
    out.push_back(MMC_UNTAGFIXNUM(MMC_CAR(lst)));
    lst = MMC_CDR(lst);
    ++n;
  }
  return n;
}

} // anonymous namespace

extern "C" int createSetupDataStrucFull(const char *const modelName,
                                        void *const counters) {
  if (!program || !program->module) {
    fprintf(stderr, "createSetupDataStrucFull: no active module\n");
    return 1;
  }
  llvm::LLVMContext &ctx = program->context;
  llvm::Module &mod = *program->module;

  std::vector<long> counterValues;
  collectMmcIntList(counters, counterValues);
  if (counterValues.size() != omc_modeldata_int_count) {
    fprintf(stderr,
            "createSetupDataStrucFull: counter list length %zu != "
            "expected %zu (layout / Modelica side out of sync)\n",
            counterValues.size(), omc_modeldata_int_count);
    return 2;
  }

  llvm::Type *const voidTy = llvm::Type::getVoidTy(ctx);
  llvm::Type *const i8 = llvm::Type::getInt8Ty(ctx);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(ctx);
  llvm::PointerType *const ptrTy = llvm::PointerType::getUnqual(ctx);

  llvm::FunctionType *const fnTy =
      llvm::FunctionType::get(voidTy, {ptrTy, ptrTy}, false);
  const std::string symName =
      std::string(modelName) + "_setupDataStruc";
  if (mod.getFunction(symName)) {
    fprintf(stderr,
            "createSetupDataStrucFull: '%s' already defined\n",
            symName.c_str());
    return 3;
  }
  llvm::Function *const fn = llvm::Function::Create(
      fnTy, llvm::Function::LinkOnceODRLinkage, symName, mod);
  llvm::Function::arg_iterator argIt = fn->arg_begin();
  llvm::Argument *const dataArg = &*argIt++;
  dataArg->setName("data");
  llvm::Argument *const tdArg = &*argIt;
  tdArg->setName("threadData");

  llvm::BasicBlock *const entryBB = llvm::BasicBlock::Create(ctx, "entry", fn);
  llvm::IRBuilder<> b(entryBB);

  /* The two critical pointer wires (same as the old shell). */
  const size_t lrSlotOffset =
      omc_layout_TD_localRoots +
      static_cast<size_t>(omc_value_LOCAL_ROOT_SIMULATION_DATA) * 8;
  llvm::Value *const lrAddr = b.CreateGEP(
      i8, tdArg, llvm::ConstantInt::get(i64, lrSlotOffset), "lrAddr");
  b.CreateStore(dataArg, lrAddr);

  const std::string callbackGlobal = std::string(modelName) + "_callback";
  llvm::GlobalVariable *const cbGV = mod.getNamedGlobal(callbackGlobal);
  if (!cbGV) {
    fprintf(stderr,
            "createSetupDataStrucFull: callback global '%s' missing\n",
            callbackGlobal.c_str());
    return 4;
  }
  llvm::Value *const cbAddr = b.CreateGEP(
      i8, dataArg, llvm::ConstantInt::get(i64, omc_layout_DATA_callback),
      "cbAddr");
  b.CreateStore(cbGV, cbAddr);

  /* modelData = data->modelData (one load). All counter stores chain
   * off this pointer rather than re-walking data->modelData each
   * time -- LLVM would CSE the loads anyway, but the IR reads cleaner
   * with the explicit hoist. */
  llvm::Value *const mdSlot = b.CreateGEP(
      i8, dataArg, llvm::ConstantInt::get(i64, omc_layout_DATA_modelData),
      "mdSlot");
  llvm::Value *const mdPtr = b.CreateLoad(ptrTy, mdSlot, "mdPtr");

  /* Counter stores. modelData fields are `long` -- 8 bytes on x86-64.
   * MMC fixnums fit into long without truncation for the count values
   * any sensible Modelica model produces. */
  for (size_t i = 0; i < omc_modeldata_int_count; ++i) {
    llvm::Value *const fieldAddr = b.CreateGEP(
        i8, mdPtr,
        llvm::ConstantInt::get(i64, omc_modeldata_int_offsets[i]), "");
    b.CreateStore(llvm::ConstantInt::get(i64, counterValues[i]), fieldAddr);
  }

  b.CreateRetVoid();
  return 0;
}

/* ------------------------------------------------------------------------ *
 * setupDataStruc shell emission.
 *
 * Emits the two critical pointer wire-ups every model's setupDataStruc
 * performs, as a linkonce_odr  void <Model>_setupDataStruc(DATA*,
 * threadData_t*)  function:
 *
 *   threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data;
 *   data->callback = &<Model>_callback;
 *
 * The remaining ~70 modelData scalar / string assignments CodegenC
 * emits are intentionally omitted: they are accessed by various
 * runtime functions during simulation, and the linkonce_odr CodegenC
 * copy still wins at llvm-link today, so the model still gets its
 * fully-initialized modelData via the C path. This shell is the IR
 * scaffolding for the future commit that lifts the full body (steps
 * 4-5 of the roadmap). Once CodegenC stops emitting the strong copy,
 * this shell will need to grow the remaining stores.
 *
 * Returns 0 on success, non-zero on duplicate / missing module.
 * ------------------------------------------------------------------------ */
extern "C" int createSetupDataStrucShell(const char *const modelName) {
  if (!program || !program->module) {
    fprintf(stderr, "createSetupDataStrucShell: no active module\n");
    return 1;
  }
  llvm::LLVMContext &ctx = program->context;
  llvm::Module &mod = *program->module;

  llvm::Type *const voidTy = llvm::Type::getVoidTy(ctx);
  llvm::Type *const i8 = llvm::Type::getInt8Ty(ctx);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(ctx);
  llvm::PointerType *const ptrTy = llvm::PointerType::getUnqual(ctx);

  llvm::FunctionType *const fnTy =
      llvm::FunctionType::get(voidTy, {ptrTy, ptrTy}, false);
  const std::string symName =
      std::string(modelName) + "_setupDataStruc";
  if (mod.getFunction(symName)) {
    fprintf(stderr,
            "createSetupDataStrucShell: '%s' already defined\n",
            symName.c_str());
    return 2;
  }
  llvm::Function *const fn = llvm::Function::Create(
      fnTy, llvm::Function::LinkOnceODRLinkage, symName, mod);
  llvm::Function::arg_iterator argIt = fn->arg_begin();
  llvm::Argument *const dataArg = &*argIt++;
  dataArg->setName("data");
  llvm::Argument *const tdArg = &*argIt;
  tdArg->setName("threadData");

  llvm::BasicBlock *const entryBB = llvm::BasicBlock::Create(ctx, "entry", fn);
  llvm::IRBuilder<> b(entryBB);

  /* threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data
   *
   * Offset = offsetof(threadData_t, localRoots) + index * sizeof(void*).
   * sizeof(void*) = 8 on every target the JIT supports today. */
  const size_t lrSlotOffset =
      omc_layout_TD_localRoots +
      static_cast<size_t>(omc_value_LOCAL_ROOT_SIMULATION_DATA) * 8;
  llvm::Value *const lrAddr = b.CreateGEP(
      i8, tdArg, llvm::ConstantInt::get(i64, lrSlotOffset), "lrAddr");
  b.CreateStore(dataArg, lrAddr);

  /* data->callback = &<Model>_callback */
  const std::string callbackGlobal = std::string(modelName) + "_callback";
  llvm::GlobalVariable *const cbGV = mod.getNamedGlobal(callbackGlobal);
  if (!cbGV) {
    /* createCallbackTable should have emitted this earlier in the same
     * Pass-2 walk; tolerating its absence would emit a setupDataStruc
     * whose callback wire-up was silently NULL. */
    fprintf(stderr,
            "createSetupDataStrucShell: callback global '%s' missing\n",
            callbackGlobal.c_str());
    return 3;
  }
  llvm::Value *const cbAddr = b.CreateGEP(
      i8, dataArg, llvm::ConstantInt::get(i64, omc_layout_DATA_callback),
      "cbAddr");
  b.CreateStore(cbGV, cbAddr);

  b.CreateRetVoid();
  return 0;
}

/* ------------------------------------------------------------------------ *
 * main() shim emission.
 *
 * Emits  int main(int argc, char **argv)  whose body is:
 *   alloca MODEL_DATA  (omc_sizeof_MODEL_DATA bytes)
 *   alloca SIMULATION_INFO (omc_sizeof_SIMULATION_INFO bytes)
 *   return omc_jit_main_runtime(argc, argv, &modelData, &simInfo,
 *                               &<Model>_setupDataStruc);
 *
 * The heavy lifting (omc_assert reassignments, MMC_INIT,
 * omc_alloc_interface.init, MMC_TRY_TOP / MMC_TRY_STACK setjmp dance,
 * _main_initRuntimeAndSimulation + _main_SimulationRuntime sequence)
 * lives in omc_jit_main_runtime inside
 * omc_jit_perform_simulation_adapter.c -- impractical to lift line-by-
 * line into IR, trivial as a single extern call. The DATA struct is
 * stack-allocated inside the adapter so the threadData_t setup
 * (which the MMC_TRY_TOP macro does) happens in the same frame.
 *
 * Linkage starts as linkonce_odr so the shim coexists with the
 * CodegenC strong main while the llvm-jit cutover is gated; flipping
 * to external linkage is a one-line change once the gate in
 * SimCodeMain flips and <Model>.c stops being emitted.
 *
 * Returns 0 on success.
 * ------------------------------------------------------------------------ */
extern "C" int createMainShim(const char *const modelName) {
  if (!program || !program->module) {
    fprintf(stderr, "createMainShim: no active module\n");
    return 1;
  }
  llvm::LLVMContext &ctx = program->context;
  llvm::Module &mod = *program->module;

  llvm::Type *const i8 = llvm::Type::getInt8Ty(ctx);
  llvm::Type *const i32 = llvm::Type::getInt32Ty(ctx);
  llvm::Type *const i64 = llvm::Type::getInt64Ty(ctx);
  llvm::PointerType *const ptrTy = llvm::PointerType::getUnqual(ctx);
  llvm::Type *const voidTy = llvm::Type::getVoidTy(ctx);

  if (mod.getFunction("main")) {
    fprintf(stderr, "createMainShim: 'main' already defined\n");
    return 2;
  }

  llvm::FunctionType *const mainTy =
      llvm::FunctionType::get(i32, {i32, ptrTy}, false);
  llvm::Function *const mainFn = llvm::Function::Create(
      mainTy, llvm::Function::LinkOnceODRLinkage, "main", mod);
  llvm::Function::arg_iterator argIt = mainFn->arg_begin();
  llvm::Argument *const argcArg = &*argIt++;
  argcArg->setName("argc");
  llvm::Argument *const argvArg = &*argIt;
  argvArg->setName("argv");

  llvm::BasicBlock *const entryBB =
      llvm::BasicBlock::Create(ctx, "entry", mainFn);
  llvm::IRBuilder<> b(entryBB);

  /* Stack-alloc the model-state structs the adapter needs. DATA itself
   * lives inside omc_jit_main_runtime so the MMC_TRY_TOP setjmp dance
   * and the DATA's threadData reference share the same stack frame. */
  llvm::AllocaInst *const modelDataAlloca = b.CreateAlloca(
      i8, llvm::ConstantInt::get(i64, omc_sizeof_MODEL_DATA), "modelData");
  modelDataAlloca->setAlignment(llvm::Align(8));
  llvm::AllocaInst *const simInfoAlloca = b.CreateAlloca(
      i8, llvm::ConstantInt::get(i64, omc_sizeof_SIMULATION_INFO), "simInfo");
  simInfoAlloca->setAlignment(llvm::Align(8));

  /* Get-or-insert the per-model setupDataStruc and the generic
   * omc_jit_main_runtime adapter. */
  llvm::FunctionType *const setupTy =
      llvm::FunctionType::get(voidTy, {ptrTy, ptrTy}, false);
  const std::string setupName =
      std::string(modelName) + "_setupDataStruc";
  llvm::FunctionCallee setupCallee =
      mod.getOrInsertFunction(setupName, setupTy);

  /* Emit private string constants for the three model-identifier
   * strings the adapter needs (the modelGUID is read out of
   * <prefix>_init.xml by the adapter itself, so the shim does not
   * pass it). */
  auto emitStr = [&](const std::string &val, const std::string &name)
      -> llvm::Constant * {
    llvm::Constant *const init =
        llvm::ConstantDataArray::getString(ctx, val, /*addNull=*/true);
    llvm::GlobalVariable *const gv = new llvm::GlobalVariable(
        mod, init->getType(), /*isConstant=*/true,
        llvm::GlobalValue::PrivateLinkage, init, name);
    gv->setUnnamedAddr(llvm::GlobalValue::UnnamedAddr::Global);
    return gv;
  };
  const std::string p(modelName);
  llvm::Constant *const sName = emitStr(p, p + "_jit_modelName");
  llvm::Constant *const sPrefix = emitStr(p, p + "_jit_modelPrefix");
  llvm::Constant *const sJson =
      emitStr(p + "_info.json", p + "_jit_jsonFile");

  llvm::FunctionType *const adapterTy = llvm::FunctionType::get(
      i32, {i32, ptrTy, ptrTy, ptrTy, ptrTy, ptrTy, ptrTy, ptrTy},
      false);
  llvm::FunctionCallee adapterCallee =
      mod.getOrInsertFunction("omc_jit_main_runtime", adapterTy);

  llvm::CallInst *const res = b.CreateCall(
      adapterCallee,
      {argcArg, argvArg, modelDataAlloca, simInfoAlloca,
       llvm::cast<llvm::Constant>(setupCallee.getCallee()),
       sName, sPrefix, sJson},
      "res");
  b.CreateRet(res);

  return 0;
}

/* Process-global bitcode buffer stashed by SimCodeToLLVM. Consumed (cleared)
 * by omc_runModelViaJIT so each model run starts from a clean slate. The
 * buffer is the in-memory replacement for the transient <prefix>_sctl.bc
 * disk file. */
static std::vector<char> g_sctlBitcodeBytes;

int stashCurrentModuleAsBitcode() {
  if (!program || !program->module) {
    fprintf(stderr, "stashCurrentModuleAsBitcode: no module to serialise\n");
    return 1;
  }
  llvm::SmallVector<char, 0> buf;
  {
    llvm::raw_svector_ostream out(buf);
    llvm::WriteBitcodeToFile(*program->module, out);
  }
  g_sctlBitcodeBytes.assign(buf.begin(), buf.end());
  return 0;
}

/* ------------------------------------------------------------------------ *
 * Model simulation via LLVM JIT.
 *
 * Counterpart of the function JIT (top_level_expression) above, but for a
 * whole simulation model. The model's regular C code (CodegenC output) is
 * compiled to LLVM bitcode and linked into a single module ahead of time
 * (clang -emit-llvm + llvm-link); this entry loads that bitcode, JIT-compiles
 * it with ORC v2 LLJIT and runs its main() in-process — the same main() the
 * compiled executable would run, which wires up the DATA struct and calls
 * _main_SimulationRuntime, writing the .mat result file.
 *
 * The generated model only *references* the simulation runtime (solver,
 * result writer, ...); those symbols live in libSimulationRuntimeC, which omc
 * does not itself link. `runtimeLib` is therefore loaded into the process so
 * the JIT can resolve the model's external references against it.
 *
 * Uses a private LLJIT instance (not the `program` one used for function
 * evaluation) so model simulation is independent of any in-flight function
 * JIT state. Returns the model main()'s exit code (0 == success), or a
 * non-zero status on a JIT setup failure. No C++ exceptions are used; LLVM's
 * Error/Expected values are consumed explicitly.
 * ------------------------------------------------------------------------ */
/* Absolute path of the LLVM tools directory omc was configured against
 * (clang, llvm-link, ...). Baked in at configure time via OMC_LLVM_TOOLS_DIR.
 * The MetaModelica side uses this to invoke the *matching* clang/llvm-link
 * when lowering a model's C to bitcode, independent of the configured CC
 * (which may be gcc and unable to emit LLVM bitcode). Empty if unknown. */
const char *omc_getLLVMToolsDir() {
#ifdef OMC_LLVM_TOOLS_DIR
  return OMC_LLVM_TOOLS_DIR;
#else
  return "";
#endif
}

/* Per-omc-session JIT cache. Keyed on modelName -- a second
 * simulate() of the same model in the same omc process reuses
 * the already-materialized LLJIT and skips parseIRFile +
 * LLJITBuilder + addIRModule + first-fire codegen entirely. The
 * dominant cost of a hot-cache call is the model's own runtime
 * loop, not the JIT plumbing.
 *
 * Cache key is modelName alone, NOT the bitcode bytes. The bytes
 * change between back-to-back simulate() calls even when the
 * source is unchanged, because CodegenC's template stamps a
 * fresh modelGUID UUID into the generated C (see
 * Compiler/Template/CodegenC.tpl, the
 *   data->modelData->modelGUID = "{<%guid%>}";
 * line) and the UUID flows into the linked bitcode as a string
 * literal. A byte-fingerprint cache would never hit.
 *
 * The modelName-only key is safe because omc's interactive flow
 * re-runs translateModel + buildModel when the user actually
 * edits the model, so any stale cache entry from a prior
 * simulate() of an edited model is superseded before it can be
 * re-hit. If a future caller wants byte-level invalidation, the
 * right hook is upstream: feed the SimCode SHA (or the source
 * file mtime) into the key. The bitcode itself is not a useful
 * fingerprint as long as CodegenC re-rolls the GUID per emit.
 *
 * Single-process, per-omc-session, no on-disk persistence
 * (omc's exit tears down the map). The map owns the LLJIT via
 * unique_ptr; raw pointers are only used inside lookup +
 * invocation. */
static std::unordered_map<std::string, std::unique_ptr<llvm::orc::LLJIT>>
    g_jitCache;

/* Forward declarations of the perform_simulation adapter entry points
 * defined in omc_jit_perform_simulation_adapter.c. The JIT looks them
 * up by name via DynamicLibrarySearchGenerator(GetForCurrentProcess);
 * without a hard reference here the static-archive linker drops the
 * adapter .o because nothing in the omc binary calls them directly.
 * The kForceLink table below pulls the .o into the final link. */
extern "C" int omc_jit_performSimulation(struct DATA *, struct threadData_s *, void *);
extern "C" int omc_jit_performQSSSimulation(struct DATA *, struct threadData_s *, void *);
extern "C" void omc_jit_updateContinuousSystem(struct DATA *, struct threadData_s *);
extern "C" int omc_jit_main_runtime(int, char **, void *, void *, void *,
                                    const char *, const char *,
                                    const char *);
extern "C" void omc_jit_relationhysteresis(struct DATA *, void *, double, double,
                                           double, double, int, int);
static void *const kOmcJitAdapterForceLink[] __attribute__((used)) = {
  reinterpret_cast<void *>(&omc_jit_performSimulation),
  reinterpret_cast<void *>(&omc_jit_performQSSSimulation),
  reinterpret_cast<void *>(&omc_jit_updateContinuousSystem),
  reinterpret_cast<void *>(&omc_jit_main_runtime),
  reinterpret_cast<void *>(&omc_jit_relationhysteresis),
};

int omc_runModelViaJIT(const char *bitcodePath, const char *runtimeLib,
                       const char *modelName, const char *logFile) {
  llvm::InitializeNativeTarget();
  llvm::InitializeNativeTargetAsmPrinter();

  /* Make the simulation runtime resolvable to the JIT before linking the
   * model's external references against the running process. */
  std::string loadErr;
  if (runtimeLib && runtimeLib[0] &&
      llvm::sys::DynamicLibrary::LoadLibraryPermanently(runtimeLib, &loadErr)) {
    fprintf(stderr, "[llvm-jit] cannot load simulation runtime '%s': %s\n",
            runtimeLib, loadErr.c_str());
    return 1;
  }
  llvm::sys::DynamicLibrary::LoadLibraryPermanently(nullptr);

  /* Also pull in the Modelica.* runtime libraries that ship next to
   * libSimulationRuntimeC. CodegenC-emitted user-function bodies
   * call into ModelicaStandardTables / ModelicaIO /
   * ModelicaExternalC for table lookup, file I/O and the small
   * extension set Modelica.Math / Modelica.Utilities depends on.
   * The legacy buildModel path links these in statically; the JIT
   * needs to dlopen them so DynamicLibrarySearchGenerator can
   * resolve their entry points. Loading is best-effort: a model
   * that does not reference any of these symbols simply ignores
   * the loaded library. */
  if (runtimeLib && runtimeLib[0]) {
    llvm::StringRef rt(runtimeLib);
    size_t slash = rt.find_last_of('/');
    std::string ffiDir =
        (slash == std::string::npos ? std::string(".") : rt.substr(0, slash).str())
        + "/ffi/";
    static const char *kModelicaLibs[] = {
        "libModelicaStandardTables.so",
        "libModelicaIO.so",
        "libModelicaMatIO.so",
        "libModelicaExternalC.so",
    };
    for (const char *name : kModelicaLibs) {
      std::string path = ffiDir + name;
      std::string err;
      if (llvm::sys::DynamicLibrary::LoadLibraryPermanently(path.c_str(), &err)) {
        fprintf(stderr,
                "[llvm-jit] note: optional Modelica library '%s' not loaded: %s\n",
                path.c_str(), err.c_str());
      }
    }
  }

  llvm::orc::LLJIT *jitPtr = nullptr;
  std::string key = (modelName && modelName[0]) ? modelName : "<anon>";
  std::unordered_map<std::string, std::unique_ptr<llvm::orc::LLJIT>>::iterator
      cacheIt = g_jitCache.find(key);
  if (cacheIt != g_jitCache.end()) {
    jitPtr = cacheIt->second.get();
    g_sctlBitcodeBytes.clear();  /* Consumed; no module being added. */
  } else {
    /* Cold path. Parse + build + add modules, then stash the
     * freshly-built LLJIT under modelName so the next simulate()
     * of the same model hits the cache. */
    llvm::Expected<std::unique_ptr<llvm::orc::LLJIT>> jitOrErr =
        llvm::orc::LLJITBuilder().create();
    if (!jitOrErr) {
      llvm::logAllUnhandledErrors(jitOrErr.takeError(), llvm::errs(),
                                  "[llvm-jit] LLJIT create: ");
      return 1;
    }
    std::unique_ptr<llvm::orc::LLJIT> newJit = std::move(*jitOrErr);

    llvm::Expected<std::unique_ptr<llvm::orc::DynamicLibrarySearchGenerator>>
        gen = llvm::orc::DynamicLibrarySearchGenerator::GetForCurrentProcess(
            newJit->getDataLayout().getGlobalPrefix());
    if (!gen) {
      llvm::logAllUnhandledErrors(gen.takeError(), llvm::errs(),
                                  "[llvm-jit] symbol generator: ");
      return 1;
    }
    newJit->getMainJITDylib().addGenerator(std::move(*gen));

    /* Parse the CodegenC-side bitcode IF the caller produced one.
     * When -d=jitSimulate suppresses every .c that clang would have
     * compiled, the script writes no merged <prefix>.bc and the path
     * is empty -- the SCTL bitcode (loaded below from
     * g_sctlBitcodeBytes) becomes the sole source of model symbols. */
    if (bitcodePath && bitcodePath[0]) {
      std::unique_ptr<llvm::LLVMContext> ctx =
          std::make_unique<llvm::LLVMContext>();
      llvm::SMDiagnostic diag;
      std::unique_ptr<llvm::Module> mod =
          llvm::parseIRFile(bitcodePath, diag, *ctx);
      if (!mod) {
        diag.print("[llvm-jit]", llvm::errs());
        return 1;
      }
      if (llvm::Error err = newJit->addIRModule(
              llvm::orc::ThreadSafeModule(std::move(mod), std::move(ctx)))) {
        llvm::logAllUnhandledErrors(std::move(err), llvm::errs(),
                                    "[llvm-jit] addIRModule: ");
        return 1;
      }
    }

    /* Pull in SimCodeToLLVM's in-memory bitcode (stashed via
     * stashCurrentModuleAsBitcode) without going through disk. */
    if (!g_sctlBitcodeBytes.empty()) {
      std::unique_ptr<llvm::LLVMContext> sctlCtx =
          std::make_unique<llvm::LLVMContext>();
      std::unique_ptr<llvm::MemoryBuffer> sctlBuf =
          llvm::MemoryBuffer::getMemBufferCopy(
              llvm::StringRef(g_sctlBitcodeBytes.data(),
                              g_sctlBitcodeBytes.size()),
              "sctl-in-memory");
      llvm::Expected<std::unique_ptr<llvm::Module>> sctlModOrErr =
          llvm::parseBitcodeFile(sctlBuf->getMemBufferRef(), *sctlCtx);
      if (!sctlModOrErr) {
        llvm::logAllUnhandledErrors(sctlModOrErr.takeError(), llvm::errs(),
                                    "[llvm-jit] parse SCTL bitcode: ");
        g_sctlBitcodeBytes.clear();
        return 1;
      }
      if (llvm::Error err = newJit->addIRModule(llvm::orc::ThreadSafeModule(
              std::move(*sctlModOrErr), std::move(sctlCtx)))) {
        llvm::logAllUnhandledErrors(std::move(err), llvm::errs(),
                                    "[llvm-jit] addIRModule SCTL: ");
        g_sctlBitcodeBytes.clear();
        return 1;
      }
      g_sctlBitcodeBytes.clear();
    }

    jitPtr = newJit.get();
    g_jitCache[key] = std::move(newJit);
  }

  llvm::Expected<llvm::orc::ExecutorAddr> mainSym = jitPtr->lookup("main");
  if (!mainSym) {
    llvm::logAllUnhandledErrors(mainSym.takeError(), llvm::errs(),
                                "[llvm-jit] lookup main: ");
    return 1;
  }
  using MainFn = int (*)(int, char **);
  MainFn modelMain = mainSym->toPtr<MainFn>();

  /* The model derives its init-xml / result-file names from the compiled-in
   * model prefix rather than argv, so argv[0] is all that is required. */
  char arg0[1024];
  snprintf(arg0, sizeof(arg0), "%s",
           (modelName && modelName[0]) ? modelName : "model");
  char *margv[] = {arg0, nullptr};

  /* Redirect the model's stdout/stderr to its log file for the duration of the
   * run, mirroring the native executable (whose entire stdout is captured to
   * <model>.log). The caller reads that log to build the SimulationResult.
   * Uses raw fds at the OS boundary; the original descriptors are restored
   * afterwards so omc's own output is unaffected. */
  int savedOut = -1, savedErr = -1;
  if (logFile && logFile[0]) {
    fflush(nullptr);
    savedOut = dup(STDOUT_FILENO);
    savedErr = dup(STDERR_FILENO);
    int logFd = open(logFile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (logFd >= 0) {
      dup2(logFd, STDOUT_FILENO);
      dup2(logFd, STDERR_FILENO);
      close(logFd);
    }
  }

  int rc = modelMain(1, margv);

  if (savedOut >= 0) {
    fflush(nullptr);
    dup2(savedOut, STDOUT_FILENO);
    dup2(savedErr, STDERR_FILENO);
    close(savedOut);
    close(savedErr);
  }
  return rc;
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

/* Phase 5: materialize the current module into the JIT and confirm the
 * named symbol resolves. Used by SimCodeToLLVM to validate that a
 * model functionODE module is well-formed and that its external
 * helpers (omc_jit_get_real_var et al.) resolve through the process
 * symbol generator. Does not invoke the function. Returns 0 on
 * success, non-zero otherwise. */
int jitFinalizeNoEntry(const char *fName) {
  verifyFunctionDumpIROnError();
  if (!program->module) {
    fprintf(stderr, "jitFinalizeNoEntry: no module to finalize\n");
    return 1;
  }
  program->jit->addModule(std::move(program->module));
  auto symbol{program->jit->findSymbol(fName)};
  if (!symbol) {
    fprintf(stderr, "jitFinalizeNoEntry: symbol '%s' not found after addModule\n", fName);
    return 2;
  }
  auto targetAddress{symbol.getAddress()};
  if (!targetAddress) {
    fprintf(stderr, "jitFinalizeNoEntry: symbol '%s' has no address\n", fName);
    return 3;
  }
  return 0;
}

/* Phase 6: look up the raw address of an already-finalized JIT symbol.
 * Returns 0 on success and writes the address into *outAddr. Used by
 * the model invocation harness in llvm_gen_wrappers.c so the lookup
 * stays in the same TU that owns `program->jit`, while the call site
 * (which needs to know about DATA/SIMULATION_DATA) stays in C. */
int jitLookupAddress(const char *fName, void **outAddr) {
  if (!fName || !outAddr) return 1;
  if (!program || !program->jit) return 2;
  auto symbol{program->jit->findSymbol(fName)};
  if (!symbol) return 3;
  auto targetAddress{symbol.getAddress()};
  if (!targetAddress) return 4;
  *outAddr = reinterpret_cast<void*>(targetAddress.get());
  return 0;
}

modelica_boolean fIsJitCompiled(const char *fName) {
  auto symbol{program->jit->findSymbol(fName)};
  if (!symbol) {
    return false;
  }
  return true;
}

/* The JIT is run internally in the C environment */
modelica_metatype run_jit_internal(modelica_metatype (*top_level_func)(modelica_metatype), modelica_metatype args);
modelica_metatype runJIT(modelica_metatype valLst) {
  DBG("Calling run JIT with argument:%s\n", anyString(valLst));
  void *valuePtr = run_jit_internal(program->top_level_func, valLst);
  return valuePtr;
}

/*Init neccessary global variables  */
void initGen(const char *name) {
  DBG("Calling initGen with %name \n");
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
        new Function(std::make_unique<FunctionPrototype>()));
    program->functions[name] = func;
  }
  program->currentFunc = func;
  /* A previous emit may have left stale state behind. When createCall
   * triggers MMC_THROW (e.g. createStoreInst on a missing dest)
   * before reaching the callArgs.clear() at the end of createCall,
   * the next emission would otherwise see the partially-built
   * argument vector. Clearing here is defensive: any in-flight call
   * for the previous function is irrelevant to the one we are about
   * to start. */
  program->currentFunc->callArgs.clear();
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
  llvm::AllocaInst *condAi = condVariable->getAllocaInst();
  llvm::Value *cond = program->builder.CreateLoad(condAi->getAllocatedType(),
                                                  condAi,
                                                  condVariable->isVolatile(),
                                                  condAi->getName());

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
  llvm::Type *retTy = getLLVMType(type, structName);
  /* MODELICA_UNKNOWN (0) reaches us when DAEToMid produced a function
   * whose return type is DAE.T_UNKNOWN. llvm::FunctionType::get
   * segfaults on a null return type, so raise an MMC failure that
   * MidToLLVM.genProgram's try/else block catches and turns into a
   * skipped-function rather than an omc crash. Mirrors the
   * MMC_THROW path in createFunctionProtArg for unknown arg types. */
  if (!retTy) {
    fprintf(stderr,
            "createFunctionType: unknown return type %u, raising MMC failure\n",
            (unsigned)type);
    MMC_THROW();
  }
  program->currentFunc->setPrototypeFunctionType(
      llvm::FunctionType::get(retTy,
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
    si->setAlignment(ai->getAlign());
    program->currentFunc->symTab[a.getName().str()] =
        std::make_unique<Variable>(ai, false);
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
    /* Clear callArgs BEFORE createStoreInst so the next emission
     * sees a clean slate if createStoreInst raises MMC_THROW on a
     * missing dest. The CallInst was already built, so the
     * arguments are baked in. */
    program->currentFunc->callArgs.clear();
    createStoreInst(s, dest);
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
    f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage, "longjump_jumpbufAsPtr",
                               program->module.get());
    /*Set attributes so that LLVM does not optimise away the function during opt
     * phase.*/
    // LLVM 14+ replaced Function::addAttributes(idx, AttributeSet)
    // with addFnAttr / addAttributeAtIndex; the equivalent for a
    // single string attribute is addFnAttr directly.
    f->addFnAttr(llvm::Attribute::get(program->context, "noinline", "true"));
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
  program->currentFunc->symTab[std::string(name)] =
      std::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

int allocaBoolean(const char *name, const bool isVolatile) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, llvm::Type::getIntNTy(program->context, 1))};
  program->currentFunc->symTab[std::string(name)] =
      std::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

/*Allocates a modelica real, a double in LLVM IR*/
int allocaDouble(const char *name, const bool isVolatile) {
  llvm::AllocaInst *alloci{createAllocaInst(name, getLLVMType(MODELICA_REAL))};
  /* Key the symtab by the REQUESTED name (the argument passed in)
   * rather than alloci->getName(). LLVM appends a numeric suffix
   * silently when the requested name collides with an existing
   * value in the same function -- which happens whenever
   * emitEquationFunction emits multiple bodies (recipes) into one
   * function and freshTmp's counter reset back to a value it
   * already used in this function. The Variable* still points to
   * the AllocaInst* LLVM created, and subsequent createStoreInst /
   * createLoadInst calls from SCTL look up by the requested name,
   * so the right alloca is found. */
  program->currentFunc->symTab[std::string(name)] =
      std::make_unique<Variable>(alloci, isVolatile);
  return 0;
}

/*For modelica_metatype and so forth 8 bits in size, however they will function
  as void pointers to differentiate
  between pointers to concrete types.
*/
int allocaInt8PtrTy(const char *name) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, getLLVMType(MODELICA_METATYPE))};
  program->currentFunc->symTab[std::string(name)] =
      std::make_unique<Variable>(alloci, false);
  return 0;
}

/*Allocates a pointer to a pointer of type i8 (idented for modelica_metatype*)*/
int allocaInt8PtrPtrTy(const char *name) {
  llvm::AllocaInst *alloci{
      createAllocaInst(name, getLLVMType(MODELICA_METATYPE_PTR))};
  program->currentFunc->symTab[std::string(name)] =
      std::make_unique<Variable>(alloci, false);
  return 0;
}

/*Stores the result of src at dest.*/
int createStoreVarInst(const char *src, const char *dest) {
  DBG("Calling store var instruction src:%s to dest:%s \n", src, dest);
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::AllocaInst *s{srcVariable->getAllocaInst()};
  llvm::Value *lv{
      program->builder.CreateLoad(s->getAllocatedType(), s,
                                  srcVariable->isVolatile(), s->getName())};
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

  llvm::AllocaInst *sAi = srcVariable->getAllocaInst();
  llvm::AllocaInst *dAi = destVariable->getAllocaInst();
  llvm::Value *s = program->builder.CreateLoad(sAi->getAllocatedType(), sAi,
                                               srcVariable->isVolatile(),
                                               sAi->getName());
  llvm::Value *d = program->builder.CreateLoad(dAi->getAllocatedType(), dAi,
                                               destVariable->isVolatile(),
                                               dAi->getName());
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
      ival, llvm::PointerType::getUnqual(program->context), "pointerTMP")};
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
  llvm::AllocaInst *retAi = returnVariable->getAllocaInst();
  llvm::Value *ret = program->builder.CreateLoad(retAi->getAllocatedType(),
                                                 retAi,
                                                 returnVariable->isVolatile(),
                                                 retAi->getName());
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

/* Emit `ret ptr null` for a function whose declared return type is
 * a pointer. Counterpart to createReturnZero / createReturnVoid for
 * SCTL's EB_NULL_PTR catalog entries (_linear_model_frame,
 * _relationDescription, ...). Inferring the pointer type from the
 * current function avoids the i64-vs-ptr mismatch the LLVM verifier
 * rejects when both kinds of return show up in the same module. */
int createReturnNullPtr() {
  DBG("Calling createReturnNullPtr\n");
  llvm::Type *retTy = program->builder.GetInsertBlock()
                          ->getParent()->getReturnType();
  if (!retTy->isPointerTy()) {
    fprintf(stderr,
            "createReturnNullPtr: current function's return type is not "
            "a pointer; falling back to createReturnZero.\n");
    return createReturnZero();
  }
  llvm::Value *retVal = llvm::ConstantPointerNull::get(
      llvm::cast<llvm::PointerType>(retTy));
  program->builder.CreateRet(retVal);
  return 0;
}

/*Unary operators */
int createIUminus(const char *src, const char *dest) {
  DBG("Creating i64 Uminus\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::AllocaInst *sAi = srcVariable->getAllocaInst();
  llvm::Value *s = program->builder.CreateLoad(sAi->getAllocatedType(), sAi,
                                               srcVariable->isVolatile(),
                                               sAi->getName());
  s = program->builder.CreateNeg(s, "negI64temp");
  createStoreInst(s, dest);
  return 0;
}

int createDUminus(const char *src, const char *dest) {
  DBG("Creating DUminus\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::AllocaInst *sAi = srcVariable->getAllocaInst();
  llvm::Value *s = program->builder.CreateLoad(sAi->getAllocatedType(), sAi,
                                               srcVariable->isVolatile(),
                                               sAi->getName());
  s = program->builder.CreateFNeg(s, "negDtemp");
  createStoreInst(s, dest);
  return 0;
}

int createNot(const char *src, const char *dest) {
  DBG("Creating  NOT\n");
  Variable *srcVariable{program->currentFunc->symTab[src].get()};
  llvm::AllocaInst *sAi = srcVariable->getAllocaInst();
  llvm::Value *s = program->builder.CreateLoad(sAi->getAllocatedType(), sAi,
                                               srcVariable->isVolatile(),
                                               sAi->getName());
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
  return castXTypeToYType(src, dest, llvm::PointerType::getUnqual(program->context),
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
    llvm::AllocaInst *ceAi = carElementVariable->getAllocaInst();
    llvm::Value *ce = ceAi;
    /*Load instruction to set the alignment*/
    llvm::LoadInst *ceL = program->builder.CreateLoad(
        ceAi->getAllocatedType(), ceAi,
        carElementVariable->isVolatile(), ceAi->getName());
    ceL->setAlignment(llvm::Align(8));
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
  llvm::AllocaInst *ceAi = carElementVariable->getAllocaInst();
  llvm::Value *ce = ceAi;
  llvm::LoadInst *ceL{program->builder.CreateLoad(
      ceAi->getAllocatedType(), ceAi,
      carElementVariable->isVolatile(), ceAi->getName())};
  ceL->setAlignment(llvm::Align(8));
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
  llvm::StructType *structTy = llvm::StructType::getTypeByName(program->context, sName);

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
  llvm::StructType *sType{llvm::StructType::getTypeByName(program->context, structName)};
  if (!sType) {
    fprintf(stderr, "Attempted to create struct without signature for: %s \n", structName);
    MMC_THROW();
    return 1;
  }

  llvm::AllocaInst *structAi{createAllocaInst(structName, sType)};

  DBG("after call to createAllocaInst\n");
  program->currentFunc->symTab[structName] =
    std::make_unique<Variable>(structAi, false);
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
    // Opaque pointers: pointee type of a GlobalVariable is recovered
    // via getValueType() (PointerType::getElementType was removed).
    auto ty = llvmC->getValueType();
    llvm::Constant *gep =
        llvm::ConstantExpr::getGetElementPtr(ty, llvmC, indices);
    gepField.push_back(gep);
  }

  DBG("Creating gvArStruct\n");
  llvm::GlobalVariable *gvarStruct = new llvm::GlobalVariable(
      *program->module.get(), llvm::StructType::getTypeByName(program->context, structTypeName),
      false,
      llvm::GlobalValue::ExternalLinkage, // TODO: See over this.
      0, name);
  DBG("gvarStructCreated\n");
  // TODO: Figure out alignment. (Problems?)
  llvm::Constant *constStruct = llvm::ConstantStruct::get(
      llvm::StructType::getTypeByName(program->context, structTypeName), gepField);
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
  // Opaque-pointer GEP requires the source pointee type. The
  // surrounding code treats the pointer as a metatype array
  // (i8*); use i8 as the element type and rely on the bitcast
  // below to recover the actual value type.
  llvm::Value *gep{program->builder.CreateInBoundsGEP(
      llvm::Type::getInt8Ty(program->context), dV, vIdx0, "gepTmp")};
  // All these functions of similar type can look the same, just add the right
  // bitcast in a later refactor.
  gep = program->builder.CreateBitCast(
      gep, llvm::PointerType::getUnqual(program->context));
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
  llvm::Value *gep{program->builder.CreateInBoundsGEP(
      llvm::Type::getInt8Ty(program->context), dV, vIdx0, "geptmp")};
  gep = program->builder.CreateBitCast(
      gep, llvm::PointerType::getUnqual(program->context));
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
  llvm::Value *gep{program->builder.CreateInBoundsGEP(llvm::Type::getInt8Ty(program->context), sV, vIdx0, "geptmp")};
  gep = program->builder.CreateBitCast(
      gep, llvm::PointerType::getUnqual(program->context));
  llvm::LoadInst *li = program->builder.CreateLoad(
      llvm::Type::getDoubleTy(program->context), gep);
  li->setAlignment(llvm::Align(8));
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
  llvm::AllocaInst *sv{structVariable->getAllocaInst()};

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
      program->builder.CreateInBoundsGEP(sv->getAllocatedType(), sv, indexVec, "gepTmp")};
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
  // Create GEP instruction. Opaque-pointer LLVM (16+) requires the
  // source struct type as the first argument.
  llvm::Type *svElTy = sv->getAllocatedType();
  llvm::Value *structElem{
      program->builder.CreateInBoundsGEP(svElTy, sv, indexVec, "gepTmp")};
  // TODO: Can probably be added to the allignment function in utils.
  // Element loaded back from the struct: use the matching member type.
  llvm::Type *elemTy = svElTy->isStructTy()
      ? svElTy->getStructElementType(idx1)
      : svElTy;
  llvm::LoadInst *structElemL =
      program->builder.CreateLoad(elemTy, structElem, structElem->getName());
  structElemL->setAlignment(sv->getAlign());
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
  gStr->setAlignment(llvm::Align(1));
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
    gStr->setAlignment(llvm::MaybeAlign(1)); // These are C style strings (char*), not Modelica strings.
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
  // The original branch used (fields * 8) as the alignment value, but
  // LLVM 16's llvm::Align asserts the argument is a power of two —
  // for fields=3 this aborts the JIT with an Alignment-is-not-a-
  // power-of-2 trap. The actual intent is pointer alignment for a
  // global array of metatype pointers, which is 8 regardless of
  // length. Stage 5 follow-up.
  gvarStrArray->setAlignment(llvm::Align(8));
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
