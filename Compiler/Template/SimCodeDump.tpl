package SimCodeDump

import interface SimCodeTV;
import CodegenUtil.*;

template dumpSimCode(SimCode code, Boolean withOperations)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let name = dotPath(mi.name)
  let res = <<
  <?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="application/xml" href="simcodedump.xsl"?>
  <simcodedump model="<%name%>">
  <variables>
    <%dumpVars(vars.stateVars,withOperations)%>
    <%dumpVars(vars.derivativeVars,withOperations)%>
    <%dumpVars(vars.algVars,withOperations)%>
    <%dumpVars(vars.intAlgVars,withOperations)%>
    <%dumpVars(vars.boolAlgVars,withOperations)%>
    <%dumpVars(vars.inputVars,withOperations)%>
    <%dumpVars(vars.outputVars,withOperations)%>
    <%dumpVars(vars.aliasVars,withOperations)%>
    <%dumpVars(vars.intAliasVars,withOperations)%>
    <%dumpVars(vars.boolAliasVars,withOperations)%>
    <%dumpVars(vars.paramVars,withOperations)%>
    <%dumpVars(vars.intParamVars,withOperations)%>
    <%dumpVars(vars.boolParamVars,withOperations)%>
    <%dumpVars(vars.stringAlgVars,withOperations)%>
    <%dumpVars(vars.stringParamVars,withOperations)%>
    <%dumpVars(vars.stringAliasVars,withOperations)%>
    <%dumpVars(vars.extObjVars,withOperations)%>
    <%dumpVars(vars.constVars,withOperations)%>
  </variables>
  <equations>
    <%dumpEqs(SimCodeUtil.sortEqSystems(
  listAppend(collectAllJacobianEquations(jacobianMatrixes),
  listAppend(residualEquations,
  listAppend(inlineEquations,
  listAppend(startValueEquations,
  listAppend(parameterEquations,
  listAppend(initialEquations,
  listAppend(algorithmAndEquationAsserts,
  allEquations)))))))),withOperations)%>
  </equations>
  <literals>
    <% literals |> exp => '<exp><%printExpStrEscaped(exp)%></exp>' ; separator="\n" %>
  </literals>
  <functions>
    <% mi.functions |> func => match func
      case FUNCTION(__)
      case EXTERNAL_FUNCTION(__)
      case KERNEL_FUNCTION(__)
      case PARALLEL_FUNCTION(__)
      case RECORD_CONSTRUCTOR(__) then
      '<function name="<%dotPath(name)%>"><%dumpInfo(info)%></function>' ; separator="\n"
    %>
  </functions>
  </simcodedump><%\n%>
  >>
  let() = textFile(res,'<%fileNamePrefix%>_info.xml')
  '<%fileNamePrefix%>_info'
end dumpSimCode;

template dumpVarsShort(list<SimVar> vars)
::=
  let varsString = (vars |> v as SIMVAR(__) hasindex index0 =>
  <<
  <%index0%>: <%crefStr(v.name)%>
  >>
  ;separator="\n";empty)
  <<
  <%varsString%>

  >>
end dumpVarsShort;


template dumpVars(list<SimVar> vars, Boolean withOperations)
::=
  vars |> v as SIMVAR(__) =>
  <<
  <variable name="<%crefStr(v.name)%>" comment="<%escapeModelicaStringToXmlString(v.comment)%>">
    <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source,withOperations)%>
  </variable><%\n%>
  >>
end dumpVars;

template dumpAlias(AliasVariable alias)
::=
  match alias
  case ALIAS(__) then '<alias><%crefStr(varName)%></alias>'
  case NEGATEDALIAS(__) then ' <alias negated="true"><%crefStr(varName)%></alias>'
end dumpAlias;

template eqIndex(SimEqSystem eq)
::=
match eq
    case SES_RESIDUAL(__)
    case SES_SIMPLE_ASSIGN(__)
    case SES_ARRAY_CALL_ASSIGN(__)
    case SES_ALGORITHM(__)
    case SES_LINEAR(__)
    case SES_NONLINEAR(__)
    case SES_MIXED(__)
    case SES_WHEN(__)
    case SES_IFEQUATION(__) then index
    else error(sourceInfo(), "dumpEqs: Unknown equation")
end eqIndex;

template dumpEqs(list<SimEqSystem> eqs, Boolean withOperations)
::= eqs |> eq hasindex i0 =>
  match eq
    case e as SES_RESIDUAL(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <residual><%printExpStrEscaped(e.exp)%></residual>
  <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <assign>
    <lhs><%crefStr(e.cref)%></lhs>
    <rhs><%printExpStrEscaped(e.exp)%></rhs>
  </assign>
  <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <assign type="array">
    <lhs><%crefStr(e.componentRef)%></lhs>
    <rhs><%printExpStrEscaped(e.exp)%></rhs>
  </assign>
  <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(statements=first::_)
      then
      <<
      <equation index="<%eqIndex(eq)%>">
  <statement>
    <%e.statements |> stmt => escapeModelicaStringToXmlString(ppStmtStr(stmt,2)) %>
  </statement>
  <%dumpElementSource(getStatementSource(first),withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_LINEAR(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <linear>
    <%e.vars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
    <row>
      <%beqs |> exp => '<cell><%printExpStrEscaped(exp)%></cell>' ; separator = "\n" %><%\n%>
    </row>
    <matrix>
      <%simJac |> (i1,i2,eq) =>
      <<
      <cell row="<%i1%>" col="<%i2%>">
        <%match eq case e as SES_RESIDUAL(__) then
          <<
          <residual><%printExpStrEscaped(e.exp)%></residual>
          <%dumpElementSource(e.source,withOperations)%>
          >>
         %>
      </cell>
      >>
      %>
    </matrix>
  </linear>
      </equation><%\n%>
      >>
    case e as SES_NONLINEAR(__) then
      <<
      <%dumpEqs(SimCodeUtil.sortEqSystems(e.eqs),withOperations)%>
      <equation index="<%eqIndex(eq)%>">
  <nonlinear indexNonlinear="<%indexNonLinearSystem%>">
    <%e.crefs |> cr => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
    <%e.eqs |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n" %>
  </nonlinear>
      </equation><%\n%>
      >>
    case e as SES_MIXED(__) then
      <<
      <%dumpEqs(fill(e.cont,1),withOperations)%>
      <%dumpEqs(e.discEqs,withOperations)%><%\n%>
      <equation index="<%eqIndex(eq)%>">
  <mixed>
    <continuous index="<%eqIndex(e.cont)%>" />
    <%e.discVars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = ","%>
    <%e.discEqs |> eq => '<discrete index="<%eqIndex(eq)%>" />'%>
  </mixed>
      </equation>
      >>
    case e as SES_WHEN(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
      <when>
  <%conditions |> cond => '<cond><%crefStr(cond)%></cond>' ; separator="\n" %>
  <lhs><%crefStr(e.left)%></lhs>
  <rhs><%printExpStrEscaped(e.right)%></rhs>
      </when>
      <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    case e as SES_IFEQUATION(__) then
      let branches = ifbranches |> (_,eqs) => dumpEqs(eqs,withOperations)
      let elsebr = dumpEqs(elsebranch,withOperations)
      <<
      <%branches%>
      <%elsebr%>
      <equation index="<%eqIndex(eq)%>">
      <ifequation /> <!-- TODO: Fix me -->
      <%dumpElementSource(e.source,withOperations)%>
      </equation><%\n%>
      >>
    else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpEqs;

template dumpWithin(Within w)
::=
  match w
    case TOP(__) then "within ;"
    case WITHIN(__) then 'within <%dotPath(path)%>;'
end dumpWithin;

template dumpElementSource(ElementSource source, Boolean withOperations)
::=
  match source
    case s as SOURCE(info=info as INFO(__)) then
      <<
      <source>
  <%dumpInfo(info)%>
  <%s.partOfLst |> w => '<part-of><%dumpWithin(w)%></part-of>' %>
  <%s.instanceOptLst |> SOME(cr) => '<instance><%crefStr(cr)%></instance>' %>
  <%s.connectEquationOptLst |> p => "<connect-equation />"%>
  <%s.typeLst |> p => '<type><%dotPath(p)%></type>' ; separator = "\n" %>
      </source>
      <% if withOperations then <<
      <operations>
  <%s.operations |> op => dumpOperation(op,s.info) ; separator="\n" %>
      </operations>
      >> %>
      >>
end dumpElementSource;

template dumpOperation(SymbolicOperation op, Info info)
::=
  match op
    case SIMPLIFY(__) then
      <<
      <simplify>
  <before><%printEquationExpStrEscaped(before)%></before>
  <after><%printEquationExpStrEscaped(after)%></after>
      </simplify>
      >>
    case SUBSTITUTION(__) then
      <<
      <substitution>
  <before><%printExpStrEscaped(source)%></before>
  <%listReverse(substitutions) |> target => '<exp><%printExpStrEscaped(target)%></exp>' ; separator="\n" %>
      </substitution>
      >>
    case op as OP_INLINE(__) then
      <<
      <inline>
  <before><%printEquationExpStrEscaped(op.before)%></before>
  <after><%printEquationExpStrEscaped(op.after)%></after>
      </inline>
      >>
    case op as OP_SCALARIZE(__) then
      <<
      <scalarize index="<%op.index%>">
  <before><%printEquationExpStrEscaped(op.before)%></before>
  <after><%printEquationExpStrEscaped(op.after)%></after>
      </scalarize>
      >>
    case op as SOLVED(__) then
      <<
      <solved>
  <lhs><%crefStr(op.cr)%></lhs>
  <rhs><%printExpStrEscaped(op.exp)%></rhs>
      </solved>
      >>
    case op as LINEAR_SOLVED(__) then
      <<
      <linear-solved>
  simple equation from linear system:
    [<%vars |> v => crefStr(v) ; separator = " ; "%>] = [<%result |> r => r ; separator = " ; "%>]
    [
      <% jac |> row => (row |> r => r ; separator = " "); separator = "\n"%>
    ]
  *
    X
  =
    [<%rhs |> r => r ; separator = " ; "%>]
      </linear-solved>
      >>
    case op as SOLVE(__) then
      <<
      <solve>
  <old>
    <lhs><%printExpStrEscaped(op.exp1)%></lhs>
    <rhs><%printExpStrEscaped(op.exp2)%></rhs>
  </old>
  <new>
    <lhs><%crefStr(op.cr)%></lhs>
    <rhs><%printExpStrEscaped(op.res)%></rhs>
  </new>
  <assertions>
    <%op.assertConds |> cond => '<assertion><%printExpStrEscaped(cond)%></assertion>'; separator="\n"%>
  </assertions>
      </solve>
      >>
    case op as OP_DIFFERENTIATE(__) then
      <<
      <derivative>
  <exp><%printExpStrEscaped(op.before)%></exp>
  <with-respect-to><%crefStr(op.cr)%></with-respect-to>
  <result><%printExpStrEscaped(op.after)%></result>
      </derivative>
      >>
    case OP_RESIDUAL(__) then
      <<
      <op-residual>
  <lhs><%printExpStrEscaped(e1)%></lhs>
  <rhs><%printExpStrEscaped(e2)%></rhs>
  <result><%printExpStrEscaped(e)%></result>
      </op-residual>
      >>
    case op as NEW_DUMMY_DER(__) then
      <<
      <dummyderivative>
  <chosen><%crefStr(op.chosen)%></chosen>
  <%op.candidates |> cr => '<candidate><%crefStr(cr)%></candidate>' ; separator = "\n"%>'
      </dummyderivative>
      >>
    else Tpl.addSourceTemplateError("Unknown operation",info)
end dumpOperation;

template dumpInfo(Info info)
::=
  match info
  case info as INFO(__) then
  '<info file="<%escapeModelicaStringToXmlString(info.fileName)%>" lineStart="<%info.lineNumberStart%>" lineEnd="<%info.lineNumberEnd%>" colStart="<%info.columnNumberStart%>" colEnd="<%info.columnNumberEnd%>"/>'
end dumpInfo;

template printExpStrEscaped(Exp exp)
::=
  escapeModelicaStringToXmlString(printExpStr(exp))
end printExpStrEscaped;

template printEquationExpStrEscaped(EquationExp eq)
::=
  match eq
  case PARTIAL_EQUATION(__)
  case RESIDUAL_EXP(__) then
    printExpStrEscaped(exp)
  case EQUALITY_EXPS(__) then
    '<%printExpStrEscaped(lhs)%> = <%printExpStrEscaped(rhs)%>'
end printEquationExpStrEscaped;


template dumpEqsSys(list<SimEqSystem> eqs, Boolean withOperations)
::= eqs |> eq hasindex i0 =>
  match eq
    case e as SES_RESIDUAL(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <residual><%printExpStrEscaped(e.exp)%></residual>
      </equation><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      '<%eqIndex(eq)%> simple_assign <%crefStr(e.cref)%> : <%printCrefsFromExpStr(e.exp)%><%\n%>'
    case e as SES_ARRAY_CALL_ASSIGN(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
  <assign type="array">
    <lhs><%crefStr(e.componentRef)%></lhs>
    <rhs><%printExpStrEscaped(e.exp)%></rhs>
  </assign>
      </equation><%\n%>
      >>
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(statements=first::_)
      then
      <<
      <equation index="<%eqIndex(eq)%>">
  <statement>
    <%e.statements |> stmt => escapeModelicaStringToXmlString(ppStmtStr(stmt,2)) %>
  </statement>
      </equation><%\n%>
      >>
    case e as SES_LINEAR(__) then
  '<%eqIndex(eq)%> linear <%e.vars |> SIMVAR(name=cr) => '<%crefStr(cr)%>' ; separator = " " %> : <%beqs |> exp => '<%printExpStrEscaped(exp)%>' ; separator = " " %><%\n%>'
    case e as SES_NONLINEAR(__) then
      <<
      <%dumpEqsSys(SimCodeUtil.sortEqSystems(e.eqs),withOperations)%>
      <%eqIndex(eq)%> non_linear <%e.eqs |> eq => '<%eqIndex(eq)%>' ; separator = " " %><%\n%>
      >>
      /*
      <<
      <%dumpEqsSys(SimCodeUtil.sortEqSystems(e.eqs),withOperations)%>
      <%eqIndex(eq)%>     
    <%e.crefs |> cr => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
    <%e.eqs |> eq => '<eq index="<%eqIndex(eq)%>"/>' ; separator = "\n" %>
  </nonlinear>
      </equation><%\n%>
      >>
      */
    case e as SES_MIXED(__) then
      <<
      <%dumpEqs(fill(e.cont,1),withOperations)%>
      <%dumpEqs(e.discEqs,withOperations)%><%\n%>
      <equation index="<%eqIndex(eq)%>">
  <mixed>
    <continuous index="<%eqIndex(e.cont)%>" />
    <%e.discVars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = ","%>
    <%e.discEqs |> eq => '<discrete index="<%eqIndex(eq)%>" />'%>
  </mixed>
      </equation>
      >>
    case e as SES_WHEN(__) then
      <<
      <equation index="<%eqIndex(eq)%>">
      <when>
  <%conditions |> cond => '<cond><%crefStr(cond)%></cond>' ; separator="\n" %>
  <lhs><%crefStr(e.left)%></lhs>
  <rhs><%printExpStrEscaped(e.right)%></rhs>
      </when>
      </equation><%\n%>
      >>
    case e as SES_IFEQUATION(__) then
      let branches = ifbranches |> (_,eqs) => dumpEqsSys(eqs,withOperations)
      let elsebr = dumpEqsSys(elsebranch,withOperations)
      <<
      <%branches%>
      <%elsebr%>
      <equation index="<%eqIndex(eq)%>">
      <ifequation /> <!-- TODO: Fix me -->
      </equation><%\n%>
      >>
    else error(sourceInfo(),"dumpEqs: Unknown equation")
end dumpEqsSys;







end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
