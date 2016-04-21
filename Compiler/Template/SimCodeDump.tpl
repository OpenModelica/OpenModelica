package SimCodeDump

import interface SimCodeTV;
import CodegenUtil.*;
import DAEDumpTpl.*;
import SCodeDumpTpl.*;

template dumpVarsShort(list<SimVar> vars)
::=
  let varsString = (vars |> v as SIMVAR(__) hasindex index0 =>
  <<
  <%index0%>: <%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(v.name))%>
  >>
  ;separator="\n";empty)
  <<
  <%varsString%>

  >>
end dumpVarsShort;

template dumpAlias(AliasVariable alias)
::=
  match alias
  case ALIAS(__) then '<alias><%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(varName))%></alias>'
  case NEGATEDALIAS(__) then ' <alias negated="true"><%Util.escapeModelicaStringToXmlString(crefStrNoUnderscore(varName))%></alias>'
end dumpAlias;

template printExpStrEscaped(Exp exp)
::=
  escapeModelicaStringToXmlString(printExpStr(exp))
end printExpStrEscaped;

annotation(__OpenModelica_Interface="backend");
end SimCodeDump;

// vim: filetype=susan sw=2 sts=2
