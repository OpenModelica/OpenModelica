package SimCodeDump

import interface SimCodeTV;
import CodegenUtil.*;

template dumpSimCode(SimCode code)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  let name = dotPath(mi.name)
  let res = <<
  <?xml version="1.0" encoding="UTF-8"?>
  <?xml-stylesheet type="application/xml" href="simcodedump.xsl"?>
  <simcodedump model="<%name%>">
  <variables>
    <%dumpVars(vars.stateVars)%>
    <%dumpVars(vars.derivativeVars)%>
    <%dumpVars(vars.algVars)%>
    <%dumpVars(vars.intAlgVars)%>
    <%dumpVars(vars.boolAlgVars)%>
    <%dumpVars(vars.inputVars)%>
    <%dumpVars(vars.outputVars)%>
    <%dumpVars(vars.aliasVars)%>
    <%dumpVars(vars.intAliasVars)%>
    <%dumpVars(vars.boolAliasVars)%>
    <%dumpVars(vars.paramVars)%>
    <%dumpVars(vars.intParamVars)%>
    <%dumpVars(vars.boolParamVars)%>
    <%dumpVars(vars.stringAlgVars)%>
    <%dumpVars(vars.stringParamVars)%>
    <%dumpVars(vars.stringAliasVars)%>
    <%dumpVars(vars.extObjVars)%>
    <%dumpVars(vars.constVars)%>
  </variables>
  <equations>
    <%/* dumpEqs(listAppend(listAppend(sc.initialEquations,sc.parameterEquations),sc.allEquations)) */
    dumpEqs(sc.allEquations)%>
  </equations>
  </simcodedump><%\n%>
  >>
  let() = textFile(res,'<%name%>_dump.xml')
  'Result dumped to <%name%>_dump.xml'
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


template dumpVars(list<SimVar> vars)
::=
  vars |> v as SIMVAR(__) =>
  <<
  <variable name="<%crefStr(v.name)%>" comment="<%escapeModelicaStringToXmlString(v.comment)%>">
    <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source)%>
  </variable><%\n%>
  >>
end dumpVars;

template dumpAlias(AliasVariable alias)
::=
  match alias
  case ALIAS(__) then '<alias><%crefStr(varName)%></alias>'
  case NEGATEDALIAS(__) then ' <alias negated="true"><%crefStr(varName)%></alias>'
end dumpAlias;

template dumpEqs(list<SimEqSystem> eqs)
::= eqs |> eq hasindex i0 =>
  <<
  <%match eq
    case SES_RESIDUAL(__)
    case SES_SIMPLE_ASSIGN(__)
    case SES_ARRAY_CALL_ASSIGN(__)
    case SES_ALGORITHM(__)
    case SES_LINEAR(__)
    case SES_NONLINEAR(__)
    case SES_MIXED(__)
    case SES_WHEN(__) then '<equation index="<%index%>">'
    else error(sourceInfo(), "dumpEqs: Unknown equation")
  %>
  <%match eq
    case e as SES_RESIDUAL(__) then
      <<
        <residual><%printExpStrEscaped(e.exp)%></residual>
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
        <assign>
          <lhs><%crefStr(e.cref)%></lhs>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign>
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then
      <<
        <assign type="array">
          <lhs><%crefStr(e.componentRef)%></lhs>
          <rhs><%printExpStrEscaped(e.exp)%></rhs>
        </assign>
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(__)
      then (e.statements |> stmt =>
      <<
        <statement>
          <%escapeModelicaStringToXmlString(ppStmtStr(stmt,2))%>
        </statement>
        <%dumpElementSource(getStatementSource(stmt))%><%\n%>
      >>
      )
    case e as SES_LINEAR(__) then
      <<
      <linear>
        <%e.vars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
        <row>
          <%beqs |> exp => '<cell><%printExpStrEscaped(exp)%></cell>' ; separator = "\n" %><%\n%>
        </row>
        <matrix>
          <%simJac |> (i1,i2,eq) => '<cell row="<%i1%>" col="<%i2%>"><%dumpEqs(fill(eq,1))%></cell>' ; separator = "\n" %><%\n%>
        </matrix>
      </linear>
      >>
    case e as SES_NONLINEAR(__) then
      <<
      <nonlinear indexNonlinear="<%indexNonLinear%>">
        <%e.crefs |> cr => '<var><%crefStr(cr)%></var>' ; separator = "\n" %>
        <%dumpEqs(e.eqs)%><%\n%>
      </nonlinear>
      >>
    case e as SES_MIXED(__) then
      <<
      <mixed>
        <continuous>
          <%dumpEqs(fill(e.cont,1))%>
        </continuous>
        <%e.discVars |> SIMVAR(name=cr) => '<var><%crefStr(cr)%></var>' ; separator = ","%>
        <discrete>
          <%dumpEqs(e.discEqs)%>
        </discrete>
      </mixed>
      >>
    case e as SES_WHEN(__) then
      <<
      <when>
        <%conditions |> cond => '<cond><%printExpStrEscaped(cond)%></cond>' ; separator="\n" %>
        <lhs><%crefStr(e.left)%></lhs>
        <rhs><%printExpStrEscaped(e.right)%></rhs>
      </when>
      <%dumpElementSource(e.source)%>
      >>
    else error(sourceInfo(),"dumpEqs: Unknown equation")
  %>
  </equation><%\n%>
  >>
end dumpEqs;

template dumpWithin(Within w)
::=
  match w
    case TOP(__) then "within ;"
    case WITHIN(__) then 'within <%dotPath(path)%>;'
end dumpWithin;

template dumpElementSource(ElementSource source)
::=
  match source
    case s as SOURCE(info=info as INFO(__)) then
      <<
      <source>
        <info file="<%info.fileName%>" lineStart="<%info.lineNumberStart%>" lineEnd="<%info.lineNumberEnd%>" colStart="<%info.columnNumberStart%>" colEnd="<%info.columnNumberEnd%>"/>
        <%s.partOfLst |> w => '<part-of><%dumpWithin(w)%></part-of>' %>
        <%s.instanceOptLst |> SOME(cr) => '<instance><%crefStr(cr)%></instance>' %>
        <%s.connectEquationOptLst |> p => "<connect-equation />"%>
        <%s.typeLst |> p => '<type><%dotPath(p)%></type>' ; separator = "\n" %>
      </source>
      <operations>
        <%s.operations |> op => dumpOperation(op,s.info) ; separator="\n" %>
      </operations>
      >>
end dumpElementSource;

template dumpOperation(SymbolicOperation op, Info info)
::=
  match op
    case SIMPLIFY(__) then
      <<
      <simplify>
        <before><%printExpStrEscaped(before)%></before>
        <after><%printExpStrEscaped(after)%></after>
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
        <before><%printExpStrEscaped(op.before)%></before>
        <after><%printExpStrEscaped(op.after)%></after>
      </inline>
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
    case op as OP_DERIVE(__) then
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

template printExpStrEscaped(Exp exp)
::=
  escapeModelicaStringToXmlString(printExpStr(exp))
end printExpStrEscaped;

end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
