package SimCodeDump

import interface SimCodeTV;
import SimCodeC.*;

template dumpSimCode(SimCode code)
::=
  match code
  case sc as SIMCODE(modelInfo=mi as MODELINFO(vars=vars as SIMVARS(__))) then
  <<
  SimCode: <%dotPath(mi.name)%>
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
  <%dumpVars(vars.jacobianVars)%>
  <%dumpVars(vars.constVars)%>
  <%dumpEqs(sc.allEquations)%>
  /* Removed Equations */
  <%dumpEqs(sc.removedEquations)%>
  >>
end dumpSimCode;

template dumpVars(list<SimVar> vars)
::=
  vars |> v as SIMVAR(__) =>
  <<
  <%crefStr(v.name)%> <%v.comment%> <%dumpAlias(v.aliasvar)%>
    <%dumpElementSource(v.source)%>
  <%\n%>
  >>
end dumpVars;

template dumpAlias(AliasVariable alias)
::=
  match alias
  case ALIAS(__) then 'alias of <%crefStr(varName)%>'
  case NEGATEDALIAS(__) then 'alias of -<%crefStr(varName)%>'
end dumpAlias;

template dumpEqs(list<SimEqSystem> eqs)
::= eqs |> eq =>
  match eq
    case e as SES_RESIDUAL(__) then
      <<
      residual: <%printExpStr(e.exp)%>;
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      eq: <%crefStr(e.cref)%> = <%printExpStr(e.exp)%>;
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then "SES_ARRAY_CALL_ASSIGN"
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(__)
      then (e.statements |> stmt =>
      <<
      statement: <%ppStmtStr(stmt,2)%>
        <%dumpElementSource(getStatementSource(stmt))%><%\n%>
      >>
      )
    case e as SES_LINEAR(__) then
      <<
      linear: <%e.vars |> var => "var" ; separator = "," %>
        <%beqs |> exp => printExpStr(exp) ; separator = "," %><%\n%>
        <%simJac |> (i1,i2,eq) => '<%i1%>,<%i2%>: <%dumpEqs(fill(eq,1))%>' ; separator = "\n" %><%\n%>
      >>
    case e as SES_NONLINEAR(__) then
      <<
      nonlinear: <%e.crefs |> cr => crefStr(cr) ; separator = "," %>
        <%dumpEqs(e.eqs)%><%\n%>
      >>
    case e as SES_MIXED(__) then
      <<
      mixed system:
        continuous part:
          <%dumpEqs(fill(e.cont,1))%>
        discrete vars:
          <%e.discVars |> var => "var" ; separator = ","%>
        discrete parts:
          <%dumpEqs(e.discEqs)%><%\n%>
      >>
    case e as SES_WHEN(__) then
      <<
      when: conditions
        <%crefStr(e.left)%> = <%printExpStr(e.right)%>
        <%dumpElementSource(e.source)%><%\n%>
      >>
    else "UNKNOWN"
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
    case s as SOURCE(__) then
      <<
      <%infoStr(s.info)%>
      partOfLst: <%s.partOfLst |> w => dumpWithin(w)%>
      instanceOptLst: <%s.instanceOptLst |> SOME(cr) => crefStr(cr)%>
      connectEquationOptLst: <%s.connectEquationOptLst |> p => "w"%>
      typeLst: <%s.typeLst |> p => dotPath(p) ; separator = "," %>
      operations (<%listLength(s.operations)%>): <%s.operations |> op => dumpOperation(op,s.info) %>
      >>
end dumpElementSource;

template dumpOperation(SymbolicOperation op, Info info)
::=
  match op
    case SIMPLIFY(__) then
      <<<%\n%>
        simplify:
          <%printExpStr(before)%>
          =>
          <%printExpStr(after)%>
      >>
    case SUBSTITUTION(__) then
      <<<%\n%>
        subst:
          <%printExpStr(source)%>
          <%listReverse(substitutions) |> target =>
          <<
          =>
          <%printExpStr(target)%>
          >> ; separator = "\n" %>
      >>
    case op as OP_INLINE(__) then
      <<<%\n%>
        inline:
          <%printExpStr(op.before)%>
          =>
          <%printExpStr(op.after)%>
      >>
    case op as SOLVED(__) then '<%\n%>  simple equation: <%crefStr(op.cr)%> = <%printExpStr(op.exp)%>'
    case op as LINEAR_SOLVED(__) then
      <<<%\n%>
        simple equation from linear system:
          [<%vars |> v => crefStr(v) ; separator = " ; "%>] = [<%result |> r => r ; separator = " ; "%>]
          [
            <% jac |> row => (row |> r => r ; separator = " "); separator = "\n"%>
          ]
        *
          X
        =
          [<%rhs |> r => r ; separator = " ; "%>]
      >>
    case op as SOLVE(__) then
      <<<%\n%>
        solve:
          <%printExpStr(op.exp1)%> = <%printExpStr(op.exp2)%>
          =>
          <%crefStr(op.cr)%> = <%printExpStr(op.res)%>
        added assertions:
          <%op.assertConds |> cond => printExpStr(cond); separator="\n"%>
      >>
    case op as OP_DERIVE(__) then
      <<<%\n%>
        derive:
          d/d<%crefStr(op.cr)%> <%printExpStr(op.before)%>
          =>
          <%printExpStr(op.after)%>
      >>
    case OP_RESIDUAL(__) then
      <<<%\n%>
        residual:
          <%printExpStr(e1)%> = <%printExpStr(e2)%>
          =>
          0.0 = <%printExpStr(e)%>
      >>
    case op as NEW_DUMMY_DER(__) then '<%\n%>  dummy derivative: <%crefStr(op.chosen)%> from candidates: <%op.candidates |> cr => crefStr(cr) ; separator = ","%>'
    else Tpl.addSourceTemplateError("Unknown operation",info)
end dumpOperation;

end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
