package DAEDumpTpl

import interface DAEDumpTV;
import AbsynDumpTpl;
import SCodeDumpTpl;

/*****************************************************************************
 *     SECTION: MAIN TEMPLATE FUNCTION                                       *
 *****************************************************************************/
template dumpDAE(list<DAEDump.compWithSplitElements> fixedDaeList, DAEDump.functionList funLists)
::=
 let comp_str =(fixedDaeList |> dae => dumpComp(dae) ;separator="\n")
 let fun_str = match funLists case FUNCTION_LIST(__) then dumpFunctions(funcs)
   if fun_str then
     <<
     <%fun_str%><%\n\n%>
     <%comp_str%>
     >>
   else
     <<
     <%comp_str%>
     >>
end dumpDAE;

template dumpComp(DAEDump.compWithSplitElements fixedDae)
::=
  match fixedDae case COMP_WITH_SPLIT(__) then
    let cmt_str = dumpCommentOpt(comment)
    let ann_str = dumpClassAnnotation(comment)
    let name_rep = if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then System.stringReplace(name, ".","__") else name
    <<
    class <%name_rep%><%cmt_str%>
    <%dumpCompStream(spltElems)%>
    <%if ann_str then "  "%><%ann_str%>
    end <%name_rep%>;<%\n%>
    >>
end dumpComp;

template dumpCompStream(DAEDump.splitElements elems)
::=
  match elems
    case SPLIT_ELEMENTS(__) then
      let var_str = dumpVars(v)
      let ieq_str = dumpInitialEquationSection(ie)
      let ial_str = dumpInitialAlgorithmSection(ia)
      let eq_str =  dumpEquationSection(e)
      let al_str = dumpAlgorithmSection(a)
      let sm_str = (sm |> flatSM => dumpStateMachineSection(flatSM) ;separator="\n")
      <<
      <%var_str%>
      <%sm_str%>
      <%ieq_str%>
      <%ial_str%>
      <%eq_str%>
      <%al_str%>
      >>
end dumpCompStream;

/*****************************************************************************
 *     SECTION: FUNCTION SECTION                                             *
 *****************************************************************************/
template dumpFunctions(list<DAE.Function> funcs)
::=
  (funcs |> func => dumpFunction(func) ;separator="\n\n")
end dumpFunctions;

template dumpFunction(DAE.Function function)
::=
  match function
    case FUNCTION(__) then
      let inline_str = dumpInlineType(inlineType)
      let cmt_str = dumpCommentOpt(comment)
      let ann_str = dumpClassAnnotation(comment)
      let impure_str = if isImpure then 'impure '
      <<
      <%impure_str%>function <%AbsynDumpTpl.dumpPathNoQual(path)%><%inline_str%><%cmt_str%>
      <%dumpFunctionDefinitions(functions)%>
      <%if ann_str then "  "%><%ann_str%>
      end <%AbsynDumpTpl.dumpPathNoQual(path)%>;
      >>
    case RECORD_CONSTRUCTOR(__) then
      <<
      function <%AbsynDumpTpl.dumpPathNoQual(path)%> "Automatically generated record constructor for <%AbsynDumpTpl.dumpPathNoQual(path)%>"
        <%dumpRecordInputVarStr(type_)%>
        output <%dumpPathLastIndent(path)%> res;
      end <%AbsynDumpTpl.dumpPathNoQual(path)%>;
      >>
end dumpFunction;

template dumpFunctionDefinitions(list<FunctionDefinition> functions)
::=
 (functions |> func => dumpFunctionDefinition(func) ;separator="\n")

end dumpFunctionDefinitions;

template dumpFunctionDefinition(DAE.FunctionDefinition functions)
::=
match functions
  case FUNCTION_DEF(__) then
    <<
    <%dumpFunctionBody(body)%>
    >>
  case FUNCTION_EXT(__) then
    <<
    <%dumpFunctionBody(body)%><%\n%><%\n%>
    <%dumpExternalDecl(externalDecl)%>
    >>
  case FUNCTION_DER_MAPPER(__) then ''
end dumpFunctionDefinition;

template dumpExternalDecl(ExternalDecl externalDecl)
::=
match externalDecl
  case EXTERNALDECL(__) then
    let func_name_str = name
    let func_args_str = dumpExtArgs(args)
    let func_str = if func_name_str then ' <%func_name_str%>(<%func_args_str%>)'
    let ext_output_str =  '<%dumpExtArg(returnArg)%>'
    let output_str = if ext_output_str then ' <%ext_output_str%> ='
    let lang_str = language
    let ann_str = match ann case SOME(annotation) then ' <%dumpAnnotation(annotation)%>'
    '  external "<%lang_str%>"<%output_str%><%func_str%><%ann_str%>;'
end dumpExternalDecl;

template dumpExtArgs(list<ExtArg> args)
::=
(args |> arg => dumpExtArg(arg) ;separator=", ")
end dumpExtArgs;

template dumpExtArg(DAE.ExtArg arg)
::=
match arg
  case EXTARG(__) then dumpCref(componentRef)
  case EXTARGEXP(__) then dumpExp(exp)
  case EXTARGSIZE(__) then 'size(<%dumpCref(componentRef)%>, <%dumpExp(exp)%>)'
end dumpExtArg;

template dumpRecordInputVarStr(Type type_)
::=
match type_
   case T_COMPLEX(__) then '<%dumpRecordVars(varLst)%>'
   case T_FUNCTION(__) then '<%dumpRecordInputVarStr(funcResultType)%>'
end dumpRecordInputVarStr;

template dumpRecordVars(list<Var> varLst)
::=
(varLst |> v => dumpRecordVar(v) ;separator="\n")
end dumpRecordVars;

template dumpRecordVar(DAE.Var v)
::=
match v
  case TYPES_VAR(__) then
    let attr_str = dumpRecordConstructorInputAttr(attributes)
    let binding_str = dumpRecordConstructorBinding(binding)
    let &attr = buffer ""
    let ty_str = dumpType(ty, &attr)
    '<%attr_str%><%ty_str%> <%name%><%attr%><%binding_str%>;'
end dumpRecordVar;

template dumpRecordConstructorInputAttr(DAE.Attributes attr)
::=
match attr
  case DAE.ATTR(visibility = SCode.PROTECTED()) then 'protected '
  case DAE.ATTR(variability = SCode.CONST()) then 'constant '
  else 'input '
end dumpRecordConstructorInputAttr;

template dumpRecordConstructorBinding(DAE.Binding binding)
::=
match binding
  case DAE.UNBOUND() then ''
  case DAE.EQBOUND(__) then ' = <%dumpExp(exp)%>'
end dumpRecordConstructorBinding;

template dumpRecordVarBinding(Binding binding)
::=
match binding
  case UNBOUND(__) then ''
  case EQBOUND(__) then ' = <%dumpExp(exp)%>'
  case VALBOUND(__) then 'value bound***** check what to display'
end dumpRecordVarBinding;

template dumpFunctionBody(list<Element> dAElist)
::=
  (dAElist |> lst => dumpFunctionElement(lst) ;separator="\n")+
  (dAElist |> lst => dumpFunctionAnnotation(lst))
end dumpFunctionBody;

template dumpFunctionElement(DAE.Element lst)
::=
match lst
 case VAR(__) then dumpVar(lst,true)
 case INITIALALGORITHM(__) then dumpFunctionAlgorithm(algorithm_ ,"initial algorithm")
 case ALGORITHM(__) then dumpFunctionAlgorithm(algorithm_ ,"algorithm")
 case COMMENT(__) then ""
 else 'Element not found'

end dumpFunctionElement;

template dumpFunctionAnnotation(DAE.Element lst)
::=
match lst
 case COMMENT(__) then
   let x=dumpCommentAnnotationNoOpt(cmt)
   if x then \n+x
 else ""

end dumpFunctionAnnotation;

template dumpFunctionAlgorithm(Algorithm algorithm_, String label)
::=
match algorithm_
  case ALGORITHM_STMTS(__) then
    <<
    <%label%>
      <%dumpStatements(statementLst)%>
    >>
end dumpFunctionAlgorithm;

template dumpInlineType(InlineType it)
::=
match it
  case AFTER_INDEX_RED_INLINE() then ' "Inline after index reduction"'
  case NORM_INLINE() then ' "Inline before index reduction"'
end dumpInlineType;

/*****************************************************************************
 *     SECTION: VARIABLE SECTION                                             *
 *****************************************************************************/
template dumpVars(list<DAE.Element> v)
::= (v |> var => dumpVar(var,false) ;separator="\n")
end dumpVars;

template dumpVar(DAE.Element lst, Boolean printTypeDimension)
::=
match lst
 case VAR(__) then
   let final = match variableAttributesOption case SOME(VariableAttributes) then dumpFinalPrefix(VariableAttributes)
   let varVisibility = dumpVarVisibility(protection)
   let varParallelism = dumpVarParallelism(parallelism)
   let varKind = dumpVarKind(kind)
   let varDirection = dumpVarDirection(direction)
   let &attr = buffer ""
   let varType = dumpType(ty, &attr)
   let dim_str = if printTypeDimension then dumpTypeDimensions(dims)
   let varName = dumpCref(componentRef)
   let bindingExp = match binding case SOME(exp) then dumpExp(exp)
   let varAttr = match variableAttributesOption case SOME(VariableAttributes) then dumpVariableAttributes(VariableAttributes)
   let cmt_str = dumpCommentOpt(comment)
   let ann_str = dumpCompAnnotation(comment)
   let binding_str = if bindingExp then ' = <%bindingExp%>'
   /* uncomment this and use the source_str if you want to print the typeLst inside the source (we should maybe put it on a flag or something)
   let source_str = match source case SOURCE(__) then (typeLst |> tp => AbsynDumpTpl.dumpPath(tp) ;separator=", ") else ''
   */
   <<
    <%varVisibility%><%final%><%varParallelism%><%varKind%><%varDirection%> <%varType%><%dim_str%> <%varName%><%attr%><%varAttr%><%binding_str%><%cmt_str%><%ann_str%>;
   >>
end dumpVar;

template dumpFinalPrefix(DAE.VariableAttributes varAttr)
::=
  match varAttr
   case VAR_ATTR_REAL(finalPrefix=SOME(true))        then ' final'
   case VAR_ATTR_INT(finalPrefix=SOME(true))         then ' final'
   case VAR_ATTR_BOOL(finalPrefix=SOME(true))        then ' final'
   case VAR_ATTR_STRING(finalPrefix=SOME(true))      then ' final'
   case VAR_ATTR_ENUMERATION(finalPrefix=SOME(true)) then ' final'
end dumpFinalPrefix;

template dumpVarVisibility(VarVisibility protection)
::=
match protection
  case PROTECTED(__) then ' protected'
end dumpVarVisibility;

template dumpVarParallelism(VarParallelism parallelism)
::=
match parallelism
  case PARGLOBAL(__) then ' parglobal'
  case PARLOCAL(__) then ' parlocal'
end dumpVarParallelism;

template dumpVarKind(VarKind kind)
::=
match kind
  case CONST(__) then ' constant'
  case PARAM(__) then ' parameter'
  case DISCRETE(__) then ' discrete'
end dumpVarKind;

template dumpVarDirection(VarDirection direction)
::=
  match direction
    case INPUT(__) then ' input'
    case OUTPUT(__) then ' output'
end dumpVarDirection;

template dumpType(Type ty, Text &attributes)
::=
  match ty
    case T_INTEGER(__) then
      let &attributes += dumpVarAttributes(varLst)
      "Integer"
    case T_REAL(__) then
      let &attributes += dumpVarAttributes(varLst)
      "Real"
    case T_STRING(__) then
      let &attributes += dumpVarAttributes(varLst)
      "String"
    case T_BOOL(__) then
      let &attributes += dumpVarAttributes(varLst)
      "Boolean"
    case T_CLOCK(__) then
      let &attributes += dumpVarAttributes(varLst)
      "Clock"
    case T_ENUMERATION(__) then
      let lit_str = names ;separator=", "
      'enumeration(<%lit_str%>)'
    case T_ARRAY(__) then dumpArrayType(ty, dumpDimensions(dims), &attributes)
    case T_COMPLEX(complexClassType=RECORD(path=rname)) then AbsynDumpTpl.dumpPathNoQual(rname)
    case T_COMPLEX(__) then AbsynDumpTpl.dumpPath(ClassInf.getStateName(complexClassType))
    case T_SUBTYPE_BASIC(__) then dumpType(complexType, &attributes)
    case T_FUNCTION(__) then dumpFunctionType(ty)
    case T_TUPLE(__) then dumpTupleType(types, "(", ")")
    case T_METATUPLE(__) then dumpTupleType(types, "tuple<", ">")
    case T_METALIST(__) then 'list<<%dumpType(ty, attributes)%>>'
    case T_METAARRAY(__) then 'array<<%dumpType(ty, attributes)%>>'
    case T_METAPOLYMORPHIC(__) then 'polymorphic<<%name%>>'
    case T_METAUNIONTYPE(__) then AbsynDumpTpl.dumpPathNoQual(path)
    case T_METARECORD(__) then AbsynDumpTpl.dumpPathNoQual(path)
    case T_METABOXED(__) then '#<%dumpType(ty, attributes)%>'
    case T_METAOPTION(ty = DAE.T_UNKNOWN(__)) then 'Option<Any>'
    case T_METAOPTION(__) then 'Option<<%dumpType(ty, &attributes)%>>'
    case T_METATYPE(__) then dumpType(ty, &attributes)
    case T_NORETCALL(__) then '#T_NORETCALL#'
    case T_UNKNOWN(__) then '#T_UNKNOWN#'
    case T_ANYTYPE(__) then '#T_ANYTYPE#'
    else 'DAEDumpTpl.dumpType: Not yet implemented'
end dumpType;

template dumpArrayType(Type ty, String dims_accum, Text &attributes)
::=
match ty
  case T_ARRAY(__) then
    let dims_str = dumpDimensions(dims)
    let dims_accum_str = if dims_accum then '<%dims_accum%>, <%dims_str%>' else dims_str
    dumpArrayType(ty, dims_accum_str, &attributes)
  else
    let ty_str = dumpType(ty, &attributes)
    let dims_str = if dims_accum then '[<%dims_accum%>]'
    '<%ty_str%><%dims_str%>'
end dumpArrayType;

template dumpTupleType(list<Type> tys, String ty_begin, String ty_end)
::=
  let &attr = buffer ""
  '<%ty_begin%><%(tys |> ty => dumpType(ty, &attr) ;separator=", ")%><%ty_end%>'
end dumpTupleType;

template dumpFunctionType(Type ty)
::=
match ty
  case T_FUNCTION(__) then
    let args_str = (funcArg |> arg => dumpFuncArg(arg) ;separator=", ")
    let src_str = AbsynDumpTpl.dumpPath(path)
    let &attr = buffer ""
    let res_str = dumpType(funcResultType, &attr)
    '<%src_str%><function>(<%args_str%>) => <%res_str%>'
end dumpFunctionType;

template dumpFuncArg(FuncArg arg)
::=
match arg
  case FUNCARG(__) then
    let &attr = buffer ""
    let ty_str = dumpType(ty, &attr)
    let c_str = dumpConst(const)
    let p_str = dumpParallelism(par)
    let binding_str = match defaultBinding case SOME(bexp) then ' := <%dumpExp(bexp)%>'
    '<%ty_str%> <%c_str%><%p_str%><%name%><%binding_str%>'
end dumpFuncArg;

template dumpConst(Const c)
::=
match c
  case C_PARAM() then "parameter "
  case C_CONST() then "constant "
end dumpConst;

template dumpParallelism(DAE.VarParallelism p)
::=
match p
  case PARGLOBAL() then "parglobal "
  case PARLOCAL() then "parlocal "
end dumpParallelism;

template dumpVarAttributes(list<Var> literalVarLst)
::= if literalVarLst then '(<%(literalVarLst |> var => dumpVarAttribute(var) ;separator=", ")%>)'
end dumpVarAttributes;

template dumpVarAttribute(DAE.Var var)
::=
  match var
    case TYPES_VAR(binding = DAE.EQBOUND(exp = e)) then '<%name%> = <%dumpExp(e)%>'
end dumpVarAttribute;

template dumpDimensions(list<Dimension> dims)
::= if dims then (dims |> dim => dumpDimension(dim) ;separator=", ")
end dumpDimensions;

template dumpDimension(Dimension dim)
::=
  match dim
    case DIM_INTEGER(__) then integer
    case DIM_ENUM(__)    then AbsynDumpTpl.dumpPath(enumTypeName)
    case DIM_EXP(__)     then dumpExp(exp)
    case DIM_UNKNOWN(__) then ':'
end dumpDimension;

template dumpVariableAttributes(DAE.VariableAttributes variableAttributesOption)
::=
match variableAttributesOption
  case VAR_ATTR_REAL(__) then
    let quantity_str = dumpExpAttrOpt(quantity, "quantity")
    let unit_str = dumpExpAttrOpt(unit, "unit")
    let displayunit_str = dumpExpAttrOpt(displayUnit, "displayUnit")
    let min_str = dumpExpAttrOpt(min, "min")
    let max_str = dumpExpAttrOpt(max, "max")
    let start_str = dumpExpAttrOpt(start, "start")
    let fixed_str = dumpExpAttrOpt(fixed, "fixed")
    let nominal_str = dumpExpAttrOpt(nominal, "nominal")
    let statesel_str = dumpStateSelectAttrOpt(stateSelectOption)
    let uncert_str = dumpUncertaintyAttrOpt(uncertainOption)
    let dist_str = dumpDistributionAttrOpt(distributionOption)
    let so_str = dumpStartOriginAttrOpt(startOrigin)
    let attrs_str = {quantity_str, unit_str, displayunit_str, min_str, max_str,
      start_str, fixed_str, nominal_str, statesel_str, uncert_str, dist_str,
      so_str} ;separator=", "
    if attrs_str then '(<%attrs_str%>)'
  case VAR_ATTR_INT(__) then
    let quantity_str = dumpExpAttrOpt(quantity, "quantity")
    let min_str = dumpExpAttrOpt(min, "min")
    let max_str = dumpExpAttrOpt(max, "max")
    let start_str = dumpExpAttrOpt(start, "start")
    let fixed_str = dumpExpAttrOpt(fixed, "fixed")
    let uncert_str = dumpUncertaintyAttrOpt(uncertainOption)
    let dist_str = dumpDistributionAttrOpt(distributionOption)
    let so_str = dumpStartOriginAttrOpt(startOrigin)
    let attrs_str = {quantity_str, min_str, max_str, start_str, fixed_str,
      uncert_str, dist_str, so_str} ;separator=", "
    if attrs_str then '(<%attrs_str%>)'
  case VAR_ATTR_BOOL(__)  then
    let quantity_str = dumpExpAttrOpt(quantity, "quantity")
    let start_str = dumpExpAttrOpt(start, "start")
    let fixed_str = dumpExpAttrOpt(fixed, "fixed")
    let so_str = dumpStartOriginAttrOpt(startOrigin)
    let attrs_str = {quantity_str, start_str, fixed_str, so_str} ;separator=", "
    if attrs_str then '(<%attrs_str%>)'
  case VAR_ATTR_STRING(__) then
    let quantity_str = dumpExpAttrOpt(quantity, "quantity")
    let start_str = dumpExpAttrOpt(start, "start")
    let so_str = dumpStartOriginAttrOpt(startOrigin)
    let attrs_str = {quantity_str, start_str, so_str} ;separator=", "
    if attrs_str then '(<%attrs_str%>)'
  case VAR_ATTR_ENUMERATION(__) then
    let quantity_str = dumpExpAttrOpt(quantity, "quantity")
    let min_str = dumpExpAttrOpt(min, "min")
    let max_str = dumpExpAttrOpt(max, "max")
    let start_str = dumpExpAttrOpt(start, "start")
    let fixed_str = dumpExpAttrOpt(fixed, "fixed")
    let so_str = dumpStartOriginAttrOpt(startOrigin)
    let attrs_str = {quantity_str, min_str, max_str, start_str, fixed_str, so_str} ;separator=", "
    if attrs_str then '(<%attrs_str%>)'
end dumpVariableAttributes;

template dumpExpAttrOpt(Option<Exp> exp, String attr)
::=
match exp
  case SOME(e) then '<%attr%> = <%dumpExp(e)%>'
end dumpExpAttrOpt;

template dumpStateSelectAttrOpt(Option<StateSelect> stateSelect)
::= match stateSelect case SOME(ss) then dumpStateSelectAttr(ss)
end dumpStateSelectAttrOpt;

template dumpStateSelectAttr(DAE.StateSelect stateSelect)
::= 'stateSelect = <%dumpStateSelect(stateSelect)%>'
end dumpStateSelectAttr;

template dumpStateSelect(DAE.StateSelect stateSelect)
::=
match stateSelect
  case NEVER(__) then 'StateSelect.never'
  case AVOID(__) then 'StateSelect.avoid'
  case DEFAULT(__) then 'StateSelect.default'
  case PREFER(__) then 'StateSelect.prefer'
  case ALWAYS(__) then 'StateSelect.always'
end dumpStateSelect;

template dumpUncertaintyAttrOpt(Option<Uncertainty> uncertainty)
::= match uncertainty case SOME(u) then dumpUncertaintyAttr(u)
end dumpUncertaintyAttrOpt;

template dumpUncertaintyAttr(DAE.Uncertainty uncertainty)
::= 'uncertainty = <%dumpUncertainty(uncertainty)%>'
end dumpUncertaintyAttr;

template dumpUncertainty(DAE.Uncertainty uncertainty)
::=
match uncertainty
  case GIVEN(__) then 'Uncertainty.given'
  case SOUGHT(__) then 'Uncertainty.sought'
  case REFINE(__) then 'Uncertainty.refine'
end dumpUncertainty;

template dumpDistributionAttrOpt(Option<Distribution> distribution)
::= match distribution case SOME(d) then dumpDistributionAttr(d)
end dumpDistributionAttrOpt;

template dumpDistributionAttr(Distribution distribution)
::= 'distribution = <%dumpDistribution(distribution)%>'
end dumpDistributionAttr;

template dumpDistribution(Distribution distribution)
::=
match distribution
  case DISTRIBUTION(__) then
    let name_str = dumpExp(name)
    let params_str = dumpExp(params)
    let paramnames_str = dumpExp(paramNames)
    'Distribution(name = <%name_str%>, params = <%params_str%>, paramNames = <%paramnames_str%>)'
end dumpDistribution;

template dumpStartOriginAttrOpt(Option<Exp> startOrigin)
::= if Config.showStartOrigin() then dumpExpAttrOpt(startOrigin, "startOrigin")
end dumpStartOriginAttrOpt;

template dumpCref(ComponentRef c)
::=
match c
  case CREF_QUAL(__) then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    <<
    <%ident%><%dumpSubscripts(subscriptLst)%>__<%dumpCref(componentRef)%>
    >>
    else
    <<
    <%ident%><%dumpSubscripts(subscriptLst)%>.<%dumpCref(componentRef)%>
    >>
  case CREF_IDENT(ident = "$DER") then
    <<
    der(<%ident%><%dumpSubscripts(subscriptLst)%>)
    >>
  case CREF_IDENT(__) then
    <<
    <%ident%><%dumpSubscripts(subscriptLst)%>
    >>
end dumpCref;

template dumpTypeDimensions(list<Dimension> dimensionLst)
::=
  if dimensionLst then
    let sub_str = (dimensionLst |> s => dumpDimension(s) ;separator=", ")
    '[<%sub_str%>]'
end dumpTypeDimensions;


template dumpSubscripts(list<Subscript> subscriptLst)
::=
  if subscriptLst then
    if (Flags.getConfigBool(Flags.MODELICA_OUTPUT)) then
    let sub_str = (subscriptLst |> s => dumpSubscript(s) ;separator="_")
    '_<%sub_str%>'
    else
    let sub_str = (subscriptLst |> s => dumpSubscript(s) ;separator=",")
    '[<%sub_str%>]'
end dumpSubscripts;

template dumpSubscript(DAE.Subscript subscript)
::=
match subscript
  case WHOLEDIM(__) then ':'
  case SLICE(__) then dumpExp(exp)
  case INDEX(__) then dumpExp(exp)
  case WHOLE_NONEXP(__) then '1:<%dumpExp(exp)%>'
end dumpSubscript;

/*****************************************************************************
 *     SECTION: INITIAL EQUATION SECTION                                     *
 *****************************************************************************/
template dumpInitialEquationSection(list<DAE.Element> ie)
::=
  if ie then
    <<
    initial equation
      <%ie |> ineq => dumpEquationElement(ineq) ;separator="\n"%>
    >>
end dumpInitialEquationSection;

/*****************************************************************************
 *     SECTION: EQUATION SECTION                                             *
 *****************************************************************************/

template dumpEquationSection(list<DAE.Element> e)
::=
  if e then
    <<
    equation
      <%e |> eq => dumpEquationElement(eq) ;separator="\n"%>
    >>
end dumpEquationSection;

template dumpEquationElement(DAE.Element lst)
::=
match lst
  case EQUATION(__) then dumpEquation(exp, scalar, source)
  case EQUEQUATION(__) then dumpEquEquation(cr1, cr2, source)
  case ARRAY_EQUATION(__) then dumpEquation(exp, array, source)
  case COMPLEX_EQUATION(__) then dumpEquation(lhs, rhs, source)
  case DEFINE(__) then dumpDefine(componentRef, exp, source)
  case WHEN_EQUATION(__) then dumpWhenEquation(lst)
  case FOR_EQUATION(__) then dumpForEquation(lst)
  case IF_EQUATION(__) then dumpIfEquation(condition1, equations2, equations3, source)
  case ASSERT(__) then dumpAssert(condition, message, level, source)
  case INITIAL_ASSERT(__) then dumpAssert(condition, message, level, source)
  case TERMINATE(__) then dumpTerminate(message, source)
  case INITIAL_TERMINATE(__) then dumpTerminate(message, source)
  case REINIT(__) then dumpReinit(componentRef, exp, source)
  case NORETCALL(__) then dumpNoRetCall(exp, source)
  case INITIAL_NORETCALL(__) then dumpNoRetCall(exp, source)
  case INITIALDEFINE(__) then dumpDefine(componentRef, exp, source)
  case INITIAL_ARRAY_EQUATION(__) then dumpEquation(exp, array, source)
  case INITIAL_COMPLEX_EQUATION(__) then dumpEquation(lhs, rhs, source)
  case INITIAL_IF_EQUATION(__) then dumpIfEquation(condition1, equations2, equations3, source)
  case INITIALEQUATION(__) then dumpEquation(exp1, exp2, source)
  else 'UNKNOWN EQUATION TYPE'
end dumpEquationElement;

template dumpEquation(DAE.Exp lhs, DAE.Exp rhs, DAE.ElementSource src)
::=
  let lhs_str = match lhs case IFEXP(__) then '(<%dumpExp(lhs)%>)' else dumpExp(lhs)
  let rhs_str = dumpExp(rhs)
  let src_str = dumpSource(src)
  <<
  <%lhs_str%> = <%rhs_str%><%src_str%>;
  >>
end dumpEquation;

template dumpEquEquation(DAE.ComponentRef lhs, DAE.ComponentRef rhs, DAE.ElementSource src)
::=
  let lhs_str = dumpCref(lhs)
  let rhs_str = dumpCref(rhs)
  let src_str = dumpSource(src)
  <<
  <%lhs_str%> = <%rhs_str%><%src_str%>;
  >>
end dumpEquEquation;

template dumpDefine(DAE.ComponentRef lhs, DAE.Exp rhs, DAE.ElementSource src)
::=
  let lhs_str = dumpCref(lhs)
  let rhs_str = dumpExp(rhs)
  let src_str = dumpSource(src)
  <<
  <%lhs_str%> = <%rhs_str%><%src_str%>;
  >>
end dumpDefine;

template dumpAssert(DAE.Exp cond, DAE.Exp msg, DAE.Exp lvl, DAE.ElementSource src)
::=
  let cond_str = dumpExp(cond)
  let msg_str = dumpExp(msg)
  let lvl_str = match lvl case DAE.ENUM_LITERAL(index = 2) then ', AssertionLevel.warning'
  let src_str = dumpSource(src)
  <<
  assert(<%cond_str%>, <%msg_str%><%lvl_str%>)<%src_str%>;
  >>
end dumpAssert;

template dumpTerminate(DAE.Exp msg, DAE.ElementSource src)
::=
  let msg_str = dumpExp(msg)
  let src_str = dumpSource(src)
  <<
  terminate(<%msg_str%>)<%src_str%>;
  >>
end dumpTerminate;

template dumpReinit(DAE.ComponentRef cref, DAE.Exp exp, DAE.ElementSource src)
::=
  let cref_str = dumpCref(cref)
  let exp_str = dumpExp(exp)
  let src_str = dumpSource(src)
  <<
  reinit(<%cref_str%>, <%exp_str%>)<%src_str%>;
  >>
end dumpReinit;

template dumpNoRetCall(DAE.Exp call_exp, DAE.ElementSource src)
::=
  let call_str = dumpExp(call_exp)
  let src_str = dumpSource(src)
  let tail_str = match call_exp
    case CALL(attr=CALL_ATTR(tailCall=TAIL(__))) then "return "
    else ""
  <<
  <%tail_str%><%call_str%><%src_str%>;
  >>
end dumpNoRetCall;

template dumpWhenEquation(DAE.Element lst)
::=
match lst
  case WHEN_EQUATION(__) then
    let when_cond_str = dumpExp(condition)
    let body_str = (equations |> e => dumpEquationElement(e) ;separator="\n")
    let elsewhen_str = match elsewhen_ case SOME(el) then dumpWhenEquation(el)
    let src_str = dumpSource(source)
    if not elsewhen_str then
    <<
    when <%when_cond_str%> then
      <%body_str%>
    end when<%src_str%>;
    >>
    else
    <<
    when <%when_cond_str%> then
      <%body_str%>
    else<%elsewhen_str%>
    >>
end dumpWhenEquation;

template dumpForEquation(DAE.Element lst)
::=
match lst
  case FOR_EQUATION(__) then
    let range_str = dumpExp(range)
    let body_str = (equations |> e => dumpEquationElement(e) ;separator="\n")
    let src_str = dumpSource(source)
    <<
    for <%iter%> in <%range_str%> loop
      <%body_str%>
    end for<%src_str%>;
    >>
end dumpForEquation;

template dumpIfEquation(list<DAE.Exp> conds, list<list<DAE.Element>> branches,
  list<DAE.Element> else_branch, DAE.ElementSource src)
::=
match conds
  case if_cond :: elseif_conds then
    match branches
      case if_branch :: elseif_branches then
        let if_cond_str = dumpExp(if_cond)
        let if_branch_str = (if_branch |> e => dumpEquationElement(e) ;separator="\n")
        let elseif_str = dumpElseIfEquation(elseif_conds, elseif_branches)
        let else_str = if else_branch then
          <<
          else
            <%else_branch |> e => dumpEquationElement(e) ;separator="\n"%>
          >>
        let src_str = dumpSource(src)
        <<
        if <%if_cond_str%> then
          <%if_branch_str%>
        <%elseif_str%>
        <%else_str%>
        end if<%src_str%>;
        >>
end dumpIfEquation;

template dumpElseIfEquation(list<Exp> condition1,
    list<list<DAE.Element>> equations)
::=
match condition1
  case cond :: rest_conds then
    match equations
      case branch :: rest_branches then
        let cond_str = dumpExp(cond)
        let branch_str = (branch |> e => dumpEquationElement(e) ;separator="\n")
        let rest_str = dumpElseIfEquation(rest_conds, rest_branches)
        <<
        elseif <%cond_str%> then
          <%branch_str%>
        <%rest_str%>
        >>
end dumpElseIfEquation;

/*****************************************************************************
 *     SECTION: INITIAL ALGORITHM SECTION                                    *
 *****************************************************************************/
template dumpInitialAlgorithmSection(list<DAE.Element> ia)
::= (ia |> alg => dumpInitialAlgorithm(alg) ;separator="\n")
end dumpInitialAlgorithmSection;

template dumpInitialAlgorithm(DAE.Element alg)
::=
match alg
  case INITIALALGORITHM(__) then
    <<
    <%dumpAlgorithm(algorithm_, "initial algorithm")%>
    >>
end dumpInitialAlgorithm;


/*****************************************************************************
 *     SECTION: ALGORITHM SECTION                                            *
 *****************************************************************************/

template dumpAlgorithmSection(list<DAE.Element> a)
::= (a |> alg => dumpAlgorithmElement(alg) ;separator="\n")
end dumpAlgorithmSection;

template dumpAlgorithmElement(DAE.Element alg)
::=
match alg
  case ALGORITHM(__) then
    <<
    <%dumpAlgorithm(algorithm_, "algorithm")%>
    >>
end dumpAlgorithmElement;

template dumpAlgorithm(Algorithm algorithm_, String header)
::=
match algorithm_
  case ALGORITHM_STMTS(__) then
    <<
    <%header%>
      <%dumpStatements(statementLst)%>
    >>
end dumpAlgorithm;

template dumpStatements(list<DAE.Statement> stmts)
::= (stmts |> stmt => dumpStatement(stmt) ;separator="\n")
end dumpStatements;

template dumpStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSIGN(__) then dumpAssignment(exp1, exp, source)
  case STMT_TUPLE_ASSIGN(__) then dumpTupleAssignStatement(stmt)
  case STMT_ASSIGN_ARR(__)   then dumpArrayAssignStatement(stmt)
  case STMT_IF(__) then dumpIfStatement(stmt)
  case STMT_FOR(__) then dumpForStatement(stmt)
  case STMT_WHILE(__) then dumpWhileStatement(stmt)
  case STMT_WHEN(__) then dumpWhenStatement(stmt)
  case STMT_ASSERT(__) then dumpAssert(cond, msg, level, source)
  case STMT_TERMINATE(__) then dumpTerminate(msg, source)
  case STMT_REINIT(__) then dumpReinitStatement(stmt)
  case STMT_NORETCALL(__) then dumpNoRetCall(exp, source)
  case STMT_RETURN(__) then 'return;'
  case STMT_BREAK(__) then 'break;'
  case STMT_CONTINUE(__) then 'continue;'
  case STMT_FAILURE(__) then 'fail();'
  else errorMsg("DAEDump.dumpStatement: Unknown statement.")

end dumpStatement;

template dumpAssignment(DAE.Exp lhs, DAE.Exp rhs, DAE.ElementSource src)
::=
  let lhs_str = match lhs case IFEXP(__) then '(<%dumpExp(lhs)%>)' else dumpExp(lhs)
  let rhs_str = dumpExp(rhs)
  let src_str = dumpSource(src)
  <<
  <%lhs_str%> := <%rhs_str%><%src_str%>;
  >>
end dumpAssignment;

template dumpTupleAssignStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_TUPLE_ASSIGN(__) then
    let lhs_str = (expExpLst |> e => dumpExp(e);separator=", ")
    let rhs_str = dumpExp(exp)
    let src_str = dumpSource(source)
    <<
    (<%lhs_str%>) := <%rhs_str%><%src_str%>;
    >>
end dumpTupleAssignStatement;

template dumpArrayAssignStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSIGN_ARR(__) then
    let lhs_str =  dumpExp(lhs)
    let rhs_str = dumpExp(exp)
    let src_str = dumpSource(source)
    <<
    <%lhs_str%> := <%rhs_str%><%src_str%>;
    >>
end dumpArrayAssignStatement;

template dumpIfStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_IF(__) then
    let if_cond_str = dumpExp(exp)
    let true_branch_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let else_if_str = dumpElseIfStatements(else_)
    let src_str = dumpSource(source)
    <<
    if <%if_cond_str%> then
      <%true_branch_str%>
    <%else_if_str%>
    end if<%src_str%>;
    >>
end dumpIfStatement;

template dumpElseIfStatements(Else else_)
::=
match else_
  case ELSEIF(__) then
    let elseif_cond_str = dumpExp(exp)
    let elseif_body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let else_str = dumpElseIfStatements(else_)
    <<
    elseif <%elseif_cond_str%> then
      <%elseif_body_str%>
    <%else_str%>
    >>
  case ELSE(__) then
    let else_body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    <<
    else
      <%else_body_str%>
    >>
end dumpElseIfStatements;

template dumpForStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_FOR(__) then
    let range_str = dumpExp(range)
    let alg_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let src_str = dumpSource(source)
    <<
    for <%iter%> in <%range_str%> loop
      <%alg_str%>
    end for<%src_str%>;
    >>
end dumpForStatement;

template dumpWhileStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_WHILE(__) then
    let while_cond = dumpExp(exp)
    let body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let src_str = dumpSource(source)
    <<
    while <%while_cond%> loop
      <%body_str%>
    end while<%src_str%>;
    >>
end dumpWhileStatement;

template dumpWhenStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_WHEN(__) then
    let when_cond_str = dumpExp(exp)
    let body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let elsewhen_str = match elseWhen case SOME(ew) then dumpWhenStatement(ew)
    let src_str = dumpSource(source)
    if not elsewhen_str then
    <<
    when <%when_cond_str%> then
      <%body_str%>
    end when<%src_str%>;
    >>
    else
    <<
    when <%when_cond_str%> then
      <%body_str%>
    else<%elsewhen_str%>
    >>
end dumpWhenStatement;

template dumpReinitStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_REINIT(__) then
    let exp_str = dumpExp(var)
    let new_exp_str = dumpExp(value)
    let src_str = dumpSource(source)
    <<
    reinit(<%exp_str%>, <%new_exp_str%>)<%src_str%>;
    >>
end dumpReinitStatement;

/*****************************************************************************
 *     SECTION: STATE MACHINES                                           *
 *****************************************************************************/
template dumpStateMachineSection(DAEDump.compWithSplitElements fixedDae)
::=
match fixedDae case COMP_WITH_SPLIT(__) then
  /* Whether we have a DAE.FLAT_SM (stateMachine) or DAE.STATE_SM (state) is encoded in the comment.
     That is a bit hackish */
  let kind = match comment case SOME(co) then dumpStateMachineComment(co)
  <<
  <%kind%> <%name%>
    <%dumpCompStream(spltElems)%>
  end <%name%>;<%\n%>
  >>
end dumpStateMachineSection;

template dumpStateMachineComment(SCode.Comment cmt)
::=
match cmt case COMMENT(__) then
    let kind_str = match comment case SOME(co) then co
    '<%kind_str%>'
end dumpStateMachineComment;


/*****************************************************************************
 *     SECTION: EXPRESSIONS                                                  *
 *****************************************************************************/
template dumpExp(DAE.Exp exp)
::= ExpressionDumpTpl.dumpExp(exp, "\"")
end dumpExp;

template dumpClassAnnotation(Option<SCode.Comment> comment)
::=
  let cmt_str = dumpCommentAnnotation(comment)
  if cmt_str then '<%cmt_str%>;'
end dumpClassAnnotation;

template dumpCompAnnotation(Option<SCode.Comment> comment)
::=
  let cmt_str = dumpCommentAnnotation(comment)
  if cmt_str then '<%\ %><%cmt_str%>'
end dumpCompAnnotation;

template dumpCommentAnnotation(Option<SCode.Comment> comment)
::= match comment case SOME(cmt) then dumpCommentAnnotationNoOpt(cmt)
end dumpCommentAnnotation;

template dumpCommentAnnotationNoOpt(SCode.Comment comment)
::= match comment case SCode.COMMENT(annotation_ = SOME(ann)) then dumpAnnotation(ann)
end dumpCommentAnnotationNoOpt;

template dumpCommentOpt(Option<SCode.Comment> comment)
::= match comment case SOME(cmt) then dumpComment(cmt)
end dumpCommentOpt;

template dumpComment(SCode.Comment comment)
::= match comment case COMMENT(__) then dumpCommentStr(comment)
end dumpComment;

template dumpCommentStr(Option<String> comment)
::= match comment case SOME(cmt) then '<%\ %>"<%System.escapedString(cmt,false)%>"'
end dumpCommentStr;

template dumpAnnotationOpt(Option<SCode.Annotation> annotation)
::= match annotation case SOME(ann) then dumpAnnotation(ann)
end dumpAnnotationOpt;

template dumpAnnotation(SCode.Annotation annotation)
::=
  match annotation
    case SCode.ANNOTATION(modification = ann_mod) then
      if Config.showAnnotations() then
        'annotation<%SCodeDumpTpl.dumpModifier(ann_mod, SCodeDump.defaultOptions)%>'
      else if Config.showStructuralAnnotations() then
        let ann_str = SCodeDumpTpl.dumpModifier(DAEDump.filterStructuralMods(ann_mod), SCodeDump.defaultOptions)
        if ann_str then
          'annotation<%ann_str%>'
end dumpAnnotation;

template dumpPathLastIndent(Absyn.Path path)
::=
match path
  case FULLYQUALIFIED(__) then dumpPathLastIndent(path)
  case QUALIFIED(__) then  dumpPathLastIndent(path)
  case IDENT(__) then  '<%name%>'
  else errorMsg("dumpPathLastIndent: Unknown path.")
end dumpPathLastIndent;

template dumpSource(DAE.ElementSource source)
::=
match source
  case SOURCE(__) then (comment |> c => dumpComment(c) ;separator=" + ")
end dumpSource;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="frontend");
end DAEDumpTpl;
