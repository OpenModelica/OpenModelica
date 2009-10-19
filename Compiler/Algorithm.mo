/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
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

public import Exp;
public import Types;
public import SCode;
public import Absyn;

public 
type Ident = String;

public 
uniontype Algorithm "The `Algorithm\' type corresponds to a whole algorithm section.
  It is simple a list of algorithm statements."
  record ALGORITHM
    list<Statement> statementLst;
  end ALGORITHM;

end Algorithm;

public 
uniontype Statement "There are four kinds of statements.  Assignments (`a := b;\'),
    if statements (`if A then B; elseif C; else D;\'), for loops
    (`for i in 1:10 loop ...; end for;\') and when statements
    (`when E do S; end when;\')."
  record ASSIGN
    Exp.Type type_;
    Exp.Exp exp1;
    Exp.Exp exp;
  end ASSIGN;

  record TUPLE_ASSIGN
    Exp.Type type_;
    list<Exp.Exp> expExpLst;
    Exp.Exp exp;
  end TUPLE_ASSIGN;

  record ASSIGN_ARR
    Exp.Type type_;
    Exp.ComponentRef componentRef;
    Exp.Exp exp;
  end ASSIGN_ARR;

  record IF
    Exp.Exp exp;
    list<Statement> statementLst;
    Else else_;
  end IF;

  record FOR
    Exp.Type type_;
    Boolean boolean;
    Ident ident;
    Exp.Exp exp;
    list<Statement> statementLst;
  end FOR;

  record WHILE
    Exp.Exp exp;
    list<Statement> statementLst;
  end WHILE;

  record WHEN
    Exp.Exp exp;
    list<Statement> statementLst;
    Option<Statement> elseWhen;
    list<Integer> helpVarIndices;
  end WHEN;

  record ASSERT "assert(cond,msg)"
    Exp.Exp cond;
    Exp.Exp msg;
  end ASSERT;
  
  record TERMINATE "terminate(msg)"
    Exp.Exp msg;
  end TERMINATE;

  record REINIT 
    Exp.Exp var "Variable"; 
    Exp.Exp value "Value "; 
  end REINIT;
  
  record NORETCALL "call with no return value, i.e. no equation. 
		   Typically sideeffect call of external function."  
    Exp.Exp exp;
  end NORETCALL;    
  
  record RETURN
  end RETURN;
  
  record BREAK
  end BREAK;

  // MetaModelica extension. KS
  record TRY
    list<Statement> tryBody;
  end TRY;

  record CATCH
    list<Statement> catchBody;
  end CATCH;

  record THROW
  end THROW;

  record GOTO
    String labelName;
  end GOTO;

  record LABEL
    String labelName;
  end LABEL;
  
  record MATCHCASES "matchcontinue helper"
    list<Exp.Exp> caseStmt;
  end MATCHCASES;
  
  //-----

end Statement;

public 
uniontype Else "An if statements can one or more `elseif\' branches and an
    optional `else\' branch."
  record NOELSE end NOELSE;

  record ELSEIF
    Exp.Exp exp;
    list<Statement> statementLst;
    Else else_;
  end ELSEIF;

  record ELSE
    list<Statement> statementLst;
  end ELSE;

end Else;

protected import Util;
protected import Print;
protected import Debug;
protected import Error;

public function algorithmEmpty "Returns true if algorithm is empty, i.e. no statements"
  input Algorithm alg;
  output Boolean empty;
algorithm
  empty := matchcontinue(alg)
    case(ALGORITHM({})) then true;
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
  case(ALGORITHM(al as {a as REINIT(var = _)})::inAlgs) 
    equation
      (reinits,rest) = splitReinits(inAlgs);
    then
      (ALGORITHM({a})::reinits,rest); 
  case(ALGORITHM(al as {a})::inAlgs) 
    equation
      (reinits,rest) = splitReinits(inAlgs);
    then
      (reinits,a::rest);
  case( ALGORITHM((a::al)):: inAlgs ) 
    equation
      inAlgs = listAppend({ALGORITHM({a}),ALGORITHM(al)},inAlgs);
      (reinits,rest) = splitReinits(inAlgs);
    then 
      (reinits,rest);
end matchcontinue;
end splitReinits; 

public function makeAssignment 
"function: makeAssignment
  This function creates an `ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match.
  LS: Added call to getPropType and isPropAnyConst instead of
  having PROP in the rules. Otherwise rules must be repeated because of
  combinations with PROP_TUPLE"
  input Exp.Exp inExp1;
  input Types.Properties inProperties2;
  input Exp.Exp inExp3;
  input Types.Properties inProperties4;
  input SCode.Accessibility inAccessibility5;
  input SCode.Initial initial_;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp1,inProperties2,inExp3,inProperties4,inAccessibility5,initial_)
    local
      Ident lhs_str,rhs_str,lt_str,rt_str;
      Exp.Exp lhs,rhs,rhs_1,e1,e2,e3;
      Types.Properties lprop,rprop,lhprop,rhprop;
      Exp.Type t,crt;
      Exp.ComponentRef c;
      tuple<Types.TType, Option<Absyn.Path>> lt,rt;

    /* It is not allowed to assign to a constant */
    case (lhs,lprop,rhs,rprop,_,initial_)
      equation 
        Types.C_CONST() = Types.propAnyConst(lprop);
        lhs_str = Exp.printExpStr(lhs);
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_CONSTANT_ERROR, {lhs_str,rhs_str});
      then
        fail();

    /* assign to parameter in algorithm produce error */
    case (lhs,lprop,rhs,rprop,_,SCode.NON_INITIAL())
      equation 
        Types.C_PARAM() = Types.propAnyConst(lprop);
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
        Types.C_PARAM() = Types.propAnyConst(lhprop);
        outStatement = makeAssignment2(lhs,lhprop,rhs,rhprop);
      then outStatement;

    case (lhs,lhprop,rhs,rhprop,_,_)
      equation 
        Types.C_VAR() = Types.propAnyConst(lhprop);
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
  input Exp.Exp lhs;
  input Types.Properties lhprop;
  input Exp.Exp rhs;
  input Types.Properties rhprop;
  output Statement outStatement; 
algorithm
  outStatement := matchcontinue(lhs,lhprop,rhs,rhprop)
    local Exp.ComponentRef c;
      Exp.Type crt,t;
      Exp.Exp rhs_1,e3,e1;
    case (Exp.CREF(componentRef = c,ty = crt),lhprop,rhs,rhprop)
      equation 
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop);
        false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        ASSIGN(t,Exp.CREF(c,crt),rhs_1);
        /* TODO: Use this when we have fixed states in DAELow.lower(...)
        case (e1 as Exp.CALL(Absyn.IDENT("der"),{Exp.CREF(_,_)},_,_,_),lhprop,rhs,rhprop)
      equation 
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop);
        false = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        ASSIGN(t,e1,rhs_1);
      */
    case (Exp.CREF(componentRef = c,ty = crt),lhprop,rhs,rhprop)
      equation 
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop);
        true = Types.isPropArray(lhprop);
        t = getPropExpType(lhprop);
      then
        ASSIGN_ARR(t,c,rhs_1);
        
    case(e3 as Exp.ASUB(e1,ea2),lhprop,rhs,rhprop)
      local list<Exp.Exp> ea2;
      equation
        (rhs_1,_) = Types.matchProp(rhs, rhprop, lhprop);
        //false = Types.isPropArray(lhprop); 
        t = getPropExpType(lhprop);        
      then     
        ASSIGN(t,e3,rhs_1);
  end matchcontinue;
end makeAssignment2;

public function makeTupleAssignment "function: makeTupleAssignment 
  This function creates an `TUPLE_ASSIGN\' construct, and checks that the
  assignment is semantically valid, which means that the component
  being assigned is not constant, and that the types match."
  input list<Exp.Exp> inExpExpLst;
  input list<Types.Properties> inTypesPropertiesLst;
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input SCode.Initial initial_;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExpExpLst,inTypesPropertiesLst,inExp,inProperties,initial_)
    local
      list<Types.Const> bvals;
      list<Ident> sl;
      Ident s,lhs_str,rhs_str;
      list<Exp.Exp> lhs,expl;
      list<Types.Properties> lprop,lhprops;
      Exp.Exp rhs,rhs_1;
      Types.Properties rprop;
      list<tuple<Types.TType, Option<Absyn.Path>>> lhrtypes,tpl;
      list<Types.TupleConst> clist;
    case (lhs,lprop,rhs,rprop,initial_)
      equation 
        bvals = Util.listMap(lprop, Types.propAnyConst);
        Types.C_CONST() = Util.listReduce(bvals, Types.constOr);
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
        Types.C_PARAM() = Util.listReduce(bvals, Types.constOr);
        sl = Util.listMap(lhs, Exp.printExpStr);
        s = Util.stringDelimitList(sl, ", ");
        lhs_str = Util.stringAppendList({"(",s,")"});
        rhs_str = Exp.printExpStr(rhs);
        Error.addMessage(Error.ASSIGN_PARAM_ERROR, {lhs_str,rhs_str});
      then
        fail();
    case (expl,lhprops,rhs,Types.PROP_TUPLE(type_ = (Types.T_TUPLE(tupleType = tpl),_),tupleConst = Types.TUPLE_CONST(tupleConstLst = clist)),_)
      equation 
        bvals = Util.listMap(lhprops, Types.propAnyConst);
        Types.C_VAR() = Util.listReduce(bvals, Types.constOr);
        lhrtypes = Util.listMap(lhprops, Types.getPropType);
        Types.matchTypeTupleCall(rhs, tpl, lhrtypes);
         /* Don\'t use new rhs\', since type conversions of several output args
	 are not clearly defined. */ 
      then
        TUPLE_ASSIGN(Exp.OTHER(),expl,rhs);
    case (lhs,lprop,rhs,rprop,_)
      equation 
        Debug.fprint("failtrace", "- Algorithm.makeTupleAssignment failed\n");
      then
        fail();
  end matchcontinue;
end makeTupleAssignment;

protected function getPropExpType "function: getPropExpType
  Returns the expression type for a given Properties by calling
  getTypeExpType. Used by makeAssignment."
  input Types.Properties p;
  output Exp.Type t;
  tuple<Types.TType, Option<Absyn.Path>> ty;
algorithm 
  ty := Types.getPropType(p);
  t := getTypeExpType(ty);
end getPropExpType;

protected function getTypeExpType "function: getTypeExpType
  Returns the expression type for a given Type module type. Used only by
  getPropExpType."
  input Types.Type inType;
  output Exp.Type outType;
algorithm 
  outType:=
  matchcontinue (inType)
    local tuple<Types.TType, Option<Absyn.Path>> t;
    case ((Types.T_INTEGER(varLstInt = _),_)) then Exp.INT(); 
    case ((Types.T_REAL(varLstReal = _),_)) then Exp.REAL(); 
    case ((Types.T_STRING(varLstString = _),_)) then Exp.STRING(); 
    case ((Types.T_BOOL(varLstBool = _),_)) then Exp.BOOL(); 
    case ((Types.T_ARRAY(arrayType = t),_)) then getTypeExpType(t);
    case ((Types.T_COMPLEX(_,{},SOME(t),_),_))
       then getTypeExpType(t);
    case ((Types.T_COMPLEX(_,_::_,_,_),_)) 
      equation 
      // Commenting out this line because it prints a lot of warnings for
      // record assignments (which actually work just fine). // sjoelund // 2009-05-07
      //print("Warning complex_varList not implemented for Array_assign\n");
      then fail();
    case ((_,_)) then Exp.OTHER();  /* was fail but records must be handled somehow */ 
  end matchcontinue;
end getTypeExpType;

public function makeIf "function: makeIf
  This function creates an `IF\' construct, checking that the types
  of the parts are correct. Else part is generated using the makeElse
  function."
  input Exp.Exp inExp1;
  input Types.Properties inProperties2;
  input list<Statement> inStatementLst3;
  input list<tuple<Exp.Exp, Types.Properties, list<Statement>>> inTplExpExpTypesPropertiesStatementLstLst4;
  input list<Statement> inStatementLst5;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp1,inProperties2,inStatementLst3,inTplExpExpTypesPropertiesStatementLstLst4,inStatementLst5)
    local
      Else else_;
      Exp.Exp e;
      list<Statement> tb,fb;
      list<tuple<Exp.Exp, Types.Properties, list<Statement>>> eib;
      Ident e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (e,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_)),tb,eib,fb)
      equation 
        else_ = makeElse(eib, fb);
      then
        IF(e,tb,else_);
    case (e,Types.PROP(type_ = t),_,_,_)
      equation 
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeIf;

protected function makeElse "function: makeElse
  This function creates the ELSE part of the IF and checks if is correct."
  input list<tuple<Exp.Exp, Types.Properties, list<Statement>>> inTplExpExpTypesPropertiesStatementLstLst;
  input list<Statement> inStatementLst;
  output Else outElse;
algorithm 
  outElse:=
  matchcontinue (inTplExpExpTypesPropertiesStatementLstLst,inStatementLst)
    local
      list<Statement> fb,b;
      Else else_;
      Exp.Exp e;
      list<tuple<Exp.Exp, Types.Properties, list<Statement>>> xs;
      Ident e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case ({},{}) then NOELSE();  /* This removes empty else branches */ 
    case ({},fb) then ELSE(fb); 
    case (((e,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_)),b) :: xs),fb)
      equation 
        else_ = makeElse(xs, fb);
      then
        ELSEIF(e,b,else_);
    case (((e,Types.PROP(type_ = t),_) :: _),_)
      equation 
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.IF_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeElse;

public function makeFor "function: makeFor
  This function creates a FOR construct, checking 
  that the types of the parts are correct."
  input Ident inIdent;
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input list<Statement> inStatementLst;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inIdent,inExp,inProperties,inStatementLst)
    local
      Boolean array;
      Exp.Type et;
      Ident i,e_str,t_str;
      Exp.Exp e;
      tuple<Types.TType, Option<Absyn.Path>> t;
      list<Statement> stmts;
    case (i,e,Types.PROP(type_ = (Types.T_ARRAY(arrayType = t),_)),stmts)
      equation 
        array = Types.isArray(t);
        et = Types.elabType(t);
      then
        FOR(et,array,i,e,stmts);
    case (_,e,Types.PROP(type_ = t),_)
      equation 
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.FOR_EXPRESSION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeFor;

public function makeWhile "function: makeWhile 
  This function creates a WHILE construct, checking that the types
  of the parts are correct."
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input list<Statement> inStatementLst;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp,inProperties,inStatementLst)
    local
      Exp.Exp e;
      list<Statement> stmts;
      Ident e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (e,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_)),stmts) then WHILE(e,stmts); 
    case (e,Types.PROP(type_ = t),_)
      equation 
        e_str = Exp.printExpStr(e);
        t_str = Types.unparseType(t);
        Error.addMessage(Error.WHILE_CONDITION_TYPE_ERROR, {e_str,t_str});
      then
        fail();
  end matchcontinue;
end makeWhile;

public function makeWhenA "function: makeWhenA
  This function creates a WHEN algorithm construct, 
  checking that the types of the parts are correct."
  input Exp.Exp inExp;
  input Types.Properties inProperties;
  input list<Statement> inStatementLst;
  input Option<Statement> elseWhenStmt;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp,inProperties,inStatementLst,elseWhenStmt)
    local
      Exp.Exp e;
      list<Statement> stmts;
      Option<Statement> elsew;
      Ident e_str,t_str;
      tuple<Types.TType, Option<Absyn.Path>> t;
    case (e,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_)),stmts,elsew) then WHEN(e,stmts,elsew,{}); 
    case (e,Types.PROP(type_ = (Types.T_ARRAY(arrayType = (Types.T_BOOL(varLstBool = _),_)),_)),stmts,elsew) then WHEN(e,stmts,elsew,{}); 
    case (e,Types.PROP(type_ = t),_,_)
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
  input Exp.Exp inExp1;
  input Exp.Exp inExp2;
  input Types.Properties inProperties3;
  input Types.Properties inProperties4;
  output Statement outStatement;
algorithm
  outStatement:=
  matchcontinue (inExp1,inExp2,inProperties3,inProperties4)
    local Exp.Exp var,val,var_1,val_1; Types.Properties prop1,prop2;
      Types.Type tp1,tp2;
    case (var as Exp.CREF(_,_),val,Types.PROP(tp1,_),Types.PROP(tp2,_))  equation
     (val_1,_) = Types.matchType(val,tp2,(Types.T_REAL({}),NONE()));
      (var_1,_) = Types.matchType(var,tp1,(Types.T_REAL({}),NONE()));
    then REINIT(var_1,val_1);  
  
   case (_,_,prop1,prop2)  equation
			Error.addMessage(Error.INTERNAL_ERROR(),{"reinit called with wrong args"});
    then fail();
      
  	// TODO: Add checks for reinit here. 1. First argument must be variable. 2. Expressions must be real.
  end matchcontinue;      
end makeReinit;

public function makeAssert "function: makeAssert
  Creates an assert statement from two expressions.
"
  input Exp.Exp inExp1 "condition";
  input Exp.Exp inExp2 "message";
  input Types.Properties inProperties3;
  input Types.Properties inProperties4;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp1,inExp2,inProperties3,inProperties4)
    local Exp.Exp cond,msg;
    case (cond,msg,Types.PROP(type_ = (Types.T_BOOL(varLstBool = _),_)),Types.PROP(type_ = (Types.T_STRING(varLstString = _),_))) then ASSERT(cond,msg);  
  end matchcontinue;
end makeAssert;

public function makeTerminate "
  Creates a terminate statement from message expression.
"
  input Exp.Exp inExp1 "message";
  input Types.Properties inProperties3;
  output Statement outStatement;
algorithm 
  outStatement:=
  matchcontinue (inExp1,inProperties3)
    local Exp.Exp cond,msg;
    case (msg,Types.PROP(type_ = (Types.T_STRING(varLstString = _),_))) then TERMINATE(msg);  
  end matchcontinue;
end makeTerminate;

public function getCrefFromAlg "Returns all crefs from an algorithm"
input Algorithm alg;
output list<Exp.ComponentRef> crs;
algorithm
  crs := Util.listListUnionOnTrue(Util.listMap(getAllExps(alg),Exp.getCrefFromExp),Exp.crefEqual);
end getCrefFromAlg;


public function getAllExps "function: getAllExps
  
  This function goes through the Algorithm structure and finds all the
  expressions and returns them in a list
"
  input Algorithm inAlgorithm;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inAlgorithm)
    local
      list<Exp.Exp> exps;
      list<Statement> stmts;
    case ALGORITHM(statementLst = stmts)
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
  output list<Exp.Exp> exps;
  list<list<Exp.Exp>> expslist;
algorithm 
  expslist := Util.listMap(stmts, getAllExpsStmt);
  exps := Util.listFlatten(expslist);
end getAllExpsStmts;

protected function getAllExpsStmt "function: getAllExpsStmt
  Returns all expressions in a statement."
  input Statement inStatement;
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inStatement)
    local
      Exp.Exp crexp,exp,e1,e2;
      Exp.Type expty;
      Exp.ComponentRef cr;
      list<Exp.Exp> exps,explist,exps1,elseexps,fargs;
      list<Statement> stmts;
      Else else_;
      Boolean flag;
      Ident id;
      Statement elsew;
      Absyn.Path fname;
    case ASSIGN(type_ = expty,exp1 = (e2 as Exp.CREF(cr,_)),exp = exp)
      equation 
        crexp = crefToExp(cr);
      then
        {crexp,exp};
    case ASSIGN(type_ = expty,exp1 = (e2 as Exp.ASUB(e1,ea2)),exp = exp)
      local list<Exp.Exp> ea2;
      equation 
      then
        {e2,exp};
    case TUPLE_ASSIGN(type_ = expty,expExpLst = explist,exp = exp)
      equation 
        exps = listAppend(explist, {exp});
      then
        exps;
    case ASSIGN_ARR(type_ = expty,componentRef = cr,exp = exp)
      equation 
        crexp = crefToExp(cr);
      then
        {crexp,exp};
    case IF(exp = exp,statementLst = stmts,else_ = else_)
      equation 
        exps1 = getAllExpsStmts(stmts);
        elseexps = getAllExpsElse(else_);
        exps = listAppend(exps1, elseexps);
      then
        (exp :: exps);
    case FOR(type_ = expty,boolean = flag,ident = id,exp = exp,statementLst = stmts)
      equation 
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case WHILE(exp = exp,statementLst = stmts)
      equation 
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case WHEN(exp = exp,statementLst = stmts, elseWhen=SOME(elsew))
      equation 
				exps1 = getAllExpsStmt(elsew);
        exps = list_append(getAllExpsStmts(stmts),exps1);
      then
        (exp :: exps);
    case WHEN(exp = exp,statementLst = stmts)
      equation 
        exps = getAllExpsStmts(stmts);
      then
        (exp :: exps);
    case ASSERT(cond = e1,msg= e2) then {e1,e2}; 
    case BREAK() then {};
    case RETURN() then {};
    case THROW() then {};
    case TRY(stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
    case CATCH(stmts)
      equation
        exps = getAllExpsStmts(stmts);
      then
        exps;
    
    case NORETCALL(e1) then {e1};

    case(REINIT(e1,e2)) then {e1,e2};    
      
    case(MATCHCASES(exps)) then exps;

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
  output list<Exp.Exp> outExpExpLst;
algorithm 
  outExpExpLst:=
  matchcontinue (inElse)
    local
      list<Exp.Exp> exps1,elseexps,exps;
      Exp.Exp exp;
      list<Statement> stmts;
      Else else_;
    case NOELSE() then {}; 
    case ELSEIF(exp = exp,statementLst = stmts,else_ = else_)
      equation 
        exps1 = getAllExpsStmts(stmts);
        elseexps = getAllExpsElse(else_);
        exps = listAppend(exps1, elseexps);
      then
        (exp :: exps);
    case ELSE(statementLst = stmts)
      equation 
        exps = getAllExpsStmts(stmts);
      then
        exps;
  end matchcontinue;
end getAllExpsElse;

protected function crefToExp "function: crefToExp
  Creates an expression from a ComponentRef.
  The type of the expression will become Exp.OTHER."
  input Exp.ComponentRef inComponentRef;
  output Exp.Exp outExp;
algorithm 
  outExp:=
  matchcontinue (inComponentRef)
    local Exp.ComponentRef cref;
    case cref then Exp.CREF(cref,Exp.OTHER()); 
  end matchcontinue;
end crefToExp;

end Algorithm;

