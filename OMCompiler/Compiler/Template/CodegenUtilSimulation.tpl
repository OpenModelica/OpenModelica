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

package CodegenUtilSimulation

import interface SimCodeTV;
import ExpressionDumpTpl.*;
import CodegenUtil.*;

template modelNamePrefix(SimCode simCode)
::=
  match simCode
  case simCode as SIMCODE(__) then makeC89Identifier(fileNamePrefix)
end modelNamePrefix;

template fileNamePrefix(SimCode simCode)
::=
  match simCode
  case simCode as SIMCODE(__) then fileNamePrefix
end fileNamePrefix;

template fullPathPrefix(SimCode simCode)
::=
  match simCode
  case simCode as SIMCODE(__) then fullPathPrefix
end fullPathPrefix;

/********* Equation Dumps *****************************/

template equationIndex(SimEqSystem eq)
 "Generates an equation."
::=
  match eq
  case SES_RESIDUAL(__)
  case SES_SIMPLE_ASSIGN(__)
  case SES_SIMPLE_ASSIGN_CONSTRAINTS(__)
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
  case SES_ALIAS(__)
    then aliasOf
  case SES_ALGEBRAIC_SYSTEM(__)
    then index
  else error(sourceInfo(), "equationIndex failed")
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
      <%escapeCComments(dumpExp(e.exp,"\""))%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      equation index: <%equationIndex(eq)%>
      type: SIMPLE_ASSIGN
      <%crefStr(e.cref)%> = <%escapeCComments(dumpExp(e.exp,"\""))%>
      >>
    case e as SES_SIMPLE_ASSIGN_CONSTRAINTS(__) then
      <<
      equation index: <%equationIndex(eq)%>
      type: SIMPLE_ASSIGN_CONSTRAINTS
      <%crefStr(e.cref)%> = <%escapeCComments(dumpExp(e.exp,"\""))%>
      constraints: <%escapeCComments(dumpConstraints(e.cons))%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(lhs=lhs as CREF(__)) then
      <<
      equation index: <%equationIndex(eq)%>
      type: ARRAY_CALL_ASSIGN

      <%crefStr(lhs.componentRef)%> = <%escapeCComments(dumpExp(e.exp,"\""))%>
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
        <%ls.beqs |> exp => '<cell><%escapeCComments(dumpExp(exp,"\""))%></cell>' ; separator = "\n" %><%\n%>
      </row>
      <matrix>
        <%ls.simJac |> (i1,i2,eq) =>
        <<
        <cell row="<%i1%>" col="<%i2%>">
          <%match eq case e as SES_RESIDUAL(__) then
            <<
            <residual><%escapeCComments(dumpExp(e.exp,"\""))%></residual>
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
    case e as SES_ALGEBRAIC_SYSTEM(residual=residual as OMSI_FUNCTION(__)) then
      let detailedDescription = dumpAlgSystemOps(matrix)
      <<
      equation index: <%equationIndex(eq)%>
      type: ALGEBRAIC_SYSTEM
      is linear: <%e.linearSystem%>
      depending functions indices: <%residual.equations |> eq => '<%equationIndex(eq)%>' ; separator = ", "%>
      dimension: <%listLength(residual.equations)%>
      <%detailedDescription%>
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
      let &forstatement += 'for ' + escapeCComments(dumpExp(e.iter,"\"")) + ' in ' + escapeCComments(dumpExp(e.startIt,"\""))
      let &forstatement += ' : ' + escapeCComments(dumpExp(e.endIt,"\"")) + ' loop<%\n%>'
      let &forstatement += '  <%crefStr(e.cref)%> = <%escapeCComments(dumpExp(e.exp,"\""))%>; '
      let &forstatement += 'end for'
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


template dumpAlgSystemOps (Option<DerivativeMatrix> derivativeMatrix)
"dumps description of eqations of algebraic system.
 Helper function for dumpEqs."
::=
  let &varsBuffer = buffer ""
  let &columnBuffer = buffer ""

  match derivativeMatrix
  case SOME(matrix as DERIVATIVE_MATRIX(__)) then
    let _ = (matrix.columns |> column =>
      dumpAlgSystemColumn(column, &columnBuffer, &varsBuffer)
    )

  <<
  iteration vars: <%varsBuffer%>

  <%columnBuffer%>
  >>
end dumpAlgSystemOps;

template dumpAlgSystemColumn (OMSIFunction column ,Text &columnBuffer, Text &varsBuffer)
"dumps equation description for one OMSIFunction"
::=

  match column
  case OMSI_FUNCTION(__) then
    let &varsBuffer += (inputVars |> var as SIMVAR(__) =>
        <<
        <%crefStr(name)%>
        >>
        ; separator=", "
    )

    let _ = (equations |> equation as SES_SIMPLE_ASSIGN(__) =>
        let &columnBuffer += crefStr(equation.cref) + " = " + escapeCComments(dumpExp(equation.exp,"\"")) + "\n"        // "
        <<>>
    )
    <<>>
end dumpAlgSystemColumn;


template dumpWhenOps(list<BackendDAE.WhenOperator> whenOps)
::=
  match whenOps
  case ({}) then <<>>
  case ((e as BackendDAE.ASSIGN(left=left as CREF(__)))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <%crefStr(left.componentRef)%> = <%escapeCComments(dumpExp(e.right,"\""))%>;
    <%restbody%>
    >>
  case ((e as BackendDAE.ASSIGN(left=left))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    <%dumpExp(e.left,"\"")%> = <%escapeCComments(dumpExp(e.right,"\""))%>;
    <%restbody%>
    >>
  case ((e as BackendDAE.REINIT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    reinit(<%crefStr(e.stateVar)%>,  <%escapeCComments(dumpExp(e.value,"\""))%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.ASSERT(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    assert(<%escapeCComments(dumpExp(e.condition,"\""))%>, <%escapeCComments(dumpExp(e.message,"\""))%>, <%escapeCComments(dumpExp(e.level,"\""))%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.TERMINATE(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    terminate(<%escapeCComments(dumpExp(e.message,"\""))%>)%>);
    <%restbody%>
    >>
  case ((e as BackendDAE.NORETCALL(__))::rest) then
    let restbody = dumpWhenOps(rest)
    <<
    noReturnCall(<%escapeCComments(dumpExp(e.exp,"\""))%>)%>);
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
        <%at.beqs |> exp => '<cell><%escapeCComments(dumpExp(exp,"\""))%></cell>' ; separator = "\n" %><%\n%>
      </row>
      <matrix>
        <%at.simJac |> (i1,i2,eq) =>
        <<
        <cell row="<%i1%>" col="<%i2%>">
          <%match eq case e as SES_RESIDUAL(__) then
            <<
            <residual><%escapeCComments(dumpExp(e.exp,"\""))%></residual>
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

annotation(__OpenModelica_Interface="backend");
end CodegenUtilSimulation;

// vim: filetype=susan sw=2 sts=2
