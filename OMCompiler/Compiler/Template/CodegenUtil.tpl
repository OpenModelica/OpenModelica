// This file defines util functions for templates for transforming Modelica/MetaModelica code to C like
// code. They are used in the code generator phase of the compiler to write
// target code.
//
// There are two root templates intended to be called from the code generator:
// translateModel and translateFunctions. These templates do not return any
// result but instead write the result to files. All other templates return
// text and are used by the root templates (most of them indirectly).
//
// To future maintainers of this file:
//
// - A line like this
//     # var = "" /*BUFD*/
//   declares a text buffer that you can later append text to. It can also be
//   passed to other templates that in turn can append text to it. In the new
//   version of Susan it should be written like this instead:
//     let &var = buffer ""
//
// - A line like this
//     ..., Text var /*BUFP*/, ...
//   declares that a template takes a text buffer as input parameter. In the
//   new version of Susan it should be written like this instead:
//     ..., Text &var, ...
//
// - A line like this:
//     ..., var /*BUFC*/, ...
//   passes a text buffer to a template. In the new version of Susan it should
//   be written like this instead:
//     ..., &var, ...
//
// - Style guidelines:
//
//   - Try (hard) to limit each row to 80 characters
//
//   - Code for a template should be indented with 2 spaces
//
//     - Exception to this rule is if you have only a single case, then that
//       single case can be written using no indentation
//
//       This single case can be seen as a clarification of the input to the
//       template
//
//   - Code after a case should be indented with 2 spaces if not written on the
//     same line

package CodegenUtil

import ExpressionDumpTpl.*;
import interface SimCodeTV;

/* public */ template symbolName(String modelNamePrefix, String symbolName)
  "Creates a unique name for the function"
::=
  modelNamePrefix + "_" + symbolName
end symbolName;

template replaceDotAndUnderscore(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case name then
    let str_dots = System.stringReplace(name,".", "_")
    let str_underscores = System.stringReplace(str_dots, "_", "__")
    System.unquoteIdentifier(str_underscores)
end replaceDotAndUnderscore;

template getGeneralTarget(String str)
 "Replace _ with __ and dot in identifiers with _"
::=
  match str
  case "msvc10"
  case "msvc12"
  case "msvc13"
  case "msvc15"
  then "msvc"
  else str
end getGeneralTarget;

template underscorePath(Path path)
 "Generate paths with components separated by underscores.
  Replaces also the . in identifiers with _.
  The dot might happen for world.gravityAccleration"
::=
  match path
  case QUALIFIED(__) then
    '<%replaceDotAndUnderscore(name)%>_<%underscorePath(path)%>'
  case IDENT(__) then
    replaceDotAndUnderscore(name)
  case FULLYQUALIFIED(__) then
    underscorePath(path)
end underscorePath;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array. Uses underscores for qualified names.
 a._b not a.b"
::=
  match cr
  case CREF_IDENT(__) then '<%System.unquoteIdentifier(ident)%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
  case CREF_QUAL(ident = "$CLKPRE") then 'previous(<%crefStr(componentRef)%>)'
  case CREF_QUAL(__) then '<%System.unquoteIdentifier(ident)%><%subscriptsStr(subscriptLst)%>._<%crefStr(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStr;

template crefStrNoUnderscore(ComponentRef cr)
 "Generates the name of a variable for variable name array. However does not use underscores on qualified names.
 a.b not a._b. Used for generating variable names that are exported e.g. xml files"
::=
  match cr
  case CREF_IDENT(__) then '<%ident%><%subscriptsStr(subscriptLst)%>'
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStrNoUnderscore(componentRef)%>)'
  case CREF_QUAL(ident = "$CLKPRE") then 'previous(<%crefStrNoUnderscore(componentRef)%>)'
  case CREF_QUAL(__) then '<%ident%><%subscriptsStr(subscriptLst)%>.<%crefStrNoUnderscore(componentRef)%>'
  else "CREF_NOT_IDENT_OR_QUAL"
end crefStrNoUnderscore;

template subscriptsStr(list<Subscript> subscripts)
 "Generares subscript part of the name."
::=
  if subscripts then
    '[<%subscripts |> s => subscriptStr(s) ;separator=","%>]'
end subscriptsStr;

template subscriptStr(Subscript subscript)
 "Generates a single subscript.
  Only works for constant integer and cref indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case INDEX(exp=ENUM_LITERAL(name=n)) then dotPath(n)
  case INDEX(exp=CREF()) then printExpStr(exp)
  case SLICE(exp=ICONST(integer=i)) then i
  case INDEX(__)
  case SLICE(__) then 'UNKNOWN_SUBSCRIPT /* <%escapeCComments(printExpStr(exp))%> */'
  case WHOLEDIM(__) then "WHOLEDIM"
  case WHOLE_NONEXP(__) then "WHOLE_NONEXP"
  else "UNKNOWN_SUBSCRIPT"
end subscriptStr;


/*********************** Comments ************************/

template escapeCComments(String stringWithCComments)
"escape the C comments inside a string, replaces them with /* */->(* *)"
::= '<%System.stringReplace(System.stringReplace(stringWithCComments, "/*", "(*"), "*/", "*)")%>'
end escapeCComments;

/*********************************************************/







template initDefaultValXml(DAE.Type type_)
::=
  match type_
  case T_INTEGER(__) then '0'
  case T_REAL(__) then '0.0'
  case T_BOOL(__) then 'false'
  case T_STRING(__) then ''
  case T_ENUMERATION(__) then '0'
  else error(sourceInfo(), 'initial value of unknown type: <%unparseType(type_)%>')
end initDefaultValXml;

template initValXml(Exp exp)
::=
  match exp
  case ICONST(__) then integer
  case RCONST(__) then real
  case SCONST(__) then '<%Util.escapeModelicaStringToXmlString(string)%>'
  case BCONST(__) then if bool then "true" else "false"
  case ENUM_LITERAL(__) then '<%index%>'
  else error(sourceInfo(), 'initial value of unknown type: <%dumpExp(exp,"\"")%>')
end initValXml;

/*********************************************************************
 *********************************************************************
 *                       Common XML Functions
 *********************************************************************
 *********************************************************************/

template getVariablity(VarKind varKind)
 "Returns the variablity Attribute of ScalarVariable."
::=
  match varKind
    case DISCRETE(__) then "discrete"
    case PARAM(__) then "parameter"
    case CONST(__) then "constant"
    else "continuous"
end getVariablity;

template variabilityString(VarKind varKind)
::=
  match varKind
    case VARIABLE() then "variable"
    case STATE(derName=NONE()) then 'STATE(<%index%>)'
    case STATE(derName=SOME(dcr)) then 'STATE(<%index%>,<%crefStrNoUnderscore(dcr)%>)'
    case STATE_DER()   then "STATE_DER"
    case DUMMY_DER()   then "DUMMY_DER"
    case DUMMY_STATE() then "DUMMY_STATE"
    case CLOCKED_STATE()  then "CLOCKED_STATE"
    case DISCRETE()    then "DISCRETE"
    case PARAM()       then "PARAM"
    case CONST()       then "CONST"
    case EXTOBJ()  then 'EXTOBJ: <%dotPath(fullClassName)%>'
    case JAC_VAR()     then "JACOBIAN_VAR"
    case JAC_DIFF_VAR()then "JACOBIAN_DIFF_VAR"
    case SEED_VAR()    then "SEED_VAR"
    case OPT_CONSTR()  then "OPT_CONSTR"
    case OPT_FCONSTR()  then "OPT_FCONSTR"
    case OPT_INPUT_WITH_DER()  then "OPT_INPUT_WITH_DER"
    case OPT_INPUT_DER()  then "OPT_INPUT_DER"
    case OPT_TGRID()  then "OPT_TGRID"
    case OPT_LOOP_INPUT()  then "OPT_LOOP_INPUT"
    case ALG_STATE()  then "ALG_STATE"
    case DAE_RESIDUAL_VAR() then "DAE_RESIDUAL_VAR"
    case DAE_AUX_VAR() then "DAE_AUX_VAR"
    case LOOP_ITERATION() then "LOOP_ITERATION"
    case LOOP_SOLVED() then "LOOP_SOLVED"
    else "#UNKNOWN_VARKIND"
  end match
end variabilityString;

template getAliasVar(AliasVariable aliasvar)
 "Returns the alias Attribute of ScalarVariable."
::=
  match aliasvar
    case NOALIAS(__) then '"noAlias"'
    case ALIAS(__) then '"alias" aliasVariable="<%crefStrNoUnderscore(varName)%>"'
    case NEGATEDALIAS(__) then '"negatedAlias" aliasVariable="<%crefStrNoUnderscore(varName)%>"'
    else '"noAlias"'
end getAliasVar;

template ScalarVariableType(String unit, String displayUnit, Option<DAE.Exp> minValue, Option<DAE.Exp> maxValue, Option<DAE.Exp> startValue, Option<DAE.Exp> nominalValue, Boolean isFixed, DAE.Type type_)
 "Generates code for ScalarVariable Type file for FMU target."
::=
  match type_
    case T_INTEGER(__) then '<Integer<%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeIntegerMinAttribute(minValue)%><%ScalarVariableTypeIntegerMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_REAL(__) then '<Real<%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeNominalAttribute(nominalValue)%><%ScalarVariableTypeRealMinAttribute(minValue)%><%ScalarVariableTypeRealMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_BOOL(__) then '<Boolean<%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_STRING(__) then '<String<%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_ENUMERATION(__) then '<Integer<%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_COMPLEX(complexClassType = ci as ClassInf.EXTERNAL_OBJ(__)) then '<ExternalObject path="<%escapeModelicaStringToXmlString(dotPath(ci.path))%>" />'
    else error(sourceInfo(), 'ScalarVariableType: <%unparseType(type_)%>')
end ScalarVariableType;

template StartString(DAE.Exp exp)
::=
  match exp
    case ICONST(__) then ' start="<%initValXml(exp)%>"'
    case RCONST(__) then ' start="<%initValXml(exp)%>"'
    case SCONST(__) then ' start="<%initValXml(exp)%>"'
    case BCONST(__) then ' start="<%initValXml(exp)%>"'
    case ENUM_LITERAL(__) then ' start="<%initValXml(exp)%>"'
    else ''
end StartString;

template ScalarVariableTypeStartAttribute(Option<DAE.Exp> startValue, DAE.Type type_)
 "generates code for start attribute"
::=
  match startValue
    case SOME(exp) then '<%StartString(exp)%>'
    else ''
end ScalarVariableTypeStartAttribute;

template ScalarVariableTypeFixedAttribute(Boolean isFixed)
 "generates code for fixed attribute"
::=
  ' fixed="<%isFixed%>"'
end ScalarVariableTypeFixedAttribute;

template NominalString(DAE.Exp exp)
::=
  match exp
    case ICONST(__) then ' nominal="<%initValXml(exp)%>"'
    case RCONST(__) then ' nominal="<%initValXml(exp)%>"'
    case SCONST(__) then ' nominal="<%initValXml(exp)%>"'
    case BCONST(__) then ' nominal="<%initValXml(exp)%>"'
    else ''
end NominalString;

template ScalarVariableTypeNominalAttribute(Option<DAE.Exp> nominalValue)
 "generates code for nominal attribute"
::=
  match nominalValue
    case SOME(exp)
    then ' useNominal="true"<%NominalString(exp)%>'
    case NONE() then ' useNominal="false"'
end ScalarVariableTypeNominalAttribute;

template ScalarVariableTypeUnitAttribute(String unit)
 "generates code for unit attribute"
::=
  '<% if unit then ' unit="<%unit%>"' %>'
end ScalarVariableTypeUnitAttribute;

template ScalarVariableTypeDisplayUnitAttribute(String displayUnit)
 "generates code for displayUnit attribute"
::=
  '<% if displayUnit then ' displayUnit="<%displayUnit%>"' %>'
end ScalarVariableTypeDisplayUnitAttribute;

template MinString(DAE.Exp exp)
::=
  match exp
    case ICONST(__) then ' min="<%initValXml(exp)%>"'
    case RCONST(__) then ' min="<%initValXml(exp)%>"'
    case SCONST(__) then ' min="<%initValXml(exp)%>"'
    case BCONST(__) then ' min="<%initValXml(exp)%>"'
    case ENUM_LITERAL(__) then ' min="<%initValXml(exp)%>"'
    else ''
end MinString;

template ScalarVariableTypeIntegerMinAttribute(Option<DAE.Exp> minValue)
 "generates code for min attribute"
::=
  match minValue
    case SOME(exp) then '<%MinString(exp)%>'
    // case NONE() then ' min="-2147483648"'
end ScalarVariableTypeIntegerMinAttribute;

template MaxString(DAE.Exp exp)
::=
  match exp
    case ICONST(__) then ' max="<%initValXml(exp)%>"'
    case RCONST(__) then ' max="<%initValXml(exp)%>"'
    case SCONST(__) then ' max="<%initValXml(exp)%>"'
    case BCONST(__) then ' max="<%initValXml(exp)%>"'
    case ENUM_LITERAL(__) then ' max="<%initValXml(exp)%>"'
    else ''
end MaxString;

template ScalarVariableTypeIntegerMaxAttribute(Option<DAE.Exp> maxValue)
 "generates code for max attribute"
::=
  match maxValue
    case SOME(exp) then '<%MaxString(exp)%>'
    // case NONE() then ' max="2147483647"'
end ScalarVariableTypeIntegerMaxAttribute;

template ScalarVariableTypeRealMinAttribute(Option<DAE.Exp> minValue)
 "generates code for min attribute"
::=
  match minValue
    case SOME(exp) then '<%MinString(exp)%>'
    // case NONE() then ' min="-1.7976931348623157E+308"'
end ScalarVariableTypeRealMinAttribute;

template ScalarVariableTypeRealMaxAttribute(Option<DAE.Exp> maxValue)
 "generates code for max attribute"
::=
  match maxValue
    case SOME(exp) then '<%MaxString(exp)%>'
    // case NONE() then ' max="1.7976931348623157E+308"'
end ScalarVariableTypeRealMaxAttribute;


/*********************************************************************
 *********************************************************************
 *                       Paths
 *********************************************************************
 *********************************************************************/

template dotPath(Path path)
 "Generates paths with components separated by dots."
::=
  match path
  case QUALIFIED(__)      then '<%name%>.<%dotPath(path)%>'
  case IDENT(__)          then name
  case FULLYQUALIFIED(__) then dotPath(path)
end dotPath;


/*********************************************************************
 *********************************************************************
 *                       Error
 *********************************************************************
 *********************************************************************/

template error(SourceInfo srcInfo, String errMessage)
"Example source template error reporting template to be used together with the sourceInfo() magic function.
Usage: error(sourceInfo(), <<message>>) "
::=
let() = Tpl.addSourceTemplateError(errMessage, srcInfo)
<<

#error "<% Error.infoStr(srcInfo) %> <% errMessage %>"<%\n%>
>>
end error;

//for completeness; although the error() template above is preferable
template errorMsg(String errMessage)
"Example template error reporting template
 that is reporting only the error message without the usage of source infotmation."
::=
let() = Tpl.addTemplateError(errMessage)
<<

#error "<% errMessage %>"<%\n%>
>>
end errorMsg;

annotation(__OpenModelica_Interface="backend");
end CodegenUtil;

// vim: filetype=susan sw=2 sts=2
