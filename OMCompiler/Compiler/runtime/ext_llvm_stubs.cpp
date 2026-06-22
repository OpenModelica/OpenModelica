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

#include "ext_llvm.hpp"
#include "errorext.h"

#define LLVM_STUB() {c_add_message(NULL,0,ErrorType_scripting,ErrorLevel_error,"LLVM support not enabled.",NULL,0);MMC_THROW();}
#define STUB_BINARY(NAME) int NAME(const char*,const char*,const char*){LLVM_STUB(); return 0;}
#define STUB_UNARY(NAME) int NAME(const char*,const char*){LLVM_STUB(); return 0;}

extern "C"
{
  void initGen(const char *) {LLVM_STUB();}

  /* Functions called externally from Compiler/LLVM/MidToLLVM.mo */
  void* runJIT(void *valLst) {
    LLVM_STUB();
    return nullptr;
  }

  int createFunctionProtArg(const uint8_t,const char *) {
    LLVM_STUB();
    return 0;
  }

  void finishGen() {LLVM_STUB();}

  void startFuncGen(const char *) {LLVM_STUB();}

  int genFunctionType() {LLVM_STUB(); return 0;}

  int createFunctionPrototype(const char *) {LLVM_STUB(); return NULL;}

  int createFunctionBody(const char *) {LLVM_STUB(); return NULL;}

  int setNewActiveBlock(const modelica_integer) {LLVM_STUB(); return 0;}

  /*Functions to create misc instructions */
  int createStoreVarInst(const char *src, const char *) {LLVM_STUB(); return 0;}

  /*Function related */
  int createReturn(const char *){LLVM_STUB(); return 0;}

  int createExit(const modelica_integer exit_id){LLVM_STUB(); return 0;}

  int createCallArg(const char *){LLVM_STUB(); return 0;}

  int createCall(const char *, const uint8_t, const char *, modelica_boolean, modelica_boolean){LLVM_STUB(); return 0;}

  /* Unary instructions */
  STUB_UNARY(createIUminus)
  STUB_UNARY(createDUminus)
  STUB_UNARY(createNot)

  //Move instructions, e.g casts
  STUB_UNARY(createIntToDouble)
  STUB_UNARY(createDoubleToInt)
  STUB_UNARY(createIntToBool)
  STUB_UNARY(createBoolToInt)
  STUB_UNARY(createIntToMeta)
  STUB_UNARY(createMetaToInt)
  STUB_UNARY(createDoubleToBool)
  STUB_UNARY(createBoolToDouble)
  STUB_UNARY(createMetaToDouble)
  STUB_UNARY(createDoubleToMeta)

  /* Binary instructions */
  STUB_BINARY(createIAdd)
  STUB_BINARY(createISub)
  STUB_BINARY(createIMul)
  STUB_BINARY(createIDiv)
  STUB_BINARY(createIPow)
  STUB_BINARY(createILess)
  STUB_BINARY(createILessEq)
  STUB_BINARY(createIEqual)
  STUB_BINARY(createINequal)
  STUB_BINARY(createDAdd)
  STUB_BINARY(createDSub)
  STUB_BINARY(createDMul)
  STUB_BINARY(createDDiv)
  STUB_BINARY(createDPow)
  STUB_BINARY(createDLess)
  STUB_BINARY(createDLessq)
  STUB_BINARY(createDEqual)
  STUB_BINARY(createDNequal)
  STUB_BINARY(createBAdd)
  STUB_BINARY(createBSub)
  STUB_BINARY(createBMul)
  STUB_BINARY(createBBiv)
  STUB_BINARY(createBPow)
  STUB_BINARY(createBLess)
  STUB_BINARY(createBLESSQ)
  STUB_BINARY(createBEqual)
  STUB_BINARY(createBNequal)
  STUB_BINARY(createPow)

  int storeLiteralInt64(const modelica_integer,const char*){LLVM_STUB(); return 0;}

  int storeLiteralReal (const double,const char *){LLVM_STUB(); return 0;}

  int storeLiteralIntForPtrTy(const uint64_t addr,const char *dest){LLVM_STUB(); return 0;}

  /* Model simulation via LLVM JIT (see llvm_gen.cpp for the real impl). */
  const char *omc_getLLVMToolsDir() { return ""; }
  int omc_runModelViaJIT(const char *, const char *, const char *, const char *) {LLVM_STUB(); return 1;}
}
