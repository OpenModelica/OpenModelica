/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Algorithm
"
  file:	       Algorithm.mo
  package:     Algorithm
  description: Algorithm datatypes

  RCS: $Id$

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

public
type Ident = String;

public type Algorithm = DAE.Algorithm;
public type Statement = DAE.Statement;
public type Else = DAE.Else;

protected import Debug;
protected import RTOpts;
protected import Error;
protected import Exp;
protected import Print;
protected import Types;
protected import Util;

public function algorithmEmpty "Returns true if algorithm is empty, i.e. no statements"
  input Algorithm alg;
  output Boolean empty;
algorithm
  empty := matchcontinue(alg)
    case(DAE.ALGORITHM_STMTS({})) then true;
    case(_) then false;
  end matchcontinue;
end algorithmEmpty;

public function splitReinits ""
  input list<Algorithm> inAlgs;
  output list<Algorithm> reinits;
  output list<Statement> rest;
algorithm (reinits,rest) := matchcontinue(inAlgs)
  local
    Statement a;
    list<Statement> al;
  case({}) then ({},{});
  case(DAE.ALGORITHM_STMTS(al as {a as DAE.STMT_REINIT(var = _)})::inAlgs)
    equation
      (reinits,rest) = splitReinits(inAlgs);
    then
      (DAE.ALGORITHM_STMTS({a})::reinits,rest);
  case(DAE.ALGORITHM_STMTS(al as {a})::inAlgs)
    equation
      (reinits,rest) = splitReinits(inAlgs);
    then
      (reinits,a::rest);
  case( DAE.ALGORITHM_STMTS((a::al)):: inAlgs )
    equation
      inAlgs = listAppend({DAE.ALGORITHM_STMTS({a}),DAE.ALGORITHM_STMTS(al)},inAlgs);
      (reinits,rest) = splitReinits(inAlgs);
    then
      (reinits,rest);
end matchcontinue;
end splitReinits;

public function makeAssignment
"function: makeAssignment
  This function creates an `DAE.STMT_ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match.
  LS: Added call to getPropType and isPropAnyConst instead of
  having PROP in the rules. Otherwise rules must be repeated because of
  combinations with PROP_TUPLE"
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input DAE.Exp inExp3;
  input DAE.Properties inProperties4;
  input SCode.Accessibility inAccessibility5;
  input SCode.Initial initial_;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inProperties2,inExp3,inProperties4,inAccessibility5,initial_)
    local
      Ident lhs_str,rhs_str,lt_str,rt_str;
      DAE.Exp lhs,rhs,rhs_1,e1,e2,e3;
      DAE.Properties lprop,rprop,lhprop,rhprop;
      DAE.ExpType t,crt;
      DAE.ComponentRef c,cr;
      tuple<DAE.TType, Option<Absyn.Path>> lt,rt;

    /* It is not allowed to assign to a constant */
    case (lhs,lprop,rhs,rprop,_,initial_)
      equation
        DAE.C_CONST() = Types.propAnyConst(lprop);
        lhs_str = Exp.printExpStr(lhs);
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_CONSTANT_ERROR, {lhs_str,rhs_str});
      then
        fail();

    /* assign to parameter in algorithm okay if record */
    case ((lhs as DAE.CREF(componentRef=cr)),lhprop,rhs,rhprop,_,SCode.NON_INITIAL())
      equation
        DAE.C_PARAM() = Types.propAnyConst(lhprop);
        true = Exp.isRecord(cr);
        outStatement = makeAssignment2(lhs,lhprop,rhs,rhprop);
      then outStatement;

    /* assign to parameter in algorithm produce error */
    case (lhs,lprop,rhs,rprop,_,SCode.NON_INITIAL())
      equation
        DAE.C_PARAM() = Types.propAnyConst(lprop);
        lhs_str = Exp.printExpStr(lhs);
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_PARAM_ERROR, {lhs_str,rhs_str});
      then
        fail();
    /* assignment to a constant, report error */
    case (lhs,_,rhs,_,SCode.RO(),_)
      equation
        lhs_str = Exp.printExpStr(lhs);
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_READONLY_ERROR, {lhs_str,rhs_str});
      then
        fail();

    /* assignment to parameter ok in initial algorithm */
    case (lhs,lhprop,rhs,rhprop,_,SCode.INITIAL())
      equation
        DAE.C_PARAM() = Types.propAnyConst(lhprop);
        outStatement = makeAssignment2(lhs,lhprop,rhs,rhprop);
      then outStatement;

    case (lhs,lhprop,rhs,rhprop,_,_)
      equation
        DAE.C_VAR() = Types.propAnyConst(lhprop);
        outStatement = makeAssignment2(lhs,lhprop,rhs,rhprop);
      then outStatement;

    /* report an error */
    case (lhs,lprop,rhs,rprop,_,_)
      equation
        lt = Types.getPropType(lprop);
        rt = Types.getPropType(rprop);
        false = Types.equivtypes(lt, rt);
        lhs_str = Exp.printExpStr(lhs);
        rhs_str = Exp.printExpStr(rhs);
        lt_str = Types.unparseType(lt);
        rt_str = Types.unparseType(rt);
        Error.addMessage(Error.ASSIGN_TYPE_MISMATCH_ERROR,
          {lhs_str,rhs_str,lt_str,rt_str});
      then
        fail();

     /* failing */
    case (lhs,lprop,rhs,rprop,_,_)
      equation
        Print.printErrorBuf("- Algorithm.makeAssignment failed\n");
        Print.printErrorBuf("    ");
        Print.printErrorBuf(Exp.printExpStr(lhs));
        Print.printErrorBuf(" := ");
        Print.printErrorBuf(Exp.printExpStr(rhs));
        Print.printErrorBuf("\n");
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
  output Statement outStatement;
algorithm
  outStatement := matchcontinue(lhs,lhprop,rhs,rhprop)
    local DAE.ComponentRef c;
      DAE.ExpType crt,t;
      DAE.Exp rhs_1,e3,e1;
    case (DAE.CREF(componentRef = c,ty = crt),lhprop,rhs,rhprop)
      equation
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop, true);
        false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t,DAE.CREF(c,crt),rhs_1);
        /* TODO: Use this when we have fixed states in DAELow .lower(...)
        case (e1 as DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(_,_)},_,_,_),lhprop,rhs,rhprop)
      equation
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop);
        false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t,e1,rhs_1);
      */
    case (DAE.CREF(componentRef = c,ty = crt),lhprop,rhs,rhprop)
      equation
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop, false /* Don't duplicate errors */);
        true = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN_ARR(t,c,rhs_1);

    case(e3 as DAE.ASUB(e1,ea2),lhprop,rhs,rhprop)
      local list<DAE.Exp> ea2;
      equation
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop, true);
        //false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        DAE.STMT_ASSIGN(t,e3,rhs_1);
  end matchcontinue;
end makeAssignment2;

public function makeTupleAssignment "function: makeTupleAssignment
  This function creates an `DAE.STMT_TUPLE_ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match."
  input list<DAE.Exp> inExpExpLst;
  input list<DAE.Properties> inTypesPropertiesLst;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input SCode.Initial initial_;
  output Statement outStatement;
algorithm
  outStatement := matchcontinue (inExpExpLst,inTypesPropertiesLst,inExp,inProperties,initial_)
    local
      list<DAE.Const> bvals;
      list<Ident> sl;
      Ident s,lhs_str,rhs_str,str1,str2,strInitial;
      list<DAE.Exp> lhs,expl;
      list<DAE.Properties> lprop,lhprops;
      DAE.Exp rhs,rhs_1;
      DAE.Properties rprop;
      list<tuple<DAE.TType, Option<Absyn.Path>>> lhrtypes,tpl;
      list<DAE.TupleConst> clist;
      DAE.Const const;
      
    case (lhs,lprop,rhs,rprop,initial_)
      equation
        bvals = Util.listMap(lprop, Types.propAnyConst);
        DAE.C_CONST() = Util.listReduce(bvals, Types.constOr);
        sl = Util.listMap(lhs, Exp.printExpStr);
        s = Util.stringDelimitList(sl, ", ");
        lhs_str = Util.stringAppendList({"(",s,")"});
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_CONSTANT_ERROR, {lhs_str,rhs_str});
      then
        fail();
    case (lhs,lprop,rhs,rprop,SCode.NON_INITIAL())
      equation
        bvals = Util.listMap(lprop, Types.propAnyConst);
        DAE.C_PARAM() = Util.listReduce(bvals, Types.constOr);
        sl = Util.listMap(lhs, Exp.printExpStr);
        s = Util.stringDelimitList(sl, ", ");
        lhs_str = Util.stringAppendList({"(",s,")"});
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_PARAM_ERROR, {lhs_str,rhs_str});
      then
        fail();
    // a normal prop in rhs that contains a T_TUPLE!
    case (expl,lhprops,rhs,DAE.PROP(type_ = (DAE.T_TUPLE(tupleType = tpl),_)),_)
      equation         
        bvals = Util.listMap(lhprops, Types.propAnyConst);
        DAE.C_VAR() = Util.listReduce(bvals, Types.constOr);
        lhrtypes = Util.listMap(lhprops, Types.getPropType);        
        Types.matchTypeTupleCall(rhs, tpl, lhrtypes);        
         /* Don\'t use new rhs\', since type conversions of 
            several output args are not clearly defined. */ 
      then
        DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,rhs);
    // a tuple in rhs        
    case (expl,lhprops,rhs,DAE.PROP_TUPLE(type_ = (DAE.T_TUPLE(tupleType = tpl),_),tupleConst = DAE.TUPLE_CONST(tupleConstLst = clist)),_)
      equation
        bvals = Util.listMap(lhprops, Types.propAnyConst);
        DAE.C_VAR() = Util.listReduce(bvals, Types.constOr);
        lhrtypes = Util.listMap(lhprops, Types.getPropType);        
        Types.matchTypeTupleCall(rhs, tpl, lhrtypes);        
         /* Don\'t use new rhs\', since type conversions of several output args are not clearly defined. */
      then
        DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,rhs);
    case (lhs,lprop,rhs,rprop,initial_)
      equation
        true = RTOpts.debugFlag("failtrace");
        sl = Util.listMap(lhs, Exp.printExpStr);
        s = Util.stringDelimitList(sl, ", ");
        lhs_str = Util.stringAppendList({"(",s,")"});
        rhs_str = Exp.printExpStr(rhs);
        str1 = Util.stringDelimitList(Util.listMap(lprop, Types.printPropStr), ", ");
        str2 = Types.printPropStr(rprop);
        strInitial = SCode.printInitialStr(initial_);
        Debug.traceln("- Algorithm.makeTupleAssignment failed on: \n\t" +& 
          lhs_str +& " = " +& rhs_str +& 
          "\n\tprops lhs: (" +& str1 +& ") =  props rhs: " +& str2 +&
          "\n\tin " +& strInitial +& " section");
      then
        fail();
  end matchcontinue;
end makeTupleAssignment;

protected function getPropExpType "function: getPropExpType
  Returns the expression type for a given Properties by calling
  getTypeExpType. Used by makeAssignment."
  input DAE.Properties p;
  output DAE.ExpType t;
  tuple<DAE.TType, Option<Absyn.Path>> ty;
algorithm
  ty := Types.getPropType(p);
  t := getTypeExpType(ty);
end getPropExpType;

protected function getTypeExpType "function: getTypeExpType
  Returns the expression type for a given Type module type. Used only by
  getPropExpType."
  input DAE.Type inType;
  output DAE.ExpType outType;
algorithm
  outType:=
  matchcontinue (inType)
    local tuple<DAE.TType, Option<Absyn.Path>> t;
    case ((DAE.T_INTEGER(varLstInt = _),_)) then DAE.ET_INT();
    case ((DAE.T_REAL(varLstReal = _),_)) then DAE.ET_REAL();
    case ((DAE.T_STRING(varLstString = _),_)) then DAE.ET_STRING();
    case ((DAE.T_BOOL(varLstBool = _),_)) then DAE.ET_BOOL();
    case ((DAE.T_ARRAY(arrayType = t),_)) then getTypeExpType(t);
    case ((DAE.T_COMPLEX(_,{},SOME(t),_),_))
       then getTypeExpType(t);
    case ((DAE.T_COMPLEX(_,_::_,_,_),_))
      equation
      // Commenting out this line because it prints a lot of warnings for
      // record assignments (which actually work just fine). // sjoelund // 2009-05-07
      //print("Warning complex_varList not implemented for Array_assign\n");
      then fail();
    case ((_,_)) then DAE.ET_OTHER();  /* was fail but records must be handled somehow */
  end matchcontinue;
end getTypeExpType;

public function makeIf "function: makeIf
  This function creates an `DAE.STMT_IF\' construct, checking that the types
  of the parts are correct. Else part is generated using the makeElse
  function."
  input DAE.Exp inExp1;
  input DAE.Properties inProperties2;
  input list<Statement> inStatementLst3;
  input list<tuple<DAE.Exp, DAE.Properties, list<Statement>>> inTplExpExpTypesPropertiesStatementLstLst4;
  input list<Statement> inStatementLst5;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inProperties2,inStatementLst3,inTplExpExpTypesPropertiesStatementLstLst4,inStatementLst5)
    local
      Else else_;
      DAE.Exp e;
      list<Statement> tb,fb;
      list<tuple<DAE.Exp, DAE.Properties, list<Statement>>> eib;
      Ident e_str,t_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case (e,DAE.PROP(type_ = t),tb,eib,fb)
      equation
        (e,_) = Types.matchType(e,t,DAE.T_BOOL_DEFAULT,true);
        else_ = makeElse(eib, fb);
      then
        DAE.STMT_IF(e,tb,else_);
    case (e,DAE.PROP(type_ = t),_,_,_)
      equation
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeIf;

protected function makeElse "function: makeElse
  This function creates the ELSE part of the DAE.STMT_IF and checks if is correct."
  input list<tuple<DAE.Exp, DAE.Properties, list<Statement>>> inTplExpExpTypesPropertiesStatementLstLst;
  input list<Statement> inStatementLst;
  output Else outElse;
algorithm
  outElse:=
  matchcontinue (inTplExpExpTypesPropertiesStatementLstLst,inStatementLst)
    local
      list<Statement> fb,b;
      Else else_;
      DAE.Exp e;
      list<tuple<DAE.Exp, DAE.Properties, list<Statement>>> xs;
      Ident e_str,t_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case ({},{}) then DAE.NOELSE();  /* This removes empty else branches */
    case ({},fb) then DAE.ELSE(fb);
    case (((e,DAE.PROP(type_ = t),b) :: xs),fb)
      equation
        (e,_) = Types.matchType(e,t,DAE.T_BOOL_DEFAULT,true);
        else_ = makeElse(xs, fb);
      then
        DAE.ELSEIF(e,b,else_);
    case (((e,DAE.PROP(type_ = t),_) :: _),_)
      equation
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeElse;

public function makeFor "function: makeFor
  This function creates a DAE.STMT_FOR construct, checking
  that the types of the parts are correct."
  input Ident inIdent;
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<Statement> inStatementLst;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inIdent,inExp,inProperties,inStatementLst)
    local
      Boolean array;
      DAE.ExpType et;
      Ident i,e_str,t_str;
      DAE.Exp e;
      tuple<DAE.TType, Option<Absyn.Path>> t;
      list<Statement> stmts;
    case (i,e,DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = t),_)),stmts)
      equation
        array = Types.isArray(t);
        et = Types.elabType(t);
      then
        DAE.STMT_FOR(et,array,i,e,stmts);
    case (_,e,DAE.PROP(type_ = t),_)
      equation
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.FOR_EXPRESSION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeFor;

public function makeWhile "function: makeWhile
  This function creates a DAE.STMT_WHILE construct, checking that the types
  of the parts are correct."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<Statement> inStatementLst;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp,inProperties,inStatementLst)
    local
      DAE.Exp e;
      list<Statement> stmts;
      Ident e_str,t_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case (e,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_)),stmts) then DAE.STMT_WHILE(e,stmts);
    case (e,DAE.PROP(type_ = t),_)
      equation
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.WHILE_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeWhile;

public function makeWhenA "function: makeWhenA
  This function creates a DAE.STMT_WHEN algorithm construct,
  checking that the types of the parts are correct."
  input DAE.Exp inExp;
  input DAE.Properties inProperties;
  input list<Statement> inStatementLst;
  input Option<Statement> elseWhenStmt;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp,inProperties,inStatementLst,elseWhenStmt)
    local
      DAE.Exp e;
      list<Statement> stmts;
      Option<Statement> elsew;
      Ident e_str,t_str;
      tuple<DAE.TType, Option<Absyn.Path>> t;
    case (e,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_)),stmts,elsew) then DAE.STMT_WHEN(e,stmts,elsew,{});
    case (e,DAE.PROP(type_ = (DAE.T_ARRAY(arrayType = (DAE.T_BOOL(varLstBool = _),_)),_)),stmts,elsew) then DAE.STMT_WHEN(e,stmts,elsew,{});
    case (e,DAE.PROP(type_ = t),_,_)
      equation
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.WHEN_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeWhenA;

public function makeReinit "function: makeReinit
 creates a reinit statement in an algorithm
 statement, only valid in when algorithm sections."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.Properties inProperties3;
  input DAE.Properties inProperties4;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inExp2,inProperties3,inProperties4)
    local DAE.Exp var,val,var_1,val_1; DAE.Properties prop1,prop2;
      DAE.Type tp1,tp2;
    case (var as DAE.CREF(_,_),val,DAE.PROP(tp1,_),DAE.PROP(tp2,_))
      equation
        (val_1,_) = Types.matchType(val,tp2,DAE.T_REAL_DEFAULT,true);
        (var_1,_) = Types.matchType(var,tp1,DAE.T_REAL_DEFAULT,true);
      then DAE.STMT_REINIT(var_1,val_1);

   case (_,_,prop1,prop2)  equation
			Error.addMessage(Error.INTERNAL_ERROR(),{"reinit called with wrong args"});
    then fail();

  	// TODO: Add checks for reinit here. 1. First argument must be variable. 2. Expressions must be real.
  end matchcontinue;
end makeReinit;

public function makeAssert "function: makeAssert
  Creates an assert statement from two expressions.
"
  input DAE.Exp inExp1 "condition";
  input DAE.Exp inExp2 "message";
  input DAE.Properties inProperties3;
  input DAE.Properties inProperties4;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inExp2,inProperties3,inProperties4)
    local DAE.Exp cond,msg;
    case (cond,msg,DAE.PROP(type_ = (DAE.T_BOOL(varLstBool = _),_)),DAE.PROP(type_ = (DAE.T_STRING(varLstString = _),_))) then DAE.STMT_ASSERT(cond,msg);
  end matchcontinue;
end makeAssert;

public function makeTerminate "
  Creates a terminate statement from message expression.
"
  input DAE.Exp inExp1 "message";
  input DAE.Properties inProperties3;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inProperties3)
    local DAE.Exp cond,msg;
    case (msg,DAE.PROP(type_ = (DAE.T_STRING(varLstString = _),_))) then DAE.STMT_TERMINATE(msg);
  end matchcontinue;
end makeTerminate;

public function getCrefFromAlg "Returns all crefs from an algorithm"
input Algorithm alg;
output list<DAE.ComponentRef> crs;
algorithm
  crs := Util.listListUnionOnTrue(Util.listMap(getAllExps(alg),Exp.getCrefFromExp),Exp.crefEqual);
end getCrefFromAlg;


public function getAllExps "function: getAllExps

  This function goes through the Algorithm structure and finds all the
  expressions and returns them in a list
"
  input Algorithm inAlgorithm;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inAlgorithm)
    local
      list<DAE.Exp> exps;
      list<Statement> stmts;
    case DAE.ALGORITHM_STMTS(statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
  end matchcontinue;
end getAllExps;

public function getAllExpsStmts "function: getAllExpsStmts

  This function takes a list of statements and returns all expressions
  in all statements.
"
  input list<Statement> stmts;
  output list<DAE.Exp> exps;
  list<list<DAE.Exp>> expslist;
algorithm
  expslist := Util.listMap(stmts, getAllExpsStmt);
  exps := Util.listFlatten(expslist);
end getAllExpsStmts;

protected function getAllExpsStmt "function: getAllExpsStmt
  Returns all expressions in a statement."
  input Statement inStatement;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inStatement)
    local
      DAE.Exp crexp,exp,e1,e2;
      DAE.ExpType expty;
      DAE.ComponentRef cr;
      list<DAE.Exp> exps,explist,exps1,elseexps,fargs;
      list<Statement> stmts;
      Else else_;
      Boolean flag;
      Ident id;
      Statement elsew;
      Absyn.Path fname;
    case DAE.STMT_ASSIGN(type_ = expty,exp1 = (e2 as DAE.CREF(cr,_)),exp = exp)
      equation
        crexp = crefToExp(cr);
      then
        {crexp,exp};
    case DAE.STMT_ASSIGN(type_ = expty,exp1 = (e2 as DAE.ASUB(e1,ea2)),exp = exp)
      local list<DAE.Exp> ea2;
      equation
      then
        {e2,exp};
    case DAE.STMT_TUPLE_ASSIGN(type_ = expty,expExpLst = explist,exp = exp)
      equation
        exps = listAppend(explist, {exp});
      then
        exps;
    case DAE.STMT_ASSIGN_ARR(type_ = expty,componentRef = cr,exp = exp)
      equation
        crexp = crefToExp(cr);
      then
        {crexp,exp};
    case DAE.STMT_IF(exp = exp,statementLst = stmts,else_ = else_)
      equation
        exps1 = getAllExpsStmts(stmts);
        elseexps = getAllExpsElse(else_);
        exps = listAppend(exps1, elseexps);
      then
        (exp :: exps);
    case DAE.STMT_FOR(type_ = expty,boolean = flag,ident = id,exp = exp,statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case DAE.STMT_WHILE(exp = exp,statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case DAE.STMT_WHEN(exp = exp,statementLst = stmts, elseWhen=SOME(elsew))
      equation
				exps1 = getAllExpsStmt(elsew);
        exps = list_append(getAllExpsStmts(stmts),exps1);
      then
        (exp :: exps);
    case DAE.STMT_WHEN(exp = exp,statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case DAE.STMT_ASSERT(cond = e1,msg= e2) then {e1,e2};
    case DAE.STMT_BREAK() then {};
    case DAE.STMT_RETURN() then {};
    case DAE.STMT_THROW() then {};
    case DAE.STMT_TRY(stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
    case DAE.STMT_CATCH(stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;

    case DAE.STMT_NORETCALL(e1) then {e1};

    case(DAE.STMT_REINIT(e1,e2)) then {e1,e2};

    case(DAE.STMT_MATCHCASES(exps)) then exps;

    case _
      equation
        Debug.fprintln("failtrace", "- Algorithm.getAllExpsStmt failed");
      then
        fail();
  end matchcontinue;
end getAllExpsStmt;

protected function getAllExpsElse "function: getAllExpsElse
  Helper function to getAllExpsStmt."
  input Else inElse;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inElse)
    local
      list<DAE.Exp> exps1,elseexps,exps;
      DAE.Exp exp;
      list<Statement> stmts;
      Else else_;
    case DAE.NOELSE() then {};
    case DAE.ELSEIF(exp = exp,statementLst = stmts,else_ = else_)
      equation
        exps1 = getAllExpsStmts(stmts);
        elseexps = getAllExpsElse(else_);
        exps = listAppend(exps1, elseexps);
      then
        (exp :: exps);
    case DAE.ELSE(statementLst = stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
  end matchcontinue;
end getAllExpsElse;

protected function crefToExp "function: crefToExp
  Creates an expression from a ComponentRef.
  The type of the expression will become DAE.ET_OTHER."
  input DAE.ComponentRef inComponentRef;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inComponentRef)
    local DAE.ComponentRef cref;
    case cref then DAE.CREF(cref,DAE.ET_OTHER());
  end matchcontinue;
end crefToExp;

end Algorithm;

