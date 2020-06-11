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

/*Author: John Tinnerholm*/

/*
  Short note. compiled without exceptions, this might effect ABI and so forth
  https://stackoverflow.com/questions/9545688/linking-with-code-that-does-not-support-exception-handling-c-llvm
*/

#ifndef _LLVM_GEN_H
#define _LLVM_GEN_H
/*Modelica headers */
#include "ext_llvm.hpp"
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
/* LLVM headers*/
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

    int createSwitch(llvm::Value *cond, const modelica_integer numCases,llvm::IRBuilder<> builder) {
      switchInst = builder.CreateSwitch(cond,nullptr,numCases);
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
    {imValMngr = llvm::make_unique<IntermediateValMngr>();}

    llvm::Function *getLLVMFunc() {return prototype->function;}
    llvm::FunctionType *getPrototypeFunctionType() {return prototype->function_type;}
    std::vector<llvm::Type*> &getPrototypeArgs() {return prototype->prot_args;}
    std::vector<std::string> &getArgNames() {return prototype->argNames;}

    void setPrototypeFunctionType(llvm::FunctionType *ft) { prototype->function_type = ft;}
    void setLLVMFunction(llvm::Function *f) { prototype->function = f; }
    const std::string getName() {return prototype->function->getName();};
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
      module = llvm::make_unique<llvm::Module>("module",context);
      functionPassMngr = llvm::make_unique<llvm::legacy::FunctionPassManager>(module.get());
      functionPassMngr->add(llvm::createPromoteMemoryToRegisterPass()); //SSA conversion
      functionPassMngr->add(llvm::createCFGSimplificationPass()); //Dead code elimination
      functionPassMngr->add(llvm::createSROAPass());
      functionPassMngr->add(llvm::createLoopSimplifyCFGPass());
      functionPassMngr->add(llvm::createConstantPropagationPass());
      functionPassMngr->add(llvm::createNewGVNPass());//Global value numbering
      functionPassMngr->add(llvm::createReassociatePass());
      functionPassMngr->add(llvm::createPartiallyInlineLibCallsPass()); //Inline standard calls
      functionPassMngr->add(llvm::createDeadCodeEliminationPass());
      functionPassMngr->add(llvm::createCFGSimplificationPass()); //Cleanup
      functionPassMngr->add(llvm::createInstructionCombiningPass());
      functionPassMngr->add(llvm::createFlattenCFGPass()); //Flatten the control flow graph.
      /*Loops*/
      functionPassMngr->add(llvm::createLoopIdiomPass());
      functionPassMngr->add(llvm::createSimpleLoopUnrollPass());
      functionPassMngr->add(llvm::createCFGSimplificationPass());
      functionPassMngr->doInitialization();
      /*   Interprocedual optimisations:
       *   We only do inlining for now to keep the JIT snappy
       *   TODO: Move to JIT Module?
       *
       */
      ipoPassMngr.add(llvm::createReversePostOrderFunctionAttrsPass());
      ipoPassMngr.add(llvm::createFunctionInliningPass());
      ipoPassMngr.add(llvm::createArgumentPromotionPass());
      ipoPassMngr.add(llvm::createInstructionCombiningPass());
      ipoPassMngr.add(llvm::createCFGSimplificationPass());
      jit = llvm::make_unique<llvm::orc::OMC_JIT>();
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
