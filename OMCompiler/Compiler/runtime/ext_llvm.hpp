#ifndef _EXT_LLVM_H
#define _EXT_LLVM_H

#include "ModelicaUtilities.h"
#include "openmodelica.h"
#include "util/modelica.h"
extern "C"
{
  void initGen(const char *);

  /* Functions called externally from Compiler/LLVM/MidToLLVM.mo */
  void* runJIT(void *valLst);

  int createFunctionProtArg(const uint8_t,const char *);

  void finishGen();

  void startFuncGen(const char *);

  int genFunctionType();

  int createFunctionPrototype(const char *);

  int createFunctionBody(const char *);

  int setNewActiveBlock(const modelica_integer);

  /*Functions to create misc instructions */
  int createStoreVarInst(const char *src, const char *);

  /*Function related */
  int createReturn(const char *);

  int createExit(const modelica_integer exit_id);

  int createCallArg(const char *);

  int createCall(const char *, const uint8_t, const char *, modelica_boolean, modelica_boolean);

  /* Unary instructions */
  int createIUminus(const char *src,const char *);

  int createDUminus(const char *src, const char *);

  int createNot(const char *src,const char *);

  //Move instructions, e.g casts
  int createIntToDouble(const char*,const char*);

  int createDoubleToInt(const char*,const char*);

  int createIntToBool(const char*,const char*);

  int createBoolToInt(const char*,const char*);

  int createIntToMeta(const char*,const char*);

  int createMetaToInt(const char*,const char*);

  int createDoubleToBool(const char*,const char*);

  int createBoolToDouble(const char*,const char*);

  int createDoubleToMeta(const char*,const char*);

  int createMetaToDouble(const char*,const char*);

  int createDoubleToMeta(const char*,const char*);

  /* Binary instructions */
  int createIAdd(const char *, const char *,const char *);

  int createISub(const char *, const char *,const char *);

  int createIMul(const char *, const char *,const char *);

  int createIDiv(const char *, const char *,const char *);

  int createIPow(const char *, const char *,const char *);

  int createILess(const char *, const char *,const char *);

  int createILESSQ(const char *, const char *,const char *);

  int createIEqual(const char *, const char *,const char *);

  int createINequal(const char *, const char *,const char *);

  int createDAdd(const char* , const char *, const char *);

  int createDSub(const char *, const char *, const char *);

  int createDMul(const char *, const char *, const char *);

  int createDDiv(const char *, const char *, const char *);

  int createDPow(const char *, const char *, const char *);

  int createDLess(const char *, const char *, const char *);

  int createDLessq(const char *, const char *, const char *);

  int createDEqual(const char *, const char *, const char *);

  int createDNequal(const char *, const char *, const char *);

  int createBAdd(const char * , const char *, const char *);

  int createBSub(const char *, const char *, const char *);

  int createBMul(const char *, const char *, const char *);

  int createBBiv(const char *, const char *, const char *);

  int createBPow(const char *, const char *, const char *);

  int createBLess(const char *, const char *, const char *);

  int createBLESSQ(const char *, const char *, const char *);

  int createBEqual(const char *, const char *, const char *);

  int createBNequal(const char *, const char *, const char *);

  int createPow(const char *, const char *, const char *);

  int storeLiteralInt64 (const modelica_integer,const char*);

  int storeLiteralReal (const double,const char *);

  int storeLiteralIntForPtrTy(const uint64_t addr,const char *dest);
} // end extern C
#endif //_EXT_LLVM_H
