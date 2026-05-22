/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package TypesDump
" file:        TypesDump.mo
  package:     TypesDump
  description: Dumping of DAE Types
"

public import DAE;
protected
import AbsynUtil;
import ClassInfUtil;
import Config;
import Dump;
import Error;
import ExpressionBasics;
import List;
import Print;
import SCodeDump;
import ValuesDump;

protected type Binding = DAE.Binding;
protected type Const = DAE.Const;
protected type EqualityConstraint = DAE.EqualityConstraint;
protected type FuncArg = DAE.FuncArg;
protected type Properties = DAE.Properties;
protected type TupleConst = DAE.TupleConst;
protected type Type = DAE.Type;
protected type Var = DAE.Var;
protected type EqMod = DAE.EqMod;

public function unparseEqMod
"prints eqmod to a string"
  input DAE.EqMod eq;
  output String str;
algorithm
  str := match(eq)
    local DAE.Exp e; Absyn.Exp e2;

    case(DAE.TYPED(modifierAsExp = e))
      algorithm
        str := ExpressionBasics.printExpStr(e);
      then
        str;

    case(DAE.UNTYPED(exp=e2))
      algorithm
        str := Dump.printExpStr(e2);
      then str;
  end match;
end unparseEqMod;

public function unparseOptionEqMod
"prints eqmod to a string"
  input Option<DAE.EqMod> eq;
  output String str;
algorithm
  str := match(eq)
    local
      DAE.EqMod e;
    case NONE() then "NONE()";
    case SOME(e) then unparseEqMod(e);
  end match;
end unparseOptionEqMod;

public function unparseType
"This function prints a Modelica type as a piece of Modelica code."
  input DAE.Type inType;
  output String outString;
algorithm
  outString := match (inType)
    local
      String s1,s2,str,dims,res,vstr,name,st_str,bc_tp_str,paramstr,restypestr,tystr,funcstr;
      list<String> l,vars,paramstrs,tystrs;
      Type ty,bc_tp,restype;
      DAE.Dimensions dimlst;
      list<DAE.Var> vs;
      ClassInf.State ci_state;
      list<DAE.FuncArg> params;
      Absyn.Path path,p;
      list<DAE.Type> tys;
      DAE.CodeType codeType;
      Boolean b;

    case (DAE.T_INTEGER(varLst = {})) then "Integer";
    case (DAE.T_REAL(varLst = {})) then "Real";
    case (DAE.T_STRING(varLst = {})) then "String";
    case (DAE.T_BOOL(varLst = {})) then "Boolean";
    // BTH
    case (DAE.T_CLOCK()) then "Clock";

    case (DAE.T_INTEGER(varLst = vs))
      algorithm
        s1 := stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 := "Integer(" + s1 + ")";
      then s2;
    case (DAE.T_REAL(varLst = vs))
      algorithm
        s1 := stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 := "Real(" + s1 + ")";
      then s2;
    case (DAE.T_STRING(varLst = vs))
      algorithm
        s1 := stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 := "String(" + s1 + ")";
      then s2;
    case (DAE.T_BOOL(varLst = vs))
      algorithm
        s1 := stringDelimitList(List.map(vs, unparseVarAttr),", ");
        s2 := "Boolean(" + s1 + ")";
      then s2;
    case (DAE.T_ENUMERATION(path = path, names = l))
      algorithm
        s1 := if Config.typeinfo() then " /*" + AbsynUtil.pathString(path) + "*/ (" else "(";
        s2 := stringDelimitList(l, ", ");
        /* s2 = stringAppendList(List.map(vs, unparseVar));
        s2 = if_(s2 == "", "", "(" + s2 + ")"); */
        str := stringAppendList({"enumeration",s1,s2,")"});
      then
        str;

    case (ty as DAE.T_ARRAY())
      algorithm
        (ty,dimlst) := flattenArrayType(ty);
        tystr := unparseType(ty);
        dims := printDimensionsStr(dimlst);
        res := stringAppendList({tystr,"[",dims,"]"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path),varLst = vs))
      algorithm
        name := AbsynUtil.pathStringNoQual(path);
        vars := List.map(vs, unparseVar);
        vstr := stringAppendList(vars);
        res := stringAppendList({"record ",name,"\n",vstr,"end ", name, ";"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path, b),varLst = vs))
      algorithm
        name := AbsynUtil.pathStringNoQual(path);
        vars := List.map(vs, unparseVar);
        vstr := stringAppendList(vars);
        str := if b then "expandable " else "";
        res := stringAppendList({str, "connector ",name,"\n",vstr,"end ", name, ";"});
      then
        res;

    case (DAE.T_SUBTYPE_BASIC(complexClassType = ci_state, complexType = bc_tp))
      algorithm
        st_str := AbsynUtil.pathString(ClassInfUtil.getStateName(ci_state));
        res := ClassInfUtil.printStateStr(ci_state);
        bc_tp_str := unparseType(bc_tp);
        res := stringAppendList({"(",res," ",st_str," bc:",bc_tp_str,")"});
      then
        res;

    case (DAE.T_COMPLEX(complexClassType = ci_state))
      algorithm
        st_str := AbsynUtil.pathString(ClassInfUtil.getStateName(ci_state));
        res := ClassInfUtil.printStateStr(ci_state);
        res := stringAppendList({res," ",st_str});
      then
        res;

    case (DAE.T_FUNCTION(funcArg = params, funcResultType = restype, path=path))
      algorithm
        funcstr := AbsynUtil.pathString(path);
        paramstrs := List.map(params, unparseParam);
        paramstr := stringDelimitList(paramstrs, ", ");
        restypestr := unparseType(restype);
        res := stringAppendList({funcstr,"<function>(",paramstr,") => ",restypestr});
      then
        res;

    case (DAE.T_TUPLE(types = tys))
      algorithm
        tystrs := match inType.names
          local
            list<String> names;
          case SOME(names) then list(unparseType(t) + " " + n threaded for t in tys, n in names);
          else list(unparseType(t) for t in tys);
        end match;
        tystr := stringDelimitList(tystrs, ", ");
        res := stringAppendList({"(",tystr,")"});
      then
        res;

    // MetaModelica tuple
    case (DAE.T_METATUPLE(types = tys))
      algorithm
        tystrs := List.map(tys, unparseType);
        tystr := stringDelimitList(tystrs, ", ");
        res := stringAppendList({"tuple<",tystr,">"});
      then
        res;

     // MetaModelica list
    case (DAE.T_METALIST(ty = ty))
      algorithm
        tystr := unparseType(ty);
        res := stringAppendList({"list<",tystr,">"});
      then
        res;

    case (DAE.T_METAARRAY(ty = ty))
      algorithm
        tystr := unparseType(ty);
        res := stringAppendList({"array<",tystr,">"});
      then
        res;

    // MetaModelica list
    case (DAE.T_METAPOLYMORPHIC(name = tystr))
      algorithm
        res := stringAppendList({"polymorphic<",tystr,">"});
      then
        res;

     // MetaModelica uniontype
    case DAE.T_METAUNIONTYPE()
      algorithm
        res := AbsynUtil.pathStringNoQual(inType.path);
      then if listEmpty(inType.typeVars) then res else (res+"<"+stringDelimitList(list(unparseType(tv) for tv in inType.typeVars), ",")+">");

    // MetaModelica uniontype (but we know which record in the UT it is)
/*
    case (DAE.T_METARECORD(utPath=_, fields = vs, source = {p}))
      algorithm
        str = AbsynUtil.pathStringNoQual(p);
        vars = List.map(vs, unparseVar);
        vstr = stringAppendList(vars);
        res = stringAppendList({"metarecord ",str,"\n",vstr,"end ", str, ";"});
      then res;
*/
    case DAE.T_METARECORD()
      algorithm
        res := AbsynUtil.pathStringNoQual(inType.path);
      then if listEmpty(inType.typeVars) then res else (res+"<"+stringDelimitList(list(unparseType(tv) for tv in inType.typeVars), ",")+">");

    // MetaModelica boxed type
    case (DAE.T_METABOXED(ty = ty))
      algorithm
        res := unparseType(ty);
        res := "#" /* this is a box */ + res;
      then res;

    // MetaModelica Option type
    case (DAE.T_METAOPTION(ty = DAE.T_UNKNOWN())) then "Option<Any>";
    case (DAE.T_METAOPTION(ty = ty))
      algorithm
        tystr := unparseType(ty);
        res := stringAppendList({"Option<",tystr,">"});
      then
        res;

    case (DAE.T_METATYPE(ty = ty)) then unparseType(ty);

    case (DAE.T_NORETCALL())              then "#NORETCALL#";
    case (DAE.T_UNKNOWN())                then "#T_UNKNOWN#";
    case (DAE.T_ANYTYPE()) then "#ANYTYPE#";
    case (DAE.T_CODE(ty = codeType)) then printCodeTypeStr(codeType);
    case (DAE.T_FUNCTION_REFERENCE_VAR(functionType=ty)) then "#FUNCTION_REFERENCE_VAR#" + unparseType(ty);
    case (DAE.T_FUNCTION_REFERENCE_FUNC(functionType=ty)) then "#FUNCTION_REFERENCE_FUNC#" + unparseType(ty);
    else "Internal error TypesDump.unparseType: not implemented yet\n";
  end match;
end unparseType;

public function unparseTypeNoAttr
  "Like unparseType, but doesn't print out builtin attributes."
  input DAE.Type inType;
  output String outString;
protected
  DAE.Type ty;
algorithm
  (ty, _) := stripTypeVars(inType);
  outString := unparseType(ty);
end unparseTypeNoAttr;

public function unparsePropTypeNoAttr
  input DAE.Properties inProps;
  output String outString;
algorithm
  outString := match(inProps)
    local
      DAE.Type ty;

    case DAE.PROP(type_ = ty) then unparseTypeNoAttr(ty);
    case DAE.PROP_TUPLE(type_ = ty) then unparseTypeNoAttr(ty);
  end match;
end unparsePropTypeNoAttr;

public function unparseConst
  input DAE.Const inConst;
  output String outString;
algorithm
  outString := match(inConst)
    case DAE.C_CONST() then "constant";
    case DAE.C_PARAM() then "parameter";
    case DAE.C_VAR() then "continuous";
    case DAE.C_UNKNOWN() then "unknown";
  end match;
end unparseConst;

public function printConstStr
  "This function prints a Const as a string."
  input DAE.Const inConst;
  output String outString;
algorithm
  outString := match (inConst)
    case DAE.C_CONST() then "C_CONST";
    case DAE.C_PARAM() then "C_PARAM";
    case DAE.C_VAR() then "C_VAR";
    else algorithm
      Error.addInternalError(getInstanceName() + " failed.", sourceInfo());
    then fail();
  end match;
end printConstStr;

public function printTupleConstStr
  "This function prints a Modelica TupleConst as a string."
  input DAE.TupleConst inTupleConst;
  output String outString;
algorithm
  outString := match (inTupleConst)
    local
      String cstr,res,res_1;
      DAE.Const c;
      list<String> strlist;
      list<DAE.TupleConst> constlist;
    case DAE.SINGLE_CONST(const = c)
      algorithm
        cstr := printConstStr(c);
      then
        cstr;
    case DAE.TUPLE_CONST(tupleConstLst = constlist)
      algorithm
        strlist := List.map(constlist, printTupleConstStr);
        res := stringDelimitList(strlist, ", ");
        res_1 := stringAppendList({"(",res,")"});
      then
        res_1;
  end match;
end printTupleConstStr;

public function printTypeStr "This function prints a textual description of a Modelica type to a string.
  If the type is not one of the primitive types, it simply prints composite."
  input DAE.Type inType;
  output String str;
algorithm
  str := matchcontinue (inType)
    local
      list<DAE.Var> vars;
      list<String> l;
      ClassInf.State st;
      list<DAE.Dimension> dims;
      Type t,ty,restype;
      list<DAE.FuncArg> params;
      list<DAE.Type> tys;
      String s1,s2,compType;
      Absyn.Path path;

    case (DAE.T_INTEGER(varLst = vars))
      then List.toString(vars, printVarStr, "Integer", "(", ", ", ")", false);

    case (DAE.T_REAL(varLst = vars))
      then List.toString(vars, printVarStr, "Real", "(", ", ", ")", false);

    case (DAE.T_STRING(varLst = vars))
      then List.toString(vars, printVarStr, "String", "(", ", ", ")", false);

    case (DAE.T_BOOL(varLst = vars))
      then List.toString(vars, printVarStr, "Boolean", "(", ", ", ")", false);

    case (DAE.T_CLOCK(varLst = vars))
      then List.toString(vars, printVarStr, "Clock", "(", ", ", ")", false);

    case (DAE.T_ENUMERATION(literalVarLst = vars))
      then List.toString(vars, printVarStr, "Enumeration", "(", ", ", ")", false);

    case (DAE.T_SUBTYPE_BASIC(complexClassType = st, complexType = t, varLst = vars))
      algorithm
        compType := printTypeStr(t);
        s1 := ClassInfUtil.printStateStr(st);
        s2 := stringDelimitList(List.map(vars, printVarStr),", ");
        str := stringAppendList({"composite(",s1,"{",s2,"}, derived from ", compType, ")"});
      then
        str;

    case (DAE.T_COMPLEX(complexClassType = st,varLst = vars))
      algorithm
        s1 := ClassInfUtil.printStateStr(st);
        s2 := stringDelimitList(List.map(vars, printVarStr),", ");
        str := stringAppendList({"composite(",s1,"{",s2,"})"});
      then
        str;

    case (DAE.T_ARRAY(dims = dims,ty = t))
      algorithm
        s1 := stringDelimitList(List.map(dims, ExpressionBasics.dimensionString), ", ");
        s2 := printTypeStr(t);
        str := stringAppendList({"array(",s2,")[",s1,"]"});
      then
        str;

    case (DAE.T_FUNCTION(funcArg = params,funcResultType = restype))
      algorithm
        s1 := printParamsStr(params);
        s2 := printTypeStr(restype);
        str := stringAppendList({"function(", s1,") => ",s2});
        str := str + AbsynUtil.pathString(inType.path);
      then
        str;

    case (DAE.T_TUPLE(types = tys))
      algorithm
        s1 := stringDelimitList(List.map(tys, printTypeStr),", ");
        str := stringAppendList({"(",s1,")"});
      then
        str;

    // MetaModelica tuple
    case (DAE.T_METATUPLE(types = tys))
      algorithm
        str := printTypeStr(DAE.T_TUPLE(tys,NONE()));
      then
        str;

    // MetaModelica list
    case (DAE.T_METALIST(ty = ty))
      algorithm
        s1 := printTypeStr(ty);
        str := stringAppendList({"list<",s1,">"});
      then
        str;

    // MetaModelica Option
    case (DAE.T_METAOPTION(ty = ty))
      algorithm
        s1 := printTypeStr(ty);
        str := stringAppendList({"Option<",s1,">"});
      then
        str;

    // MetaModelica Array
    case (DAE.T_METAARRAY(ty = ty))
      algorithm
        s1 := printTypeStr(ty);
        str := stringAppendList({"array<",s1,">"});
      then
        str;

    // MetaModelica Boxed
    case (DAE.T_METABOXED(ty = ty))
      algorithm
        s1 := printTypeStr(ty);
        str := stringAppendList({"boxed<",s1,">"});
      then
        str;

    // MetaModelica polymorphic
    case (DAE.T_METAPOLYMORPHIC(name = s1))
      algorithm
        str := stringAppendList({"polymorphic<",s1,">"});
      then
        str;

    // NoType
    case (DAE.T_UNKNOWN())
      algorithm
        str := "T_UNKNOWN";
      then
        str;

    // AnyType of none
    case (DAE.T_ANYTYPE(anyClassType = NONE()))
      algorithm
        str := "ANYTYPE()";
      then
        str;
    // AnyType of some
    case (DAE.T_ANYTYPE(anyClassType = SOME(st)))
      algorithm
        s1 := ClassInfUtil.printStateStr(st);
        str := "ANYTYPE(" + s1 + ")";
      then
        str;

    case (DAE.T_NORETCALL())
      then "()";

    // MetaType
    case (DAE.T_METATYPE(ty = t))
      algorithm
        s1 := printTypeStr(t);
        str := stringAppendList({"METATYPE(", s1, ")"});
      then
        str;

    // Uniontype, Metarecord
    case (t as DAE.T_METARECORD())
      algorithm
        s1 := AbsynUtil.pathStringNoQual(t.path);
        str := "#" + s1 + "#";
      then
        str;
    case (t as DAE.T_METAUNIONTYPE())
      algorithm
        s1 := AbsynUtil.pathStringNoQual(t.path);
        str := "#" + s1 + "#";
      then
        str;

    // Code
    case (DAE.T_CODE(DAE.C_EXPRESSION())) then "$Code(Expression)";
    case (DAE.T_CODE(DAE.C_EXPRESSION_OR_MODIFICATION())) then "$Code(ExpressionOrModification)";
    case (DAE.T_CODE(DAE.C_TYPENAME())) then "$Code(TypeName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAME())) then "$Code(VariableName)";
    case (DAE.T_CODE(DAE.C_VARIABLENAMES())) then "$Code(VariableName[:])";

    // All the other ones we don't handle
    else
      algorithm
        str := "Types.printTypeStr failed";
      then
        str;

  end matchcontinue;
end printTypeStr;

public function printConnectorTypeStr
"Author BZ, 2009-09
 Print the connector-type-name"
  input DAE.Type it;
  output String s "Connector type";
  output String s2 "Components of connector";
algorithm
  (s,s2) := matchcontinue(it)
    local
      ClassInf.State st;
      Absyn.Path connectorName;
      list<DAE.Var> vars;
      list<String> varNames;
      Boolean isExpandable;
      String isExpandableStr;
      Type t;

    case(DAE.T_COMPLEX(complexClassType = (ClassInf.CONNECTOR(connectorName,isExpandable)),varLst = vars))
      algorithm
        varNames := List.map(vars,getVarName);
        isExpandableStr := if isExpandable then "/* expandable */ " else "";
        s := isExpandableStr + AbsynUtil.pathString(connectorName);
        s2 := "{" + stringDelimitList(varNames,", ") + "}";
      then
        (s,s2);

    // TODO! check if we can get T_SUBTYPE_BASIC here??!!
    case(DAE.T_SUBTYPE_BASIC(complexClassType = (ClassInf.CONNECTOR(connectorName,isExpandable)), varLst = vars, complexType = t))
      algorithm
        varNames := List.map(vars,getVarName);
        isExpandableStr := if isExpandable then "/* expandable */ " else "";
        s := isExpandableStr + AbsynUtil.pathString(connectorName);
        s2 := "{" + stringDelimitList(varNames,", ") + "}" + " subtype of: " + printTypeStr(t);
      then
        (s,s2);

    else ("", unparseType(it));
  end matchcontinue;
end printConnectorTypeStr;

public function printParamsStr "Prints function arguments to a string."
  input list<DAE.FuncArg> inFuncArgLst;
  output String str;
algorithm
  str := matchcontinue (inFuncArgLst)
    local
      String n;
      DAE.Type t;
      list<DAE.FuncArg> params;
      String s1,s2;
    case {} then "";
    case {DAE.FUNCARG(name=n,ty=t)}
      algorithm
        s1 := printTypeStr(t);
        str := stringAppendList({n," :: ",s1});
      then
        str;
    case (DAE.FUNCARG(name=n,ty=t)::params)
      algorithm
        s1 := printTypeStr(t);
        s2 := printParamsStr(params);
        str := stringAppendList({n," :: ",s1, " * ",s2});
      then
       str;
  end matchcontinue;
end printParamsStr;

public function unparseVarAttr "
  Prints a variable which is attribute of builtin type to a string, e.g. on the form 'max = 10.0'"
  input DAE.Var inVar;
  output String outString;
algorithm
  outString := matchcontinue (inVar)
    local
      String res,n,bindStr,valStr;
      Values.Value value;
      DAE.Exp e;

    case DAE.TYPES_VAR(name = n, binding = DAE.EQBOUND(exp=e))
      algorithm
        bindStr := ExpressionBasics.printExpStr(e);
        res := stringAppendList({n," = ",bindStr});
      then
        res;
    case DAE.TYPES_VAR(name = n, binding = DAE.VALBOUND(valBound=value))
      algorithm
        valStr := ValuesDump.valString(value);
        res := stringAppendList({n," = ",valStr});
      then
        res;
    else "";
  end matchcontinue;
end unparseVarAttr;

public function unparseVar
"Prints a variable to a string."
  input DAE.Var inVar;
  output String outString;
algorithm
  outString := match (inVar)
    local
      String t,res,n, s;
      DAE.Type typ;
      DAE.ConnectorType ct;

    case DAE.TYPES_VAR(name = n,ty = typ,attributes = DAE.ATTR(connectorType = ct))
      algorithm
        s := connectorTypeStr(ct);
        t := unparseType(typ);
        res := stringAppendList({"  ", s, t," ", n, ";\n"});
      then
        res;

  end match;
end unparseVar;

public function connectorTypeStr
  input DAE.ConnectorType ct;
  output String str;
algorithm
  str := matchcontinue(ct)
    local String s;
    case DAE.POTENTIAL() then "";
    case DAE.FLOW() then "flow ";
    case DAE.STREAM(_) then "stream ";
    else "";
  end matchcontinue;
end connectorTypeStr;

protected function unparseParam "Prints a function argument to a string."
  input DAE.FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      String tstr,res,id,cstr,estr,pstr;
      DAE.Type ty;
      DAE.Const c;
      DAE.VarParallelism p;
      DAE.Exp exp;
    case DAE.FUNCARG(id,ty,c,p,NONE())
      algorithm
        tstr := unparseType(ty);
        cstr := constStrFriendly(c);
        pstr := dumpVarParallelismStr(p);
        res := stringAppendList({tstr," ",cstr,pstr,id});
      then
        res;
    case DAE.FUNCARG(id,ty,c,p,SOME(exp))
      algorithm
        tstr := unparseType(ty);
        cstr := constStrFriendly(c);
        estr := ExpressionBasics.printExpStr(exp);
        pstr := dumpVarParallelismStr(p);
        res := stringAppendList({tstr," ",cstr,pstr,id," := ",estr});
      then
        res;
  end match;
end unparseParam;

public function printVarStr "author: LS
  Prints a Var to the a string."
  input DAE.Var inVar;
  output String str;
algorithm
  str := matchcontinue (inVar)
    local
      String vs,n;
      SCode.Variability var;
      DAE.Type typ;
      DAE.Binding bind;
      String s1,s2;

    case DAE.TYPES_VAR(name = n,attributes = DAE.ATTR(variability = var),ty = typ,binding = bind)
      algorithm
        s1 := printTypeStr(typ);
        vs := SCodeDump.variabilityString(var);
        s2 := printBindingStr(bind);
        str := stringAppendList({s1," ",n," ",vs," ",s2});
      then
        str;
    case DAE.TYPES_VAR(name = n)
      algorithm
        str := stringAppendList({n});
      then
        str;
  end matchcontinue;
end printVarStr;

public function printBindingStr "Print a variable binding to a string."
  input DAE.Binding inBinding;
  output String outString;
algorithm
  outString := match inBinding
    local
      String str,str2,res,v_str,s,str3;
      Values.Value v;

    case DAE.UNBOUND() then "UNBOUND";
    case DAE.EQBOUND(evaluatedExp = NONE())
      algorithm
        str := ExpressionBasics.printExpStr(inBinding.exp);
        str2 := printConstStr(inBinding.constant_);
        str3 := printBindingSourceStr(inBinding.source);
        res := stringAppendList({"DAE.EQBOUND(",str,", NONE(), ",str2,", ",str3,")"});
      then
        res;
    case DAE.EQBOUND(evaluatedExp = SOME(v))
      algorithm
        str := ExpressionBasics.printExpStr(inBinding.exp);
        str2 := printConstStr(inBinding.constant_);
        v_str := ValuesDump.valString(v);
        str3 := printBindingSourceStr(inBinding.source);
        res := stringAppendList({"DAE.EQBOUND(",str,", SOME(",v_str,"), ",str2,", ",str3,")"});
      then
        res;
    case DAE.VALBOUND(valBound = v)
      algorithm
        s := ValuesDump.unparseValues({v});
        str3 := printBindingSourceStr(inBinding.source);
        res := stringAppendList({"DAE.VALBOUND(",s,", ",str3,")"});
      then
        res;
    else
      algorithm
        Error.addInternalError(getInstanceName() + " failed.", sourceInfo());
      then
        fail();
  end match;
end printBindingStr;

public function printFarg "Prints a function argument to the Print buffer."
  input DAE.FuncArg inFuncArg;
algorithm
  _ := match (inFuncArg)
    local
      String n;
      DAE.Type ty;
    case DAE.FUNCARG(name=n,ty=ty)
      algorithm
        Print.printErrorBuf(printTypeStr(ty));
        Print.printErrorBuf(" ");
        Print.printErrorBuf(n);
      then
        ();
  end match;
end printFarg;

public function printFargStr "Prints a function argument to a string"
  input DAE.FuncArg inFuncArg;
  output String outString;
algorithm
  outString := match (inFuncArg)
    local
      String s,res,n,cs,ps;
      DAE.Type ty;
      DAE.Const c;
      DAE.VarParallelism p;

    case DAE.FUNCARG(n,ty,c,_,_)
      algorithm
        s := unparseType(ty);
        cs := constStrFriendly(c);
        // res = stringAppendList({ps,cs,s," ",n});
        res := stringAppendList({cs,s," ",n});
      then
        res;
  end match;
end printFargStr;

public function getTypeName "Return the type name of a Type."
  input DAE.Type inType;
  output String outString;
algorithm
  outString := matchcontinue (inType)
    local
      String n,dimstr,tystr,str;
      ClassInf.State st;
      DAE.Type ty,arrayty;
      list<DAE.Dimension> dims;

    case (DAE.T_INTEGER()) then "Integer";
    case (DAE.T_REAL()) then "Real";
    case (DAE.T_STRING()) then "String";
    case (DAE.T_BOOL()) then "Boolean";
    // BTH
    case (DAE.T_CLOCK()) then "Clock";
    case (DAE.T_COMPLEX(complexClassType = st))
      algorithm
        n := AbsynUtil.pathString(ClassInfUtil.getStateName(st));
      then
        n;
    case (DAE.T_SUBTYPE_BASIC(complexClassType = st))
      algorithm
        n := AbsynUtil.pathString(ClassInfUtil.getStateName(st));
      then
        n;
    case (arrayty as DAE.T_ARRAY())
      algorithm
        (ty,dims) := flattenArrayType(arrayty);
        dimstr := ExpressionBasics.dimensionsString(dims);
        tystr := getTypeName(ty);
        str := stringAppendList({tystr,"[",dimstr,"]"});
      then
        str;

    // MetaModelica type
    case (DAE.T_METALIST(ty = ty))
      algorithm
        n := getTypeName(ty);
      then
        n;

    else "Not nameable type or no type";
  end matchcontinue;
end getTypeName;

function constStrFriendly "return the DAE.Const as a friendly string. Used for debugging."
  input DAE.Const const;
  output String str;
algorithm
  str := match(const)
    case(DAE.C_VAR()) then "";
    case(DAE.C_PARAM()) then "parameter ";
    case(DAE.C_CONST()) then "constant ";

  end match;
end constStrFriendly;

function dumpVarParallelismStr "Dump VarParallelism to a string"
  input DAE.VarParallelism inVarParallelism;
  output String outString;
algorithm
  outString := match (inVarParallelism)
    case DAE.NON_PARALLEL() then "";
    case DAE.PARGLOBAL() then "parglobal ";
    case DAE.PARLOCAL() then "parlocal ";
  end match;
end dumpVarParallelismStr;

function printBindingSourceStr "prints a binding source as a string"
  input DAE.BindingSource bindingSource;
  output String str;
algorithm
  str := match(bindingSource)
    case(DAE.BINDING_FROM_DEFAULT_VALUE())       then "[DEFAULT VALUE]";
    case(DAE.BINDING_FROM_START_VALUE())         then "[START VALUE]";
    case(DAE.BINDING_FROM_RECORD_SUBMODS())      then "[RECORD SUBMODS]";
    case(DAE.BINDING_FROM_DERIVED_RECORD_DECL()) then "[DERIVED RECORD]";
  end match;
end printBindingSourceStr;

public function flattenArrayType
  "Returns the element type of a Type and the dimensions of the type."
  input DAE.Type inType;
  output DAE.Type outType;
  output DAE.Dimensions outDimensions;
algorithm
  (outType, outDimensions) := match inType
    local
      Type ty;
      DAE.Dimensions dims;
      DAE.Dimension dim;

    // Array type
    case DAE.T_ARRAY()
      algorithm
        (ty, dims) := flattenArrayType(inType.ty);
        dims := listAppend(inType.dims, dims);
      then
        (ty, dims);

    // Complex type extending basetype with equality constraint
    case DAE.T_SUBTYPE_BASIC(equalityConstraint = SOME(_))
      then (inType, {});

    // Complex type extending basetype.
    case DAE.T_SUBTYPE_BASIC()
      then flattenArrayType(inType.complexType);

    // Element type
    else (inType, {});
  end match;
end flattenArrayType;

public function getVarName "Return the name of a Var"
  input DAE.Var v;
  output String name;
algorithm
  name := match (v)
    case(DAE.TYPES_VAR(name = name)) then name;
  end match;
end getVarName;

public function stripTypeVars
  "Strips the attribute variables from a type, and returns both the stripped
   type and the attribute variables."
  input DAE.Type inType;
  output DAE.Type outType;
  output list<DAE.Var> outVars;
algorithm
  (outType, outVars) := match(inType)
    local
      list<DAE.Var> vars, sub_vars;
      DAE.Type ty;
      DAE.Dimensions dims;
      ClassInf.State state;
      EqualityConstraint ec;
      list<DAE.Type> tys;

    case DAE.T_INTEGER(varLst=vars) then (DAE.T_INTEGER_DEFAULT, vars);
    case DAE.T_REAL(varLst=vars) then (DAE.T_REAL_DEFAULT, vars);
    case DAE.T_STRING(varLst=vars)  then (DAE.T_STRING_DEFAULT, vars);
    case DAE.T_BOOL(varLst=vars)    then (DAE.T_BOOL_DEFAULT, vars);
    case DAE.T_TUPLE(tys, _) then (DAE.T_TUPLE(tys, NONE()), {});

    case DAE.T_ARRAY(ty, dims)
      algorithm
        (ty, vars) := stripTypeVars(ty);
      then
        (DAE.T_ARRAY(ty, dims), vars);

    case DAE.T_SUBTYPE_BASIC(state, sub_vars, ty, ec)
      algorithm
        (ty, vars) := stripTypeVars(ty);
      then
        (DAE.T_SUBTYPE_BASIC(state, sub_vars, ty, ec), vars);

    else (inType, {});

  end match;
end stripTypeVars;

public function printDimensionsStr "Prints dimensions to a string"
  input DAE.Dimensions dims;
  output String res;
algorithm
  res:=stringDelimitList(List.map(dims,ExpressionBasics.dimensionString),", ");
end printDimensionsStr;

public function printCodeTypeStr
  input DAE.CodeType ct;
  output String str;
algorithm
  str := match ct
    case DAE.C_EXPRESSION() then "OpenModelica.Code.Expression";
    case DAE.C_EXPRESSION_OR_MODIFICATION() then "OpenModelica.Code.ExpressionOrModification";
    case DAE.C_MODIFICATION() then "OpenModelica.Code.Modification";
    case DAE.C_TYPENAME() then "OpenModelica.Code.TypeName";
    case DAE.C_VARIABLENAME() then "OpenModelica.Code.VariableName";
    case DAE.C_VARIABLENAMES() then "OpenModelica.Code.VariableNames";
    else "Types.printCodeTypeStr failed";
  end match;
end printCodeTypeStr;

annotation(__OpenModelica_Interface="frontend_dump");
end TypesDump;
