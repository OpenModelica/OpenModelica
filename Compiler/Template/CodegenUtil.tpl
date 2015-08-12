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

template modelNamePrefix(SimCode simCode)
::=
  match simCode
  case simCode as SIMCODE(__) then
    System.stringReplace(fileNamePrefix,".", "_")
  // underscorePath(mi.name)
  // case simCode as SIMCODE(modelInfo=mi as MODELINFO(__)) then
  // underscorePath(mi.name)
end modelNamePrefix;

template crefStr(ComponentRef cr)
 "Generates the name of a variable for variable name array. Uses underscores for qualified names.
 a._b not a.b"
::=
  match cr
  case CREF_IDENT(__) then '<%System.unquoteIdentifier(ident)%><%subscriptsStr(subscriptLst)%>'
  // Are these even needed? Function context should only have CREF_IDENT :)
  case CREF_QUAL(ident = "$DER") then 'der(<%crefStr(componentRef)%>)'
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
  Only works for constant integer indicies."

::=
  match subscript
  case INDEX(exp=ICONST(integer=i)) then i
  case INDEX(exp=ENUM_LITERAL(name=n)) then dotPath(n)
  case SLICE(exp=ICONST(integer=i)) then i
  case WHOLEDIM(__) then "WHOLEDIM"
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
  else error(sourceInfo(), 'initial value of unknown type: <%printExpStr(exp)%>')
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
    case T_INTEGER(__) then '<Integer <%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeIntegerMinAttribute(minValue)%><%ScalarVariableTypeIntegerMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_REAL(__) then '<Real <%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeNominalAttribute(nominalValue)%><%ScalarVariableTypeRealMinAttribute(minValue)%><%ScalarVariableTypeRealMaxAttribute(maxValue)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_BOOL(__) then '<Boolean <%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_STRING(__) then '<String <%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
    case T_ENUMERATION(__) then '<Integer <%ScalarVariableTypeStartAttribute(startValue, type_)%><%ScalarVariableTypeFixedAttribute(isFixed)%><%ScalarVariableTypeUnitAttribute(unit)%><%ScalarVariableTypeDisplayUnitAttribute(displayUnit)%> />'
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
    case SOME(exp) then 'useStart="true"<%StartString(exp)%>'
    case NONE() then 'useStart="false"'
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



/********* Equation Dumps *****************************/

template equationIndex(SimEqSystem eq)
 "Generates an equation."
::=
  match eq
  case SES_RESIDUAL(__)
  case SES_SIMPLE_ASSIGN(__)
  case SES_ARRAY_CALL_ASSIGN(__)
  case SES_IFEQUATION(__)
  case SES_ALGORITHM(__)
    then index
  case SES_INVERSE_ALGORITHM(__)
    then index
  case SES_LINEAR(lSystem=ls as LINEARSYSTEM(__))
    then ls.index
  case SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__))
    then nls.index
  case SES_MIXED(__)
  case SES_WHEN(__)
  case SES_FOR_LOOP(__)
    then index
end equationIndex;

template equationIndexAlternativeTearing(SimEqSystem eq)
 "Generates an equation."
::=
  match eq
  case SES_LINEAR(alternativeTearing=SOME(at as LINEARSYSTEM(__)))
    then at.index
  case SES_NONLINEAR(alternativeTearing=SOME(at as NONLINEARSYSTEM(__)))
    then at.index
end equationIndexAlternativeTearing;

template dumpEqs(list<SimEqSystem> eqs)
::= eqs |> eq hasindex i0 =>
  match eq
    case e as SES_RESIDUAL(__) then
      <<
      equation index: <%equationIndex(eq)%>
      type: RESIDUAL

      <%escapeCComments(printExpStr(e.exp))%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      equation index: <%equationIndex(eq)%>
      type: SIMPLE_ASSIGN
      <%crefStr(e.cref)%> = <%escapeCComments(printExpStr(e.exp))%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(lhs=lhs as CREF(__)) then
      <<
      equation index: <%equationIndex(eq)%>
      type: ARRAY_CALL_ASSIGN

      <%crefStr(lhs.componentRef)%> = <%escapeCComments(printExpStr(e.exp))%>
      >>
    case e as SES_ALGORITHM(statements={}) then
      <<
      empty algorithm
      >>
    case e as SES_ALGORITHM(statements=first::_) then
      <<
      equation index: <%equationIndex(eq)%>
      type: ALGORITHM

      <%e.statements |> stmt => escapeCComments(ppStmtStr(stmt,2))%>
      >>
    case e as SES_INVERSE_ALGORITHM(statements=first::_) then
      <<
      equation index: <%equationIndex(eq)%>
      type: INVERSE ALGORITHM

      <%e.statements |> stmt => escapeCComments(ppStmtStr(stmt,2))%>
      >>
    case e as SES_LINEAR(lSystem=ls as LINEARSYSTEM(__)) then
      <<
      equation index: <%equationIndex(eq)%>
      type: LINEAR

      <%ls.vars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
      <row>
        <%ls.beqs |> exp => '<cell><%escapeCComments(printExpStr(exp))%></cell>' ; separator = "\n" %><%\n%>
      </row>
      <matrix>
        <%ls.simJac |> (i1,i2,eq) =>
        <<
        <cell row="<%i1%>" col="<%i2%>">
          <%match eq case e as SES_RESIDUAL(__) then
            <<
            <residual><%escapeCComments(printExpStr(e.exp))%></residual>
            >>
           %>
        </cell>
        >>
        %>
      </matrix>
      >>
    case e as SES_NONLINEAR(nlSystem=nls as NONLINEARSYSTEM(__)) then
      <<
      equation index: <%equationIndex(eq)%>
      indexNonlinear: <%nls.indexNonLinearSystem%>
      type: NONLINEAR

      vars: {<%nls.crefs |> cr => '<%crefStr(cr)%>' ; separator = ", "%>}
      eqns: {<%nls.eqs |> eq => '<%equationIndex(eq)%>' ; separator = ", "%>}
      >>
    case e as SES_MIXED(__) then
      <<
      equation index: <%equationIndex(eq)%>
      type: MIXED

      <%dumpEqs(fill(e.cont,1))%>
      <%dumpEqs(e.discEqs)%><%\n%>

      <mixed>
        <continuous index="<%equationIndex(e.cont)%>" />
        <%e.discVars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = ","%>
        <%e.discEqs |> eq => '<discrete index="<%equationIndex(eq)%>" />'%>
      </mixed>
      >>
    case e as SES_WHEN(__) then
      let body = dumpWhenOps(whenStmtLst)
      <<
      equation index: <%equationIndex(eq)%>
      type: WHEN

      when {<%conditions |> cond => '<%crefStr(cond)%>' ; separator=", " %>} then
        <%body%>
      end when;
      >>
    case e as SES_IFEQUATION(__) then
      let branches = ifbranches |> (_,eqs) => dumpEqs(eqs)
      let elsebr = dumpEqs(elsebranch)
      <<
      equation index: <%equationIndex(eq)%>
      type: IFEQUATION

      <%branches%>
      <%elsebr%>
      >>
    case e as SES_FOR_LOOP(__) then
      let &forstatement = buffer ""
      let &forstatement += 'for(size_t ' + escapeCComments(printExpStr(e.iter)) + ' = ' + escapeCComments(printExpStr(e.startIt)) + '; '
      let &forstatement += escapeCComments(printExpStr(e.iter)) + ' != ' + escapeCComments(printExpStr(e.endIt)) + '+1; '
      let &forstatement += escapeCComments(printExpStr(e.iter)) + '++) {<%\n%>'
      let &forstatement += '  <%crefStr(e.cref)%> = <%escapeCComments(printExpStr(e.exp))%><%\n%>'
      let &forstatement += '}'
      <<
      equation index: <%equationIndex(e)%>
      type: FOR_LOOP
      <%forstatement%>
      >>
    else
      <<
      unknown equation
      >>
end dumpEqs;

template dumpWhenOps(list<BackendDAE.WhenOperator> whenOps)
::=
  match whenOps
  case ({}) then <<>>
  case ((e as BackendDAE.ASSIGN(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <%crefStr(e.left)%> = <%escapeCComments(printExpStr(e.right))%>;
    <%restbody%>
    >>
  case ((e as BackendDAE.REINIT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    reinit(<%crefStr(e.stateVar)%>,  <%escapeCComments(printExpStr(e.value))%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.ASSERT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    assert(<%escapeCComments(printExpStr(e.condition))%>, <%escapeCComments(printExpStr(e.message))%>, <%escapeCComments(printExpStr(e.level))%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.TERMINATE(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    terminate(<%escapeCComments(printExpStr(e.message))%>)%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.NORETCALL(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    noReturnCall(<%escapeCComments(printExpStr(e.exp))%>)%>);
    <%restbody%>
    >>
  else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpWhenOps;

template dumpEqsAlternativeTearing(list<SimEqSystem> eqs)
::= eqs |> eq hasindex i0 =>
  match eq
    case e as SES_LINEAR(alternativeTearing=SOME(at as LINEARSYSTEM(__))) then
      <<
      equation index: <%equationIndexAlternativeTearing(eq)%>
      type: LINEAR

      <%at.vars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
      <row>
        <%at.beqs |> exp => '<cell><%escapeCComments(printExpStr(exp))%></cell>' ; separator = "\n" %><%\n%>
      </row>
      <matrix>
        <%at.simJac |> (i1,i2,eq) =>
        <<
        <cell row="<%i1%>" col="<%i2%>">
          <%match eq case e as SES_RESIDUAL(__) then
            <<
            <residual><%escapeCComments(printExpStr(e.exp))%></residual>
            >>
           %>
        </cell>
        >>
        %>
      </matrix>

      This is the alternative tearing set with casual solvability rules.
      If it fails, this function will call the strict tearing set.
      >>
    case e as SES_NONLINEAR(alternativeTearing=SOME(at as NONLINEARSYSTEM(__))) then
      <<
      equation index: <%equationIndexAlternativeTearing(eq)%>
      indexNonlinear: <%at.indexNonLinearSystem%>
      type: NONLINEAR

      vars: {<%at.crefs |> cr => '<%crefStr(cr)%>' ; separator = ", "%>}
      eqns: {<%at.eqs |> eq => '<%equationIndex(eq)%>' ; separator = ", "%>}

      This is the alternative tearing set with casual solvability rules.
      If it fails, this function will call the strict tearing set.
      >>
    else
      <<
      unknown equation
      >>
end dumpEqsAlternativeTearing;


/************************************************************************************************/



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
