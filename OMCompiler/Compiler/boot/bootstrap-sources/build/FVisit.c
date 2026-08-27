#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/FVisit.c"
#endif
#include "omc_simulation_settings.h"
#include "FVisit.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,17,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "FVisit.avlTreeReplace failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,28,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,1) {_OMC_LIT5,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,0,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,2,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data ",  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,3,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,2,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,5,3) {&FCore_VAvlTree_VAVLTREENODE__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Env.avlTreeAdd failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,21,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,1) {_OMC_LIT13,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "Already visited: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,17,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data " seq: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,6,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,3,3) {&FCore_Visited_V__desc,_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#include "util/modelica.h"
#include "FVisit_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_avlTreeReplace2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKeyComp, modelica_integer _inKey, modelica_metatype _inValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_avlTreeReplace2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKeyComp, modelica_metatype _inKey, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeReplace2,2,0) {(void*) boxptr_FVisit_avlTreeReplace2,0}};
#define boxvar_FVisit_avlTreeReplace2 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeReplace2)
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_printAvlTreeStrPP2(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inIndent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStrPP2,2,0) {(void*) boxptr_FVisit_printAvlTreeStrPP2,0}};
#define boxvar_FVisit_printAvlTreeStrPP2 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStrPP2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_FVisit_getHeight(threadData_t *threadData, modelica_metatype _bt);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_getHeight(threadData_t *threadData, modelica_metatype _bt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_getHeight,2,0) {(void*) boxptr_FVisit_getHeight,0}};
#define boxvar_FVisit_getHeight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_getHeight)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_computeHeight(threadData_t *threadData, modelica_metatype _bt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_computeHeight,2,0) {(void*) boxptr_FVisit_computeHeight,0}};
#define boxvar_FVisit_computeHeight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_computeHeight)
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_printAvlTreeStr(threadData_t *threadData, modelica_metatype _inAvlTree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStr,2,0) {(void*) boxptr_FVisit_printAvlTreeStr,0}};
#define boxvar_FVisit_printAvlTreeStr MMC_REFSTRUCTLIT(boxvar_lit_FVisit_printAvlTreeStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_getOptionStr(threadData_t *threadData, modelica_metatype _inTypeAOption, modelica_fnptr _inFuncTypeTypeAToString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_getOptionStr,2,0) {(void*) boxptr_FVisit_getOptionStr,0}};
#define boxvar_FVisit_getOptionStr MMC_REFSTRUCTLIT(boxvar_lit_FVisit_getOptionStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_avlTreeGet2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _keyComp, modelica_integer _inKey);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_avlTreeGet2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _keyComp, modelica_metatype _inKey);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_avlTreeGet2,2,0) {(void*) boxptr_FVisit_avlTreeGet2,0}};
#define boxvar_FVisit_avlTreeGet2 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_avlTreeGet2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_FVisit_differenceInHeight(threadData_t *threadData, modelica_metatype _node);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_differenceInHeight(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_differenceInHeight,2,0) {(void*) boxptr_FVisit_differenceInHeight,0}};
#define boxvar_FVisit_differenceInHeight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_differenceInHeight)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rotateRight(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_rotateRight,2,0) {(void*) boxptr_FVisit_rotateRight,0}};
#define boxvar_FVisit_rotateRight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_rotateRight)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_getOption(threadData_t *threadData, modelica_metatype _opt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_getOption,2,0) {(void*) boxptr_FVisit_getOption,0}};
#define boxvar_FVisit_getOption MMC_REFSTRUCTLIT(boxvar_lit_FVisit_getOption)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rotateLeft(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_rotateLeft,2,0) {(void*) boxptr_FVisit_rotateLeft,0}};
#define boxvar_FVisit_rotateLeft MMC_REFSTRUCTLIT(boxvar_lit_FVisit_rotateLeft)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_exchangeRight(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_exchangeRight,2,0) {(void*) boxptr_FVisit_exchangeRight,0}};
#define boxvar_FVisit_exchangeRight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_exchangeRight)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_exchangeLeft(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_exchangeLeft,2,0) {(void*) boxptr_FVisit_exchangeLeft,0}};
#define boxvar_FVisit_exchangeLeft MMC_REFSTRUCTLIT(boxvar_lit_FVisit_exchangeLeft)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rightNode(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_rightNode,2,0) {(void*) boxptr_FVisit_rightNode,0}};
#define boxvar_FVisit_rightNode MMC_REFSTRUCTLIT(boxvar_lit_FVisit_rightNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_leftNode(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_leftNode,2,0) {(void*) boxptr_FVisit_leftNode,0}};
#define boxvar_FVisit_leftNode MMC_REFSTRUCTLIT(boxvar_lit_FVisit_leftNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_setLeft(threadData_t *threadData, modelica_metatype _node, modelica_metatype _left);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_setLeft,2,0) {(void*) boxptr_FVisit_setLeft,0}};
#define boxvar_FVisit_setLeft MMC_REFSTRUCTLIT(boxvar_lit_FVisit_setLeft)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_setRight(threadData_t *threadData, modelica_metatype _node, modelica_metatype _right);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_setRight,2,0) {(void*) boxptr_FVisit_setRight,0}};
#define boxvar_FVisit_setRight MMC_REFSTRUCTLIT(boxvar_lit_FVisit_setRight)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance4(threadData_t *threadData, modelica_metatype _inBt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_doBalance4,2,0) {(void*) boxptr_FVisit_doBalance4,0}};
#define boxvar_FVisit_doBalance4 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_doBalance4)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance3(threadData_t *threadData, modelica_metatype _inBt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_doBalance3,2,0) {(void*) boxptr_FVisit_doBalance3,0}};
#define boxvar_FVisit_doBalance3 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_doBalance3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance2(threadData_t *threadData, modelica_boolean _differenceIsNegative, modelica_metatype _inBt);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_doBalance2(threadData_t *threadData, modelica_metatype _differenceIsNegative, modelica_metatype _inBt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_doBalance2,2,0) {(void*) boxptr_FVisit_doBalance2,0}};
#define boxvar_FVisit_doBalance2 MMC_REFSTRUCTLIT(boxvar_lit_FVisit_doBalance2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance(threadData_t *threadData, modelica_integer _difference, modelica_metatype _inBt);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_doBalance(threadData_t *threadData, modelica_metatype _difference, modelica_metatype _inBt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_doBalance,2,0) {(void*) boxptr_FVisit_doBalance,0}};
#define boxvar_FVisit_doBalance MMC_REFSTRUCTLIT(boxvar_lit_FVisit_doBalance)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_balance(threadData_t *threadData, modelica_metatype _inBt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_balance,2,0) {(void*) boxptr_FVisit_balance,0}};
#define boxvar_FVisit_balance MMC_REFSTRUCTLIT(boxvar_lit_FVisit_balance)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_nodeValue(threadData_t *threadData, modelica_metatype _bt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_nodeValue,2,0) {(void*) boxptr_FVisit_nodeValue,0}};
#define boxvar_FVisit_nodeValue MMC_REFSTRUCTLIT(boxvar_lit_FVisit_nodeValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_createEmptyAvlIfNone(threadData_t *threadData, modelica_metatype _t);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FVisit_createEmptyAvlIfNone,2,0) {(void*) boxptr_FVisit_createEmptyAvlIfNone,0}};
#define boxvar_FVisit_createEmptyAvlIfNone MMC_REFSTRUCTLIT(boxvar_lit_FVisit_createEmptyAvlIfNone)
DLLExport
modelica_metatype omc_FVisit_getAvlValue(threadData_t *threadData, modelica_metatype _inValue)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inValue;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_res = tmpMeta[1];
tmpMeta[0] = _res;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_res = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_FVisit_getAvlTreeValues(threadData_t *threadData, modelica_metatype _tree, modelica_metatype _acc)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _tree;
{
modelica_metatype _value = NULL;
modelica_metatype _left = NULL;
modelica_metatype _right = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _acc;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
_value = tmpMeta[4];
_left = tmpMeta[5];
_right = tmpMeta[6];
_rest = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_right, _rest);
tmpMeta[1] = mmc_mk_cons(_left, tmpMeta[2]);
_tree = tmpMeta[1];
_acc = omc_List_consOption(threadData, _value, _acc);
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (!optionNone(tmpMeta[1])) goto tmp2_end;
_rest = tmpMeta[2];
_tree = _rest;
goto _tailrecursive;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_res = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_avlTreeReplace2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKeyComp, modelica_integer _inKey, modelica_metatype _inValue)
{
modelica_metatype _outAvlTree = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;modelica_integer tmp3_3;modelica_metatype tmp3_4;
tmp3_1 = _inAvlTree;
tmp3_2 = _inKeyComp;
tmp3_3 = _inKey;
tmp3_4 = _inValue;
{
modelica_integer _key;
modelica_metatype _value = NULL;
modelica_metatype _left = NULL;
modelica_metatype _right = NULL;
modelica_integer _h;
modelica_metatype _t = NULL;
modelica_metatype _oval = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(tmp3_2)) {
case 0: {
modelica_integer tmp4;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp4 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_h = tmp4;
_left = tmpMeta[4];
_right = tmpMeta[5];
_key = tmp3_3;
_value = tmp3_4;
tmpMeta[1] = mmc_mk_box3(3, &FCore_VAvlTreeValue_VAVLTREEVALUE__desc, mmc_mk_integer(_key), _value);
tmpMeta[2] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, mmc_mk_some(tmpMeta[1]), mmc_mk_integer(_h), _left, _right);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_oval = tmpMeta[1];
_h = tmp5;
_left = tmpMeta[3];
_right = tmpMeta[4];
_key = tmp3_3;
_value = tmp3_4;
_t = omc_FVisit_createEmptyAvlIfNone(threadData, _right);
_t = omc_FVisit_avlTreeReplace(threadData, _t, _key, _value);
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _oval, mmc_mk_integer(_h), _left, mmc_mk_some(_t));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case -1: {
modelica_integer tmp6;
if (-1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_oval = tmpMeta[1];
_h = tmp6;
_left = tmpMeta[3];
_right = tmpMeta[4];
_key = tmp3_3;
_value = tmp3_4;
_t = omc_FVisit_createEmptyAvlIfNone(threadData, _left);
_t = omc_FVisit_avlTreeReplace(threadData, _t, _key, _value);
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _oval, mmc_mk_integer(_h), mmc_mk_some(_t), _right);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outAvlTree = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAvlTree;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_avlTreeReplace2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKeyComp, modelica_metatype _inKey, modelica_metatype _inValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outAvlTree = NULL;
tmp1 = mmc_unbox_integer(_inKeyComp);
tmp2 = mmc_unbox_integer(_inKey);
_outAvlTree = omc_FVisit_avlTreeReplace2(threadData, _inAvlTree, tmp1, tmp2, _inValue);
return _outAvlTree;
}
DLLExport
modelica_metatype omc_FVisit_avlTreeReplace(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey, modelica_metatype _inValue)
{
modelica_metatype _outAvlTree = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inAvlTree;
tmp3_2 = _inKey;
tmp3_3 = _inValue;
{
modelica_integer _key;
modelica_integer _rkey;
modelica_metatype _value = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
_rkey = tmp5;
_key = tmp3_2;
_value = tmp3_3;
tmpMeta[0] = omc_FVisit_avlTreeReplace2(threadData, _inAvlTree, omc_FVisit_keyCompare(threadData, _key, _rkey), _key, _value);
goto tmp2_done;
}
case 1: {
omc_Error_addMessage(threadData, _OMC_LIT4, _OMC_LIT6);
goto goto_1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outAvlTree = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAvlTree;
}
modelica_metatype boxptr_FVisit_avlTreeReplace(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey, modelica_metatype _inValue)
{
modelica_integer tmp1;
modelica_metatype _outAvlTree = NULL;
tmp1 = mmc_unbox_integer(_inKey);
_outAvlTree = omc_FVisit_avlTreeReplace(threadData, _inAvlTree, tmp1, _inValue);
return _outAvlTree;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_printAvlTreeStrPP2(threadData_t *threadData, modelica_metatype _inTree, modelica_string _inIndent)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inTree;
{
modelica_integer _rkey;
modelica_metatype _l = NULL;
modelica_metatype _r = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _indent = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_rkey = tmp6;
_l = tmpMeta[4];
_r = tmpMeta[5];
tmpMeta[0] = stringAppend(_inIndent,_OMC_LIT8);
_indent = tmpMeta[0];
_s1 = omc_FVisit_printAvlTreeStrPP2(threadData, _l, _indent);
_s2 = omc_FVisit_printAvlTreeStrPP2(threadData, _r, _indent);
tmpMeta[0] = stringAppend(_OMC_LIT9,_inIndent);
tmpMeta[1] = stringAppend(tmpMeta[0],omc_FVisit_keyStr(threadData, _rkey));
tmpMeta[2] = stringAppend(tmpMeta[1],_s1);
tmpMeta[3] = stringAppend(tmpMeta[2],_s2);
tmp1 = tmpMeta[3];
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_l = tmpMeta[2];
_r = tmpMeta[3];
tmpMeta[0] = stringAppend(_inIndent,_OMC_LIT8);
_indent = tmpMeta[0];
_s1 = omc_FVisit_printAvlTreeStrPP2(threadData, _l, _indent);
_s2 = omc_FVisit_printAvlTreeStrPP2(threadData, _r, _indent);
tmpMeta[0] = stringAppend(_OMC_LIT9,_s1);
tmpMeta[1] = stringAppend(tmpMeta[0],_s2);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_FVisit_printAvlTreeStrPP(threadData_t *threadData, modelica_metatype _inTree)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_FVisit_printAvlTreeStrPP2(threadData, mmc_mk_some(_inTree), _OMC_LIT7);
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_FVisit_getHeight(threadData_t *threadData, modelica_metatype _bt)
{
modelica_integer _height;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _bt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_height = tmp6;
tmp1 = _height;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_height = tmp1;
_return: OMC_LABEL_UNUSED
return _height;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_getHeight(threadData_t *threadData, modelica_metatype _bt)
{
modelica_integer _height;
modelica_metatype out_height;
_height = omc_FVisit_getHeight(threadData, _bt);
out_height = mmc_mk_icon(_height);
return out_height;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_computeHeight(threadData_t *threadData, modelica_metatype _bt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _bt;
{
modelica_metatype _l = NULL;
modelica_metatype _r = NULL;
modelica_metatype _v = NULL;
modelica_integer _hl;
modelica_integer _hr;
modelica_integer _height;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_v = tmpMeta[1];
_l = tmpMeta[3];
_r = tmpMeta[4];
_hl = omc_FVisit_getHeight(threadData, _l);
_hr = omc_FVisit_getHeight(threadData, _r);
_height = ((modelica_integer) 1) + modelica_integer_max((modelica_integer)(_hl),(modelica_integer)(_hr));
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _v, mmc_mk_integer(_height), _l, _r);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_printAvlTreeStr(threadData_t *threadData, modelica_metatype _inAvlTree)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAvlTree;
{
modelica_string _s2 = NULL;
modelica_string _s3 = NULL;
modelica_metatype _rval = NULL;
modelica_metatype _l = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_string tmp7;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_rval = tmpMeta[2];
_l = tmpMeta[3];
_r = tmpMeta[4];
_s2 = omc_FVisit_getOptionStr(threadData, _l, boxvar_FVisit_printAvlTreeStr);
_s3 = omc_FVisit_getOptionStr(threadData, _r, boxvar_FVisit_printAvlTreeStr);
tmpMeta[0] = stringAppend(_OMC_LIT9,omc_FVisit_valueStr(threadData, _rval));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT10);
tmp6 = (modelica_boolean)(stringEqual(_s2, _OMC_LIT7));
if(tmp6)
{
tmp7 = _OMC_LIT7;
}
else
{
tmpMeta[2] = stringAppend(_s2,_OMC_LIT11);
tmp7 = tmpMeta[2];
}
tmpMeta[3] = stringAppend(tmpMeta[1],tmp7);
tmpMeta[4] = stringAppend(tmpMeta[3],_s3);
tmp1 = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_boolean tmp8;
modelica_string tmp9;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_l = tmpMeta[1];
_r = tmpMeta[2];
_s2 = omc_FVisit_getOptionStr(threadData, _l, boxvar_FVisit_printAvlTreeStr);
_s3 = omc_FVisit_getOptionStr(threadData, _r, boxvar_FVisit_printAvlTreeStr);
tmp8 = (modelica_boolean)(stringEqual(_s2, _OMC_LIT7));
if(tmp8)
{
tmp9 = _OMC_LIT7;
}
else
{
tmpMeta[0] = stringAppend(_s2,_OMC_LIT11);
tmp9 = tmpMeta[0];
}
tmpMeta[1] = stringAppend(tmp9,_s3);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_FVisit_getOptionStr(threadData_t *threadData, modelica_metatype _inTypeAOption, modelica_fnptr _inFuncTypeTypeAToString)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_fnptr tmp4_2;
tmp4_1 = _inTypeAOption;
tmp4_2 = ((modelica_fnptr) _inFuncTypeTypeAToString);
{
modelica_metatype _a = NULL;
modelica_fnptr _r;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_a = tmpMeta[0];
_r = tmp4_2;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 2))), _a) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_r), 1)))) (threadData, _a);
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_avlTreeGet2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _keyComp, modelica_integer _inKey)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;modelica_integer tmp3_3;
tmp3_1 = _inAvlTree;
tmp3_2 = _keyComp;
tmp3_3 = _inKey;
{
modelica_integer _key;
modelica_metatype _rval = NULL;
modelica_metatype _left = NULL;
modelica_metatype _right = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(tmp3_2)) {
case 0: {
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_rval = tmpMeta[3];
tmpMeta[0] = _rval;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_right = tmpMeta[2];
_key = tmp3_3;
tmpMeta[0] = omc_FVisit_avlTreeGet(threadData, _right, _key);
goto tmp2_done;
}
case -1: {
if (-1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_left = tmpMeta[2];
_key = tmp3_3;
tmpMeta[0] = omc_FVisit_avlTreeGet(threadData, _left, _key);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outValue = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_avlTreeGet2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _keyComp, modelica_metatype _inKey)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outValue = NULL;
tmp1 = mmc_unbox_integer(_keyComp);
tmp2 = mmc_unbox_integer(_inKey);
_outValue = omc_FVisit_avlTreeGet2(threadData, _inAvlTree, tmp1, tmp2);
return _outValue;
}
DLLExport
modelica_metatype omc_FVisit_avlTreeGet(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;
tmp3_1 = _inAvlTree;
tmp3_2 = _inKey;
{
modelica_integer _rkey;
modelica_integer _key;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
_rkey = tmp5;
_key = tmp3_2;
tmpMeta[0] = omc_FVisit_avlTreeGet2(threadData, _inAvlTree, omc_FVisit_keyCompare(threadData, _key, _rkey), _key);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outValue = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValue;
}
modelica_metatype boxptr_FVisit_avlTreeGet(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey)
{
modelica_integer tmp1;
modelica_metatype _outValue = NULL;
tmp1 = mmc_unbox_integer(_inKey);
_outValue = omc_FVisit_avlTreeGet(threadData, _inAvlTree, tmp1);
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_FVisit_differenceInHeight(threadData_t *threadData, modelica_metatype _node)
{
modelica_integer _diff;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
modelica_integer _lh;
modelica_integer _rh;
modelica_metatype _l = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_l = tmpMeta[0];
_r = tmpMeta[1];
_lh = omc_FVisit_getHeight(threadData, _l);
_rh = omc_FVisit_getHeight(threadData, _r);
tmp1 = _lh - _rh;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_diff = tmp1;
_return: OMC_LABEL_UNUSED
return _diff;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_differenceInHeight(threadData_t *threadData, modelica_metatype _node)
{
modelica_integer _diff;
modelica_metatype out_diff;
_diff = omc_FVisit_differenceInHeight(threadData, _node);
out_diff = mmc_mk_icon(_diff);
return out_diff;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rotateRight(threadData_t *threadData, modelica_metatype _node)
{
modelica_metatype _outNode = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outNode = omc_FVisit_exchangeRight(threadData, omc_FVisit_getOption(threadData, omc_FVisit_leftNode(threadData, _node)), _node);
_return: OMC_LABEL_UNUSED
return _outNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_getOption(threadData_t *threadData, modelica_metatype _opt)
{
modelica_metatype _val = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _opt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_val = tmpMeta[1];
tmpMeta[0] = _val;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_val = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _val;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rotateLeft(threadData_t *threadData, modelica_metatype _node)
{
modelica_metatype _outNode = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outNode = omc_FVisit_exchangeLeft(threadData, omc_FVisit_getOption(threadData, omc_FVisit_rightNode(threadData, _node)), _node);
_return: OMC_LABEL_UNUSED
return _outNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_exchangeRight(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParent)
{
modelica_metatype _outParent = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inNode;
tmp3_2 = _inParent;
{
modelica_metatype _node = NULL;
modelica_metatype _parent = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_node = tmp3_1;
_parent = tmp3_2;
_parent = omc_FVisit_setLeft(threadData, _parent, omc_FVisit_rightNode(threadData, _node));
_parent = omc_FVisit_balance(threadData, _parent);
_node = omc_FVisit_setRight(threadData, _node, mmc_mk_some(_parent));
tmpMeta[0] = omc_FVisit_balance(threadData, _node);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outParent = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_exchangeLeft(threadData_t *threadData, modelica_metatype _inNode, modelica_metatype _inParent)
{
modelica_metatype _outParent = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inNode;
tmp3_2 = _inParent;
{
modelica_metatype _node = NULL;
modelica_metatype _parent = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_node = tmp3_1;
_parent = tmp3_2;
_parent = omc_FVisit_setRight(threadData, _parent, omc_FVisit_leftNode(threadData, _node));
_parent = omc_FVisit_balance(threadData, _parent);
_node = omc_FVisit_setLeft(threadData, _node, mmc_mk_some(_parent));
tmpMeta[0] = omc_FVisit_balance(threadData, _node);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outParent = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_rightNode(threadData_t *threadData, modelica_metatype _node)
{
modelica_metatype _subNode = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_subNode = tmpMeta[1];
tmpMeta[0] = _subNode;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_subNode = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _subNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_leftNode(threadData_t *threadData, modelica_metatype _node)
{
modelica_metatype _subNode = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_subNode = tmpMeta[1];
tmpMeta[0] = _subNode;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_subNode = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _subNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_setLeft(threadData_t *threadData, modelica_metatype _node, modelica_metatype _left)
{
modelica_metatype _outNode = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
modelica_metatype _value = NULL;
modelica_metatype _r = NULL;
modelica_integer _height;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_value = tmpMeta[1];
_height = tmp5;
_r = tmpMeta[3];
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _value, mmc_mk_integer(_height), _left, _r);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outNode = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_setRight(threadData_t *threadData, modelica_metatype _node, modelica_metatype _right)
{
modelica_metatype _outNode = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
modelica_metatype _value = NULL;
modelica_metatype _l = NULL;
modelica_integer _height;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_value = tmpMeta[1];
_height = tmp5;
_l = tmpMeta[3];
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _value, mmc_mk_integer(_height), _l, _right);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outNode = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance4(threadData_t *threadData, modelica_metatype _inBt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inBt;
{
modelica_metatype _rl = NULL;
modelica_metatype _bt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
_bt = tmp3_1;
tmp5 = (omc_FVisit_differenceInHeight(threadData, omc_FVisit_getOption(threadData, omc_FVisit_leftNode(threadData, _bt))) < ((modelica_integer) 0));
if (1 != tmp5) goto goto_1;
_rl = omc_FVisit_rotateLeft(threadData, omc_FVisit_getOption(threadData, omc_FVisit_leftNode(threadData, _bt)));
tmpMeta[0] = omc_FVisit_setLeft(threadData, _bt, mmc_mk_some(_rl));
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inBt;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance3(threadData_t *threadData, modelica_metatype _inBt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inBt;
{
modelica_metatype _rr = NULL;
modelica_metatype _bt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
_bt = tmp3_1;
tmp5 = (omc_FVisit_differenceInHeight(threadData, omc_FVisit_getOption(threadData, omc_FVisit_rightNode(threadData, _bt))) > ((modelica_integer) 0));
if (1 != tmp5) goto goto_1;
_rr = omc_FVisit_rotateRight(threadData, omc_FVisit_getOption(threadData, omc_FVisit_rightNode(threadData, _bt)));
tmpMeta[0] = omc_FVisit_setRight(threadData, _bt, mmc_mk_some(_rr));
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inBt;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance2(threadData_t *threadData, modelica_boolean _differenceIsNegative, modelica_metatype _inBt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _differenceIsNegative;
tmp3_2 = _inBt;
{
modelica_metatype _bt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
_bt = tmp3_2;
_bt = omc_FVisit_doBalance3(threadData, _bt);
tmpMeta[0] = omc_FVisit_rotateLeft(threadData, _bt);
goto tmp2_done;
}
case 1: {
if (0 != tmp3_1) goto tmp2_end;
_bt = tmp3_2;
_bt = omc_FVisit_doBalance4(threadData, _bt);
tmpMeta[0] = omc_FVisit_rotateRight(threadData, _bt);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_doBalance2(threadData_t *threadData, modelica_metatype _differenceIsNegative, modelica_metatype _inBt)
{
modelica_integer tmp1;
modelica_metatype _outBt = NULL;
tmp1 = mmc_unbox_integer(_differenceIsNegative);
_outBt = omc_FVisit_doBalance2(threadData, tmp1, _inBt);
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_doBalance(threadData_t *threadData, modelica_integer _difference, modelica_metatype _inBt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _difference;
tmp3_2 = _inBt;
{
modelica_metatype _bt = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(tmp3_1)) {
case -1: {
if (-1 != tmp3_1) goto tmp2_end;
_bt = tmp3_2;
tmpMeta[0] = omc_FVisit_computeHeight(threadData, _bt);
goto tmp2_done;
}
case 0: {
if (0 != tmp3_1) goto tmp2_end;
_bt = tmp3_2;
tmpMeta[0] = omc_FVisit_computeHeight(threadData, _bt);
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
_bt = tmp3_2;
tmpMeta[0] = omc_FVisit_computeHeight(threadData, _bt);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
_bt = tmp3_2;
tmpMeta[0] = omc_FVisit_doBalance2(threadData, (_difference < ((modelica_integer) 0)), _bt);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FVisit_doBalance(threadData_t *threadData, modelica_metatype _difference, modelica_metatype _inBt)
{
modelica_integer tmp1;
modelica_metatype _outBt = NULL;
tmp1 = mmc_unbox_integer(_difference);
_outBt = omc_FVisit_doBalance(threadData, tmp1, _inBt);
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_balance(threadData_t *threadData, modelica_metatype _inBt)
{
modelica_metatype _outBt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBt;
{
modelica_integer _d;
modelica_metatype _bt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_bt = tmp3_1;
_d = omc_FVisit_differenceInHeight(threadData, _bt);
tmpMeta[0] = omc_FVisit_doBalance(threadData, _d, _bt);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outBt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_nodeValue(threadData_t *threadData, modelica_metatype _bt)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _bt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_v = tmpMeta[3];
tmpMeta[0] = _v;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_v = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _v;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FVisit_createEmptyAvlIfNone(threadData_t *threadData, modelica_metatype _t)
{
modelica_metatype _outT = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _t;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT12;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_outT = tmpMeta[1];
tmpMeta[0] = _outT;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outT = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outT;
}
DLLExport
modelica_metatype omc_FVisit_avlTreeAdd2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _keyComp, modelica_integer _inKey, modelica_metatype _inValue)
{
modelica_metatype _outAvlTree = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;modelica_integer tmp3_3;modelica_metatype tmp3_4;
tmp3_1 = _inAvlTree;
tmp3_2 = _keyComp;
tmp3_3 = _inKey;
tmp3_4 = _inValue;
{
modelica_integer _key;
modelica_integer _rkey;
modelica_metatype _value = NULL;
modelica_metatype _left = NULL;
modelica_metatype _right = NULL;
modelica_integer _h;
modelica_metatype _t_1 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _oval = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(tmp3_2)) {
case 0: {
modelica_integer tmp4;
modelica_integer tmp5;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp4 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_rkey = tmp4;
_h = tmp5;
_left = tmpMeta[5];
_right = tmpMeta[6];
_value = tmp3_4;
tmpMeta[1] = mmc_mk_box3(3, &FCore_VAvlTreeValue_VAVLTREEVALUE__desc, mmc_mk_integer(_rkey), _value);
tmpMeta[2] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, mmc_mk_some(tmpMeta[1]), mmc_mk_integer(_h), _left, _right);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_oval = tmpMeta[1];
_h = tmp6;
_left = tmpMeta[3];
_right = tmpMeta[4];
_key = tmp3_3;
_value = tmp3_4;
_t = omc_FVisit_createEmptyAvlIfNone(threadData, _right);
_t_1 = omc_FVisit_avlTreeAdd(threadData, _t, _key, _value);
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _oval, mmc_mk_integer(_h), _left, mmc_mk_some(_t_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case -1: {
modelica_integer tmp7;
if (-1 != tmp3_2) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_oval = tmpMeta[1];
_h = tmp7;
_left = tmpMeta[3];
_right = tmpMeta[4];
_key = tmp3_3;
_value = tmp3_4;
_t = omc_FVisit_createEmptyAvlIfNone(threadData, _left);
_t_1 = omc_FVisit_avlTreeAdd(threadData, _t, _key, _value);
tmpMeta[1] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, _oval, mmc_mk_integer(_h), mmc_mk_some(_t_1), _right);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outAvlTree = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAvlTree;
}
modelica_metatype boxptr_FVisit_avlTreeAdd2(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _keyComp, modelica_metatype _inKey, modelica_metatype _inValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outAvlTree = NULL;
tmp1 = mmc_unbox_integer(_keyComp);
tmp2 = mmc_unbox_integer(_inKey);
_outAvlTree = omc_FVisit_avlTreeAdd2(threadData, _inAvlTree, tmp1, tmp2, _inValue);
return _outAvlTree;
}
DLLExport
modelica_metatype omc_FVisit_avlTreeAdd(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_integer _inKey, modelica_metatype _inValue)
{
modelica_metatype _outAvlTree = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_integer tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inAvlTree;
tmp3_2 = _inKey;
tmp3_3 = _inValue;
{
modelica_integer _key;
modelica_integer _rkey;
modelica_metatype _value = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (!optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
_key = tmp3_2;
_value = tmp3_3;
tmpMeta[1] = mmc_mk_box3(3, &FCore_VAvlTreeValue_VAVLTREEVALUE__desc, mmc_mk_integer(_key), _value);
tmpMeta[2] = mmc_mk_box5(3, &FCore_VAvlTree_VAVLTREENODE__desc, mmc_mk_some(tmpMeta[1]), mmc_mk_integer(((modelica_integer) 1)), mmc_mk_none(), mmc_mk_none());
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
_rkey = tmp5;
_key = tmp3_2;
_value = tmp3_3;
tmpMeta[0] = omc_FVisit_balance(threadData, omc_FVisit_avlTreeAdd2(threadData, _inAvlTree, omc_FVisit_keyCompare(threadData, _key, _rkey), _key, _value));
goto tmp2_done;
}
case 2: {
omc_Error_addMessage(threadData, _OMC_LIT4, _OMC_LIT14);
goto goto_1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outAvlTree = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAvlTree;
}
modelica_metatype boxptr_FVisit_avlTreeAdd(threadData_t *threadData, modelica_metatype _inAvlTree, modelica_metatype _inKey, modelica_metatype _inValue)
{
modelica_integer tmp1;
modelica_metatype _outAvlTree = NULL;
tmp1 = mmc_unbox_integer(_inKey);
_outAvlTree = omc_FVisit_avlTreeAdd(threadData, _inAvlTree, tmp1, _inValue);
return _outAvlTree;
}
DLLExport
modelica_metatype omc_FVisit_avlTreeNew(threadData_t *threadData)
{
modelica_metatype _tree = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tree = _OMC_LIT12;
_return: OMC_LABEL_UNUSED
return _tree;
}
DLLExport
modelica_string omc_FVisit_valueStr(threadData_t *threadData, modelica_metatype _v)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _v;
{
modelica_integer _seq;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
_seq = tmp6;
tmp1 = intString(_seq);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_string omc_FVisit_keyStr(threadData_t *threadData, modelica_integer _k)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = intString(_k);
_return: OMC_LABEL_UNUSED
return _str;
}
modelica_metatype boxptr_FVisit_keyStr(threadData_t *threadData, modelica_metatype _k)
{
modelica_integer tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_integer(_k);
_str = omc_FVisit_keyStr(threadData, tmp1);
return _str;
}
DLLExport
modelica_integer omc_FVisit_keyCompare(threadData_t *threadData, modelica_integer _k1, modelica_integer _k2)
{
modelica_integer _i;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((_k1 > _k2)?((modelica_integer) 1):((_k1 < _k2)?((modelica_integer) -1):((modelica_integer) 0)));
_return: OMC_LABEL_UNUSED
return _i;
}
modelica_metatype boxptr_FVisit_keyCompare(threadData_t *threadData, modelica_metatype _k1, modelica_metatype _k2)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _i;
modelica_metatype out_i;
tmp1 = mmc_unbox_integer(_k1);
tmp2 = mmc_unbox_integer(_k2);
_i = omc_FVisit_keyCompare(threadData, tmp1, tmp2);
out_i = mmc_mk_icon(_i);
return out_i;
}
DLLExport
modelica_metatype omc_FVisit_visit(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef)
{
modelica_metatype _outVisited = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inVisited;
{
modelica_integer _s;
modelica_integer _n;
modelica_metatype _a = NULL;
modelica_metatype _v = NULL;
modelica_integer _id;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
omc_FNode_id(threadData, omc_FNode_fromRef(threadData, _inRef));
_v = omc_FVisit_avlTreeGet(threadData, omc_FVisit_tree(threadData, _inVisited), omc_FNode_id(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta[1] = stringAppend(_OMC_LIT15,omc_FNode_toStr(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT16);
tmpMeta[3] = stringAppend(tmpMeta[2],intString(omc_FVisit_seq(threadData, _v)));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT9);
fputs(MMC_STRINGDATA(tmpMeta[4]),stdout);
goto goto_1;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
modelica_integer tmp7;
modelica_integer tmp8;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_a = tmpMeta[1];
_id = omc_FNode_id(threadData, omc_FNode_fromRef(threadData, _inRef));
tmp5 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_FVisit_avlTreeGet(threadData, omc_FVisit_tree(threadData, _inVisited), _id);
tmp5 = 1;
goto goto_6;
goto_6:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp5) {goto goto_1;}
tmpMeta[1] = omc_FVisit_next(threadData, _inVisited, &tmp7);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
_n = tmp8;
_s = tmp7;
tmpMeta[1] = mmc_mk_box3(3, &FCore_Visit_VN__desc, _inRef, mmc_mk_integer(_s));
_a = omc_FVisit_avlTreeAdd(threadData, _a, _id, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box3(3, &FCore_Visited_V__desc, _a, mmc_mk_integer(_n));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outVisited = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVisited;
}
DLLExport
modelica_metatype omc_FVisit_tree(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _a = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _v;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_a = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _a;
}
DLLExport
modelica_metatype omc_FVisit_ref(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _r = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _v;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_r = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _r;
}
DLLExport
modelica_integer omc_FVisit_seq(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _s;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _v;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_s = tmp1;
_return: OMC_LABEL_UNUSED
return _s;
}
modelica_metatype boxptr_FVisit_seq(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _s;
modelica_metatype out_s;
_s = omc_FVisit_seq(threadData, _v);
out_s = mmc_mk_icon(_s);
return out_s;
}
DLLExport
modelica_boolean omc_FVisit_visited(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inVisited;
{
modelica_metatype _a = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_a = tmpMeta[0];
omc_FNode_id(threadData, omc_FNode_fromRef(threadData, _inRef));
omc_FVisit_avlTreeGet(threadData, _a, omc_FNode_id(threadData, omc_FNode_fromRef(threadData, _inRef)));
tmp1 = 1;
goto tmp3_done;
}
case 1: {
tmp1 = 0;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_FVisit_visited(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype _inRef)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_FVisit_visited(threadData, _inVisited, _inRef);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_FVisit_next(threadData_t *threadData, modelica_metatype _inVisited, modelica_integer *out_next)
{
modelica_metatype _outVisited = NULL;
modelica_integer _next;
modelica_metatype _v = NULL;
modelica_integer _n;
modelica_integer tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVisited;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
_v = tmpMeta[1];
_n = tmp1;
_next = _n;
_n = omc_FCore_next(threadData, _n);
tmpMeta[0] = mmc_mk_box3(3, &FCore_Visited_V__desc, _v, mmc_mk_integer(_n));
_outVisited = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_next) { *out_next = _next; }
return _outVisited;
}
modelica_metatype boxptr_FVisit_next(threadData_t *threadData, modelica_metatype _inVisited, modelica_metatype *out_next)
{
modelica_integer _next;
modelica_metatype _outVisited = NULL;
_outVisited = omc_FVisit_next(threadData, _inVisited, &_next);
if (out_next) { *out_next = mmc_mk_icon(_next); }
return _outVisited;
}
DLLExport
modelica_metatype omc_FVisit_reset(threadData_t *threadData, modelica_metatype _inVisited)
{
modelica_metatype _visited = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_visited = omc_FVisit_new(threadData);
_return: OMC_LABEL_UNUSED
return _visited;
}
DLLExport
modelica_metatype omc_FVisit_new(threadData_t *threadData)
{
modelica_metatype _visited = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_visited = _OMC_LIT17;
_return: OMC_LABEL_UNUSED
return _visited;
}
