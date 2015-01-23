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

template getQtInterface(list<DAE.Type> tys, String className)
::=
  let heads = tys |> ty as T_FUNCTION(source=path::_) => '<%getQtInterfaceHeader(pathLastIdent(path), "", ty.funcArg, ty.funcResultType, className)%><%\n%>'
  let funcs = tys |> ty as T_FUNCTION(source=path::_) => '<%getQtInterfaceFunc(pathLastIdent(path), ty.funcArg, ty.funcResultType, className)%><%\n%>'
  <<
  #include <Qt/QtCore>
  #include "OpenModelicaScriptingAPI.h"

  <%funcs%>
  >>
end getQtInterface;

template getQtType(DAE.Type ty)
::=
  match ty
    case T_STRING(__) then "QString"
    case T_INTEGER(__) then "modelica_integer"
    case T_BOOL(__) then "modelica_boolean"
    case T_REAL(__) then "modelica_real"
    case aty as T_ARRAY(__) then 'QList<<%getQtType(aty.ty)%>>'
    case T_CODE(ty=C_TYPENAME(__)) then "QString"
    else error(sourceInfo(), 'getQtType failed for <%unparseType(ty)%>')
end getQtType;

template getQtInterfaceHeader(String name, String prefix, list<DAE.FuncArg> args, DAE.Type res, String className)
::=
  let inTypes = args |> arg as FUNCARG(__) => '<%getQtType(arg.ty)%> <%arg.name%>' ; separator=", "
  let outType = match res
    case T_TUPLE(__) then
      <<
      typedef struct {
        <%types |> ty hasindex i fromindex 1 => '<%getQtType(ty)%> res<%i%>;' ; separator="\n" %>
      } <%name%>_res;
      <%name%>_res
      >>
    case T_NORETCALL(__) then "void"
    else '<%getQtType(res)%>'
  <<
  <%outType%> <%prefix%><%name%>(<%inTypes%>)
  >>
end getQtInterfaceHeader;

template getQtInArg(Text name, DAE.Type ty, Text &varDecl)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then
      let &varDecl += 'QByteArray <%name%>_utf8 = <%name%>.toUtf8();<%\n%>'
      'mmc_mk_scon(<%name%>_utf8.data())'
    case T_INTEGER(__)
    case T_BOOL(__)
    case T_REAL(__) then name
    case aty as T_ARRAY(__) then
      let &varDecl2 = buffer ""
      let elt = '<%name%>_elt'
      let body = getQtInArg(elt, aty.ty, varDecl2)
      let &varDecl +=
      <<
      void *<%name%>_lst = mmc_mk_nil();
      for (int <%name%>_i = <%name%>.size()-1; i>=0; i--) {
        <%getQtType(aty.ty)%> <%elt%> = <%name%>[<%name%>_i];
        <%varDecl2%>
        <%name%>_lst = mmc_mk_cons(<%body%>, <%name%>_lst);
      }<%\n%>
      >>
      '<%name%>_lst'
    else error(sourceInfo(), 'getQtInArg failed for <%unparseType(ty)%>')
end getQtInArg;

template getQtOutArg(Text name, Text shortName, DAE.Type ty, Text &varDecl, Text &postCall)
::=
  match ty
    case T_CODE(ty=C_TYPENAME(__))
    case T_STRING(__) then
      let &varDecl += 'void *<%shortName%>_mm = NULL;<%\n%>'
      let &postCall += '<%name%> = QString::fromUtf8(MMC_STRINGDATA(<%shortName%>_mm));<%\n%>'
      '&<%name%>_mm'
    case T_INTEGER(__)
    case T_BOOL(__)
    case T_REAL(__) then '&<%name%>'
    case aty as T_ARRAY(__) then
      let &varDecl += 'void *<%shortName%>_mm = NULL;<%\n%>'
      let &varDecl2 = buffer ""
      let &postCall +=
      <<
      while (!listEmpty(<%shortName%>_mm)) {
        <%varDecl2%>
        <%getQtType(aty.ty)%> <%shortName%>_elt = MMC_CAR(<%shortName%>_mm);
        <%name%>.push_back(...);
        <%shortName%>_mm = MMC_CDR(<%shortName%>_mm);
      }<%\n%>
      >>
      '&<%name%>_mm'
    else error(sourceInfo(), 'getQtOutArg failed for <%unparseType(ty)%>')
end getQtOutArg;

template getQtInterfaceFunc(String name, list<DAE.FuncArg> args, DAE.Type res, String className)
::=
  let &varDecl = buffer ""
  let &postCall = buffer ""
  let inArgs = args |> arg as FUNCARG(__) => ', <%getQtInArg(arg.name, arg.ty, varDecl)%>'
  let outArgs = (match res
    case T_NORETCALL(__) then ""
    case t as T_TUPLE(__) then
      let &varDecl += '<%name%>_res result;<%\n%>'
      (types |> t hasindex i1 fromindex 1 => ', <%getQtOutArg('result.res<%i1%>', 'out<%i1%>', t, varDecl, postCall)%>')
    else
      let &varDecl += '<%getQtType(res)%> result;<%\n%>'
      ', <%getQtOutArg('result', 'result', res, varDecl, postCall)%>'
    )
  <<
  <%getQtInterfaceHeader(name, '<%className%>::', args, res, className)%>
  {
    <%varDecl%>

    MMC_TRY_TOP_INTERNAL()

    st = omc_OpenModelicaScriptingAPI_<%name%>(threadData, st<%inArgs%><%outArgs%>);
    <%postCall%>

    MMC_CATCH_TOP(throw std::runtime_error("getClassInformation failed");)

    /*
    while (!MMC_NILTEST(dimensions)) {
      result.dimensions.push_back(MMC_STRINGDATA(MMC_CAR(dimensions)));
      dimensions = MMC_CDR(dimensions);
    }
    */
  }
  >>
end getQtInterfaceFunc;

annotation(__OpenModelica_Interface="backend");
end GenerateAPIFunctionsTpl;

// vim: filetype=susan sw=2 sts=2
