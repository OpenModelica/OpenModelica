package GenerateAPIFunctionsTpl

import interface SimCodeTV;
import CodegenUtil.*;

template getCevalScriptInterface(list<DAE.Type> tys)
::=
  let funcs = tys |> ty as T_FUNCTION(source=path::_) => '<%getCevalScriptInterfaceFunc(pathLastIdent(path), ty.funcArg, ty.funcResultType)%><%\n%>'
  <<
  import Absyn;
  import CevalScript;
  import GlobalScript;
  import Parser;

  protected

  import Values;
  import ValuesUtil;
  constant Absyn.Msg dummyMsg = Absyn.MSG(SOURCEINFO("<interactive>",false,1,1,1,1,0.0));

  public

  <%funcs%>
  >>
end getCevalScriptInterface;

template getInType(DAE.Type ty)
::=
  match ty
    case T_STRING(__) then "String"
    case T_INTEGER(__) then "Integer"
    case T_BOOL(__) then "Boolean"
    case T_REAL(__) then "Real"
    case aty as T_ARRAY(__) then 'list<<%getInType(aty.ty)%>>'
    case T_CODE(ty=C_TYPENAME(__)) then "String"
    else error(sourceInfo(), 'getInType failed for <%unparseType(ty)%>')
end getInType;

template getInValue(Text name, DAE.Type ty)
::=
  match ty
    case T_STRING(__) then 'Values.STRING(<%name%>)'
    case T_INTEGER(__) then 'Values.INTEGER(<%name%>)'
    case T_BOOL(__) then 'Values.BOOL(<%name%>)'
    case T_REAL(__) then 'Values.REAL(<%name%>)'
    case aty as T_ARRAY(__) then 'ValuesUtil.makeArray(list(<%getInValue('<%name%>_iter', aty.ty)%> for <%name%>_iter in <%name%>))'
    case T_CODE(ty=C_TYPENAME(__)) then 'Values.CODE(Absyn.C_TYPENAME(Parser.stringPath(<%name%>)))'
    else error(sourceInfo(), 'getInValue failed for <%unparseType(ty)%>')
end getInValue;

template getOutValue(Text name, DAE.Type ty, Text &varDecl, Text &postMatch)
::=
  match ty
    case T_STRING(__) then 'Values.STRING(<%name%>)'
    case T_INTEGER(__) then 'Values.INTEGER(<%name%>)'
    case T_BOOL(__) then 'Values.BOOL(<%name%>)'
    case T_REAL(__) then 'Values.REAL(<%name%>)'
    case aty as T_ARRAY(__) then
      let &varDecl += 'Values.Value <%name%>_arr;<%\n%>'
      let &postMatch += '<%name%> := <%getOutValueArray('<%name%>_arr', aty)%>;<%\n%>'
      '<%name%>_arr'

    case T_CODE(ty=C_TYPENAME(__)) then
      let &varDecl += 'Absyn.Path <%name%>_path;<%\n%>'
      let &postMatch += '<%name%> := Absyn.pathString(<%name%>_path);<%\n%>'
      'Values.CODE(Absyn.C_TYPENAME(path=<%name%>_path))'
    else error(sourceInfo(), 'getOutValue failed for <%unparseType(ty)%>')
end getOutValue;

template getOutValueArray(Text name, DAE.Type ty)
::=
  match ty
    case T_STRING(__) then 'match <%name%> case Values.STRING() then <%name%>.string; end match'
    case T_INTEGER(__) then 'match <%name%> case Values.INTEGER() then <%name%>.integer; end match'
    case T_BOOL(__) then 'match <%name%> case Values.BOOL() then <%name%>.boolean; end match'
    case T_REAL(__) then 'match <%name%> case Values.REAL() then <%name%>.real; end match'
    case aty as T_ARRAY(__) then
      'list(<%getOutValueArray('<%name%>_iter', aty.ty)%> for <%name%>_iter in ValuesUtil.arrayValues(<%name%>))'
    case T_CODE(ty=C_TYPENAME(__)) then
      'ValuesUtil.valString(<%name%>)'
    else error(sourceInfo(), 'getOutValueArray failed for <%unparseType(ty)%>')
end getOutValueArray;

template getCevalScriptInterfaceFunc(String name, list<DAE.FuncArg> args, DAE.Type res)
::=
  let &varDecl = buffer ""
  let &postMatch = buffer ""
  let inVals = args |> arg as FUNCARG(__) => getInValue(arg.name, arg.ty) ; separator=", "
  let outVals = match res
    case T_TUPLE(__) then 'Values.TUPLE({<%types |> ty hasindex i fromindex 1 => getOutValue('res<%i%>', ty, &varDecl, &postMatch) ; separator=", "%>})'
    case T_NORETCALL(__) then "Values.NORETCALL()"
    else '<%getOutValue("res", res, &varDecl, &postMatch)%>'
  <<
  function <%name%>
    input GlobalScript.SymbolTable st;
    <%args |> arg as FUNCARG(__) =>
      'input <%getInType(arg.ty)%> <%arg.name%>;' ; separator="\n" %>
    output GlobalScript.SymbolTable outSymTab;
    <%
    match res
    case T_TUPLE(__) then (types |> ty hasindex i fromindex 1 => 'output <%getInType(ty)%> res<%i%>;' ; separator="\n")
    case T_NORETCALL(__) then ""
    else 'output <%getInType(res)%> res;'
    %>
  <%if varDecl then
  <<
  protected
    <%varDecl%>
  >>
  %>
  algorithm
    (_,<%outVals%>,outSymTab) := CevalScript.cevalInteractiveFunctions2(FCore.emptyCache(), FGraph.empty(), "<%name%>", {<%inVals%>}, st, dummyMsg);
    <%postMatch%>
  end <%name%>;<%\n%>
  >>
end getCevalScriptInterfaceFunc;

annotation(__OpenModelica_Interface="backend");
end GenerateAPIFunctionsTpl;

// vim: filetype=susan sw=2 sts=2
