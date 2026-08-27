#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Graphviz.c"
#endif
#include "omc_simulation_settings.h"
#include "Graphviz.h"
#define _OMC_LIT0_data "="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,0,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data " -- "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,4,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ";\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,2,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "GVNOD"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,5,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "\\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,2,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,1,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "label"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,5,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "graph AST {\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,12,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,2,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#include "util/modelica.h"
#include "Graphviz_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeAttrReq(threadData_t *threadData, modelica_metatype _inAttributeLst, modelica_string _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeAttrReq,2,0) {(void*) boxptr_Graphviz_makeAttrReq,0}};
#define boxvar_Graphviz_makeAttrReq MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeAttrReq)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeAttr(threadData_t *threadData, modelica_metatype _l);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeAttr,2,0) {(void*) boxptr_Graphviz_makeAttr,0}};
#define boxvar_Graphviz_makeAttr MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeAttr)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeNode(threadData_t *threadData, modelica_string _nm, modelica_metatype _attr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeNode,2,0) {(void*) boxptr_Graphviz_makeNode,0}};
#define boxvar_Graphviz_makeNode MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeNode)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeEdge(threadData_t *threadData, modelica_string _n1, modelica_string _n2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeEdge,2,0) {(void*) boxptr_Graphviz_makeEdge,0}};
#define boxvar_Graphviz_makeEdge MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeEdge)
PROTECTED_FUNCTION_STATIC void omc_Graphviz_printEdge(threadData_t *threadData, modelica_string _n1, modelica_string _n2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_printEdge,2,0) {(void*) boxptr_Graphviz_printEdge,0}};
#define boxvar_Graphviz_printEdge MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_printEdge)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_nodename(threadData_t *threadData, modelica_string _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_nodename,2,0) {(void*) boxptr_Graphviz_nodename,0}};
#define boxvar_Graphviz_nodename MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_nodename)
PROTECTED_FUNCTION_STATIC void omc_Graphviz_dumpChildren(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inChildren);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_dumpChildren,2,0) {(void*) boxptr_Graphviz_dumpChildren,0}};
#define boxvar_Graphviz_dumpChildren MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_dumpChildren)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeLabelReq(threadData_t *threadData, modelica_metatype _inStringLst, modelica_string _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeLabelReq,2,0) {(void*) boxptr_Graphviz_makeLabelReq,0}};
#define boxvar_Graphviz_makeLabelReq MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeLabelReq)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeLabel(threadData_t *threadData, modelica_metatype _sl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_makeLabel,2,0) {(void*) boxptr_Graphviz_makeLabel,0}};
#define boxvar_Graphviz_makeLabel MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_makeLabel)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_dumpNode(threadData_t *threadData, modelica_metatype _inNode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Graphviz_dumpNode,2,0) {(void*) boxptr_Graphviz_dumpNode,0}};
#define boxvar_Graphviz_dumpNode MMC_REFSTRUCTLIT(boxvar_lit_Graphviz_dumpNode)
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeAttrReq(threadData_t *threadData, modelica_metatype _inAttributeLst, modelica_string _inString)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAttributeLst;
{
modelica_string _s = NULL;
modelica_string _name = NULL;
modelica_string _v = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
_name = tmpMeta[2];
_v = tmpMeta[3];
tmpMeta[0] = stringAppend(_inString,_name);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT0);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_v);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_name = tmpMeta[2];
_v = tmpMeta[3];
_rest = tmpMeta[1];
tmpMeta[0] = stringAppend(_inString,_name);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT0);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_v);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT1);
_s = tmpMeta[0];
_inAttributeLst = _rest;
_inString = _s;
goto _tailrecursive;
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
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeAttr(threadData_t *threadData, modelica_metatype _l)
{
modelica_string _str = NULL;
modelica_string _res = NULL;
modelica_string _s = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_Graphviz_makeAttrReq(threadData, _l, _OMC_LIT2);
tmpMeta[0] = stringAppend(_OMC_LIT3,_res);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT4);
_str = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeNode(threadData_t *threadData, modelica_string _nm, modelica_metatype _attr)
{
modelica_string _str = NULL;
modelica_string _s = NULL;
modelica_string _s_1 = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = omc_Graphviz_makeAttr(threadData, _attr);
tmpMeta[0] = stringAppend(_nm,_s);
_s_1 = tmpMeta[0];
tmpMeta[0] = stringAppend(_s_1,_OMC_LIT5);
_str = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeEdge(threadData_t *threadData, modelica_string _n1, modelica_string _n2)
{
modelica_string _str = NULL;
modelica_string _s = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = stringAppend(_n1,_OMC_LIT6);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_n2);
_str = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC void omc_Graphviz_printEdge(threadData_t *threadData, modelica_string _n1, modelica_string _n2)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_Graphviz_makeEdge(threadData, _n1, _n2);
fputs(MMC_STRINGDATA(_str),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT7),stdout);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_nodename(threadData_t *threadData, modelica_string _str)
{
modelica_string _s = NULL;
modelica_integer _i;
modelica_string _is = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = tick();
_is = intString(_i);
tmpMeta[0] = stringAppend(_OMC_LIT8,_is);
_s = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _s;
}
PROTECTED_FUNCTION_STATIC void omc_Graphviz_dumpChildren(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inChildren)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inIdent;
tmp3_2 = _inChildren;
{
modelica_string _nm = NULL;
modelica_string _parent = NULL;
modelica_metatype _node = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_2);
tmpMeta[1] = MMC_CDR(tmp3_2);
_node = tmpMeta[0];
_rest = tmpMeta[1];
_parent = tmp3_1;
_nm = omc_Graphviz_dumpNode(threadData, _node);
omc_Graphviz_printEdge(threadData, _nm, _parent);
_inIdent = _parent;
_inChildren = _rest;
goto _tailrecursive;
;
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
;
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeLabelReq(threadData_t *threadData, modelica_metatype _inStringLst, modelica_string _inString)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStringLst;
{
modelica_string _s = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_inString,_s);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
_s1 = tmpMeta[0];
_s2 = tmpMeta[2];
tmpMeta[0] = stringAppend(_inString,_s1);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT9);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_s2);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
_s1 = tmpMeta[0];
_rest = tmpMeta[1];
tmpMeta[0] = stringAppend(_inString,_s1);
_s = tmpMeta[0];
tmpMeta[0] = stringAppend(_s,_OMC_LIT9);
_s = tmpMeta[0];
_inStringLst = _rest;
_inString = _s;
goto _tailrecursive;
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
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_makeLabel(threadData_t *threadData, modelica_metatype _sl)
{
modelica_string _s2 = NULL;
modelica_string _s0 = NULL;
modelica_string _s1 = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s0 = omc_Graphviz_makeLabelReq(threadData, _sl, _OMC_LIT2);
tmpMeta[0] = stringAppend(_OMC_LIT10,_s0);
_s1 = tmpMeta[0];
tmpMeta[0] = stringAppend(_s1,_OMC_LIT10);
_s2 = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _s2;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Graphviz_dumpNode(threadData_t *threadData, modelica_metatype _inNode)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inNode;
{
modelica_string _nm = NULL;
modelica_string _typlbl = NULL;
modelica_string _out = NULL;
modelica_string _typ = NULL;
modelica_string _lblstr = NULL;
modelica_metatype _newattr = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _children = NULL;
modelica_metatype _lbl_1 = NULL;
modelica_metatype _lbl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_typ = tmpMeta[0];
_attr = tmpMeta[1];
_children = tmpMeta[2];
_nm = omc_Graphviz_nodename(threadData, _typ);
tmpMeta[0] = mmc_mk_cons(_typ, MMC_REFSTRUCTLIT(mmc_nil));
_typlbl = omc_Graphviz_makeLabel(threadData, tmpMeta[0]);
tmpMeta[1] = mmc_mk_box3(3, &Graphviz_Attribute_ATTR__desc, _OMC_LIT11, _typlbl);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _attr);
_newattr = tmpMeta[0];
_out = omc_Graphviz_makeNode(threadData, _nm, _newattr);
fputs(MMC_STRINGDATA(_out),stdout);
omc_Graphviz_dumpChildren(threadData, _nm, _children);
tmp1 = _nm;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_typ = tmpMeta[0];
_lbl = tmpMeta[1];
_attr = tmpMeta[2];
_children = tmpMeta[3];
_nm = omc_Graphviz_nodename(threadData, _typ);
tmpMeta[0] = mmc_mk_cons(_typ, _lbl);
_lbl_1 = tmpMeta[0];
_lblstr = omc_Graphviz_makeLabel(threadData, _lbl_1);
tmpMeta[1] = mmc_mk_box3(3, &Graphviz_Attribute_ATTR__desc, _OMC_LIT11, _lblstr);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], _attr);
_newattr = tmpMeta[0];
_out = omc_Graphviz_makeNode(threadData, _nm, _newattr);
fputs(MMC_STRINGDATA(_out),stdout);
omc_Graphviz_dumpChildren(threadData, _nm, _children);
tmp1 = _nm;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
void omc_Graphviz_dump(threadData_t *threadData, modelica_metatype _node)
{
modelica_string _nm = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(_OMC_LIT12),stdout);
_nm = omc_Graphviz_dumpNode(threadData, _node);
fputs(MMC_STRINGDATA(_OMC_LIT13),stdout);
_return: OMC_LABEL_UNUSED
return;
}
