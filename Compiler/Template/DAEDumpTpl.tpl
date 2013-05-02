package DAEDumpTpl

import interface DAEDumpTV;
import AbsynDumpTpl;
import SCodeDumpTpl;

/***************************************************************************************
 *     SECTION: MAIN TEMPLATE FUNCTION
 ***************************************************************************************/
template dumpDAE(list<DAEDump.compWithSplitElements> fixedDaeList, DAEDump.functionList  funLists)
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
    <<
    class <%name%><%cmt_str%>
    <%dumpCompStream(spltElems)%>
    end <%name%>;<%\n%>
    >>
end dumpComp;

template dumpCompStream(DAEDump.splitElements elems)
::=
  match elems
    case SPLIT_ELEMENTS(__) then
      let var_str = dumpVars(v)
      let ieq_str = dumpInitialEquations(ie, "initial equation")
      let ial_str = dumpInitialAlgorithms(ia, "initial algorithm")
      let eq_str =  dumpEquations(e, "equation")
      let al_str = dumpAlgorithms(a, "algorithm")
      <<
      <%var_str%>
      <%ieq_str%>
      <%ial_str%>
      <%eq_str%>
      <%al_str%>
      >>
end dumpCompStream;

/***************************************************************************************
 *     SECTION: FUNCTION SECTION
 ***************************************************************************************/
template dumpFunctions(list<DAE.Function> funcs)
::=
  (funcs |> func => dumpFunction(func) ;separator="\n\n")
end dumpFunctions;

template dumpFunction(DAE.Function function)
::=
  match function
    case FUNCTION(functions=FUNCTION_EXT(externalDecl = EXTERNALDECL(language="builtin"))::_) then ''
    case FUNCTION(__) then
      let cmt_str = dumpCommentOpt(comment)
      <<
      function <%AbsynDumpTpl.dumpPathNoQual(path)%><%cmt_str%>
      <%dumpFunctionDefinitions(functions)%>
      end <%AbsynDumpTpl.dumpPathNoQual(path)%>;
      >>
    case RECORD_CONSTRUCTOR(__)  then
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
    <%dumpElements(body)%>
    >>
  case FUNCTION_EXT(__) then
    <<
    <%dumpElements(body)%><%\n%><%\n%>
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
    let output_str = if ext_output_str then '<%ext_output_str%> ='
    let lang_str = language
    '  external "<%lang_str%>" <%output_str%> <%func_str%>;'
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
  case  TYPES_VAR(attributes = DAE.ATTR(visibility=SCode.PROTECTED())) then
    let varType = dumpVarType(ty)
    <<
    protected <%varType%> <%name%><%dumpRecordVarBinding(binding)%>;
    >>
  case TYPES_VAR(attributes=DAE.ATTR(variability=SCode.CONST())) then
    let varType = dumpVarType(ty)
    <<
    constant <%varType%> <%name%><%dumpRecordVarBinding(binding)%>;
    >>
  case TYPES_VAR(__) then
    let varType = dumpVarType(ty)
    <<
    input <%varType%> <%name%><%dumpRecordVarBinding(binding)%>;
    >>
end dumpRecordVar;

template dumpRecordVarBinding(Binding binding)
::=
match binding
  case UNBOUND(__) then ''
  case EQBOUND(__) then ' = <%dumpExp(exp)%>'
  case VALBOUND(__) then 'value bound***** check what to display'
end dumpRecordVarBinding;

template dumpElements(list<Element> dAElist)
::=
(dAElist |> lst => dumpElement(lst) ;separator="\n")
end dumpElements;

template dumpElement(DAE.Element lst)
::=
match lst
 case VAR(__) then dumpVar(lst,true)
 case INITIALALGORITHM(__) then dumpAlgorithmElement(algorithm_ ,"initial algorithm")
 case ALGORITHM(__) then dumpAlgorithmElement(algorithm_ ,"algorithm")
 else 'Element not found'

end dumpElement;

template dumpAlgorithmElement(Algorithm algorithm_, String label)
::=
match algorithm_
  case ALGORITHM_STMTS(__) then
    <<
    <%label%>
      <%dumpStatements(statementLst)%>
    >>
end dumpAlgorithmElement;

/***************************************************************************************
 *     SECTION: VARIABLE SECTION
 ***************************************************************************************/
template dumpVars(list<DAE.Element> v)
::=
  (v |> var => dumpVar(var,false) ;separator="\n")

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
   let varType = dumpVarType(ty)
   let dim_str = if printTypeDimension then dumpTypeDimensions(dims)
   let varName = dumpCref(componentRef)
   let bindingExp = match binding case SOME(exp) then dumpExp(exp)
   let varAttr = match variableAttributesOption case SOME(VariableAttributes) then dumpVariableAttributesStr(VariableAttributes)
   let cmt_str = dumpCommentOpt(absynCommentOption)
   if bindingExp then
   <<
    <%final%><%varVisibility%><%varParallelism%><%varKind%><%varDirection%> <%varType%><%dim_str%> <%varName%><%varAttr%> = <%bindingExp%><%cmt_str%>;
   >>
   else
   <<
    <%final%><%varVisibility%><%varParallelism%><%varKind%><%varDirection%> <%varType%><%dim_str%> <%varName%><%varAttr%><%cmt_str%>;
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

template dumpVarType(Type ty)
::=
  match ty
    case T_INTEGER(varLst = {}) then  'Integer'
    case T_REAL(varLst = {})    then  'Real'
    case T_STRING(varLst = {})  then  'String'
    case T_BOOL(varLst = {})    then  'Boolean'
    case T_ENUMERATION(__)      then  'enumeration(<%dumpEnumVars(literalVarLst)%>)'
    case T_INTEGER(__)          then  'Integer(<%dumpVarAttributes(varLst)%>)'
    case T_REAL(__)             then  'Real(<%dumpVarAttributes(varLst)%>)'
    case T_STRING(__)           then  'String(<%dumpVarAttributes(varLst)%>)'
    case T_BOOL(__)             then  'Bool(<%dumpVarAttributes(varLst)%>)'
    case T_ARRAY(__)            then  '<%dumpVarType(ty)%><%dumpDimensions(dims)%>'
    case T_COMPLEX(complexClassType=RECORD(path=rname))     then  '<%AbsynDumpTpl.dumpPathNoQual(rname)%>'
    else 'variable type not yet implemented'
end dumpVarType;

template dumpEnumVars(list<Var> literalVarLst)
::=
  (literalVarLst |> var => dumpEnumVar(var) ;separator=", ")
end dumpEnumVars;

template dumpEnumVar(DAE.Var var)
::=
  match var
     case TYPES_VAR(__) then '<%name%>'
end dumpEnumVar;

template dumpVarAttributes(list<Var> literalVarLst)
::=
  (literalVarLst |> var => dumpVarAttribute(var) ;separator=", ")
end dumpVarAttributes;

template dumpVarAttribute(DAE.Var var)
::=
  match var
    case TYPES_VAR(binding = DAE.EQBOUND(exp = e)) then '<%name%>=<%dumpExp(e)%>'
end dumpVarAttribute;

template dumpDimensions(list<Dimension> dims)
::=
  (dims |> dim => dumpDimension(dim) ;separator=",")
end dumpDimensions;

template dumpDimension(Dimension dim)
::=
  match dim
    case DIM_INTEGER(__) then integer
    case DIM_ENUM(__)    then AbsynDumpTpl.dumpPath(enumTypeName)
    case DIM_EXP(__)     then dumpExp(exp)
    case DIM_UNKNOWN(__) then ':'
end dumpDimension;

template dumpVariableAttributesStr(DAE.VariableAttributes variableAttributesOption)
::=
match variableAttributesOption
   case VAR_ATTR_REAL(__) then
     let quantity_str = dumpQuantityAttribute(quantity)
     let unit_str = dumpUnitAttribute(unit)
     let displayunit_str =dumpDisplayUnitAttribute(displayUnit)
     let start_str = dumpInitialAttribute(initial_)
     let fixed_str = dumpFixedAttribute(fixed)
     let min_max_str = dumpMinMaxAttribute(min)
     let nominal_str = dumpNominalAttribute(nominal)
     let stateSel_str = dumpStateSelectStrs(stateSelectOption)
     let uncertainty_str = dumpUncertaintyStrs(uncertainOption)
     let attrs_str = {quantity_str, unit_str, displayunit_str, min_max_str, start_str, fixed_str, nominal_str,stateSel_str ,uncertainty_str} ;separator=", "
     if attrs_str then
     <<
     (<%attrs_str%>)
     >>
   case VAR_ATTR_INT(__) then
     let quantity_str = dumpQuantityAttribute(quantity)
     let start_str = dumpInitialAttribute(initial_)
     let fixed_str = dumpFixedAttribute(fixed)
     let min_max_str = dumpMinMaxAttribute(min)
     let attrs_str = {quantity_str, min_max_str, start_str, fixed_str} ;separator=", "
     if attrs_str then
     <<
     (<%attrs_str%>)
     >>
   case VAR_ATTR_BOOL(__)  then
     let quantity_str = dumpQuantityAttribute(quantity)
     let start_str = dumpInitialAttribute(initial_)
     let fixed_str = dumpFixedAttribute(fixed)
     let attrs_str = {quantity_str, start_str, fixed_str} ;separator=", "
     if attrs_str then
     <<
     (<%attrs_str%>)
     >>
   case VAR_ATTR_STRING(__) then
     let quantity_str = dumpQuantityAttribute(quantity)
     let start_str = dumpInitialAttribute(initial_)
     let attrs_str = {quantity_str, start_str} ;separator=", "
     if attrs_str then
     <<
     (<%attrs_str%>)
     >>
   case VAR_ATTR_ENUMERATION(__) then
     let quantity_str = dumpQuantityAttribute(quantity)
     let start_str = dumpInitialAttribute(start)
     let fixed_str = dumpFixedAttribute(fixed)
     let min_max_str = dumpMinMaxAttribute(min)
     let attrs_str = {quantity_str, min_max_str, start_str, fixed_str} ;separator=", "
     if attrs_str then
     <<
     (<%attrs_str%>)
     >>
end dumpVariableAttributesStr;

template dumpQuantityAttribute(Option<Exp> quantity)
::=
match quantity
  case SOME(exp) then 'quantity = <%dumpExp(exp)%>'
end dumpQuantityAttribute;

template dumpUnitAttribute(Option<Exp> unit)
::=
match unit
  case SOME(exp) then 'unit = <%dumpExp(exp)%>'
end dumpUnitAttribute;

template dumpDisplayUnitAttribute(Option<Exp> displayUnit)
::=
match displayUnit
  case SOME(exp) then 'displayUnit = <%dumpExp(exp)%>'
end dumpDisplayUnitAttribute;

template dumpInitialAttribute(Option<Exp> initial_)
::=
match initial_
  case SOME(exp) then 'start = <%dumpExp(exp)%>'
end dumpInitialAttribute;

template dumpFixedAttribute(Option<Exp> fixed)
::=
match fixed
  case SOME(exp) then 'fixed = <%dumpExp(exp)%>'
end dumpFixedAttribute;

template dumpMinMaxAttribute(tuple<Option<Exp>, Option<Exp>> min)
::=
match min
  case (SOME(exp1), SOME(exp2)) then 'min = <%dumpExp(exp1)%>, max = <%dumpExp(exp2)%>'
  case (NONE(), SOME(exp2)) then 'max = <%dumpExp(exp2)%>'
  case (SOME(exp1),NONE()) then  'min = <%dumpExp(exp1)%>'
end dumpMinMaxAttribute;

template dumpNominalAttribute(Option<Exp> nominal)
::=
match nominal
  case SOME(exp) then 'nominal = <%dumpExp(exp)%>'
end dumpNominalAttribute;

template dumpStateSelectStrs(Option<StateSelect> stateS)
::=
match stateS
  case SOME(StateSelect)  then  dumpStateSelectStr(StateSelect)
end dumpStateSelectStrs;

template dumpStateSelectStr(DAE.StateSelect stateS)
::=
match stateS
  case NEVER(__)   then  'stateSelect = StateSelect.never'
  case AVOID(__)   then  'stateSelect = StateSelect.avoid'
  case DEFAULT(__) then  'stateSelect = StateSelect.default'
  case PREFER(__)  then  'stateSelect = StateSelect.prefer'
  case ALWAYS(__)  then  'stateSelect = StateSelect.always'
end dumpStateSelectStr;

template dumpUncertaintyStrs(Option<Uncertainty> uncertain)
::=
match uncertain
  case SOME(Uncertainty)  then   dumpUncertaintyStr(Uncertainty)
end dumpUncertaintyStrs;

template dumpUncertaintyStr(DAE.Uncertainty uncertain)
::=
match uncertain
  case GIVEN(__)   then   'uncertainty = Uncertainty.given'
  case SOUGHT(__)  then   'uncertainty = Uncertainty.sought'
  case REFINE(__)  then   'uncertainty = Uncertainty.refine'
end dumpUncertaintyStr;

template dumpCref(ComponentRef c)
::=
match c
  case CREF_QUAL(__) then
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

template dumpTypeDimensions(list<Subscript> subscriptLst)
::=
  if subscriptLst then
    let sub_str = (subscriptLst |> s => dumpSubscript(s) ;separator=", ")
    '[<%sub_str%>]'
end dumpTypeDimensions;


template dumpSubscripts(list<Subscript> subscriptLst)
::=
  if subscriptLst then
    let sub_str = (subscriptLst |> s => dumpSubscript(s) ;separator=",")
    '[<%sub_str%>]'
end dumpSubscripts;

template dumpSubscript(DAE.Subscript subscript)
::=
match subscript
  case WHOLEDIM(__) then ':'
  case SLICE(__) then dumpExp(exp)
  case INDEX(__) then dumpExp(exp)
  case WHOLE_NONEXP(__) then dumpExp(exp)
end dumpSubscript;

/*****************************************************************************************
 *     SECTION: INITIAL EQUATION SECTION
 ****************************************************************************************/
 template dumpInitialEquations(list<DAE.Element> ie, String label)
::=
  if ie then
    <<
    <%label%>
      <%ie |> ineq => dumpInitialEquation(ineq) ;separator="\n"%>
    >>
end dumpInitialEquations;

template dumpInitialEquation(DAE.Element lst )
::=
match lst
  case INITIALDEFINE(__) then
    let lhs_str = dumpCref(componentRef)
    let rhs_str = dumpExp(exp)
    <<
    <%lhs_str%> = <%rhs_str%>;
    >>
  case INITIAL_ARRAY_EQUATION(__) then
    let lhs_str = dumpExp(exp)
    let rhs_str = dumpExp(array)
    <<
    <%lhs_str%> = <%rhs_str%>;
    >>
  case INITIAL_COMPLEX_EQUATION(__) then
    let lhs_str = dumpExp(lhs)
    let rhs_str = dumpExp(rhs)
    <<
    <%lhs_str%> = <%rhs_str%>;
    >>
  case INITIAL_IF_EQUATION(__) then dumpInitialIfEquation(lst)
  case INITIALEQUATION(__) then
    let lhs_str = dumpExp(exp1)
    let rhs_str = dumpExp(exp2)
    <<
    <%lhs_str%> = <%rhs_str%>;
    >>
end dumpInitialEquation;

template dumpInitialIfEquation(DAE.Element lst)
::=
match lst
  case INITIAL_IF_EQUATION(condition1 = if_cond :: elseif_conds,
             equations2 = if_branch :: elseif_branches) then
    let if_cond_str = dumpExp(if_cond)
    let if_branch_str = (if_branch |> e => dumpEquation(e) ;separator="\n")
    let elseif_str = dumpElseIfEquation(elseif_conds, elseif_branches)
    let else_str = if equations3 then
      <<
      else
       <%equations3 |> e => dumpEquation(e) ;separator="\n"%>
      >>
    <<
    if <%if_cond_str%> then
    <%if_branch_str%>
    <%elseif_str%>
    <%else_str%>
    end if;
    >>
end dumpInitialIfEquation;

/***********************************************************************************************************
 *     SECTION: EQUATION SECTION
 ***********************************************************************************************************/

template dumpEquations(list<DAE.Element> e, String label)
::=
  if e then
    <<
    <%label%>
      <%e |> eq => dumpEquation(eq) ;separator="\n"%>
    >>
end dumpEquations;

template dumpEquation(DAE.Element lst)
::=
match lst
  case EQUATION(__) then
    let lhs_str = dumpExp(exp)
    let rhs_str = dumpExp(scalar)
    let source_src = dumpSource(source)
    <<
    <%lhs_str%> = <%rhs_str%><%source_src%>;
    >>
  case EQUEQUATION(__) then
    let lhs_cref = dumpCref(cr1)
    let rhs_cref = dumpCref(cr2)
    let source_src = dumpSource(source)
    <<
    <%lhs_cref%> = <%rhs_cref%><%source_src%>;
    >>
  case ARRAY_EQUATION(__) then
    let lhs_str = dumpExp(exp)
    let rhs_str = dumpExp(array)
    let source_src = dumpSource(source)
    <<
    <%lhs_str%> = <%rhs_str%><%source_src%>;
    >>
  case COMPLEX_EQUATION(__) then
    let lhs_str = dumpExp(lhs)
    let rhs_str = dumpExp(rhs)
    let source_src = dumpSource(source)
    <<
    <%lhs_str%> = <%rhs_str%><%source_src%>;
    >>
  case DEFINE(__) then
    let lhs_str = dumpCref(componentRef)
    let rhs_str = dumpExp(exp)
    let source_src = dumpSource(source)
    <<
    <%lhs_str%> = <%rhs_str%><%source_src%>;
    >>
  case WHEN_EQUATION(__) then dumpWhenEquation(lst)
  case IF_EQUATION(__) then dumpIfEquation(lst)
  case ASSERT(__) then
    let cond_str = dumpExp(condition)
    let msg_str = dumpExp(message)
    let source_src = dumpSource(source)
    <<
    assert(<%cond_str%>,<%msg_str%>)<%source_src%>;
    >>
  case TERMINATE(__) then
    let msg_str = dumpExp(message)
    let source_src = dumpSource(source)
    <<
    terminate(<%msg_str%>)<%source_src%>;
    >>
  case REINIT(__) then
    let cref_str = dumpCref(componentRef)
    let exp_str = dumpExp(exp)
    let source_src = dumpSource(source)
    <<
    reinit(<%cref_str%>,<%exp_str%>)<%source_src%>;
    >>
  case NORETCALL(__) then
    let source_src = dumpSource(source)
    'NO_RETURN_CALL<%source_src%>;'
  else 'UNKNOWN EQUATION TYPE'
end dumpEquation;

template dumpWhenEquation(DAE.Element lst)
::=
match lst
  case WHEN_EQUATION(__) then
    let when_cond_str = dumpExp(condition)
    let body_str = (equations |> e => dumpEquation(e) ;separator="\n")
    let elsewhen_str = match lst case WHEN_EQUATION(elsewhen_ = SOME(Element)) then dumpEquation(Element)
    if not elsewhen_str then
    <<
    when <%when_cond_str%> then
    <%body_str%>
    end when;
    >>
    else
    <<
    when <%when_cond_str%> then
    <%body_str%>
    else<%elsewhen_str%>
    >>
end dumpWhenEquation;

template dumpIfEquation(DAE.Element lst)
::=
match lst
  case IF_EQUATION(condition1 = if_cond :: elseif_conds,
             equations2 = if_branch :: elseif_branches) then
    let if_cond_str = dumpExp(if_cond)
    let if_branch_str = (if_branch |> e => dumpEquation(e) ;separator="\n")
    let elseif_str = dumpElseIfEquation(elseif_conds, elseif_branches)
    let else_str = if equations3 then
      <<
      else
       <%equations3 |> e => dumpEquation(e) ;separator="\n"%>
      >>
    <<
    if <%if_cond_str%> then
    <%if_branch_str%>
    <%elseif_str%>
    <%else_str%>
    end if;
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
        let branch_str = (branch |> e => dumpEquation(e) ;separator="\n")
        let rest_str = dumpElseIfEquation(rest_conds, rest_branches)
        <<
        elseif <%cond_str%> then
        <%branch_str%>
        <%rest_str%>
        >>
end dumpElseIfEquation;

/************************************************************************************************************
 *     SECTION: INITIAL ALGORITHM SECTION
 ************************************************************************************************************/
template dumpInitialAlgorithms(list<DAE.Element> ia, String label)
::=
  if ia then
    <<
    <%label%>
    <%ia |> alg => dumpInitialAlgorithm(alg) ;separator="\n"%>
    >>
end dumpInitialAlgorithms;

template dumpInitialAlgorithm(DAE.Element alg)
::=
match alg
  case INITIALALGORITHM(__) then
    <<
    <%dumpAlgorithmStatement(algorithm_)%>
    >>
end dumpInitialAlgorithm;


/************************************************************************************************************
 *     SECTION: ALGORITHM SECTION
 ************************************************************************************************************/
template dumpAlgorithms(list<DAE.Element> a, String label)
::=
  if a then
    <<
    <%label%>
      <%a |> alg => dumpAlgorithm(alg) ;separator="\n"%>
    >>
end dumpAlgorithms;

template dumpAlgorithm(DAE.Element alg)
::=
match alg
  case ALGORITHM(__) then
    <<
    <%dumpAlgorithmStatement(algorithm_)%>
    >>
end dumpAlgorithm;

template dumpAlgorithmStatement(Algorithm algorithm_)
::=
match algorithm_
  case ALGORITHM_STMTS(__) then
    <<
    <%dumpStatements(statementLst)%>
    >>
end dumpAlgorithmStatement;

template dumpStatements(list<DAE.Statement> stmts)
::=
(stmts |> stmt => dumpStatement(stmt) ;separator="\n")
end dumpStatements;

template dumpStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSIGN(__) then
    let lhs_str = dumpExp(exp1)
    let rhs_str = dumpExp(exp)
    '<%lhs_str%> := <%rhs_str%>;'
  case STMT_TUPLE_ASSIGN(__) then dumpTupleAssignStatement(stmt)
  case STMT_ASSIGN_ARR(__)   then dumpArrayAssignStatement(stmt)
  case STMT_IF(__) then dumpIfStatement(stmt)
  case STMT_FOR(__) then dumpForStatement(stmt)
  case STMT_WHILE(__) then dumpWhileStatement(stmt)
  case STMT_WHEN(__) then dumpWhenStatement(stmt)
  case STMT_ASSERT(__) then dumpAssertStatement(stmt)
  case STMT_TERMINATE(__) then dumpTerminateStatement(stmt)
  case STMT_REINIT(__) then dumpReinitStatement(stmt)
  case STMT_NORETCALL(__) then dumpNoReturnCallStatement(stmt)
  case STMT_RETURN(__) then 'return;'
  case STMT_BREAK(__) then 'break;'
  else errorMsg("DAEDump.dumpStatement: Unknown statement.")

end dumpStatement;

template dumpTupleAssignStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_TUPLE_ASSIGN(__) then
    let lhs_str = (expExpLst |> e => dumpExp(e);separator=", ")
    let rhs_str = dumpExp(exp)
    <<
    (<%lhs_str%>) := <%rhs_str%>;
    >>
end dumpTupleAssignStatement;

template dumpArrayAssignStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSIGN_ARR(__) then
    let lhs_str =  dumpCref(componentRef)
    let rhs_str = dumpExp(exp)
    <<
    <%lhs_str%> := <%rhs_str%>;
    >>
end dumpArrayAssignStatement;

template dumpIfStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_IF(__) then
    let if_cond_str = dumpExp(exp)
    let true_branch_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let else_if_str =  dumpElseIfStatements(else_)
    <<
    if <%if_cond_str%> then
      <%true_branch_str%>
    <%else_if_str%>
    end if;
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
    <<
    for <%iter%> in <%range_str%> loop
      <%alg_str%>
    end for;
    >>
end dumpForStatement;

template dumpWhileStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_WHILE(__) then
    let while_cond = dumpExp(exp)
    let body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    <<
    while <%while_cond%> loop
      <%body_str%>
    end while;
    >>
end dumpWhileStatement;

template dumpWhenStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_WHEN(__) then
    let when_cond_str = dumpExp(exp)
    let body_str = (statementLst |> e => dumpStatement(e) ;separator="\n")
    let elsewhen_str = match stmt case STMT_WHEN(elseWhen = SOME(Statement)) then dumpStatement(Statement)
    if not elsewhen_str then
    <<
    when <%when_cond_str%> then
     <%body_str%>
    end when;
    >>
    else
    <<
    when <%when_cond_str%> then
     <%body_str%>
    else<%elsewhen_str%>
    >>
end dumpWhenStatement;

template dumpAssertStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_ASSERT(__) then
    let assert_cond = dumpExp(cond)
    let assert_msg = dumpExp(msg)
    <<
    assert(<%assert_cond%>, <%assert_msg%>);
    >>
end dumpAssertStatement;

template dumpTerminateStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_TERMINATE(__) then
    let msg_str = dumpExp(msg)
    <<
    terminate(<%msg_str%>);
    >>
end dumpTerminateStatement;

template dumpReinitStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_REINIT(__) then
    let exp_str = dumpExp(var)
    let new_exp_str = dumpExp(value)
    <<
    reinit(<%exp_str%>, <%new_exp_str%>);
    >>
end dumpReinitStatement;

template dumpNoReturnCallStatement(DAE.Statement stmt)
::=
match stmt
  case STMT_NORETCALL(__) then
    let exp_str = dumpExp(exp)
    <<
    <%exp_str%>;
    >>
end dumpNoReturnCallStatement;

/*********************************************************************************************************
 *     SECTION: EXPRESSIONS
 *********************************************************************************************************/
template dumpExp(DAE.Exp exp)
::= ExpressionDumpTpl.dumpExp(exp, "\"")
end dumpExp;

template dumpCommentOpt(Option<SCode.Comment> comment)
::= match comment case SOME(cmt) then dumpComment(cmt)
end dumpCommentOpt;

template dumpComment(SCode.Comment comment)
::=
  match comment
    case COMMENT(__) then
      let cmt_str = dumpCommentStr(comment)
      '<%cmt_str%>'
end dumpComment;

template dumpCommentStr(Option<String> comment)
::= match comment case SOME(cmt) then ' "<%cmt%>"'
end dumpCommentStr;

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
  case SOURCE(__) then
    let cmt = (comment |> c => dumpComment(c) ;separator=" ")
    '<%cmt%>'
end dumpSource;

template errorMsg(String errMessage)
::=
let() = Tpl.addTemplateError(errMessage)
<<
<%errMessage%>
>>
end errorMsg;

end DAEDumpTpl;
