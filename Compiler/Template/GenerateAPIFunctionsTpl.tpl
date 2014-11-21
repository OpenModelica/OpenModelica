package GenerateAPIFunctionsTpl

import interface SimCodeTV;

template getCevalScriptInterface(list<DAE.Type> tys)
::=
  let funcs = tys |> ty as T_FUNCTION(source=path::_) => '<%getCevalScriptInterfaceFunc(pathLastIdent(path), ty.funcArg, ty.funcResultType)%><%\n%>'
  <<
  import Absyn;
  import CevalScript;
  import GlobalScript;
  import Parser;

  protected

  constant Absyn.Msg dummyMsg = Absyn.MSG(SOURCEINFO("<interactive>",false,1,1,1,1,0.0));

  public

  <%funcs%>
  >>
end getCevalScriptInterface;

template getCevalScriptInterfaceFunc(String name, list<DAE.FuncArg> args, DAE.Type res)
::=
  <<
  function <%name%>
    input GlobalScript.SymbolTable st;
    input ...;
    output GlobalScript.SymbolTable outSymTab;
    output ...;
  algorithm
    (_,...,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "<%name%>", {...}, st, dummyMsg);
  end <%name%>;
  >>
end getCevalScriptInterfaceFunc;

annotation(__OpenModelica_Interface="backend");
end GenerateAPIFunctionsTpl;

// vim: filetype=susan sw=2 sts=2
