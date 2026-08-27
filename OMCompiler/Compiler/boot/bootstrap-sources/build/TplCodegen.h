#ifndef TplCodegen__H
#define TplCodegen__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

extern struct record_description Tpl_BlockType_BT__ABS__INDENT__desc;

extern struct record_description Tpl_BlockType_BT__ANCHOR__desc;

extern struct record_description Tpl_BlockType_BT__INDENT__desc;

extern struct record_description Tpl_IterOptions_ITER__OPTIONS__desc;

extern struct record_description Tpl_StringToken_ST__LINE__desc;

extern struct record_description Tpl_StringToken_ST__NEW__LINE__desc;

extern struct record_description Tpl_StringToken_ST__STRING__desc;

extern struct record_description Tpl_StringToken_ST__STRING__LIST__desc;


DLLDirection
modelica_metatype omc_TplCodegen_sActualMMParams(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_argValues);
#define boxptr_TplCodegen_sActualMMParams omc_TplCodegen_sActualMMParams
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sActualMMParams,2,0) {(void*) boxptr_TplCodegen_sActualMMParams,0}};
#define boxvar_TplCodegen_sActualMMParams MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sActualMMParams)


#define boxptr_TplCodegen_lm__84 omc_TplCodegen_lm__84


DLLDirection
modelica_metatype omc_TplCodegen_sFunSignature(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_name, modelica_metatype _a_iargs, modelica_metatype _a_oargs);
#define boxptr_TplCodegen_sFunSignature omc_TplCodegen_sFunSignature
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sFunSignature,2,0) {(void*) boxptr_TplCodegen_sFunSignature,0}};
#define boxvar_TplCodegen_sFunSignature MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sFunSignature)


DLLDirection
modelica_metatype omc_TplCodegen_sTypedIdents(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_args);
#define boxptr_TplCodegen_sTypedIdents omc_TplCodegen_sTypedIdents
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sTypedIdents,2,0) {(void*) boxptr_TplCodegen_sTypedIdents,0}};
#define boxvar_TplCodegen_sTypedIdents MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sTypedIdents)


#define boxptr_TplCodegen_lm__81 omc_TplCodegen_lm__81


DLLDirection
modelica_metatype omc_TplCodegen_sConstStringToken(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_sConstStringToken omc_TplCodegen_sConstStringToken
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sConstStringToken,2,0) {(void*) boxptr_TplCodegen_sConstStringToken,0}};
#define boxvar_TplCodegen_sConstStringToken MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sConstStringToken)


#define boxptr_TplCodegen_lm__77 omc_TplCodegen_lm__77


#define boxptr_TplCodegen_lm__76 omc_TplCodegen_lm__76


#define boxptr_TplCodegen_lm__75 omc_TplCodegen_lm__75


DLLDirection
modelica_metatype omc_TplCodegen_sTemplateDef(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it, modelica_string _in_a_templId);
#define boxptr_TplCodegen_sTemplateDef omc_TplCodegen_sTemplateDef
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sTemplateDef,2,0) {(void*) boxptr_TplCodegen_sTemplateDef,0}};
#define boxvar_TplCodegen_sTemplateDef MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sTemplateDef)


DLLDirection
modelica_metatype omc_TplCodegen_sRecordTypeDef(threadData_t *threadData, modelica_metatype _txt, modelica_string _a_id, modelica_metatype _a_fields);
#define boxptr_TplCodegen_sRecordTypeDef omc_TplCodegen_sRecordTypeDef
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sRecordTypeDef,2,0) {(void*) boxptr_TplCodegen_sRecordTypeDef,0}};
#define boxvar_TplCodegen_sRecordTypeDef MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sRecordTypeDef)


#define boxptr_TplCodegen_fun__72 omc_TplCodegen_fun__72


#define boxptr_TplCodegen_lm__71 omc_TplCodegen_lm__71


DLLDirection
modelica_metatype omc_TplCodegen_sASTDefType(threadData_t *threadData, modelica_metatype _txt, modelica_string _a_id, modelica_metatype _a_info);
#define boxptr_TplCodegen_sASTDefType omc_TplCodegen_sASTDefType
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sASTDefType,2,0) {(void*) boxptr_TplCodegen_sASTDefType,0}};
#define boxvar_TplCodegen_sASTDefType MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sASTDefType)


#define boxptr_TplCodegen_fun__69 omc_TplCodegen_fun__69


#define boxptr_TplCodegen_lm__68 omc_TplCodegen_lm__68


#define boxptr_TplCodegen_lm__67 omc_TplCodegen_lm__67


#define boxptr_TplCodegen_lm__66 omc_TplCodegen_lm__66


DLLDirection
modelica_metatype omc_TplCodegen_sTemplPackage(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_sTemplPackage omc_TplCodegen_sTemplPackage
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_sTemplPackage,2,0) {(void*) boxptr_TplCodegen_sTemplPackage,0}};
#define boxvar_TplCodegen_sTemplPackage MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_sTemplPackage)


#define boxptr_TplCodegen_lm__64 omc_TplCodegen_lm__64


#define boxptr_TplCodegen_lm__63 omc_TplCodegen_lm__63


#define boxptr_TplCodegen_lm__62 omc_TplCodegen_lm__62


DLLDirection
modelica_metatype omc_TplCodegen_mmStatements(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_stmts);
#define boxptr_TplCodegen_mmStatements omc_TplCodegen_mmStatements
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmStatements,2,0) {(void*) boxptr_TplCodegen_mmStatements,0}};
#define boxvar_TplCodegen_mmStatements MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmStatements)


#define boxptr_TplCodegen_lm__59 omc_TplCodegen_lm__59


DLLDirection
modelica_metatype omc_TplCodegen_mmMatchingExp(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_mmMatchingExp omc_TplCodegen_mmMatchingExp
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmMatchingExp,2,0) {(void*) boxptr_TplCodegen_mmMatchingExp,0}};
#define boxvar_TplCodegen_mmMatchingExp MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmMatchingExp)


#define boxptr_TplCodegen_lm__57 omc_TplCodegen_lm__57


#define boxptr_TplCodegen_lm__56 omc_TplCodegen_lm__56


#define boxptr_TplCodegen_lm__55 omc_TplCodegen_lm__55


DLLDirection
modelica_metatype omc_TplCodegen_mmExp(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it, modelica_string _in_a_assignStr);
#define boxptr_TplCodegen_mmExp omc_TplCodegen_mmExp
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmExp,2,0) {(void*) boxptr_TplCodegen_mmExp,0}};
#define boxvar_TplCodegen_mmExp MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmExp)


#define boxptr_TplCodegen_lm__53 omc_TplCodegen_lm__53


#define boxptr_TplCodegen_fun__52 omc_TplCodegen_fun__52


#define boxptr_TplCodegen_lm__51 omc_TplCodegen_lm__51


DLLDirection
modelica_metatype omc_TplCodegen_mmEscapeStringConst(threadData_t *threadData, modelica_metatype _txt, modelica_string _a_internalValue, modelica_boolean _a_escapeNewLine);
DLLDirection
modelica_metatype boxptr_TplCodegen_mmEscapeStringConst(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_internalValue, modelica_metatype _a_escapeNewLine);
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmEscapeStringConst,2,0) {(void*) boxptr_TplCodegen_mmEscapeStringConst,0}};
#define boxvar_TplCodegen_mmEscapeStringConst MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmEscapeStringConst)


DLLDirection
modelica_metatype omc_TplCodegen_mmStringTokenConstant(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_mmStringTokenConstant omc_TplCodegen_mmStringTokenConstant
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmStringTokenConstant,2,0) {(void*) boxptr_TplCodegen_mmStringTokenConstant,0}};
#define boxvar_TplCodegen_mmStringTokenConstant MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmStringTokenConstant)


#define boxptr_TplCodegen_lm__45 omc_TplCodegen_lm__45


DLLDirection
modelica_metatype omc_TplCodegen_typeSig(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_typeSig omc_TplCodegen_typeSig
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_typeSig,2,0) {(void*) boxptr_TplCodegen_typeSig,0}};
#define boxvar_TplCodegen_typeSig MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_typeSig)


#define boxptr_TplCodegen_lm__43 omc_TplCodegen_lm__43


DLLDirection
modelica_metatype omc_TplCodegen_typedIdentsEx(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_decls, modelica_string _a_typePrfx, modelica_string _a_idPrfx);
#define boxptr_TplCodegen_typedIdentsEx omc_TplCodegen_typedIdentsEx
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_typedIdentsEx,2,0) {(void*) boxptr_TplCodegen_typedIdentsEx,0}};
#define boxvar_TplCodegen_typedIdentsEx MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_typedIdentsEx)


#define boxptr_TplCodegen_lm__41 omc_TplCodegen_lm__41


DLLDirection
modelica_metatype omc_TplCodegen_typedIdents(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_decls);
#define boxptr_TplCodegen_typedIdents omc_TplCodegen_typedIdents
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_typedIdents,2,0) {(void*) boxptr_TplCodegen_typedIdents,0}};
#define boxvar_TplCodegen_typedIdents MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_typedIdents)


#define boxptr_TplCodegen_lm__39 omc_TplCodegen_lm__39


DLLDirection
modelica_metatype omc_TplCodegen_mmPublic(threadData_t *threadData, modelica_metatype _in_txt, modelica_boolean _in_a_it);
DLLDirection
modelica_metatype boxptr_TplCodegen_mmPublic(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmPublic,2,0) {(void*) boxptr_TplCodegen_mmPublic,0}};
#define boxvar_TplCodegen_mmPublic MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmPublic)


DLLDirection
modelica_metatype omc_TplCodegen_pathIdent(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_path);
#define boxptr_TplCodegen_pathIdent omc_TplCodegen_pathIdent
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_pathIdent,2,0) {(void*) boxptr_TplCodegen_pathIdent,0}};
#define boxvar_TplCodegen_pathIdent MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_pathIdent)


DLLDirection
modelica_metatype omc_TplCodegen_inOutArgs(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_inArgs, modelica_metatype _a_outArgs);
#define boxptr_TplCodegen_inOutArgs omc_TplCodegen_inOutArgs
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_inOutArgs,2,0) {(void*) boxptr_TplCodegen_inOutArgs,0}};
#define boxvar_TplCodegen_inOutArgs MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_inOutArgs)


#define boxptr_TplCodegen_fun__35 omc_TplCodegen_fun__35


#define boxptr_TplCodegen_fun__34 omc_TplCodegen_fun__34


#define boxptr_TplCodegen_fun__33 omc_TplCodegen_fun__33


#define boxptr_TplCodegen_fun__32 omc_TplCodegen_fun__32


#define boxptr_TplCodegen_fun__31 omc_TplCodegen_fun__31


#define boxptr_TplCodegen_fun__30 omc_TplCodegen_fun__30


#define boxptr_TplCodegen_fun__29 omc_TplCodegen_fun__29


DLLDirection
modelica_metatype omc_TplCodegen_mmForLoopFunBody(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_inArgs, modelica_metatype _a_outArgs, modelica_metatype _a_locals, modelica_string _a_idxName, modelica_string _a_arrName, modelica_string _a_eltName, modelica_metatype _a_statements);
#define boxptr_TplCodegen_mmForLoopFunBody omc_TplCodegen_mmForLoopFunBody
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmForLoopFunBody,2,0) {(void*) boxptr_TplCodegen_mmForLoopFunBody,0}};
#define boxvar_TplCodegen_mmForLoopFunBody MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmForLoopFunBody)


#define boxptr_TplCodegen_lm__26 omc_TplCodegen_lm__26


#define boxptr_TplCodegen_fun__25 omc_TplCodegen_fun__25


#define boxptr_TplCodegen_fun__23 omc_TplCodegen_fun__23


DLLDirection
modelica_metatype omc_TplCodegen_mmMatchFunBody(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_inArgs, modelica_metatype _a_outArgs, modelica_metatype _a_locals, modelica_metatype _a_matchCases);
#define boxptr_TplCodegen_mmMatchFunBody omc_TplCodegen_mmMatchFunBody
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmMatchFunBody,2,0) {(void*) boxptr_TplCodegen_mmMatchFunBody,0}};
#define boxvar_TplCodegen_mmMatchFunBody MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmMatchFunBody)


#define boxptr_TplCodegen_lm__20 omc_TplCodegen_lm__20


#define boxptr_TplCodegen_fun__19 omc_TplCodegen_fun__19


#define boxptr_TplCodegen_lm__18 omc_TplCodegen_lm__18


#define boxptr_TplCodegen_fun__17 omc_TplCodegen_fun__17


#define boxptr_TplCodegen_lm__16 omc_TplCodegen_lm__16


#define boxptr_TplCodegen_lm__15 omc_TplCodegen_lm__15


#define boxptr_TplCodegen_lm__14 omc_TplCodegen_lm__14


#define boxptr_TplCodegen_fun__13 omc_TplCodegen_fun__13


#define boxptr_TplCodegen_lm__12 omc_TplCodegen_lm__12


DLLDirection
modelica_metatype omc_TplCodegen_mmDeclaration(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_mmDeclaration omc_TplCodegen_mmDeclaration
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmDeclaration,2,0) {(void*) boxptr_TplCodegen_mmDeclaration,0}};
#define boxvar_TplCodegen_mmDeclaration MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmDeclaration)


#define boxptr_TplCodegen_fun__9 omc_TplCodegen_fun__9


#define boxptr_TplCodegen_lm__7 omc_TplCodegen_lm__7


#define boxptr_TplCodegen_fun__5 omc_TplCodegen_fun__5


DLLDirection
modelica_metatype omc_TplCodegen_mmPackage(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_it);
#define boxptr_TplCodegen_mmPackage omc_TplCodegen_mmPackage
static const MMC_DEFSTRUCTLIT(boxvar_lit_TplCodegen_mmPackage,2,0) {(void*) boxptr_TplCodegen_mmPackage,0}};
#define boxvar_TplCodegen_mmPackage MMC_REFSTRUCTLIT(boxvar_lit_TplCodegen_mmPackage)


#define boxptr_TplCodegen_lm__3 omc_TplCodegen_lm__3

#ifdef __cplusplus
}
#endif
#endif
