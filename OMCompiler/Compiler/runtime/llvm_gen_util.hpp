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

/* This file contains the helper functions used by the llvm_gen interface
   note since we use templates all helper code is written here.
*/
#ifndef _LLVM_GEN_UTIL_H
#define _LLVM_GEN_UTIL_H
#include "llvm_gen.hpp"
#include "llvm_gen_modelica_constants.h"
#include <algorithm>

/* The "program" currently being generated. */
extern std::unique_ptr<Program> program;

extern "C"
{
  //Non template functions.
  /* Given a binary operation on the form dest = lhs OP rhs as llvm::StringRef's
    fetch l,r,d from the symbol table.
    For lhs and rhs the corresponding load instructions are created.
  */
  void binopInit(const char *lhs, const char *rhs, const char *dest,
                 llvm::Value *&l, llvm::Value *&r, llvm::Value *&d)
  {
    DBG("Calling binop init\n");
    Variable *leftVariable = program->currentFunc->symTab[lhs].get();
    Variable *rightVariable = program->currentFunc->symTab[rhs].get();
    Variable *destVariable = program->currentFunc->symTab[dest].get();
    DBG("Creating load instructions\n");
    l = leftVariable->getAllocaInst();
    r = rightVariable->getAllocaInst();
    d = destVariable->getAllocaInst();
    l = program->builder.CreateLoad(l, leftVariable->isVolatile(), lhs);
    r = program->builder.CreateLoad(r, rightVariable->isVolatile(), rhs);
  }

  llvm::Type *getLLVMType(const uint8_t type,const char* structName="")
  {
    switch(type) {
    case MODELICA_INTEGER: return llvm::Type::getIntNTy(program->context,NBITS_MODELICA_INTEGER);
    case MODELICA_BOOLEAN: return llvm::Type::getInt1Ty(program->context);
    case MODELICA_REAL: return llvm::Type::getDoubleTy(program->context);
    case MODELICA_METATYPE: return llvm::Type::getInt8PtrTy(program->context);
    case MODELICA_TUPLE: return program->module->getTypeByName(structName);
    case MODELICA_VOID: return llvm::Type::getVoidTy(program->context);
    case MODELICA_INTEGER_PTR: return llvm::Type::getIntNPtrTy(program->context,NBITS_MODELICA_INTEGER);
    case MODELICA_BOOLEAN_PTR: return llvm::Type::getInt1PtrTy(program->context);
    case MODELICA_REAL_PTR: return llvm::Type::getDoublePtrTy(program->context);
    case MODELICA_METATYPE_PTR: return llvm::PointerType::get(llvm::Type::getInt8PtrTy(program->context), 0);
    default: fprintf(stderr,"Attempted to deduce unknown type:%u\n",type); return nullptr;
    }
  }

  /*Map type to stack alignment in bytes (llvm align) */
  unsigned short getAlignment(llvm::Type *type)
  {
    if (type == getLLVMType(MODELICA_METATYPE)) {
      return 8;
    } else if (type == getLLVMType(MODELICA_INTEGER)) {
      return 8;
    } else if (type == getLLVMType(MODELICA_REAL)) {
      return 8;
    } else if  (type == getLLVMType(MODELICA_BOOLEAN)) {
      return 1;
    } else if (type == getLLVMType(MODELICA_TUPLE)) {
      //TODO add struct parameter, does however seem to work but can give problems.
      //fprintf(stderr,"TODO SIZE OF STRUCT REQUESTED, NOT SUPPORTED!\n");
      return 8;
    }
    return 8; //All other types should have 8. Yes Linux only probably..
  }

  /*For Debugging*/
  const char *getModelicaLLVMTypeString(const uint8_t ty) {
    switch(ty) {
    case MODELICA_INTEGER: return "MODELICA_INTEGER";
    case MODELICA_BOOLEAN: return "MODELICA_BOOLEAN";
    case MODELICA_REAL: return "MODELICA_REAL";
    case MODELICA_METATYPE: return "MODELICA_METATYPE";
    case MODELICA_TUPLE: return "MODELICA_TUPLE";
    case MODELICA_VOID: return "MODELICA_VOID";
    case MODELICA_INTEGER_PTR: return "MODELICA_INTEGER_PTR";
    case MODELICA_BOOLEAN_PTR: return "MODELICA_BOOLEAN_PTR";
    case MODELICA_REAL_PTR: return "MODELICA_REAL_PTR";
    case MODELICA_METATYPE_PTR: return "MODELICA_METATYPE_PTR";
    default: fprintf(stderr,"Attempted to deduce unknown type:%u\n",ty); return nullptr;
    }
  }

  /*For debugging. Print all keys in the symbol table */
  void printSymbolTable() {
    fprintf(stderr,"Keys in symbol table:\n");
    for(const auto &p : program->currentFunc->symTab) {
      fprintf(stderr,"%s\n",p.first.c_str());
    }
    fprintf(stderr,"\n");
  }

  /*Helper function to create the different kinds of alloca instructions.
    Also referenced in createFunctionBody */
  llvm::AllocaInst *createAllocaInst(llvm::StringRef name, llvm::Type *type)
  {
    DBG("create allocaInst for:%s \n", name);
    if (!type) {
      fprintf(stderr,"Attempted allocation with unknown type\n");
      MMC_THROW();
    }
    DBG("Type is OK trying to allocate and set alignment:");
    llvm::AllocaInst *ai {program->builder.CreateAlloca(type, 0, name)};
    ai->setAlignment(getAlignment(type));
    return ai;
  }

  llvm::Value *createLoadInst(const char *dest)
  {
    DBG("Create load instruction with dest:%s\n line %d of file \"%s\".\n",dest,__LINE__, __FILE__);
    Variable *destVar {program->currentFunc->symTab[dest].get()};
    llvm::AllocaInst* ai = destVar->getAllocaInst();
    llvm::LoadInst *li = program->builder.CreateLoad(ai, destVar->isVolatile(), ai->getName());
    li->setAlignment(ai->getAlignment());
    DBG("Load instruction created\n");
    return li;
  }

  void createStoreInst(llvm::Value* val, const char *dest)
  {
    DBG("Create store instruction with dest:%s line %d of file \"%s\".\n",dest,__LINE__, __FILE__);
    Variable *variable {program->currentFunc->symTab[dest].get()};
    llvm::AllocaInst *ai {variable->getAllocaInst()};
    if (!ai) {
      fprintf(stderr,"No variable named:%s in symboltable\n",dest);
      printSymbolTable();
      return;
    }
    llvm::StoreInst *si {program->builder.CreateStore(val,ai,variable->isVolatile())};
    si->setAlignment(ai->getAlignment());
  }

} //End extern C;

extern "C++"
{
  /* Templates */
  template<typename Func>
  int createBinop(const char *lhs, const char *rhs, const char *dest,
                  const char *registerName, Func irBuilderFunc)
  {
    llvm::Value *l,*r,*d;
    /* Load the symbols from the symbol table and do neccessary preprocessing.*/
    binopInit(lhs,rhs,dest,l,r,d);
    /* Call the IR-builder, to create the correct instruction, assign it to the result register.*/
    llvm::Value *res{irBuilderFunc(l,r,registerName)};
    DBG("Storing result of binary operation\n");
    createStoreInst(res,dest);
    return 0;
  }

  template<typename Func>
  int castXTypeToYType(const char *src, const char *dest,llvm::Type* ty, Func irBuilderFunc)
  {
    DBG("CallingXTypeToYType\n");
    Variable *variable {program->currentFunc->symTab[src].get()};
    llvm::Value *s {variable->getAllocaInst()};
    s = program->builder.CreateLoad(s,s->getName());
    DBG("Invoking builder instruction\n");
    llvm::Value *res { irBuilderFunc(s,ty) };
    createStoreInst(res,dest);
    return 0;
  }

  /* For the execution engine to find external calls, we need to add a declaration. */
  llvm::Function *createExternalCallDecl(const char *name, const uint8_t functionTy,
										 std::vector<llvm::Type*> args, modelica_boolean isVariadic=false)
  {
    DBG("Creating external call for:%s of type:%d\n",name,functionTy);
    llvm::FunctionType *ft = llvm::FunctionType::get(getLLVMType(functionTy), args, isVariadic);
    if (!ft) {
      fprintf(stderr,"Unknown function type. Generating external call declaration for:%s failed\n", name);
      return nullptr;
    }
    llvm::Function *f { program->module->getFunction(name) };
    if (!f ) {
      f = llvm::Function::Create(ft, llvm::Function::ExternalLinkage, name, program->module.get());
    }
    return f;
  }

  void verifyFunctionDumpIROnError()
  {
    if(llvm::verifyFunction(*(program->currentFunc->getLLVMFunc()),&llvm::errs())) {
      fprintf(stderr,"\n\n LLVM syntax error:\n");
      program->module->print(llvm::errs(), nullptr);
    }
  }


  /*
    Some signatures have to be generated before processing input.
    (Should be done for all variadic runtime/simruntime functions).
    this function should only be executed once.
  */
  void generateInitialRuntimeSignatures ()
  {
    DBG("GenerateIntialRuntimeSignatures\n");
    std::vector<llvm::Type*> args {
      getLLVMType(MODELICA_INTEGER),
      getLLVMType(MODELICA_INTEGER)};
    createExternalCallDecl("mmc_mk_box",MODELICA_METATYPE,args,true);
    /*For records, we need a "struct record description" it is described in the C context as a utility
      function. We need to manually provide the signature to bridge between the C runtime and LLVM.
      When everything is compiled by LLVM this can probably be removed..
    */
    auto record_description = llvm::StructType::create(program->context, "struct.record_description");
    std::vector<llvm::Type*> fields {
                                     getLLVMType(MODELICA_METATYPE)
                                     ,getLLVMType(MODELICA_METATYPE)
                                     ,getLLVMType(MODELICA_METATYPE_PTR)
    };
    if (record_description->isOpaque()) {
      record_description->setBody(fields,false);
    }
    DBG("Intial runtime signatures generated\n");
  }
}; //End extern "C++"

#endif /*_LLVM_GEN_UTIL_H */
