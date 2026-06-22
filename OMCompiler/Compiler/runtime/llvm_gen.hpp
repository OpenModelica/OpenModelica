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

/*Author: John Tinnerholm*/

/*
  Short note. compiled without exceptions, this might effect ABI and so forth
  https://stackoverflow.com/questions/9545688/linking-with-code-that-does-not-support-exception-handling-c-llvm
*/

#ifndef _LLVM_GEN_H
#define _LLVM_GEN_H
/*C++ STL headers */
#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <memory>
#include <string>
#include <vector>
#include <functional>
/* LLVM headers — must come BEFORE the OMC meta_modelica_builtin.h headers
 * (pulled in via ext_llvm.hpp). The OMC headers define short macros like
 * `isPresent`, `equality`, `valueConstructor` that collide with member
 * functions and template parameters in modern llvm/Support/Casting.h. */
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Verifier.h"
/*Optimisations and JIT Info*/
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/IRReader/IRReader.h"//Parse pre-compiled files.
#include "llvm/Support/SourceMgr.h"
#include "llvm/Transforms/Scalar.h" //Per function opts
#include "llvm/Transforms/IPO.h" //Interprocedual optimisations.
/*For JIT.*/
#include "OMC_JIT.hpp"
/* We need to fetch stuff from dynlibs */
#include "llvm/Support/DynamicLibrary.h"
/*Modelica headers — intentionally last so the macro pollution does not
 * leak into LLVM headers above. */
#include "ext_llvm.hpp"

extern "C"
{

  void dumpIR();
  /*Forward decls*/
  struct Function;
  struct Program;
  class IntermediateValMngr;
  struct FunctionPrototype;
  extern std::unique_ptr<Program> program = nullptr;

  class Variable {
  private:
    llvm::AllocaInst *m_alloci;
    const bool m_isVolatile;
  public:
    Variable(llvm::AllocaInst *alloci, const bool &isVolatile) :
      m_alloci{alloci}, m_isVolatile{isVolatile} {}
    bool isVolatile() const {return m_isVolatile;}
    llvm::AllocaInst *getAllocaInst() {return m_alloci;}
  };
  /*
    This class contains Intermediate values, used to store variables that
    needs to be referenced 1 or n times before an instruction is created.
    The object is owned by the function it is handling IR for.
  */
  class IntermediateValMngr {
  private:
    /*For switch instructions*/
    llvm::SwitchInst *switchInst;
    bool switchIsIncomplete; //switchInst is incomplete if this is true.
    /*For generation of lists */
    llvm::Value *cdr;
    /*For generation of structs*/
    std::vector<llvm::Type*> structField;
  public:
    IntermediateValMngr() {
      switchIsIncomplete = false;
      switchInst = nullptr;
      cdr = nullptr;
    }
    /*Switch related functions*/
    llvm::SwitchInst *getSwiInst() {return switchInst;}
    const bool &switchNeedsDefaultBB() {return switchIsIncomplete;}

    int createSwitch(llvm::Value *cond, const modelica_integer numCases, llvm::IRBuilder<> &builder) {
      // LLVM verifier (post LLVM 15 / opaque-pointer era) rejects a
      // switch with a null default destination, which ORC v2 hits when
      // SimpleCompiler runs the verifier as part of its codegen
      // pipeline — manifesting as a segfault in FPPassManager rather
      // than a clean diagnostic. Wire up a synthetic "default-trap"
      // basic block so the switch is always structurally valid; if
      // the surrounding lowering later overwrites the default via
      // setDefaultBBForSwiInst (the normal matchcontinue path), the
      // trap block becomes dead and gets optimised away.
      llvm::Function *F = builder.GetInsertBlock()->getParent();
      llvm::BasicBlock *trapBB = llvm::BasicBlock::Create(F->getContext(),
                                                         "switch.default.trap",
                                                         F);
      llvm::IRBuilder<> trapBuilder(trapBB);
      trapBuilder.CreateUnreachable();
      switchInst = builder.CreateSwitch(cond, trapBB, numCases);
      switchIsIncomplete = true;
      return 0;
    }

    void setDefaultBBForSwiInst(llvm::BasicBlock *bb) {
      switchInst->setDefaultDest(bb);
      switchIsIncomplete = false;
    }

    void setCdr(llvm::Value *newCdr) { this->cdr = newCdr; }
    std::vector<llvm::Type*> &getStructField() {return structField;}
    llvm::Value *getCdr() {return this->cdr;}
  };

  //Contains the different components of a LLVM function prototype.
  struct FunctionPrototype { // TODO, remove this include it in Function.
    //Temporary storage when creating a function
    std::vector<std::string> argNames;
    std::vector<llvm::Type*> prot_args;
    llvm::FunctionType *function_type;
    llvm::Function *function;
  };

  struct Function {
    std::unique_ptr<FunctionPrototype> prototype;
    /*For looking up variables*/
    std::map<std::string,std::unique_ptr<Variable>> symTab;
    /*For looking up basic block, (they are NOT ordered in a linear fashion in Midcode).*/
    std::map<std::string,llvm::BasicBlock*> blockMap;
    /*For function calls*/
    std::vector<llvm::Value*> callArgs;
    /*Handles Intermediate values that need to be built in steps.*/
    std::unique_ptr<IntermediateValMngr> imValMngr;

    explicit Function(std::unique_ptr<FunctionPrototype> prototype_) :
      prototype{std::move(prototype_)}
    {imValMngr = std::make_unique<IntermediateValMngr>();}

    llvm::Function *getLLVMFunc() {return prototype->function;}
    llvm::FunctionType *getPrototypeFunctionType() {return prototype->function_type;}
    std::vector<llvm::Type*> &getPrototypeArgs() {return prototype->prot_args;}
    std::vector<std::string> &getArgNames() {return prototype->argNames;}

    void setPrototypeFunctionType(llvm::FunctionType *ft) { prototype->function_type = ft;}
    void setLLVMFunction(llvm::Function *f) { prototype->function = f; }
    std::string getName() {return prototype->function->getName().str();};
  };

  struct Program {
    const std::string name;
    /*Used for temporary storage for generating llvmStrArrays.*/
    std::vector<std::string> llvmStrArray;
    /*Constants used to create a global struct */
    std::vector<llvm::GlobalVariable*> globalStructField;
    /*For looking up global constants*/
    std::map<std::string, llvm::GlobalVariable*> globalConstants; //TODO: Might need to use a different subclass (generality).
    /*Ident to keep track of functions (which in turn hold alot of stuff)*/
    std::map<const std::string, std::shared_ptr<Function>> functions;
    /*Keeps track of the function that we are currently generating IR for*/
    std::shared_ptr<Function> currentFunc;
    llvm::LLVMContext context;
    llvm::IRBuilder<> builder;
    std::unique_ptr<llvm::Module> module;
    /*For per function optimisations*/
    std::unique_ptr<llvm::legacy::FunctionPassManager> functionPassMngr;
    /* For interprodecdual optimisations. Experimental*/
    llvm::legacy::PassManager ipoPassMngr;
    std::unique_ptr<llvm::orc::OMC_JIT> jit;
    modelica_boolean shallOptimize;
    /* Function pointer to the top level expression */
    modelica_metatype (*top_level_func)(modelica_metatype);
    //Creates the module and sets the pass mananger.
    //TODO: Can be extended to configure the different optimisations on setup.
    Program(const std::string &name) :  builder{context}
    {
      module = std::make_unique<llvm::Module>("module",context);
      functionPassMngr = std::make_unique<llvm::legacy::FunctionPassManager>(module.get());
      // The entire optimisation pipeline was registered against the
      // legacy pass manager. Most of those passes (PromoteMemoryToRegister,
      // SROA, NewGVN, InstCombine, FlattenCFG, ArgumentPromotion etc.)
      // moved to the new pass manager on the way to LLVM 16 and either
      // dropped their llvm:: factory function or stopped being
      // convertible to the legacy `Pass *`. Disable the registrations
      // here so the JIT can be brought up unoptimised; a follow-up
      // commit will migrate the pipeline to the new PassBuilder API.
      functionPassMngr->doInitialization();
      jit = std::make_unique<llvm::orc::OMC_JIT>();
    }

    void nameArgument(const char *name) {
      currentFunc->getArgNames().push_back(name);
    }

    /*We either use all optimisations or none at all..*/
    void runOptimizations() {
      if (shallOptimize) {
        functionPassMngr->run(*currentFunc->getLLVMFunc());
        ipoPassMngr.run(*program->module);
      }
    }

    void runIPO() {
      //TODO. Move this to another location?
      ipoPassMngr.run(*program->module);
    }

  };

} /* end extern "C" */
#endif //_LLVM_GEN_H
