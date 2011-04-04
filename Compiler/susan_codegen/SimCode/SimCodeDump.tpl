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
  >>
end dumpSimCode;

template dumpVars(list<SimVar> vars)
::=
  vars |> v as SIMVAR(__) =>
  <<
  <%crefStr(v.name)%> <%v.comment%> <%dumpAlias(v.aliasvar)%><%\n%>
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
    case e as SES_RESIDUAL(__) then "RESIDUAL"
    case e as SES_SIMPLE_ASSIGN(__) then
      <<
      eq: <%crefStr(e.cref)%> = <%printExpStr(e.exp)%>;
        <%dumpElementSource(e.source)%><%\n%>
      >>
    case e as SES_ARRAY_CALL_ASSIGN(__) then "SES_ARRAY_CALL_ASSIGN"
    case e as SES_ALGORITHM(statements={}) then 'empty algorithm<%\n%>'
    case e as SES_ALGORITHM(__)
      then (e.statements |> stmt => ppStmtStr(stmt,2))
    case e as SES_LINEAR(__) then "SES_LINEAR"
    case e as SES_NONLINEAR(__) then "SES_NONLINEAR"
    case e as SES_MIXED(__) then "SES_MIXED"
    case e as SES_WHEN(__) then "SES_WHEN"
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
      typeLst: <%s.typeLst |> p => "w"%>
      operations: <%s.operations |> op => dumpOperation(op,s.info) %>
      >>
end dumpElementSource;

template dumpOperation(SymbolicOperation op, Info info)
::=
  match op
    case SIMPLIFY(__) then "SIMPLIFY!"
    else Tpl.addSourceTemplateError("Unknown operation",info)
end dumpOperation;

end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
