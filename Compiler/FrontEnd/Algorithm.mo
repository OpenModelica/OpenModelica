/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Algorithm
"
  file:        Algorithm.mo
  package:     Algorithm
  description: Algorithm datatypes


  This file contains data types and functions for managing
  algorithm sections. The algorithms in the AST are analyzed by the `Inst\'
  module (Inst.mo) which uses this module to represent the algorithms. No
  processing of any kind, except for building the datastructure is
  done in this module.

  It is used primarily by Inst.mo which both provides its input data
  and uses its \"output\" data.

"

public import Absyn;
public import DAE;
public import SCode;

protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import SCodeDump;
protected import Types;
protected import Util;

public function algorithmEmpty "Returns true if algorithm is empty, i.e. no statements"
  input DAE.Algorithm alg;
  output Boolean empty;
algorithm
  empty := match(alg)
    case(DAE.ALGORITHM_STMTS({})) then true;
    else false;
  end match;
end algorithmEmpty;

public function isReinitStatement "returns true if statement is a reinit"
  input DAE.Statement stmt;
  output Boolean res;
algorithm
  res := match(stmt)
    case(DAE.STMT_REINIT()) then true;
    else false;
  end match;
end isReinitStatement;

public function isNotAssertStatement "returns true if statement is NOT an assert"
  input DAE.Statement stmt;
  output Boolean res;
algorithm
  res := match(stmt)
    case(DAE.STMT_ASSERT()) then false;
    else true;
  end match;
end isNotAssertStatement;

public function makeAssignmentNoTypeCheck
"Used to optimize assignments to NORETCALL if applicable"
  input DAE.Type ty;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := match (ty,lhs,rhs,source)
    case (_,DAE.CREF(componentRef=DAE.WILD()),_,_)
      then DAE.STMT_NORETCALL(rhs, source);
    case (_,DAE.PATTERN(pattern=DAE.PAT_WILD()),_,_)
      then DAE.STMT_NORETCALL(rhs, source);
    else DAE.STMT_ASSIGN(ty, lhs, rhs, source);
  end match;
end makeAssignmentNoTypeCheck;

public function makeArrayAssignmentNoTypeCheck
"Used to optimize assignments to NORETCALL if applicable"
  input DAE.Type ty;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := match (ty,lhs,rhs,source)
    case (_,DAE.CREF(DAE.WILD()),_,_)
      then DAE.STMT_NORETCALL(rhs, source);
    else DAE.STMT_ASSIGN_ARR(ty, lhs, rhs, source);
  end match;
end makeArrayAssignmentNoTypeCheck;

public function makeTupleAssignmentNoTypeCheck
"Used to optimize assignments to NORETCALL if applicable"
  input DAE.Type ty;
  input list<DAE.Exp> lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
protected
  Boolean b1,b2;
algorithm
  b1 := List.fold(List.map(lhs, Expression.isWild), boolAnd, true);
  b2 := List.fold(List.map(List.restOrEmpty(lhs), Expression.isWild), boolAnd, true);
  outStatement := makeTupleAssignmentNoTypeCheck2(b1,b2,ty,lhs,rhs,source);
end makeTupleAssignmentNoTypeCheck;

protected function makeTupleAssignmentNoTypeCheck2
  input Boolean allWild;
  input Boolean singleAssign;
  input DAE.Type ty;
  input list<DAE.Exp> lhs;
  input DAE.Exp rhs;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := match (allWild,singleAssign,ty,lhs,rhs,source)
    local
      DAE.Type ty1;
      DAE.Exp lhs1;
      DAE.ComponentRef cr;
    case (true,_,_,_,_,_) then DAE.STMT_NORETCALL(rhs, source);
    case (_,true,DAE.T_TUPLE(types=(ty1 as DAE.T_ARRAY())::_),lhs1::_,_,_)
      then DAE.STMT_ASSIGN_ARR(ty1, lhs1, DAE.TSUB(rhs, 1, ty1), source);
    case (_,true,DAE.T_TUPLE(types=ty1::_),lhs1::_,_,_)
      then DAE.STMT_ASSIGN(ty1, lhs1, DAE.TSUB(rhs,1,ty1), source);
    else DAE.STMT_TUPLE_ASSIGN(ty,lhs,rhs,source);
  end match;
end makeTupleAssignmentNoTypeCheck2;

public function makeAssignment
"This function creates an `DAE.STMT_ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match.
  LS: Added call to getPropType and isPropAnyConst instead of
  having PROP in the rules. Otherwise rules must be repeated because of
  combinations with PROP_TUPLE"
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input DAE.Exp inExp3;
  input DAE.Properties inProperties4;
  input DAE.Attributes inAttributes;
  input SCode.Initial initial_;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := matchcontinue (inExp1, inProperties2, inExp3, inProperties4, inAttributes, initial_, source)
    local
      String lhs_str, rhs_str, lt_str, rt_str;
      DAE.Exp lhs, rhs;
      DAE.Properties lprop, rprop, lhprop, rhprop;
      DAE.ComponentRef cr;
      DAE.Type lt, rt;
      Absyn.Direction direction;
      SourceInfo info;

    case ((DAE.CREF(componentRef=DAE.WILD())), _, rhs, _, _, _, _)
      then DAE.STMT_NORETCALL(rhs, source);

    // assign to parameter in algorithm okay if record
    case ((lhs as DAE.CREF(componentRef=cr)), lhprop, rhs, rhprop, _, SCode.NON_INITIAL(), _)
      equation
        DAE.C_PARAM() = Types.propAnyConst(lhprop);
        true = ComponentReference.isRecord(cr);
        outStatement = makeAssignment2(lhs, lhprop, rhs, rhprop, source);
      then outStatement;

    // assign to parameter in algorithm produce error
    case (lhs, lprop, rhs, _, _, SCode.NON_INITIAL(), _)
      equation
        DAE.C_PARAM() = Types.propAnyConst(lprop);
        lhs_str = ExpressionDump.printExpStr(lhs);
        rhs_str = ExpressionDump.printExpStr(rhs);
        Error.addSourceMessage(Error.ASSIGN_PARAM_ERROR, {lhs_str, rhs_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

    // assignment to a constant, report error
    case (lhs, _, _, _, DAE.ATTR(variability = SCode.CONST()), _, _)
      equation
        lhs_str = ExpressionDump.printExpStr(lhs);
        Error.addSourceMessage(Error.ASSIGN_READONLY_ERROR, {"constant", lhs_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

    // assignment to parameter ok in initial algorithm
    case (lhs, lhprop, rhs, rhprop, _, SCode.INITIAL(), _)
      equation
        DAE.C_PARAM() = Types.propAnyConst(lhprop);
        outStatement = makeAssignment2(lhs, lhprop, rhs, rhprop, source);
      then outStatement;

    case (lhs, lhprop, rhs, rhprop, DAE.ATTR(), _, _)
      equation
        DAE.C_VAR() = Types.propAnyConst(lhprop);
        outStatement = makeAssignment2(lhs, lhprop, rhs, rhprop, source);
      then outStatement;

    /* report an error */
    case (lhs, lprop, rhs, rprop, _, _, _)
      equation
        lt = Types.getPropType(lprop);
        rt = Types.getPropType(rprop);
        false = Types.equivtypes(lt, rt);
        lhs_str = ExpressionDump.printExpStr(lhs);
        rhs_str = ExpressionDump.printExpStr(rhs);
        lt_str = Types.unparseTypeNoAttr(lt);
        rt_str = Types.unparseTypeNoAttr(rt);
        info = DAEUtil.getElementSourceFileInfo(source);
        Types.typeErrorSanityCheck(lt_str, rt_str, info);
        Error.addSourceMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,
          {lhs_str, rhs_str, lt_str, rt_str}, info);
      then
        fail();

     /* failing */
    case (lhs, _, rhs, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- Algorithm.makeAssignment failed");
        Debug.trace("    ");
        Debug.trace(ExpressionDump.printExpStr(lhs));
        Debug.trace(" := ");
        Debug.traceln(ExpressionDump.printExpStr(rhs));
      then
        fail();
  end matchcontinue;
end makeAssignment;

protected function makeAssignment2
"Help function to makeAssignment"
  input DAE.Exp lhs;
  input DAE.Properties lhprop;
  input DAE.Exp rhs;
  input DAE.Properties rhprop;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := match (lhs, lhprop, rhs, rhprop, source)
    local
      DAE.ComponentRef c;
      DAE.Exp rhs_1, e3, e1;
      DAE.Type t, ty;
      list<DAE.Exp> ea2;

    case (DAE.CREF(), _, _, _, _) guard not Types.isPropArray(lhprop)
      equation
        (rhs_1, _) = Types.matchProp(rhs, rhprop, lhprop, true);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t, lhs, rhs_1, source);
        /* TODO: Use this when we have fixed states in BackendDAE .lower(...)
        case (e1 as DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(_, _)}, _, _, _), lhprop, rhs, rhprop)
      equation
        (rhs_1, _) = Types.matchProp(rhs, rhprop, lhprop);
        false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t, e1, rhs_1);
      */
    case (DAE.CREF(), _, _, _, _) // guard Types.isPropArray(lhprop)
      equation
        (rhs_1, _) = Types.matchProp(rhs, rhprop, lhprop, false /* Don't duplicate errors */);
        ty = Types.getPropType(lhprop);
        t = Types.simplifyType(ty);
      then
        DAE.STMT_ASSIGN_ARR(t, lhs, rhs_1, source);

    case(e3 as DAE.ASUB(_, _), _, _, _, _)
      equation
        (rhs_1, _) = Types.matchProp(rhs, rhprop, lhprop, true);
        //false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t, e3, rhs_1, source);
  end match;
end makeAssignment2;

public function makeSimpleAssignment
  input tuple<DAE.Exp, DAE.Exp> inTpl;
  input DAE.ElementSource source;
  output DAE.Statement outStmt;
protected
  DAE.Exp e1, e2;
  DAE.Type tp;
algorithm
  (e1 as DAE.CREF(ty=tp), e2) := inTpl;
  outStmt := DAE.STMT_ASSIGN(tp, e1, e2, source);
end makeSimpleAssignment;

public function makeAssignmentsList
  input list<DAE.Exp> lhsExps;
  input list<DAE.Properties> lhsProps;
  input list<DAE.Exp> rhsExps;
  input list<DAE.Properties> rhsProps;
  input DAE.Attributes attributes;
  input SCode.Initial initial_;
  input DAE.ElementSource source;
  output list<DAE.Statement> assignments;
algorithm
  assignments := match(lhsExps, lhsProps, rhsExps, rhsProps, attributes, initial_, source)
    local
      DAE.Exp lhs, rhs;
      list<DAE.Exp> rest_lhs, rest_rhs;
      DAE.Properties lhs_prop, rhs_prop;
      list<DAE.Properties> rest_lhs_prop, rest_rhs_prop;
      DAE.Statement ass;
      list<DAE.Statement> rest_ass;
    case ({}, {}, _, _, _, _, _) then {}; /* rhs does not need to be empty */
    case (DAE.CREF(componentRef=DAE.WILD()) :: rest_lhs, _ :: rest_lhs_prop, _ :: rest_rhs, _ :: rest_rhs_prop, _, _, _)
      then makeAssignmentsList(rest_lhs, rest_lhs_prop, rest_rhs, rest_rhs_prop, attributes, initial_, source);
    case (lhs :: rest_lhs, lhs_prop :: rest_lhs_prop,
          rhs :: rest_rhs, rhs_prop :: rest_rhs_prop, _, _, _)
      equation
        ass = makeAssignment(lhs, lhs_prop, rhs, rhs_prop, attributes, initial_, source);
        rest_ass = makeAssignmentsList(rest_lhs, rest_lhs_prop, rest_rhs, rest_rhs_prop, attributes, initial_, source);
      then
        ass :: rest_ass;
  end match;
end makeAssignmentsList;

public function makeTupleAssignment "This function creates an `DAE.STMT_TUPLE_ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input SCode.Initial initial_;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := matchcontinue (inExpExpLst, inTypesPropertiesLst, inExp, inProperties, initial_, source)
    local
      list<DAE.Const> bvals;
      list<String> sl;
      String s, lhs_str, rhs_str, str1, str2, strInitial;
      list<DAE.Exp> lhs, expl;
      list<DAE.Properties> lprop, lhprops;
      DAE.Exp rhs;
      DAE.Properties rprop;
      list<DAE.Type> lhrtypes, tpl;
      list<DAE.TupleConst> clist;
      DAE.Type ty;

    case (lhs, lprop, rhs, _, _, _)
      equation
        bvals = List.map(lprop, Types.propAnyConst);
        DAE.C_CONST() = List.reduce(bvals, Types.constOr);
        sl = List.map(lhs, ExpressionDump.printExpStr);
        s = stringDelimitList(sl, ", ");
        lhs_str = stringAppendList({"(", s, ")"});
        rhs_str = ExpressionDump.printExpStr(rhs);
        Error.addSourceMessage(Error.ASSIGN_CONSTANT_ERROR, {lhs_str, rhs_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
    case (lhs, lprop, rhs, _, SCode.NON_INITIAL(), _)
      equation
        bvals = List.map(lprop, Types.propAnyConst);
        DAE.C_PARAM() = List.reduce(bvals, Types.constOr);
        sl = List.map(lhs, ExpressionDump.printExpStr);
        s = stringDelimitList(sl, ", ");
        lhs_str = stringAppendList({"(", s, ")"});
        rhs_str = ExpressionDump.printExpStr(rhs);
        Error.addSourceMessage(Error.ASSIGN_PARAM_ERROR, {lhs_str, rhs_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
    // a normal prop in rhs that contains a T_TUPLE!
    case (expl, lhprops, rhs, DAE.PROP(type_ = ty as DAE.T_TUPLE(types = tpl)), _, _)
      equation
        bvals = List.map(lhprops, Types.propAnyConst);
        DAE.C_VAR() = List.reduce(bvals, Types.constOr);
        lhrtypes = List.map(lhprops, Types.getPropType);
        Types.matchTypeTupleCall(rhs, tpl, lhrtypes);
         /* Don\'t use new rhs\', since type conversions of
            several output args are not clearly defined. */
      then makeTupleAssignmentNoTypeCheck(ty, expl, rhs, source);
    // a tuple in rhs
    case (expl, lhprops, rhs, DAE.PROP_TUPLE(type_ = ty as DAE.T_TUPLE(types = tpl), tupleConst = DAE.TUPLE_CONST()), _, _)
      equation
        bvals = List.map(lhprops, Types.propAnyConst);
        DAE.C_VAR() = List.reduce(bvals, Types.constOr);
        lhrtypes = List.map(lhprops, Types.getPropType);
        Types.matchTypeTupleCall(rhs, tpl, lhrtypes);
         /* Don\'t use new rhs\', since type conversions of several output args are not clearly defined. */
      then makeTupleAssignmentNoTypeCheck(ty, expl, rhs, source);
    case (lhs, lprop, rhs, rprop, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        sl = List.map(lhs, ExpressionDump.printExpStr);
        s = stringDelimitList(sl, ", ");
        lhs_str = stringAppendList({"(", s, ")"});
        rhs_str = ExpressionDump.printExpStr(rhs);
        str1 = stringDelimitList(List.map(lprop, Types.printPropStr), ", ");
        str2 = Types.printPropStr(rprop);
        strInitial = SCodeDump.printInitialStr(initial_);
        Debug.traceln("- Algorithm.makeTupleAssignment failed on: \n\t" +
          lhs_str + " = " + rhs_str +
          "\n\tprops lhs: (" + str1 + ") =  props rhs: " + str2 +
          "\n\tin " + strInitial + " section");
      then
        fail();
  end matchcontinue;
end makeTupleAssignment;

protected function getPropExpType "Returns the expression type for a given Properties by calling
  getTypeExpType. Used by makeAssignment."
  input DAE.Properties p;
  output DAE.Type t;
protected
  DAE.Type ty;
algorithm
  ty := Types.getPropType(p);
  t := Types.simplifyType(ty);
end getPropExpType;

public function makeIf "This function creates an `DAE.STMT_IF\' construct, checking that the types
  of the parts are correct. Else part is generated using the makeElse
  function."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<DAE.Statement> inTrueBranch;
  input list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> inElseIfBranches;
  input list<DAE.Statement> inElseBranch;
  input DAE.ElementSource source;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements :=
  matchcontinue (inExp, inProperties, inTrueBranch, inElseIfBranches, inElseBranch, source)
    local
      DAE.Else else_;
      DAE.Exp e;
      list<DAE.Statement> tb, fb;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> eib;
      String e_str, t_str;
      DAE.Type t;
      DAE.Properties prop;
    case (DAE.BCONST(true), _, tb, _, _, _)
      then tb;
    case (DAE.BCONST(false), _, _, {}, fb, _)
      then fb;
    case (DAE.BCONST(false), _, _, (e, prop, tb)::eib, fb, _)
      then makeIf(e, prop, tb, eib, fb, source);
    case (e, DAE.PROP(type_ = t), tb, eib, fb, _)
      equation
        (e, _) = Types.matchType(e, t, DAE.T_BOOL_DEFAULT, true);
        else_ = makeElse(eib, fb, source);
      then
        {DAE.STMT_IF(e, tb, else_, source)};
    case (e, DAE.PROP(type_ = t), _, _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str, t_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end makeIf;

public function makeIfFromBranches "
  Create an if-statement from branches, optimizing as needed."
  input list<tuple<DAE.Exp, list<DAE.Statement>>> branches;
  input DAE.ElementSource source;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := match (branches, source)
    local
      DAE.Else else_;
      DAE.Exp e;
      list<DAE.Statement> br;
      list<tuple<DAE.Exp, list<DAE.Statement>>> rest;
    case ({}, _) then {};
    case ((e, br)::rest, _)
      equation
        else_ = makeElseFromBranches(rest);
      then {DAE.STMT_IF(e, br, else_, source)};
  end match;
end makeIfFromBranches;

protected function makeElseFromBranches "Creates the ELSE part of the DAE.STMT_IF."
  input list<tuple<DAE.Exp, list<DAE.Statement>>> inTpl;
  output DAE.Else outElse;
algorithm
  outElse := match inTpl
    local
      list<DAE.Statement> b;
      DAE.Else else_;
      DAE.Exp e;
      list<tuple<DAE.Exp, list<DAE.Statement>>> xs;
    case {} then DAE.NOELSE();
    case {(DAE.BCONST(true), b)} then DAE.ELSE(b);
    case ((e, b)::xs)
      equation
        else_ = makeElseFromBranches(xs);
      then DAE.ELSEIF(e, b, else_);
  end match;
end makeElseFromBranches;

public function optimizeIf
  "Every time we re-create/walk an if-statement, we optimize a bit :)"
  input DAE.Exp icond;
  input list<DAE.Statement> istmts;
  input DAE.Else iels;
  input DAE.ElementSource isource;
  output list<DAE.Statement> ostmts "can be empty or selected branch";
  output Boolean changed;
algorithm
  (ostmts,changed) := match (icond, istmts, iels, isource)
    local
      list<DAE.Statement> stmts;
      DAE.Else els;
      DAE.ElementSource source;
      DAE.Exp cond;

    case (DAE.BCONST(true), stmts, _, _) then (stmts,true);
    case (DAE.BCONST(false), _, DAE.NOELSE(), _) then ({},true);
    case (DAE.BCONST(false), _, DAE.ELSE(stmts), _) then (stmts,true);
    case (DAE.BCONST(false), _, DAE.ELSEIF(cond, stmts, els), source) equation (ostmts,_) = optimizeIf(cond, stmts, els, source); then (ostmts,true);
    else (DAE.STMT_IF(icond, istmts, iels, isource)::{},false);
  end match;
end optimizeIf;

public function optimizeElseIf
  "Every time we re-create/walk an if-statement, we optimize a bit :)"
  input DAE.Exp cond;
  input list<DAE.Statement> stmts;
  input DAE.Else els;
  output DAE.Else oelse;
algorithm
  oelse := match (cond, stmts, els)
    case (DAE.BCONST(true), _, _) then DAE.ELSE(stmts);
    case (DAE.BCONST(false), _, _) then els;
    else DAE.ELSEIF(cond, stmts, els);
  end match;
end optimizeElseIf;

protected function makeElse "This function creates the ELSE part of the DAE.STMT_IF and checks if is correct."
  input list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> inTuple;
  input list<DAE.Statement> inStatementLst;
  input DAE.ElementSource inSource;
  output DAE.Else outElse;
algorithm
  outElse := matchcontinue(inTuple, inStatementLst, inSource)
    local
      list<DAE.Statement> fb, b;
      DAE.Else else_;
      DAE.Exp e;
      list<tuple<DAE.Exp, DAE.Properties, list<DAE.Statement>>> xs;
      String e_str, t_str;
      DAE.Type t;
      SourceInfo info;

    case ({}, {}, _) then DAE.NOELSE();  /* This removes empty else branches */
    case ({}, fb, _) then DAE.ELSE(fb);
    case (((DAE.BCONST(true), DAE.PROP(), b) :: _), _, _) then DAE.ELSE(b);
    case (((DAE.BCONST(false), DAE.PROP(), _) :: xs), fb, _) then makeElse(xs, fb, inSource);
    case (((e, DAE.PROP(type_ = t), b) :: xs), fb, _)
      equation
        (e, _) = Types.matchType(e, t, DAE.T_BOOL_DEFAULT, true);
        else_ = makeElse(xs, fb, inSource);
      then
        DAE.ELSEIF(e, b, else_);
    case (((e, DAE.PROP(type_ = t), _) :: _), _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        info = DAEUtil.getElementSourceFileInfo(inSource);
        Error.addSourceMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str, t_str}, info);
      then
        fail();
  end matchcontinue;
end makeElse;

public function makeFor "This function creates a DAE.STMT_FOR construct, checking
  that the types of the parts are correct."
  input String inIdent;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<DAE.Statement> inStatementLst;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := matchcontinue (inIdent, inExp, inProperties, inStatementLst, source)
    local
      Boolean isArray;
      DAE.Type et;
      String i, e_str, t_str;
      DAE.Exp e;
      DAE.Type t;
      list<DAE.Statement> stmts;
      DAE.Dimensions dims;

    case (i, e, DAE.PROP(type_ = DAE.T_ARRAY(ty = t, dims = dims)), stmts, _)
      equation
        isArray = Types.isNonscalarArray(t, dims);
      then DAE.STMT_FOR(t, isArray, i, -1, e, stmts, source);

    case (i, e, DAE.PROP(type_ = DAE.T_METALIST(ty = t)), stmts, _)
      equation
        t = Types.simplifyType(t);
      then DAE.STMT_FOR(t, false, i, -1, e, stmts, source);

    case (i, e, DAE.PROP(type_ = DAE.T_METAARRAY(ty = t)), stmts, _)
      equation
        t = Types.simplifyType(t);
      then DAE.STMT_FOR(t, false, i, -1, e, stmts, source);

    case (_, e, DAE.PROP(type_ = t), _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        Error.addSourceMessage(Error.FOR_EXPRESSION_TYPE_ERROR, {e_str, t_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end makeFor;

public function makeParFor "This function creates a DAE.STMT_PARFOR construct, checking
  that the types of the parts are correct."
  input String inIdent;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<DAE.Statement> inStatementLst;
  input list<tuple<DAE.ComponentRef, SourceInfo>> inLoopPrlVars;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement := matchcontinue (inIdent, inExp, inProperties, inStatementLst, inLoopPrlVars, source)
    local
      Boolean isArray;
      DAE.Type et;
      String i, e_str, t_str;
      DAE.Exp e;
      DAE.Type t;
      list<DAE.Statement> stmts;
      DAE.Dimensions dims;

    case (i, e, DAE.PROP(type_ = DAE.T_ARRAY(ty = t, dims = dims)), stmts, _, _)
      equation
        isArray = Types.isNonscalarArray(t, dims);
        _ = Types.simplifyType(t);
      then
        DAE.STMT_PARFOR(t, isArray, i, -1, e, stmts, inLoopPrlVars, source);

    case (_, e, DAE.PROP(type_ = t), _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        Error.addSourceMessage(Error.FOR_EXPRESSION_TYPE_ERROR, {e_str, t_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end makeParFor;

public function makeWhile "This function creates a DAE.STMT_WHILE construct, checking that the types
  of the parts are correct."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<DAE.Statement> inStatementLst;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp, inProperties, inStatementLst, source)
    local
      DAE.Exp e;
      list<DAE.Statement> stmts;
      String e_str, t_str;
      DAE.Type t;
    case (e, DAE.PROP(type_ = DAE.T_BOOL()), stmts, _) then DAE.STMT_WHILE(e, stmts, source);
    case (e, DAE.PROP(type_ = t), _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        Error.addSourceMessage(Error.WHILE_CONDITION_TYPE_ERROR, {e_str, t_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end makeWhile;

public function makeWhenA "This function creates a DAE.STMT_WHEN algorithm construct,
  checking that the types of the parts are correct."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<DAE.Statement> inStatementLst;
  input Option<DAE.Statement> elseWhenStmt;
  input DAE.ElementSource source;
  output DAE.Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp, inProperties, inStatementLst, elseWhenStmt, source)
    local
      DAE.Exp e;
      list<DAE.Statement> stmts;
      Option<DAE.Statement> elsew;
      String e_str, t_str;
      DAE.Type t;
    case (e, DAE.PROP(type_ = DAE.T_BOOL()), stmts, elsew, _) then DAE.STMT_WHEN(e, {}, false, stmts, elsew, source);
    case (e, DAE.PROP(type_ = DAE.T_ARRAY(ty = DAE.T_BOOL())), stmts, elsew, _) then DAE.STMT_WHEN(e, {}, false, stmts, elsew, source);
    case (e, DAE.PROP(type_ = t), _, _, _)
      equation
        e_str = ExpressionDump.printExpStr(e);
        t_str = Types.unparseTypeNoAttr(t);
        Error.addSourceMessage(Error.WHEN_CONDITION_TYPE_ERROR, {e_str, t_str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end makeWhenA;

public function makeReinit " creates a reinit statement in an algorithm
 statement, only valid in when algorithm sections."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Properties inProperties3;
  input DAE.Properties inProperties4;
  input DAE.ElementSource source;
  output list<DAE.Statement> outStatement;
algorithm
  outStatement := matchcontinue (inExp1, inExp2, inProperties3, inProperties4)
    local
      DAE.Exp var, val, var_1, val_1;
      DAE.Properties prop1, prop2;
      DAE.Type tp1, tp2;

    case (var as DAE.CREF(), val, DAE.PROP(tp1, _), DAE.PROP(tp2, _))
      equation
        val_1 = Types.matchType(val, tp2, DAE.T_REAL_DEFAULT, true);
        var_1 = Types.matchType(var, tp1, DAE.T_REAL_DEFAULT, true);
      then
        {DAE.STMT_REINIT(var_1, val_1, source)};

    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"reinit called with wrong args"}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();

  // TODO: Add checks for reinit here. 1. First argument must be variable. 2. Expressions must be real.
  end matchcontinue;
end makeReinit;

public function makeAssert "Creates an assert statement from two expressions.
"
  input DAE.Exp cond "condition";
  input DAE.Exp msg "message";
  input DAE.Exp level;
  input DAE.Properties inProperties3;
  input DAE.Properties inProperties4;
  input DAE.Properties inProperties5;
  input DAE.ElementSource source;
  output list<DAE.Statement> outStatement;
algorithm
  outStatement := matchcontinue (cond, msg, level, inProperties3, inProperties4, inProperties5, source)
    local
      SourceInfo info;
      DAE.Type t1, t2, t3;
      String strTy, strExp;
    case (DAE.BCONST(true), _, _, DAE.PROP(type_ = DAE.T_BOOL()), DAE.PROP(type_ = DAE.T_STRING()), DAE.PROP(type_ = DAE.T_ENUMERATION(path=Absyn.FULLYQUALIFIED(Absyn.IDENT("AssertionLevel")))), _)
      then {};
    case (_, _, _, DAE.PROP(type_ = DAE.T_BOOL()), DAE.PROP(type_ = DAE.T_STRING()), DAE.PROP(type_ = DAE.T_ENUMERATION(path=Absyn.FULLYQUALIFIED(Absyn.IDENT("AssertionLevel")))), _)
      then {DAE.STMT_ASSERT(cond, msg, level, source)};
    case (_, _, _, DAE.PROP(type_ = t1), DAE.PROP(type_ = t2), DAE.PROP(type_ = t3), _)
      equation
        info = DAEUtil.getElementSourceFileInfo(source);
        strExp = ExpressionDump.printExpStr(cond);
        strTy = Types.unparseType(t1);
        Error.assertionOrAddSourceMessage(Types.isBooleanOrSubTypeBoolean(t1), Error.EXP_TYPE_MISMATCH, {strExp, "Boolean", strTy}, info);
        strExp = ExpressionDump.printExpStr(msg);
        strTy = Types.unparseType(t2);
        Error.assertionOrAddSourceMessage(Types.isString(t2), Error.EXP_TYPE_MISMATCH, {strExp, "String", strTy}, info);
        failure(DAE.T_ENUMERATION(path=Absyn.IDENT("AssertionLevel")) = t3);
        strExp = ExpressionDump.printExpStr(level);
        strTy = Types.unparseType(t3);
        Error.assertionOrAddSourceMessage(Types.isString(t3), Error.EXP_TYPE_MISMATCH, {strExp, "AssertionLevel", strTy}, info);
      then fail();
  end matchcontinue;
end makeAssert;

public function makeTerminate "
  Creates a terminate statement from message expression.
"
  input DAE.Exp msg "message";
  input DAE.Properties props;
  input DAE.ElementSource source;
  output list<DAE.Statement> outStatement;
algorithm
  outStatement := match (msg, props, source)
    case (_, DAE.PROP(type_ = DAE.T_STRING()), _) then {DAE.STMT_TERMINATE(msg, source)};
  end match;
end makeTerminate;

public function getCrefFromAlg "Returns all crefs from an algorithm"
  input DAE.Algorithm alg;
  output list<DAE.ComponentRef> crs;
algorithm
  crs := List.unionOnTrueList(List.map(getAllExps(alg), Expression.extractCrefsFromExp), ComponentReference.crefEqual);
end getCrefFromAlg;


public function getAllExps "
  This function goes through the Algorithm structure and finds all the
  expressions and returns them in a list
"
  input DAE.Algorithm inAlgorithm;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  match (inAlgorithm)
    local
      list<DAE.Exp> exps;
      list<DAE.Statement> stmts;
    case DAE.ALGORITHM_STMTS(statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
  end match;
end getAllExps;

public function getAllExpsStmts "
  This function takes a list of statements and returns all expressions and subexpressions
  in all statements.
"
  input list<DAE.Statement> stmts;
  output list<DAE.Exp> exps;
algorithm
  (_, (_,exps)) := DAEUtil.traverseDAEEquationsStmts(stmts, Expression.traverseSubexpressionsHelper, (Expression.expressionCollector, {}));
end getAllExpsStmts;

public function getStatementSource
  input DAE.Statement stmt;
  output DAE.ElementSource source;
algorithm
  source := match stmt
    case DAE.STMT_ASSIGN(source=source) then source;
    case DAE.STMT_TUPLE_ASSIGN(source=source) then source;
    case DAE.STMT_ASSIGN_ARR(source=source) then source;
    case DAE.STMT_IF(source=source) then source;
    case DAE.STMT_FOR(source=source) then source;
    case DAE.STMT_PARFOR(source=source) then source;
    case DAE.STMT_WHILE(source=source) then source;
    case DAE.STMT_WHEN(source=source) then source;
    case DAE.STMT_ASSERT(source=source) then source;
    case DAE.STMT_TERMINATE(source=source) then source;
    case DAE.STMT_REINIT(source=source) then source;
    case DAE.STMT_NORETCALL(source=source) then source;
    case DAE.STMT_RETURN(source=source) then source;
    case DAE.STMT_BREAK(source=source) then source;
    case DAE.STMT_CONTINUE(source=source) then source;
    case DAE.STMT_FAILURE(source=source) then source;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Algorithm.getStatementSource"});
      then fail();
  end match;
end getStatementSource;

public function getAssertCond
  input DAE.Statement stmt;
  output DAE.Exp cond;
algorithm
  DAE.STMT_ASSERT(cond=cond) := stmt;
end getAssertCond;

public function isNotDummyStatement
  input DAE.Statement stmt;
  output Boolean b;
algorithm
  b := match stmt
    local
      DAE.Exp exp;
    case DAE.STMT_NORETCALL(exp=exp)
      equation
        (_,b) = Expression.traverseExpBottomUp(exp,Expression.hasNoSideEffects,true);
      then not b; // has side effects => this is an expression that could do something
    else true;
  end match;
end isNotDummyStatement;

annotation(__OpenModelica_Interface="frontend");
end Algorithm;
