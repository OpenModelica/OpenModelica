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

encapsulated package ExpressionSimplify
"
  file:        ExpressionSimplify.mo
  package:     ExpressionSimplify
  description: ExpressionSimplify

  RCS: $Id$

  This file contains the module ExpressionSimplify, which contains
  functions to simplify a DAE.Expression."

// public imports
public import Absyn;
public import DAE;
public import Error;

public type ComponentRef = DAE.ComponentRef;
public type Ident = String;
public type Operator = DAE.Operator;
public type Type = DAE.ExpType;
public type Subscript = DAE.Subscript;

// protected imports
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import Env;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import Prefix;
protected import Static;
protected import Types;
protected import Util;
protected import Values;
protected import ValuesUtil;

public uniontype IntOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
end IntOp;

public function simplify "function simplify
  Simplifies expressions"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := matchcontinue(inExp)
    local
      DAE.Exp e, eNew;
      Boolean b;
    case (e)
      equation
        true = Config.getNoSimplify();
        (eNew,b) = simplify1(e);
      then (eNew,b);
    case (e)
      equation
        //print("SIMPLIFY BEFORE->" +& ExpressionDump.printExpStr(e) +& "\n");
        (eNew,_) = simplify1(e); // Basic local simplifications
        //print("SIMPLIFY INTERMEDIATE->" +& ExpressionDump.printExpStr(eNew) +& "\n");
        eNew = simplify2(eNew); // Advanced (global) simplifications
        (eNew,_) = simplify1(eNew); // Basic local simplifications
        b = not Expression.expEqual(e,eNew);
        //print("SIMPLIFY FINAL->" +& ExpressionDump.printExpStr(eNew) +& "\n");
      then (eNew,b);
  end matchcontinue;
end simplify;

public function simplify1time "simplify1 with timing"
  input DAE.Exp e;
  output DAE.Exp outE;
protected
  Real t1,t2;
algorithm
  t1 := clock();
  (outE,_) := simplify1(e);
  t2 := clock();
  print(Util.if_(t2 -. t1 >. 0.01,"simplify1 took "+&realString(t2 -. t1)+&" seconds for exp: "+&ExpressionDump.printExpStr(e)+& " \nsimplified to :"+&ExpressionDump.printExpStr(outE)+&"\n",""));
end simplify1time;

public function simplifyWork
"This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input tuple<DAE.Exp,Boolean> inTpl;
  output tuple<DAE.Exp,Boolean> tpl;
algorithm
  tpl := matchcontinue (inTpl)
    local
      Integer n,i;
      DAE.Exp e,res,exp,e1_1,exp_1,e1,e_1,e2,e2_1,e3_1,e3,sub,exp1;
      Type t,tp;
      Boolean b,b1,remove_if,tpl,builtin,b2;
      Ident idn;
      list<DAE.Exp> exps,exps_1,expl,matrix;
      list<Subscript> s;
      ComponentRef c_1;
      Operator op;
      DAE.InlineType inlineType,b3;
      Absyn.Path fn, path;
      list<list<tuple<DAE.Exp, Boolean>>> matr,matr2;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      Option<DAE.Exp> oe1,foldExp;
      Option<Values.Value> v;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      DAE.TailCall tc;

    // noEvent propagated to relations and event triggering functions
    case ((DAE.CALL(path=Absyn.IDENT("noEvent"),expLst={e}),b))
      equation
        (e1,_) = simplify1(Expression.stripNoEvent(e));
        e2 = Expression.addNoEventToRelations(e1);
        e3 = Expression.addNoEventToEventTriggeringFunctions(e2);
        // TODO: Do this better?
      then 
        ((e3,b));
    
    case ((DAE.CALL(path=Absyn.IDENT("pre"), expLst={e as DAE.ASUB(exp = exp)}), b))
      equation
        true = Expression.isConst(exp);
      then
        ((e, true));
        
    // normal call 
    case ((e as DAE.CALL(expLst=expl),_))
      equation
        true = Expression.isConstWorkList(expl, true);
        e2 = simplifyBuiltinConstantCalls(e);
      then
        ((e2,true));
    
    // simplify some builtin calls, like cross, etc
    case ((e as DAE.CALL(attr=DAE.CALL_ATTR(builtin = true)),_))
      equation
        e2 = simplifyBuiltinCalls(e);
      then 
        ((e2,true));
    
    case ((e,_))
      equation
        e2 = simplifyTrigIdentities(e);
      then 
        ((e2,true));

    /* simplify different casts. Optimized to only run simplify1 once on subexpression e*/
    case ((DAE.CAST(ty = tp,exp=e),_))
      equation
        e = simplifyCast(e,tp);
      then ((e,true));
    
    // simplify identity 
    case ((DAE.CALL(path = Absyn.IDENT(name = "identity"), expLst = {DAE.ICONST(n)}),_))
      equation
        matrix = simplifyIdentity(1,n);
        e = DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT(),{DAE.DIM_INTEGER(n),DAE.DIM_INTEGER(n)}),
          false,matrix);
      then ((e,true));

    // MetaModelica builtin operators are calls
    case ((e,_))
      equation
        true = Config.acceptMetaModelicaGrammar();
      then ((simplifyMetaModelica(e),true));
    
    // other subscripting/asub simplifications where e is not simplified first.
    case ((DAE.ASUB(exp = e,sub = sub::{}),_))
      equation
        _ = Expression.expInt(sub);
        e = simplifyAsub(e, sub) "For arbitrary vector operations, e.g (a+b-c)[1] => a[1]+b[1]-c[1]" ;
      then
        ((e,true));

    // unary operations
    case (((exp as DAE.UNARY(operator = op,exp = e1)),_)) 
      equation
        e = simplifyUnary(op, e1);
      then
        ((e,true));
    
    // binary operations on arrays
    case (((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),_)) 
      equation
        e_1 = simplifyBinaryArray(e1, op, e2);
      then
        ((e_1,true));
    
    // binary scalar simplifications
    case (((DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),_))
      equation
        e_1 = simplifyBinaryCommutative(op, e1, e2);
      then
        ((e_1,true));
    
    // binary scalar simplifications
    case (((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2)),_))
      equation
        e_1 = simplifyBinary(op, e1, e2);
      then
        ((e_1,true));
    
    // relations 
    case (((exp as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB= isExpisASUB)),_))
      equation
        e = simplifyBinary(op, e1, e2);
      then
        ((e,true));
    
    // logical unary expressions
    case (((DAE.LUNARY(operator = op,exp = e1)),_))
      equation
        e = simplifyUnary(op, e1);
      then
        ((e,true));
    
    // logical binary expressions
    case ((DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),_))
      equation
        e = simplifyBinary(op, e1, e2);
      then
        ((e,true));
    
    // if true and false branches are equal
    case ((DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),_))
      equation
        e = simplifyIfExp(e1,e2,e3);
      then ((e,true));
    
    // component references
    case ((DAE.CREF(componentRef = c_1 as DAE.CREF_IDENT(idn,_,s),ty=t),_))
      equation
        exp1 = simplifyCref(c_1,t);
      then
        ((exp1,true));
    
    case ((DAE.REDUCTION(reductionInfo,e1,riters),_))
      equation
        (riters,b2) = simplifyReductionIterators(riters, {}, false);
        exp1 = DAE.REDUCTION(reductionInfo,e1,riters);
      then ((simplifyReduction(exp1,b2),true));

    // anything else
    else inTpl;
  end matchcontinue;
end simplifyWork;

public function simplify1
"function: simplify1
  This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := simplify1FixP(inExp,100,true);
  checkSimplify(Flags.isSet(Flags.CHECK_SIMPLIFY),inExp,outExp);
end simplify1;

protected function checkSimplify
  "Verifies that the complexity of the expression is lower or equal than before the simplification was performed"
  input Boolean check;
  input DAE.Exp before;
  input DAE.Exp after;
algorithm
  _ := matchcontinue (check,before,after)
    local
      Integer c1,c2;
      Boolean b;
      String s1,s2,s3,s4;
    case (false,_,_) then ();
    case (true,before,after)
      equation
        c1 = Expression.complexity(before);
        c2 = Expression.complexity(after);
        b = c1 < c2;
        s1 = intString(c2);
        s2 = intString(c1);
        s3 = Debug.bcallret1(b,ExpressionDump.printExpStr,before,"");
        s4 = Debug.bcallret1(b,ExpressionDump.printExpStr,after,"");
        Error.assertionOrAddSourceMessage(not b, Error.SIMPLIFICATION_COMPLEXITY, {s1,s2,s3,s4}, Absyn.dummyInfo);
      then ();
  end matchcontinue;
end checkSimplify;

protected function simplify1FixP
"Does fixpoint simplify1 max n times"
  input DAE.Exp inExp;
  input Integer n;
  input Boolean cont;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := match (inExp,n,cont)
    local
      DAE.Exp exp;
      Boolean b;
      String str;
    case (exp,_,false)
      equation
        // print("End fixp: " +& ExpressionDump.printExpStr(exp) +& "\n");
      then (exp,false);
    case (exp,0,_)
      equation
        str = "ExpressionSimplify iterated to the fixpoint maximum for expression: " +& ExpressionDump.printExpStr(exp);
        Error.addMessage(Error.COMPILER_WARNING, {str});
      then (exp,false); 
    case (exp,n,_)
      equation
        // print("simplify1 start: " +& ExpressionDump.printExpStr(exp) +& "\n");
        ((exp,b)) = Expression.traverseExp(exp,simplifyWork,false);
        // print("simplify1 iter: " +& ExpressionDump.printExpStr(exp) +& "\n");
        (exp,_) = simplify1FixP(exp,n-1,b);
      then (exp,b);
  end match;
end simplify1FixP;

protected function simplifyReductionIterators
  input list<DAE.ReductionIterator> iters;
  input list<DAE.ReductionIterator> acc;
  input Boolean change;
  output list<DAE.ReductionIterator> outIters;
  output Boolean outChange;
algorithm
  (outIters,outChange) := match (iters,acc,change)
    local
      Boolean b;
      String id;
      DAE.Exp exp,gexp;
      DAE.Type ty;
      Option<DAE.Exp> ogexp;
      DAE.ReductionIterator iter;
    case ({},acc,change) then (listReverse(acc),change);

    case (DAE.REDUCTIONITER(id,exp,SOME(DAE.BCONST(true)),ty)::iters,acc,_)
      equation
        (iters,change) = simplifyReductionIterators(iters,DAE.REDUCTIONITER(id,exp,NONE(),ty)::acc,true);
      then (iters,change);

    case (DAE.REDUCTIONITER(id,_,SOME(DAE.BCONST(false)),ty)::_,_,_)
      then ({DAE.REDUCTIONITER(id,DAE.LIST({}),NONE(),ty)},true);

    case (iter::iters,acc,change)
      equation
        (iters,change) = simplifyReductionIterators(iters,iter::acc,change);
      then (iters,change);
  end match;
end simplifyReductionIterators;

protected function simplifyIfExp
  "Handles simplification of if-expressions"
  input DAE.Exp cond;
  input DAE.Exp tb;
  input DAE.Exp fb;
  output DAE.Exp exp;
algorithm
  exp := match (cond,tb,fb)
    local
      Boolean remove_if;
      // Condition is constant
    case (DAE.BCONST(true),tb,fb) then tb;
    case (DAE.BCONST(false),tb,fb) then fb;
      // The expression is the condition
    case (exp,DAE.BCONST(true),DAE.BCONST(false)) then exp;
    case (exp,DAE.BCONST(false),DAE.BCONST(true))
      equation
        exp = DAE.LUNARY(DAE.NOT(DAE.ET_BOOL()), exp);
      then exp;
      // Are the branches equal?
    case (cond,tb,fb)
      equation
        true = Expression.expEqual(tb,fb);
      then tb;
  end match;
end simplifyIfExp;

protected function simplifyMetaModelica "simplifies MetaModelica expressions"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue exp
    local
      DAE.Exp e,e1,e2,e1_1,e2_1;
      Boolean b,b1,b2;
      DAE.ExpType tp;
      Absyn.Path path;
      list<DAE.Exp> el;
      Integer i;
      Real r;
      String s,idn;
      Option<DAE.Exp> oe1,foldExp;
      Option<Values.Value> v;
      DAE.Type ty;
      DAE.ReductionIterators riters;
    case DAE.MATCHEXPRESSION(inputs={e}, localDecls={}, cases={
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b1))},localDecls={},body={},result=SOME(e1)),
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b2))},localDecls={},body={},result=SOME(e2))
      })
      equation
        false = boolEq(b1,b2);
        e1_1 = Util.if_(b1,e1,e2);
        e2_1 = Util.if_(b1,e2,e1);
        e = DAE.IFEXP(e, e1_1, e2_1);
      then e;

    case DAE.MATCHEXPRESSION(matchType=DAE.MATCH(switch=_), inputs={e}, localDecls={}, cases={
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b1))},localDecls={},body={},result=SOME(e1)),
        DAE.CASE(patterns={DAE.PAT_WILD()},localDecls={},body={},result=SOME(e2))
      })
      equation
        e1_1 = Util.if_(b1,e1,e2);
        e2_1 = Util.if_(b1,e2,e1);
        e = DAE.IFEXP(e, e1_1, e2_1);
      then e;

    case DAE.CALL(path=Absyn.IDENT("listAppend"),expLst={DAE.LIST(el),e2})
      equation
        e = List.fold(listReverse(el), Expression.makeCons, e2);
      then e;

    case DAE.CALL(path=Absyn.IDENT("listAppend"),expLst={e1,DAE.LIST(valList={})})
      then e1;

    case DAE.CALL(path=path as Absyn.IDENT("intString"),expLst={DAE.ICONST(i)})
      equation
        s = intString(i);
      then DAE.SCONST(s);

    case DAE.CALL(path=path as Absyn.IDENT("realString"),expLst={DAE.RCONST(r)})
      equation
        s = realString(r);
      then DAE.SCONST(s);

    case DAE.CALL(path=path as Absyn.IDENT("boolString"),expLst={DAE.BCONST(b)})
      equation
        s = boolString(b);
      then DAE.SCONST(s);

    case DAE.CALL(path=path as Absyn.IDENT("listReverse"),expLst={DAE.LIST(el)})
      equation
        el = listReverse(el);
        e1_1 = DAE.LIST(el);
      then e1_1;

    case DAE.CALL(path=path as Absyn.IDENT("listReverse"),expLst={DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("list"),ty,v,foldExp),e1,riters)})
      equation
        e1 = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("listReverse"),ty,v,foldExp),e1,riters);
      then e1;

    case DAE.CALL(path=path as Absyn.IDENT("listReverse"),expLst={DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("listReverse"),ty,v,foldExp),e1,riters)})
      equation
        e1 = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("list"),ty,v,foldExp),e1,riters);
      then e1;

    case DAE.CALL(path=path as Absyn.IDENT("listLength"),expLst={DAE.LIST(el)})
      equation
        i = listLength(el);
      then DAE.ICONST(i);

    case DAE.CONS(e1,DAE.LIST(el))
      then DAE.LIST(e1::el);

    case DAE.UNBOX(exp=DAE.BOX(e)) then e;
    case DAE.BOX(DAE.UNBOX(exp=e1)) then e1;

    case DAE.IFEXP(e,DAE.BOX(e1),DAE.BOX(e2))
      equation
        e = DAE.IFEXP(e,e1,e2);
      then DAE.BOX(e);
  end matchcontinue;
end simplifyMetaModelica;

protected function simplifyCast "help function to simplify1"
  input DAE.Exp exp;
  input Type tp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(exp,tp)
    local 
      Real r;
      Integer i,n;
      Boolean b;
      list<DAE.Exp> exps,exps_1;
      Type t,tp_1,tp1,tp2,t1,t2;
      DAE.Exp res,e1,e2,cond,e1_1,e2_1,e;
      list<list<DAE.Exp>> mexps,mexps_1;
    
    // Real -> Real
    case(DAE.RCONST(r),DAE.ET_REAL()) then DAE.RCONST(r);
    
    // Int -> Real
    case(DAE.ICONST(i),DAE.ET_REAL()) 
      equation
        r = intReal(i);
      then 
        DAE.RCONST(r);
      
    // cast of array
    case(DAE.ARRAY(t,b,exps),tp) 
      equation
        tp_1 = Expression.unliftArray(tp);
        exps_1 = List.map1(exps, addCast, tp_1);
      then
        DAE.ARRAY(tp,b,exps_1);
    
    // simplify cast in an if expression
    case (DAE.IFEXP(cond,e1,e2),tp) 
      equation
        e1_1 = DAE.CAST(tp,e1);
        e2_1 = DAE.CAST(tp,e2);
      then DAE.IFEXP(cond,e1_1,e2_1);
    
    // simplify cast of matrix expressions
    case (DAE.MATRIX(t,n,mexps),tp) 
      equation
        tp1 = Expression.unliftArray(tp);
        tp2 = Expression.unliftArray(tp1);
        mexps_1 = List.map1List(mexps, addCast, tp2);
      then DAE.MATRIX(tp,n,mexps_1);
    
    // fill(e, ...) can be simplified
    case(DAE.CALL(path=Absyn.IDENT("fill"),expLst=e::exps),tp) 
      equation
        tp_1 = List.fold(exps,Expression.unliftArrayIgnoreFirst,tp);
        e = DAE.CAST(tp_1,e);
        e = Expression.makeBuiltinCall("fill",e::exps,tp);
      then e;

    // expression already has a specified cast type.
    case(e,tp) 
      equation
        t1 = Expression.arrayEltType(tp);
        t2 = Expression.arrayEltType(Expression.typeof(e));
        true = valueEq(t1, t2);
      then e;
  end matchcontinue;
end simplifyCast;

protected function addCast
"function: addCast
  Adds a cast of a Type to an expression."
  input DAE.Exp inExp;
  input Type inType;
  output DAE.Exp outExp;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outExp:=DAE.CAST(inType,inExp);
end addCast;

protected function simplifyTrigIdentities
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp)
    local
      list<DAE.Exp> expl;
      DAE.Exp e,len_exp,just_exp,e1,e2;
      DAE.ExpType tp;
      list<DAE.Exp> v1, v2;
      Boolean scalar;
      list<Values.Value> valueLst;
      Integer i;
      String str,id1,id2;
      Real r,r1,r2;
    
      /* arcxxx(xxx(e)) => e; xxx(arcxxx(e)) => e */
    case (DAE.CALL(path=Absyn.IDENT("sin"),expLst={DAE.CALL(path=Absyn.IDENT("asin"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("cos"),expLst={DAE.CALL(path=Absyn.IDENT("acos"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("tan"),expLst={DAE.CALL(path=Absyn.IDENT("atan"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("asin"),expLst={DAE.CALL(path=Absyn.IDENT("sin"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("acos"),expLst={DAE.CALL(path=Absyn.IDENT("cos"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("atan"),expLst={DAE.CALL(path=Absyn.IDENT("tan"),expLst={e})}))
      then e;

      /* sin(2*x) = 2*sin(x)*cos(x) */
    case (DAE.BINARY(DAE.CALL(path=Absyn.IDENT(id1),expLst={e1}),DAE.MUL(_),DAE.CALL(path=Absyn.IDENT(id2),expLst={e2})))
      equation
        true = (stringEq(id1,"sin") and stringEq(id2,"cos")) or (stringEq(id1,"cos") and stringEq(id2,"sin"));
        true = Expression.expEqual(e1,e2);
        e = DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),e1);
        e = Expression.makeBuiltinCall("sin",{e},DAE.ET_REAL());
      then DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.ET_REAL()),e);
        
      /* sin^2(x)+cos^2(x) = 1 */
    case (DAE.BINARY(DAE.BINARY(DAE.CALL(path=Absyn.IDENT(id1),expLst={e1}),DAE.POW(DAE.ET_REAL()),DAE.RCONST(r1)),
                     DAE.ADD(_),
                     DAE.BINARY(DAE.CALL(path=Absyn.IDENT(id2),expLst={e2}),DAE.POW(DAE.ET_REAL()),DAE.RCONST(r2))))
      equation
        true = realEq(r1,r2) and realEq(r1,2.0);
        true = (stringEq(id1,"sin") and stringEq(id2,"cos")) or (stringEq(id1,"cos") and stringEq(id2,"sin"));
        true = Expression.expEqual(e1,e2);
      then DAE.RCONST(1.0);

  end matchcontinue;
end simplifyTrigIdentities;

protected function simplifyBuiltinCalls "simplifies some builtin calls (with no constant expressions)"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp)
    local
      list<list<DAE.Exp>> mexpl;
      list<DAE.Exp> es,expl;
      DAE.Exp e,len_exp,just_exp,e1,e2,e3,e4;
      DAE.ExpType tp,tp1,tp2;
      DAE.Operator op;
      list<DAE.Exp> v1, v2;
      Boolean scalar,sc;
      list<Values.Value> valueLst;
      Integer i,i1,i2,dim;
      String str;
      Real r;
    
    // min/max function on arrays of only 1 element
    case (DAE.CALL(path=Absyn.IDENT("min"),expLst={DAE.ARRAY(array={e})})) then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),expLst={DAE.ARRAY(array={e})})) then e;
    // Try to unify the expressions :)
    case (DAE.CALL(path=Absyn.IDENT("min"),expLst={DAE.ARRAY(array=es)},attr=DAE.CALL_ATTR(ty=tp)))
      equation
        i1 = listLength(es);
        es = List.union(es,es);
        i2 = listLength(es);
        false = i1 == i2;
        e = Expression.makeScalarArray(es,tp);
      then Expression.makeBuiltinCall("min",{e},tp);
    case (DAE.CALL(path=Absyn.IDENT("max"),expLst={DAE.ARRAY(array=es)},attr=DAE.CALL_ATTR(ty=tp)))
      equation
        i1 = listLength(es);
        es = List.union(es,es);
        i2 = listLength(es);
        false = i1 == i2;
        e = Expression.makeScalarArray(es,tp);
      then Expression.makeBuiltinCall("max",{e},tp);

    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=tp),expLst={DAE.ARRAY(array={e1,e2})}))
      equation
        e = Expression.makeBuiltinCall("min",{e1,e2},tp);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=tp),expLst={DAE.ARRAY(array={e1,e2})}))
      equation
        e = Expression.makeBuiltinCall("max",{e1,e2},tp);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=DAE.ET_BOOL()),expLst={e1,e2}))
      equation
        e = DAE.LBINARY(e1,DAE.AND(DAE.ET_BOOL()),e2);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=DAE.ET_BOOL()),expLst={e1,e2}))
      equation
        e = DAE.LBINARY(e1,DAE.OR(DAE.ET_BOOL()),e2);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=DAE.ET_BOOL()),expLst={DAE.ARRAY(array=expl)}))
      equation
        e = Expression.makeLBinary(expl,DAE.AND(DAE.ET_BOOL()));
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=DAE.ET_BOOL()),expLst={DAE.ARRAY(array=expl)}))
      equation
        e = Expression.makeLBinary(expl,DAE.OR(DAE.ET_BOOL()));
      then e;

    // cross
    case (e as DAE.CALL(path = Absyn.IDENT("cross"), expLst = expl))
      equation
        {DAE.ARRAY(array = v1),DAE.ARRAY(array = v2)} = expl;
        expl = Static.elabBuiltinCross2(v1, v2);
        tp = Expression.typeof(e);
        // Since there is a bug somewhere in simplify that gives wrong types for arrays we take the type from cross.
        scalar = not Expression.isArrayType(Expression.unliftArray(tp));
      then
        DAE.ARRAY(tp, scalar,expl);
    
    case (e as DAE.CALL(path = Absyn.IDENT("skew"), expLst = {DAE.ARRAY(array = v1)}))
      equation
        mexpl = Static.elabBuiltinSkew2(v1);
        tp = Expression.typeof(e);
      then DAE.MATRIX(tp, 3, mexpl);

    // Simplify built-in function fill. MathCore depends on this being done here, do not remove!
    case (DAE.CALL(path = Absyn.IDENT("fill"), expLst = e::expl))
      equation
        valueLst = List.map(expl, ValuesUtil.expValue);
        (_,outExp,_) = Static.elabBuiltinFill2(Env.emptyCache(), Env.emptyEnv, e, (DAE.T_NOTYPE(),NONE()), valueLst, DAE.C_CONST(),Prefix.NOPRE());
      then
        outExp;

    case (DAE.CALL(path = Absyn.IDENT("String"), expLst = {e,len_exp,just_exp}))
      then simplifyBuiltinStringFormat(e,len_exp,just_exp);

    case (DAE.CALL(path = Absyn.IDENT("stringAppendList"), expLst = {DAE.LIST(expl)}))
      then simplifyStringAppendList(expl,{},false);
        
    // sqrt(e ^ r) => e ^ (0.5 * r)
    case DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={DAE.BINARY(e1,DAE.POW(ty = DAE.ET_REAL()),e2)})
      equation
        e = DAE.BINARY(e1,DAE.POW(DAE.ET_REAL()),DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.ET_REAL()),e2));
      then Expression.makeBuiltinCall("abs",{e},DAE.ET_REAL());
    
    // delay of constant expression
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={e1,_,_})
      equation
        true = Expression.isConst(e1);
      then e1;

    // delay of constant subexpression
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.BINARY(e1,op,e2),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        true = Expression.isConst(e1);
        e = Expression.makeBuiltinCall("delay",{e2,e3,e4},tp);
      then DAE.BINARY(e1,op,e);

    // delay of constant subexpression
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.BINARY(e1,op,e2),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        true = Expression.isConst(e2);
        e = Expression.makeBuiltinCall("delay",{e1,e3,e4},tp);
      then DAE.BINARY(e,op,e2);

    // delay(-x) = -delay(x)
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.UNARY(op,e),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        e = Expression.makeBuiltinCall("delay",{e,e3,e4},tp);
      then DAE.UNARY(op,e);

    // To calculate sums, first try matrix concatenation
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.MATRIX(ty=tp1,matrix=mexpl)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        es = List.flatten(mexpl);
        tp1 = Expression.unliftArray(Expression.unliftArray(tp1));
        sc = not Expression.isArrayType(tp1);
        tp1 = Debug.bcallret1(sc,Expression.unliftArray,tp1,tp1);
        tp1 = Debug.bcallret2(sc,Expression.liftArrayLeft,tp1,DAE.DIM_UNKNOWN(),tp1);
        dim = listLength(es);
        tp1 = Expression.liftArrayLeft(tp1,DAE.DIM_INTEGER(dim));
        e = DAE.ARRAY(tp1,sc,es);
        e = Expression.makeBuiltinCall("sum",{e},tp2);
        // print("Matrix sum: " +& boolString(sc) +& ExpressionDump.typeString(tp1) +& " " +& ExpressionDump.printExpStr(e) +& "\n");
      then e;
    // Then try array concatenation
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array=es,ty=tp1,scalar=false)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        es = simplifyCat(1,es,{},false);
        tp1 = Expression.unliftArray(tp1);
        sc = not Expression.isArrayType(tp1);
        tp1 = Debug.bcallret1(sc,Expression.unliftArray,tp1,tp1);
        tp1 = Debug.bcallret2(sc,Expression.liftArrayLeft,tp1,DAE.DIM_UNKNOWN(),tp1);
        dim = listLength(es);
        tp1 = Expression.liftArrayLeft(tp1,DAE.DIM_INTEGER(dim));
        e = DAE.ARRAY(tp1,sc,es);
        e = Expression.makeBuiltinCall("sum",{e},tp2);
        // print("Array sum: " +& boolString(sc) +& ExpressionDump.typeString(tp1) +& " " +& ExpressionDump.printExpStr(e) +& "\n");
      then e;
    // Try to reduce the number of dimensions
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array={e},scalar=false)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        e = Expression.makeBuiltinCall("sum",{e},tp2);
      then e;
    // The sum of a single array is simply the sum of its elements
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array=es,scalar=true)})
      equation
        e = Expression.makeSum(es);
      then e;

    case DAE.CALL(path=Absyn.IDENT("cat"),expLst=_::{e1}) then e1;

    case DAE.CALL(path=Absyn.IDENT("cat"),expLst=DAE.ICONST(i)::es,attr=DAE.CALL_ATTR(ty=tp))
      equation
        es = simplifyCat(i,es,{},false);
        i = listLength(es);
        e = Expression.makeBuiltinCall("cat",DAE.ICONST(i)::es,tp);
      then e;

  end matchcontinue;
end simplifyBuiltinCalls;

protected function simplifyCat
  input Integer dim;
  input list<DAE.Exp> es;
  input list<DAE.Exp> acc;
  input Boolean changed;
  output list<DAE.Exp> oes;
algorithm
  oes := matchcontinue (dim,es,acc,changed)
    local
      list<DAE.Exp> es1,es2,esn;
      DAE.Exp e;
      DAE.Dimension ndim,dim1,dim2,dim11,dim21;
      list<DAE.Dimension> dims;
      DAE.ExpType etp;
      Integer i1,i2,i;
      list<list<DAE.Exp>> ms1,ms2,mss;
      Boolean sc;
    case (_,{},acc,true) then listReverse(acc);
    case (1,DAE.ARRAY(array=es1,scalar=sc,ty=DAE.ET_ARRAY(arrayDimensions=dim1::dims,ty=etp))::DAE.ARRAY(array=es2,ty=DAE.ET_ARRAY(arrayDimensions=dim2::_))::es,acc,_)
      equation
        esn = listAppend(es1,es2);
        ndim = Expression.addDimensions(dim1,dim2);
        etp = DAE.ET_ARRAY(etp,ndim::dims);
        e = DAE.ARRAY(etp,sc,esn);
      then simplifyCat(dim,e::es,acc,true);
    case (1,DAE.MATRIX(matrix=ms1,integer=i1,ty=DAE.ET_ARRAY(arrayDimensions=dim1::dims,ty=etp))::DAE.MATRIX(matrix=ms2,integer=i2,ty=DAE.ET_ARRAY(arrayDimensions=dim2::_))::es,acc,_)
      equation
        i = i1+i2;
        mss = listAppend(ms1,ms2);
        ndim = Expression.addDimensions(dim1,dim2);
        etp = DAE.ET_ARRAY(etp,ndim::dims);
        e = DAE.MATRIX(etp,i,mss);
      then simplifyCat(dim,e::es,acc,true);
    case (2,DAE.MATRIX(matrix=ms1,integer=i,ty=DAE.ET_ARRAY(arrayDimensions=dim11::dim1::dims,ty=etp))::DAE.MATRIX(matrix=ms2,ty=DAE.ET_ARRAY(arrayDimensions=_::dim2::_))::es,acc,_)
      equation
        mss = List.threadMap(ms1,ms2,listAppend);
        ndim = Expression.addDimensions(dim1,dim2);
        etp = DAE.ET_ARRAY(etp,dim11::ndim::dims);
        e = DAE.MATRIX(etp,i,mss);
      then simplifyCat(dim,e::es,acc,true);
    case (dim,e::es,acc,changed) then simplifyCat(dim,es,e::acc,changed);
  end matchcontinue;
end simplifyCat;

protected function simplifyBuiltinStringFormat
  input DAE.Exp exp;
  input DAE.Exp len_exp;
  input DAE.Exp just_exp;
  output DAE.Exp outExp;
algorithm
  outExp := match (exp,len_exp,just_exp)
    local
      Integer i,len;
      Real r;
      Boolean b,just;
      String str;
      Absyn.Path name;
    case (DAE.ICONST(i),DAE.ICONST(len),DAE.BCONST(just))
      equation
        str = intString(i);
        str = cevalBuiltinStringFormat(str,stringLength(str),len,just);
      then DAE.SCONST(str);
    case (DAE.RCONST(r),DAE.ICONST(len),DAE.BCONST(just))
      equation
        str = realString(r);
        str = cevalBuiltinStringFormat(str,stringLength(str),len,just);
      then DAE.SCONST(str);
    case (DAE.BCONST(b),DAE.ICONST(len),DAE.BCONST(just))
      equation
        str = boolString(b);
        str = cevalBuiltinStringFormat(str,stringLength(str),len,just);
      then DAE.SCONST(str);
    case (DAE.ENUM_LITERAL(name=name),DAE.ICONST(len),DAE.BCONST(just))
      equation
        str = Absyn.pathLastIdent(name);
        str = cevalBuiltinStringFormat(str,stringLength(str),len,just);
      then DAE.SCONST(str);
  end match;
end simplifyBuiltinStringFormat;

public function cevalBuiltinStringFormat
  "Helper function to cevalBuiltinStringFormat, does the actual formatting."  
  input String inString;
  input Integer stringLength;
  input Integer minLength;
  input Boolean leftJustified;
  output String outString;
algorithm
  outString := matchcontinue(inString, stringLength, minLength, leftJustified)
    local
      String str;
      Integer fill_size;
    // The string is longer than the minimum length, do nothing.
    case (_, _, _, _)
      equation
        true = stringLength >= minLength;
      then
        inString;
    // leftJustified is false, append spaces at the beginning of the string.
    case (_, _, _, false)
      equation
        fill_size = minLength - stringLength;
        str = stringAppendList(List.fill(" ", fill_size)) +& inString;
      then
        str;
    // leftJustified is true, append spaces at the end of the string.
    case (_, _, _, true)
      equation
        fill_size = minLength - stringLength;
        str = inString +& stringAppendList(List.fill(" ", fill_size));
      then
        str;
  end matchcontinue;
end cevalBuiltinStringFormat;

protected function simplifyStringAppendList
"
stringAppendList({abc,def,String(time),ghi,jkl}) => stringAppendList({abcdef,String(time),ghijkl})
stringAppendList({abc,def,ghi,jkl}) => abcdefghijkl
stringAppendList({}) => abcdefghijkl
"
  input list<DAE.Exp> expl;
  input list<DAE.Exp> acc;
  input Boolean change;
  output DAE.Exp exp;
algorithm
  exp := match (expl,acc,change)
    local
      String s1,s2,s;
      DAE.Exp exp,exp1,exp2;
      list<DAE.Exp> rest;
    case ({},{},_) then DAE.SCONST("");
    case ({},{exp},_) then exp;
    case ({},{exp1,exp2},_)
      then DAE.BINARY(exp2,DAE.ADD(DAE.ET_STRING()),exp1);
    case ({},acc,true)
      equation
        acc = listReverse(acc);
        exp = DAE.LIST(acc);
      then Expression.makeBuiltinCall("stringAppendList",{exp},DAE.ET_STRING());
    case (DAE.SCONST(s1)::rest,DAE.SCONST(s2)::acc,_)
      equation
        s = s2 +& s1;
      then simplifyStringAppendList(rest,DAE.SCONST(s)::acc,true);
    case (exp::rest,acc,change) then simplifyStringAppendList(rest,exp::acc,change);
  end match;
end simplifyStringAppendList;

protected function simplifyBuiltinConstantCalls "simplifies some builtin calls if constant arguments"
  input DAE.Exp exp "assumes already simplified call arguments";
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue exp
    local 
      Boolean b;
      Real r,v1,v2;
      Integer i, j;
      Absyn.Path path;
      DAE.Exp e,e1;
    
    // der(constant) ==> 0
    case (DAE.CALL(path=Absyn.IDENT("der"),expLst ={e}))
      equation
        e1 = simplifyBuiltinConstantDer(e);
      then e1;
    
    // pre(constant) ==> constant
    case (DAE.CALL(path=Absyn.IDENT("pre"),expLst ={e}))
      then e;

    // edge(constant) ==> false
    case (DAE.CALL(path=Absyn.IDENT("edge"),expLst ={e}))
      then DAE.BCONST(false);

    // edge(constant) ==> false
    case (DAE.CALL(path=Absyn.IDENT("change"),expLst ={e}))
      then DAE.BCONST(false);

    // sqrt function
    case(DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e})) 
      equation
        r = realSqrt(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // abs on real
    case(DAE.CALL(path=Absyn.IDENT("abs"),expLst={DAE.RCONST(r)})) 
      equation
        r = realAbs(r);
      then 
        DAE.RCONST(r);
    
    // abs on integer 
    case(DAE.CALL(path=Absyn.IDENT("abs"),expLst={DAE.ICONST(i)})) 
      equation
        i = intAbs(i);
      then 
        DAE.ICONST(i);
    
    // sin function
    case(DAE.CALL(path=Absyn.IDENT("sin"),expLst={e})) 
      equation
        r = realSin(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // cos function
    case(DAE.CALL(path=Absyn.IDENT("cos"),expLst={e})) 
      equation
        r = realCos(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // tangent function
    case(DAE.CALL(path=Absyn.IDENT("tan"),expLst={e})) 
      equation
        v1 = realSin(Expression.getRealConst(e));
        v2 = realCos(Expression.getRealConst(e));
        r = v1 /. v2;
      then 
        DAE.RCONST(r);
    
    // DAE.Exp function
    case(DAE.CALL(path=Absyn.IDENT("exp"),expLst={e})) 
      equation
        r = realExp(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
    
    // log function
    case(DAE.CALL(path=Absyn.IDENT("log"),expLst={e})) 
      equation
        r = realLn(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
        
    // log10 function
    case(DAE.CALL(path=Absyn.IDENT("log10"),expLst={e})) 
      equation
        r = realLog10(Expression.getRealConst(e));
      then 
        DAE.RCONST(r);
        
    // min function on integers
    case(DAE.CALL(path=Absyn.IDENT("min"),expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        i = intMin(i, j);
      then DAE.ICONST(i);

    // min function on reals
    case(DAE.CALL(path=Absyn.IDENT("min"),expLst={e, e1})) 
      equation
        v1 = Expression.getRealConst(e);
        v2 = Expression.getRealConst(e1);
        r = realMin(v1, v2);
      then DAE.RCONST(r);

    // min function on integers
    case(DAE.CALL(path=Absyn.IDENT("max"),expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        i = intMax(i, j);
      then DAE.ICONST(i);

    // max function on reals
    case(DAE.CALL(path=Absyn.IDENT("max"),expLst={e, e1})) 
      equation
        v1 = Expression.getRealConst(e);
        v2 = Expression.getRealConst(e1);
        r = realMax(v1, v2);
      then DAE.RCONST(r);
  end matchcontinue;
end simplifyBuiltinConstantCalls;

protected function simplifyIdentity ""
  input Integer row;
  input Integer n;
  output list<DAE.Exp> outExp;
algorithm
  outExp := matchcontinue(row,n)
    local
      list<DAE.Exp> rowExps;
      DAE.Exp arrExp;
    
    case(row,n) // bottom right
      equation
        true = intEq(row,n);
        rowExps = simplifyIdentityMakeRow(n,1,row);
      then
       {DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT(),{DAE.DIM_INTEGER(n)}),true,rowExps)};
    
    case(row,n) // bottom right
      equation
        true = row < n;
        rowExps = simplifyIdentityMakeRow(n,1,row);
        outExp = simplifyIdentity(row+1,n);
        arrExp = DAE.ARRAY(DAE.ET_ARRAY(DAE.ET_INT(),{DAE.DIM_INTEGER(n)}),true,rowExps);
      then
        arrExp::outExp;
  end matchcontinue;
end simplifyIdentity;

protected function simplifyIdentityMakeRow ""
  input Integer n;
  input Integer col;
  input Integer row;
  output list<DAE.Exp> expl;
algorithm
  expl := matchcontinue(n,col,row)
    local
      Integer i;
    
    case(n,col,row)
      equation
        true = intEq(n,col);
        i = Util.if_(intEq(col,row),1,0);
      then
        {DAE.ICONST(i)};
    
    case(n,col,row)
      equation
        true = col < n;
        i = Util.if_(intEq(col,row),1,0);
        expl = simplifyIdentityMakeRow(n,col+1,row);
      then
        DAE.ICONST(i)::expl;
  end matchcontinue;
end simplifyIdentityMakeRow;

protected function simplifyCref
" Function for simplifying
  x[{y,z,q}] to {x[y], x[z], x[q]}"
  input ComponentRef inCREF;
  input Type inType;
  output DAE.Exp exp;
algorithm
  exp := match (inCREF, inType)
    local
      Type t,t2;
      list<Subscript> ssl;
      ComponentRef cr;
      Ident idn;
      list<DAE.Exp> expl_1;
      DAE.Exp expCref;
      
    case(DAE.CREF_IDENT(idn,t2,(ssl as ((DAE.SLICE(DAE.ARRAY(_,_,expl_1))) :: _))),t)
      equation
        cr = ComponentReference.makeCrefIdent(idn,t2,{});
        expCref = Expression.makeCrefExp(cr,t);
        exp = simplifyCref2(expCref,ssl);
      then
        exp;
  end match;
end simplifyCref;

protected function simplifyCref2
"Helper function for simplifyCref
 Does the recursion."
  input DAE.Exp inExp;
  input list<Subscript> inSsl;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp,inSsl)
    local
      Ident idn;
      Type t,tp;
      DAE.Exp exp_1, crefExp, exp;
      list<DAE.Exp> expl_1,expl;
      Subscript ss;
      list<Subscript> ssl,ssl_2,subs;
      list<ComponentRef> crefs;
      ComponentRef cr;
      Integer dim;
      Boolean sc;
    
    case(exp_1,{}) then exp_1;
    
    case(DAE.CREF(cr as DAE.CREF_IDENT(idn, _,ssl_2),t), ((ss as (DAE.SLICE(DAE.ARRAY(_,_,(expl_1))))) :: ssl))
      equation
        subs = List.map(expl_1,Expression.makeIndexSubscript);
        crefs = List.map1r(List.map(subs,List.create),ComponentReference.subscriptCref,cr);
        expl = List.map1(crefs,Expression.makeCrefExp,t);
        dim = listLength(expl);
        exp = simplifyCref2(DAE.ARRAY(DAE.ET_ARRAY(t,{DAE.DIM_INTEGER(dim)}),true,expl),ssl);
      then
        exp;
    
    case(crefExp as DAE.ARRAY(tp,sc,expl), ssl )
      equation
        expl = List.map1(expl,simplifyCref2,ssl);
      then
        DAE.ARRAY(tp,sc,expl);
    
  end matchcontinue;
end simplifyCref2;

public function simplify2
"Advanced simplifications covering several
 terms or factors, like a +2a +3a = 5a "
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp)
    local 
      DAE.Exp e,exp,e1,e2,exp_2,exp_3;
      Operator op;
    
    case ((exp as DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))) /* multiple terms/factor simplifications */
      equation
        true = Expression.isIntegerOrReal(Expression.typeof(exp));
        e1 = simplify2(e1);
        e2 = simplify2(e2);
        /* Sorting constants, 1+a+2+b => 3+a+b */
        exp_2 = simplifyBinarySortConstants(DAE.BINARY(e1,op,e2));
        /* Merging coefficients 2a+4b+3a+b => 5a+5b */
        exp_3 = simplifyBinaryCoeff(exp_2);
      then
        exp_3;
    
    case(DAE.UNARY(op,e1)) 
      equation
        e1 = simplify2(e1);
      then 
        DAE.UNARY(op,e1);
        
    case (e) then e;
    
  end matchcontinue;
end simplify2;

protected function simplifyBinaryArray "function: simplifyBinaryArray
  Simplifies binary array expressions,
  e.g. matrix multiplication, etc."
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      DAE.Exp e_1,e1,e2,res,s1,a1;
      Type tp,atp,atp2;
      Boolean b;
      Operator op2,op;
    
    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation
        e_1 = simplifyMatrixProduct(e1, e2);
      then
        e_1;
    
    case(e1,op as DAE.ADD_ARR(ty = _),e2)
      equation
        a1 = simplifyVectorBinary0(e1,op,e2);
      then 
        a1;
    
    case (e1,op as DAE.SUB_ARR(ty = _),e2)
      equation
        a1 = simplifyVectorBinary0(e1, op, e2);
      then
        a1;
    
    case (e1,DAE.MUL_ARR(ty = _),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, DAE.MUL(tp), e2);
      then a1;

    case (e1,DAE.DIV_ARR(ty = _),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, DAE.DIV(tp), e2);
      then a1;

    case (e1,DAE.POW_ARR(ty = _),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyMatrixPow(e1, tp, e2);
      then a1;

    case (e1,DAE.POW_ARR2(ty = _),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, DAE.POW(tp), e2);
      then a1;

    // v1 - -v2 => v1 + v2
    case (e1,DAE.SUB_ARR(ty=tp),DAE.UNARY(_,e2))
      then 
        DAE.BINARY(e1,DAE.ADD_ARR(tp),e2);

    // v1 + -v2 => v1 - v2
    case (e1,DAE.ADD_ARR(ty=tp),DAE.UNARY(_,e2))
      then 
        DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);

    // matrix * scalar
    case (a1 as DAE.MATRIX(ty =_),DAE.MUL_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(Expression.unliftArray(atp));
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_ARRAY_SCALAR(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array * scalar
    case (a1,DAE.MUL_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.MUL_ARRAY_SCALAR(atp2),DAE.MUL(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array .+ scalar
    case (a1,DAE.ADD_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.ADD_ARRAY_SCALAR(atp2),DAE.ADD(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // scalar .- array
    case (s1,DAE.SUB_SCALAR_ARRAY(ty = tp),a1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.SUB_SCALAR_ARRAY(atp2),DAE.SUB(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // scalar ./ array
    case (s1,DAE.DIV_SCALAR_ARRAY(ty = tp),a1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_SCALAR_ARRAY(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // matrix / scalar
    case (a1 as DAE.MATRIX(ty =_),DAE.DIV_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(Expression.unliftArray(atp));
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_ARRAY_SCALAR(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    // array / scalar
    case (a1,DAE.DIV_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.DIV_ARRAY_SCALAR(atp2),DAE.DIV(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    // scalar .^ array
    case (s1,DAE.POW_SCALAR_ARRAY(ty = tp),a1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.POW_SCALAR_ARRAY(atp2),DAE.POW(tp));
        res = simplifyVectorScalar(s1, op2, a1);
      then
        res;

    // array .+ scalar
    case (a1,DAE.POW_ARRAY_SCALAR(ty = tp),s1)
      equation
        tp = Expression.typeof(s1);
        atp = Expression.typeof(a1);
        atp2 = Expression.unliftArray(atp);
        b = DAEUtil.expTypeArray(atp2);
        op2 = Util.if_(b,DAE.POW_ARRAY_SCALAR(atp2),DAE.POW(tp));
        res = simplifyVectorScalar(a1, op2, s1);
      then
        res;

    case (e1,DAE.MUL_SCALAR_PRODUCT(ty = tp),e2)
      equation
        res = simplifyScalarProduct(e1, e2);
      then
        res;

    case (e1,DAE.MUL_MATRIX_PRODUCT(ty = tp),e2)
      equation
        res = simplifyScalarProduct(e1, e2);
      then
        res;

    case (e1,op as DAE.ADD_ARR(ty = _),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
      then a1;

    case (e1,op as DAE.SUB_ARR(ty = _),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
        // print("simplifyMatrixBinary: " +& ExpressionDump.printExpStr(e1) +& "=>" +& ExpressionDump.printExpStr(a1) +& "\n");
      then a1;
  end matchcontinue;
end simplifyBinaryArray;

public function simplifyScalarProduct
"function: simplifyScalarProduct
  author: PA
  Simplifies scalar product:
   v1v2, M  v1 and v1  M
  for vectors v1,v2 and matrix M."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inExp2)
    local
      list<DAE.Exp> expl,expl1,expl2,expl_1;
      DAE.Exp exp;
      Type tp1,tp2,tp;
      Boolean sc1,sc2,sc;
      Integer size;
      list<list<DAE.Exp>> lstexpl1,lstexpl2;
      DAE.Dimension d;
    
    case (DAE.ARRAY(ty = tp1,scalar = sc1,array = expl1),DAE.ARRAY(ty = tp2,scalar = sc2,array = expl2)) /* v1  v2 */
      equation
        expl = List.threadMap(expl1, expl2, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
      then
        exp;
    
    // M * v1, use first dimension of M as the dimension of the result, in case the array has dimension 1, i.e. is a scalar.
    case (DAE.MATRIX(ty = DAE.ET_ARRAY(ty = tp1, arrayDimensions = d :: _), matrix = lstexpl1),
          DAE.ARRAY(scalar = sc,array = expl2))
      equation
        expl_1 = simplifyScalarProductMatrixVector(lstexpl1, expl2);
      then
        DAE.ARRAY(DAE.ET_ARRAY(tp1, {d}),sc,expl_1);
    
    case (DAE.ARRAY(ty = tp1,scalar = sc,array = expl1),
          DAE.MATRIX(ty = tp2,integer = size,matrix = lstexpl2))
      equation
        expl_1 = simplifyScalarProductVectorMatrix(expl1, lstexpl2);
      then
        DAE.ARRAY(tp2,sc,expl_1);
    
    case (DAE.ARRAY(ty = tp as DAE.ET_ARRAY(arrayDimensions= _::_::{}),array = expl1),exp as 
          DAE.ARRAY(ty = tp2,scalar = sc,array = expl2))
      equation 
        expl_1 = simplifyScalarProductMatrixVector1(expl1, expl2);
      then
        DAE.ARRAY(tp2,sc,expl_1);
  end matchcontinue;
end simplifyScalarProduct;

protected function simplifyScalarProductMatrixVector
"function: simplifyScalarProductMatrixVector
  Simplifies scalar product of matrix  vector."
  input list<list<DAE.Exp>> inTplExpBooleanLstLst;
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inTplExpBooleanLstLst,inExpLst)
    local
      list<DAE.Exp> row_1,expl,res,v1;
      DAE.Exp exp;
      list<DAE.Exp> row;
      list<list<DAE.Exp>> rows;
      Integer x;
    
    case ({},_) then {};
    
    case ((row :: rows),v1)
      equation
        row_1 = row;
        x = listLength(row_1);
        true = (x<=0);
        res = simplifyScalarProductMatrixVector(rows, v1);
      then
        (DAE.ICONST(0) :: res);
    
    case ((row :: rows),v1)
      equation
        row_1 = row;
        expl = List.threadMap(row_1, v1, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
        res = simplifyScalarProductMatrixVector(rows, v1);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductMatrixVector;

protected function simplifyScalarProductMatrixVector1
"function: simplifyScalarProductMatrixVector1
  Simplifies scalar product of matrix  vector."
  input list<DAE.Exp> inExpLst;
  input list<DAE.Exp> inExpLst1;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := match (inExpLst,inExpLst1)
    local
      list<DAE.Exp> row,rows,res,v1,expl;
      DAE.Exp exp;
    
    case ({},_) then {};
    
    case ((DAE.ARRAY(array=row) :: rows),v1)
      equation
        expl = List.threadMap(row, v1, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
        res = simplifyScalarProductMatrixVector1(rows, v1);
      then
        (exp :: res);
  end match;
end simplifyScalarProductMatrixVector1;

protected function simplifyScalarProductVectorMatrix
"function: simplifyScalarProductVectorMatrix
  Simplifies scalar product of vector  matrix"
  input list<DAE.Exp> inExpLst;
  input list<list<DAE.Exp>> inTplExpBooleanLstLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst,inTplExpBooleanLstLst) // non working
    local
      list<DAE.Exp> row_1,expl,res,v1;
      DAE.Exp exp;
      DAE.Exp texp;
      list<DAE.Exp> heads;
      list<list<DAE.Exp>> rows,tails;
    
    case (v1,  ((texp :: {}) :: rows)    )
      equation
        heads = List.map(((texp :: {}) :: rows),List.first);
        row_1 = heads;
        expl = List.threadMap(v1, row_1, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
      then
        (exp :: {});
    
    case (v1,(rows))
      equation
        heads = List.map((rows),List.first);
        tails = List.map((rows),List.rest);
        row_1 = heads;
        expl = List.threadMap(v1, row_1, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
        res = simplifyScalarProductVectorMatrix(v1, tails);
      then
        (exp :: res);
  end matchcontinue;
end simplifyScalarProductVectorMatrix;

protected function simplifyVectorScalar
"function: simplifyVectorScalar
  Simplifies vector scalar operations."
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      DAE.Exp s1,e1,e;
      Operator op;
      Type tp;
      Boolean sc;
      list<DAE.Exp> es_1,es;
      list<list<DAE.Exp>> mexpl;
      Integer dims;
    
    // scalar operator array
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = {})) then DAE.ARRAY(tp,sc,{DAE.BINARY(s1,op,DAE.ICONST(0))});
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = {e1})) then DAE.ARRAY(tp,sc,{DAE.BINARY(s1,op,e1)});
    
    case (s1,op,DAE.ARRAY(ty = tp,scalar = sc,array = (e1 :: es)))
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorScalar(s1, op, DAE.ARRAY(tp,sc,es));
      then
        DAE.ARRAY(tp,sc,(DAE.BINARY(s1,op,e1) :: es_1));

    case (s1,op,DAE.MATRIX(tp,dims,mexpl)) 
      equation
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,false /*scalar-array*/);
      then 
        DAE.MATRIX(tp,dims,mexpl);

    // array operator scalar
    case (DAE.ARRAY(ty = tp,scalar = sc,array = {}),op,s1) then DAE.ARRAY(tp,sc,{/*DAE.BINARY(DAE.ICONST(0),op,s1)*/});
    case (DAE.ARRAY(ty = tp,scalar = sc,array = {e1}),op,s1) 
      equation
        e = DAE.BINARY(e1,op,s1);
      then 
        DAE.ARRAY(tp,sc,{e});
    
    case (DAE.ARRAY(ty = tp,scalar = sc,array = (e1 :: es)),op,s1)
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorScalar(DAE.ARRAY(tp,sc,es),op,s1);
        e = DAE.BINARY(e1,op,s1);
      then
        DAE.ARRAY(tp,sc,(e :: es_1));

    case (DAE.MATRIX(tp,dims,mexpl),op,s1) 
      equation
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,true/*array-scalar*/);
      then 
        DAE.MATRIX(tp,dims,mexpl);
  end matchcontinue;
end simplifyVectorScalar;

protected function simplifyVectorBinary0 "help function to simplify1, prevents simplify1 to be called multiple times
 in subsequent cases"
  input DAE.Exp e1;
  input Operator op;
  input DAE.Exp e2;
  output DAE.Exp res;
algorithm
  res := matchcontinue(e1,op,e2)
    local DAE.Exp a1;
    
    case(e1,op,e2) 
      equation
        a1 = simplifyVectorBinary(e1,op,e2);
      then a1;
    
    case(e1,DAE.ADD(ty=_),e2) 
      equation
        true = Expression.isZero(e1);
      then 
        e2;
        
    case(e1,DAE.ADD_ARR(ty=_),e2) 
      equation
        true = Expression.isZero(e1);
      then 
        e2;

    case(e1,DAE.SUB_ARR(ty=_),e2) 
      equation
        true = Expression.isZero(e1);
      then 
        Expression.negate(e2);

    case(e1,DAE.SUB(ty=_),e2) 
      equation
        true = Expression.isZero(e1);
      then 
        Expression.negate(e2);
    
    case(e1,op,e2) 
      equation
        true = Expression.isZero(e2);
      then 
        e1;
  end matchcontinue;
end simplifyVectorBinary0;

protected function simplifyVectorBinary
"function: simlify_binary_array
  author: PA
  Simplifies vector addition and subtraction"
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type tp1,tp2;
      Boolean scalar1,scalar2;
      DAE.Exp e1,e2;
      Operator op,op2;
      list<DAE.Exp> es_1,es1,es2;
    
    case (DAE.ARRAY(ty = tp1,scalar = scalar1,array = {e1}),
          op,
         DAE.ARRAY(ty = tp2,scalar = scalar2,array = {e2}))
      equation
        op2 = removeOperatorDimension(op);
      then 
        DAE.ARRAY(tp1,scalar1,{DAE.BINARY(e1,op2,e2)});  /* resulting operator */

    case (DAE.ARRAY(ty = tp1,scalar = scalar1,array = (e1 :: es1)),
          op,
          DAE.ARRAY(ty = tp2,scalar = scalar2,array = (e2 :: es2)))
      equation
        DAE.ARRAY(_,_,es_1) = simplifyVectorBinary(DAE.ARRAY(tp1,scalar1,es1), op, DAE.ARRAY(tp2,scalar2,es2));
        op2 = removeOperatorDimension(op);
      then
        DAE.ARRAY(tp1,scalar1,(DAE.BINARY(e1,op2,e2) :: es_1));
  end matchcontinue;
end simplifyVectorBinary;

protected function simplifyMatrixBinary
"function: simlify_binary_matrix
  author: PA
  Simplifies matrix addition and subtraction"
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      Type tp1,tp2;
      Integer integer1,integer2,i1,i2;
      list<DAE.Exp> e,e1,e2;
      Operator op,op2;
      list<list<DAE.Exp>> es_1,es1,es2;
      list<DAE.Exp> el1,el2;
      DAE.Exp exp1;
    case (DAE.MATRIX(ty = tp1,integer=integer1,matrix = {e1}),
          op,
         DAE.MATRIX(ty = tp2,integer=integer2,matrix = {e2}))
      equation
        op2 = removeOperatorDimension(op);
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp1,integer1,{e});  /* resulting operator */

    case (DAE.MATRIX(ty = tp1,integer=integer1,matrix = (e1 :: es1)),
          op,
          DAE.MATRIX(ty = tp2,integer=integer2,matrix = (e2 :: es2)))
      equation
        op2 = removeOperatorDimension(op);
        e = simplifyMatrixBinary1(e1,op2,e2);
        i1 = integer1-1;
        i2 = integer2-1;
        DAE.MATRIX(matrix = es_1) = simplifyMatrixBinary(DAE.MATRIX(tp1,i1,es1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp1,integer1,(e :: es_1));
        
    // because identity is array of array    
    case (DAE.ARRAY(ty=tp1,scalar=false,array={exp1 as DAE.ARRAY(array=el2)}),
          op,
         DAE.MATRIX(ty = tp2,integer=integer2,matrix = {e2}))
      equation
        op2 = removeOperatorDimension(op);
        e1 = el2;
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp2,integer2,{e});  /* resulting operator */        
        
    case (DAE.ARRAY(ty=tp1,scalar=false,array=((exp1 as DAE.ARRAY(array=el2))::el1)),
          op,     
          DAE.MATRIX(ty = tp2,integer=integer2,matrix = (e2 :: es2)))
      equation
        op2 = removeOperatorDimension(op);
        e1 = el2;
        e = simplifyMatrixBinary1(e1,op2,e2);
        i2 = integer2-1;
        DAE.MATRIX(_,_,es_1) = simplifyMatrixBinary(DAE.ARRAY(tp1,false,el1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp2,integer2,(e :: es_1));
     
    case (DAE.MATRIX(ty = tp2,integer=integer2,matrix = {e2}),
          op,
         DAE.ARRAY(ty=tp1,scalar=false,array={exp1 as DAE.ARRAY(array=el2)}))
      equation
        op2 = removeOperatorDimension(op);
        e1 = el2;
        e = simplifyMatrixBinary1(e1,op2,e2);
      then DAE.MATRIX(tp2,integer2,{e});  /* resulting operator */        
        
    case (DAE.MATRIX(ty = tp2,integer=integer2,matrix = (e2 :: es2)),
          op,     
          DAE.ARRAY(ty=tp1,scalar=false,array=((exp1 as DAE.ARRAY(array=el2))::el1)))
      equation
        op2 = removeOperatorDimension(op);
        e1 = el2;
        e = simplifyMatrixBinary1(e1,op2,e2);
        i2 = integer2-1;
        DAE.MATRIX(matrix = es_1) = simplifyMatrixBinary(DAE.ARRAY(tp1,false,el1), op, DAE.MATRIX(tp2,i2,es2));
      then
        DAE.MATRIX(tp2,integer2,(e :: es_1));
                  
  end matchcontinue;
end simplifyMatrixBinary;

protected function simplifyMatrixBinary1
"function: simlify_binary_matrix
  author: PA
  Simplifies matrix addition and subtraction"
  input list<DAE.Exp> inExp1;
  input Operator inOperator2;
  input list<DAE.Exp> inExp3;
  output list<DAE.Exp> outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inOperator2,inExp3)
    local
      DAE.Exp e1,e2,e;
      Boolean b1,b2,b;
      Operator op,op2;
      list<DAE.Exp> es_1,es1,es2;
    case ({e1},op,{e2})
      equation
        op2 = removeOperatorDimension(op);
        // failure(_ = removeOperatorDimension(op2));
        e = DAE.BINARY(e1,op2,e2);
      then {e};  // resulting operator 
    case (e1::es1,op,e2::es2)
      equation
        op2 = removeOperatorDimension(op);
        e = DAE.BINARY(e1,op2,e2);
        es_1 = simplifyMatrixBinary1(es1, op, es2);
      then
        e :: es_1;
  end matchcontinue;
end simplifyMatrixBinary1;

protected function simplifyMatrixPow
"function: simplifyMatrixPow
  author: Frenkel TUD
  Simplifies matrix powers."
  input DAE.Exp inExp1;
  input Type inType;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp1,inType,inExp2)
    local
      list<list<DAE.Exp>> expl_1,expl1,expl2;
      list<DAE.Exp> el;
      Type tp1,tp;
      Integer size1,i,i_1;
      list<Integer> range;
      DAE.Exp e,m,res;
    /* A^0=I */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,matrix = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        0=i;
        el = List.fill(DAE.RCONST(0.0),size1);
        expl2 =  List.fill(el,size1);
        range = List.intRange2(0,size1-1);
        expl_1 = simplifyMatrixPow1(range,expl2,DAE.RCONST(1.0));
      then
        DAE.MATRIX(tp1,size1,expl_1);
    /* A^1=A */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,matrix = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        1=i;
      then
        m;
    /* A^i */
    case (m as DAE.MATRIX(ty = tp1,integer = size1,matrix = expl1),tp,
          DAE.ICONST(integer = i))
      equation
        true = 1 < i;
        i_1 = i - 1;
        e = simplifyMatrixPow(m,tp1,DAE.ICONST(i_1));
        res = simplifyMatrixProduct(m,e);
      then
        res;
  end matchcontinue;
end simplifyMatrixPow;

protected function simplifyMatrixPow1
"function: simplifyMatrixPow1
  author: Frenkel TUD
  Simplifies matrix powers."
  input list<Integer> inRange;
  input list<list<DAE.Exp>> inMatrix;
  input DAE.Exp inValue;
  output list<list<DAE.Exp>> outMatrix;
algorithm
  outMatrix:=
  matchcontinue (inRange,inMatrix,inValue)
    local
      list<list<DAE.Exp>> rm,rm1;
      list<DAE.Exp> row,row1;
      DAE.Exp e;
      Integer i;
      list<Integer> rr;
    case ({},{},e)
      then
        {};
    case (i::{},row::{},e)
      equation
        row1 = List.replaceAt(e,i,row);
      then
        {row1};
    case (i::rr,row::rm,e)
      equation
        row1 = List.replaceAt(e,i,row);
        rm1 = simplifyMatrixPow1(rr,rm,e);
      then
        row1::rm1;
  end matchcontinue;
end simplifyMatrixPow1;

protected function simplifyMatrixProduct
"function: simplifyMatrixProduct
  author: PA
  Simplifies matrix products A * B for matrices A and B."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output DAE.Exp outExp;
algorithm
  outExp := match (inExp1,inExp2)
    local
      list<list<DAE.Exp>> expl_1,expl1,expl2;
      Type tp;
      Integer size1,size2;
      DAE.Dimension n, p;
    /* A[n, m] * B[m, p] = C[n, p] */
    case (DAE.MATRIX(ty = DAE.ET_ARRAY(ty = tp, arrayDimensions = {n, _}),integer = size1,matrix = expl1),
          DAE.MATRIX(ty = DAE.ET_ARRAY(arrayDimensions = {_, p}),integer = size2,matrix = expl2))
      equation
        expl_1 = simplifyMatrixProduct2(expl1, expl2);
      then
        DAE.MATRIX(DAE.ET_ARRAY(tp, {n, p}),size1,expl_1);
  end match;
end simplifyMatrixProduct;

protected function simplifyMatrixProduct2
"function: simplifyMatrixProduct2
  author: PA
  Helper function to simplifyMatrixProduct."
  input list<list<DAE.Exp>> inTplExpBooleanLstLst1;
  input list<list<DAE.Exp>> inTplExpBooleanLstLst2;
  output list<list<DAE.Exp>> outTplExpBooleanLstLst;
algorithm
  outTplExpBooleanLstLst:=
  match (inTplExpBooleanLstLst1,inTplExpBooleanLstLst2)
    local
      list<DAE.Exp> res1,e1lst;
      list<list<DAE.Exp>> res2,rest1,m2;
    case ((e1lst :: rest1),m2)
      equation
        res1 = simplifyMatrixProduct3(e1lst, m2);
        res2 = simplifyMatrixProduct2(rest1, m2);
      then
        (res1 :: res2);
    case ({},_) then {};
  end match;
end simplifyMatrixProduct2;

protected function simplifyMatrixProduct3
"function: simplifyMatrixProduct3
  author: PA
  Helper function to simplifyMatrixProduct2. Extract each column at
  a time from the second matrix to calculate vector products with the
  first argument."
  input list<DAE.Exp> inTplExpBooleanLst;
  input list<list<DAE.Exp>> inTplExpBooleanLstLst;
  output list<DAE.Exp> outTplExpBooleanLst;
algorithm
  outTplExpBooleanLst:=
  matchcontinue (inTplExpBooleanLst,inTplExpBooleanLstLst)
    local
      list<DAE.Exp> first_col,es,expl;
      list<list<DAE.Exp>> mat_1,mat;
      DAE.Exp e_1;
      Type tp;
      Boolean builtin;
    case ({},_) then {};
    case (expl,mat)
      equation
        first_col = List.map(mat, List.first);
        mat_1 = List.map(mat, List.rest);
        e_1 = simplifyMatrixProduct4(expl, first_col);
        //tp = Expression.typeof(e_1);
        //builtin = Expression.typeBuiltin(tp);
        es = simplifyMatrixProduct3(expl, mat_1);
      then
        (e_1 :: es);
    case (_,_) then {};
  end matchcontinue;
end simplifyMatrixProduct3;

protected function simplifyMatrixProduct4
"function simplifyMatrixProduct4
  author: PA
  Helper function to simplifyMatrix3,
  performs a scalar mult of vectors"
  input list<DAE.Exp> inTplExpBooleanLst1;
  input list<DAE.Exp> inTplExpBooleanLst2;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inTplExpBooleanLst1,inTplExpBooleanLst2)
    local
      Type tp,tp_1;
      DAE.Exp e1,e2,e,res;
      list<DAE.Exp> es1,es2;
    case ({e1},{e2})
      equation
        tp = Expression.typeof(e1);
        tp_1 = Expression.arrayEltType(tp);
      then
        DAE.BINARY(e1,DAE.MUL(tp_1),e2);
    case (e1 :: es1,e2 :: es2)
      equation
        e = simplifyMatrixProduct4(es1, es2);
        tp = Expression.typeof(e);
        tp_1 = Expression.arrayEltType(tp);
        res = DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp_1),e2),DAE.ADD(tp_1),e);
      then
        res;
  end matchcontinue;
end simplifyMatrixProduct4;

protected function simplifyBinarySortConstants
"function: simplifyBinarySortConstants
  author: PA
  Sorts all constants of a sum or product to the
  beginning of the expression.
  Also combines expressions like 2a+4a and aaa+3a^3."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      list<DAE.Exp> e_lst,e_lst_1,const_es1,notconst_es1,const_es1_1;
      DAE.Exp res,e,e1,e2,res1,res2;
      Type tp;

    // e1 * e2
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2)))
      equation
        res = simplifyBinarySortConstantsMul(e);
      then
        res;

    // e1 / e2
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2))) 
      equation
        e1 = simplifyBinarySortConstantsMul(e1);
        e2 = simplifyBinarySortConstantsMul(e2);
      then 
        DAE.BINARY(e1,DAE.DIV(tp),e2);

    // e1 + e2 
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2)))
      equation
        e_lst = Expression.terms(e);
        //e_lst_1 = List.map(e_lst,simplify2);
        (const_es1, notconst_es1) = 
          List.splitOnTrue(e_lst, Expression.isConst);
        const_es1_1 = simplifyBinaryAddConstants(const_es1);
        res1 = Expression.makeSum(const_es1_1);
        res2 = Expression.makeSum(notconst_es1); // Cannot simplify this, if const_es1_1 empty => infinite recursion.
        res = Expression.makeSum({res1,res2});
      then
        res;

    // return e
    case(e) then e;

  end matchcontinue;
end simplifyBinarySortConstants;

protected function simplifyBinaryCoeff
"function: simplifyBinaryCoeff
  author: PA
  Combines expressions like 2a+4a and aaa+3a^3, etc"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      list<DAE.Exp> e_lst,e_lst_1,e1_lst,e2_lst,e2_lst_1;
      DAE.Exp res,e,e1,e2;
      Type tp;
    
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2)))
      equation
        e_lst = Expression.factors(e);
        e_lst_1 = simplifyMul(e_lst);
        res = Expression.makeProductLst(e_lst_1);
        (res,_) = simplify1(res);
      then
        res;
    
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2)))
      equation
        e1_lst = Expression.factors(e1);
        e2_lst = Expression.factors(e2);
        e2_lst_1 = List.map(e2_lst, Expression.inverseFactors);
        e_lst = listAppend(e1_lst, e2_lst_1);
        e_lst_1 = simplifyMul(e_lst);
        res = Expression.makeProductLst(e_lst_1);
        (res,_) = simplify1(res);
      then
        res;
    
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2)))
      equation
        e_lst = Expression.terms(e);
        e_lst_1 = simplifyAdd(e_lst);
        res = Expression.makeSum(e_lst_1);
      then
        res;
    
    case ((e as DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2)))
      equation
        e1_lst = Expression.terms(e1);
        e2_lst = Expression.terms(e2);
        e2_lst = List.map(e2_lst, Expression.negate);
        e_lst = listAppend(e1_lst, e2_lst);
        e_lst_1 = simplifyAdd(e_lst);
        res = Expression.makeSum(e_lst_1);
      then
        res;

    case (e) then e;

  end matchcontinue;
end simplifyBinaryCoeff;

protected function simplifyBinaryAddConstants
"function: simplifyBinaryAddConstants
  author: PA
  Adds all expressions in the list, given that they are constant."
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst)
    local
      DAE.Exp e,e_1,e1;
      list<DAE.Exp> es;
    
    case ({}) then {};
    
    case ({e}) then {e};
    
    case ((e1 :: es))
      equation
        {e} = simplifyBinaryAddConstants(es);
        e_1 = simplifyBinaryConst(DAE.ADD(DAE.ET_REAL()), e1, e);
      then
        {e_1};
    
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE,"- ExpressionSimplify.simplifyBinaryAddConstants failed\n");
      then
        fail();
  end matchcontinue;
end simplifyBinaryAddConstants;

protected function simplifyBinaryMulConstants
"function: simplifyBinaryMulConstants
  author: PA
  Multiplies all expressions in the list, given that they are constant."
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst)
    local
      DAE.Exp e,e_1,e1;
      list<DAE.Exp> es;
      Type tp;
    
    case ({}) then {};
    
    case ({e}) then {e};
    
    case ((e1 :: es))
      equation
        {e} = simplifyBinaryMulConstants(es);
        tp = Expression.typeof(e);
        e_1 = simplifyBinaryConst(DAE.MUL(tp), e1, e);
      then
        {e_1};
  end matchcontinue;
end simplifyBinaryMulConstants;

protected function simplifyMul
"function: simplifyMul
  author: PA
  Simplifies expressions like a*a*a*b*a*b*a"
  input list<DAE.Exp> expl;
  output list<DAE.Exp> expl_1;
protected
  list<tuple<DAE.Exp, Real>> exp_const,exp_const_1;
algorithm
  exp_const := simplifyMul2(expl);
  exp_const_1 := simplifyMulJoinFactors(exp_const);
  expl_1 := simplifyMulMakePow(exp_const_1);
end simplifyMul;

protected function simplifyMul2
"function: simplifyMul2
  author: PA
  Helper function to simplifyMul."
  input list<DAE.Exp> inExpLst;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst := match (inExpLst)
    local
      DAE.Exp e_1,e;
      Real coeff;
      list<tuple<DAE.Exp, Real>> rest;
      list<DAE.Exp> es;
    
    case ({}) then {};
    
    case ((e :: es))
      equation
        (e_1,coeff) = simplifyBinaryMulCoeff2(e);
        rest = simplifyMul2(es);
      then
        ((e_1,coeff) :: rest);
  end match;
end simplifyMul2;

protected function simplifyMulJoinFactors
"function: simplifyMulJoinFactors
 author: PA
  Helper function to simplifyMul.
  Joins expressions that have the same base.
  E.g. {(a,2), (a,4), (b,2)} => {(a,6), (b,2)}"
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst := match (inTplExpRealLst)
    local
      Real coeff2,coeff_1,coeff;
      list<tuple<DAE.Exp, Real>> rest_1,res,rest;
      DAE.Exp e;
    
    case ({}) then {};
    
    case (((e,coeff) :: rest))
      equation
        (coeff2,rest_1) = simplifyMulJoinFactorsFind(e, rest);
        res = simplifyMulJoinFactors(rest_1);
        coeff_1 = coeff +. coeff2;
      then
        ((e,coeff_1) :: res);
  end match;
end simplifyMulJoinFactors;

protected function simplifyMulJoinFactorsFind
"function: simplifyMulJoinFactorsFind
  author: PA
  Helper function to simplifyMulJoinFactors.
  Searches rest of list to find all occurences of a base."
  input DAE.Exp inExp;
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  (outReal,outTplExpRealLst) := matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<DAE.Exp, Real>> res,rest;
      DAE.Exp e,e2,e1;
      Type tp;
    
    case (_,{}) then (0.0,{});
    
    case (e,((e2,coeff) :: rest)) /* e1 == e2 */
      equation
        true = Expression.expEqual(e, e2);
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    
    case (e,((DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = tp),exp2 = e2),coeff) :: rest)) /* e11-e12 and e12-e11, negative -1.0 factor */
      equation
        true = Expression.expEqual(e, DAE.BINARY(e2,DAE.SUB(tp),e1));
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff -. coeff2;
      then
        (coeff3,res);
    
    case (e,((e2,coeff) :: rest)) /* not Expression.expEqual */
      equation
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyMulJoinFactorsFind;

protected function simplifyMulMakePow
"function: simplifyMulMakePow
  author: PA
  Helper function to simplifyMul.
  Makes each item in the list into a pow
  expression, except when exponent is 1.0."
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inTplExpRealLst)
    local
      list<DAE.Exp> res;
      DAE.Exp e;
      Real r;
      list<tuple<DAE.Exp, Real>> xs;
    
    case ({}) then {};
    
    case (((e,r) :: xs))
      equation
        (r ==. 1.0) = true;
        res = simplifyMulMakePow(xs);
      then
        (e :: res);
    
    case (((e,r) :: xs))
      equation
        res = simplifyMulMakePow(xs);
      then
        (DAE.BINARY(e,DAE.POW(DAE.ET_REAL()),DAE.RCONST(r)) :: res);
  end matchcontinue;
end simplifyMulMakePow;

protected function simplifyAdd
"function: simplifyAdd
  author: PA
  Simplifies terms like 2a+4b+2a+a+b"
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst)
    local
      list<tuple<DAE.Exp, Real>> exp_const,exp_const_1;
      list<DAE.Exp> expl_1,expl;
    
    case (expl)
      equation
        exp_const = simplifyAdd2(expl);
        exp_const_1 = simplifyAddJoinTerms(exp_const);
        expl_1 = simplifyAddMakeMul(exp_const_1);
      then
        expl_1;
    
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE,"- ExpressionSimplify.simplifyAdd failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd;

protected function simplifyAdd2
"function: simplifyAdd2
  author: PA
  Helper function to simplifyAdd"
  input list<DAE.Exp> inExpLst;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst := matchcontinue (inExpLst)
    local
      DAE.Exp e_1,e;
      Real coeff;
      list<tuple<DAE.Exp, Real>> rest;
      list<DAE.Exp> es;
    
    case ({}) then {};
    
    case ((e :: es))
      equation
        (e_1,coeff) = simplifyBinaryAddCoeff2(e);
        rest = simplifyAdd2(es);
      then
        ((e_1,coeff) :: rest);
    
    case (_)
      equation
        Debug.fprint(Flags.FAILTRACE,"- ExpressionSimplify.simplifyAdd2 failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd2;

protected function simplifyAddJoinTerms
"function: simplifyAddJoinTerms
  author: PA
  Helper function to simplifyAdd.
  Join all terms with the same expression.
  i.e. 2a+4a gives an element (a,6) in the list."
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  outTplExpRealLst := match (inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<DAE.Exp, Real>> rest_1,res,rest;
      DAE.Exp e;
    
    case ({}) then {};
    
    case (((e,coeff) :: rest))
      equation
        (coeff2,rest_1) = simplifyAddJoinTermsFind(e, rest);
        res = simplifyAddJoinTerms(rest_1);
        coeff3 = coeff +. coeff2;
      then
        ((e,coeff3) :: res);
  end match;
end simplifyAddJoinTerms;

protected function simplifyAddJoinTermsFind
"function: simplifyAddJoinTermsFind
  author: PA
  Helper function to simplifyAddJoinTerms, finds all occurences of Expression."
  input DAE.Exp inExp;
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output Real outReal;
  output list<tuple<DAE.Exp, Real>> outTplExpRealLst;
algorithm
  (outReal,outTplExpRealLst) := matchcontinue (inExp,inTplExpRealLst)
    local
      Real coeff2,coeff3,coeff;
      list<tuple<DAE.Exp, Real>> res,rest;
      DAE.Exp e,e2;
    
    case (_,{}) then (0.0,{});
    
    case (e,((e2,coeff) :: rest))
      equation
        true = Expression.expEqual(e, e2);
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
        coeff3 = coeff +. coeff2;
      then
        (coeff3,res);
    
    case (e,((e2,coeff) :: rest)) /* not Expression.expEqual */
      equation
        (coeff2,res) = simplifyAddJoinTermsFind(e, rest);
      then
        (coeff2,((e2,coeff) :: res));
  end matchcontinue;
end simplifyAddJoinTermsFind;

protected function simplifyAddMakeMul
"function: simplifyAddMakeMul
  author: PA
  Makes multiplications of each element
  in the list, except for coefficient 1.0"
  input list<tuple<DAE.Exp, Real>> inTplExpRealLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inTplExpRealLst)
    local
      list<DAE.Exp> res;
      DAE.Exp e;
      Real r;
      list<tuple<DAE.Exp, Real>> xs;
      Integer tmpInt;
          
    case ({}) then {};
    
    case (((e,r) :: xs))
      equation
        (r ==. 1.0) = true;
        res = simplifyAddMakeMul(xs);
      then
        (e :: res);
    
    case (((e,r) :: xs))
      equation
        DAE.ET_INT() = Expression.typeof(e);
        res = simplifyAddMakeMul(xs);
        tmpInt = realInt(r);
      then
        (DAE.BINARY(DAE.ICONST(tmpInt),DAE.MUL(DAE.ET_INT()),e) :: res);
    
    case (((e,r) :: xs))
      equation
        res = simplifyAddMakeMul(xs);
      then
        (DAE.BINARY(DAE.RCONST(r),DAE.MUL(DAE.ET_REAL()),e) :: res);
  end matchcontinue;
end simplifyAddMakeMul;

protected function simplifyBinaryAddCoeff2
"function: simplifyBinaryAddCoeff2
  This function checks for x+x+x+x and returns (x,4.0)"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Real outReal;
algorithm
  (outExp,outReal) := matchcontinue (inExp)
    local
      DAE.Exp exp,e1,e2,e;
      Real coeff,coeff_1;
      Integer icoeff;
      Type tp;
    
    case ((exp as DAE.CREF(componentRef = _))) then (exp,1.0);
    
    case (DAE.UNARY(operator = DAE.UMINUS(ty = DAE.ET_REAL()), exp = exp))
      equation
        (exp,coeff) = simplifyBinaryAddCoeff2(exp);
        coeff = realMul(-1.0,coeff);
      then (exp,coeff);
    
    case (DAE.BINARY(exp1 = DAE.RCONST(real = coeff),operator = DAE.MUL(ty = _),exp2 = e1))
      then (e1,coeff);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = DAE.RCONST(real = coeff)))
      then (e1,coeff);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = DAE.ICONST(integer = icoeff)))
      equation
        coeff_1 = intReal(icoeff);
      then
        (e1,coeff_1);
    
    case (DAE.BINARY(exp1 = DAE.ICONST(integer = icoeff),operator = DAE.MUL(ty = _),exp2 = e1))
      equation
        coeff_1 = intReal(icoeff);
      then
        (e1,coeff_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = tp),exp2 = e2))
      equation
        true = Expression.expEqual(e1, e2);
      then
        (e1,2.0);
    
    case (e) then (e,1.0);

  end matchcontinue;
end simplifyBinaryAddCoeff2;

protected function simplifyBinaryMulCoeff2
"function: simplifyBinaryMulCoeff2
  This function takes an expression XXXXX
  and return (X,5.0) to be used for X^5."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Real outReal;
algorithm
  (outExp,outReal) := matchcontinue (inExp)
    local
      DAE.Exp e,e1,e2;
      ComponentRef cr;
      Real coeff,coeff_1,coeff_2;
      Type tp;
      Integer icoeff;
    
    case ((e as DAE.CREF(componentRef = cr)))
      then (e,1.0);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.RCONST(real = coeff)))
      then (e1,coeff);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = DAE.RCONST(real = coeff))))
      equation
        coeff_1 = 0.0 -. coeff;
      then
        (e1,coeff_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.ICONST(integer = icoeff)))
      equation
        coeff_1 = intReal(icoeff);
      then
        (e1,coeff_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = _),exp2 = DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = DAE.ICONST(integer = icoeff))))
      equation
        coeff_1 = intReal(icoeff);
        coeff_2 = 0.0 -. coeff_1;
      then
        (e1,coeff_1);
    
    case (DAE.BINARY(exp1 = e1, operator = DAE.POW(ty = _), exp2 = DAE.ICONST(integer = icoeff)))
      equation
        coeff_1 = intReal(icoeff);
      then
        (e1, coeff_1);
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = tp),exp2 = e2))
      equation
        true = Expression.expEqual(e1, e2);
      then
        (e1,2.0);
    
    case (e) then (e,1.0);

  end matchcontinue;
end simplifyBinaryMulCoeff2;

protected function simplifyAsub0 "simplifies asub when expression already has been simplified with simplify1
Earlier these cases were directly in simplify1, but now they are here so simplify1 only is called once for 
the subexpression"
  input DAE.Exp e;
  input Integer sub;
  output DAE.Exp res;
algorithm
  res := match(e,sub)
    local 
      Type t,t1,t2;
      Boolean b,sc, bstart, bstop;
      list<DAE.Exp> exps,expl_1;
      list<Boolean> bls;
      list<list<DAE.Exp>> mexps;
      list<DAE.Exp> mexpl;
      DAE.Exp e1,e2,cond,exp,start,stop,step;
      Integer istart,istop,istep,ival;
      Real rstart,rstop,rstep,rval;
      DAE.ComponentRef c,c_1;
      list<Subscript> s,s_1;
      Integer n;
      String idn;
    
    // subscript of an array
    case(DAE.ARRAY(t,b,exps),sub) 
      equation
        exp = listNth(exps, sub - 1);
      then 
        exp;
    
    case (DAE.RANGE(DAE.ET_BOOL(), DAE.BCONST(bstart), NONE(), DAE.BCONST(bstop)), _)
      equation
        b = listGet(simplifyRangeBool(bstart, bstop), sub);
      then
        DAE.BCONST(b);
      
    case (DAE.RANGE(DAE.ET_INT(),DAE.ICONST(istart),NONE(),DAE.ICONST(istop)),sub) 
      equation
        ival = listGet(simplifyRange(istart,1,istop),sub);
        exp = DAE.ICONST(ival);
      then exp;
        
    case (DAE.RANGE(DAE.ET_INT(),DAE.ICONST(istart),SOME(DAE.ICONST(istep)),DAE.ICONST(istop)),sub) 
      equation
        ival = listGet(simplifyRange(istart,istep,istop),sub);
        exp = DAE.ICONST(ival);
      then exp;
    
    case (DAE.RANGE(DAE.ET_REAL(),DAE.RCONST(rstart),NONE(),DAE.RCONST(rstop)),sub) 
      equation
        rval = listGet(simplifyRangeReal(rstart,1.0,rstop),sub);
        exp = DAE.RCONST(rval);
      then exp;
        
    case (DAE.RANGE(DAE.ET_REAL(),DAE.RCONST(rstart),SOME(DAE.RCONST(rstep)),DAE.RCONST(rstop)),sub) 
      equation
        rval = listGet(simplifyRangeReal(rstart,rstep,rstop),sub);
        exp = DAE.RCONST(rval);
      then exp;

    // subscript of a matrix
    case(DAE.MATRIX(t,n,mexps),sub) 
      equation
        t1 = Expression.unliftArray(t);
        (mexpl) = listNth(mexps, sub - 1);
      then 
        DAE.ARRAY(t1,true,mexpl);
    
    // subscript of an if-expression
    case(DAE.IFEXP(cond,e1,e2),sub) 
      equation
        e1 = Expression.makeASUB(e1,{DAE.ICONST(sub)});
        e2 = Expression.makeASUB(e2,{DAE.ICONST(sub)});
        e = DAE.IFEXP(cond,e1,e2); 
      then 
        e;
    
    // name subscript
    case(DAE.CREF(c,t),sub) 
      equation
        t = Expression.unliftArray(t);
        c_1 = simplifyAsubCref(c,sub);
        exp = Expression.makeCrefExp(c_1, t);
      then 
        exp;
    
  end match;
end simplifyAsub0;

protected function simplifyAsubCref
  input DAE.ComponentRef cr;
  input Integer sub;
  output DAE.ComponentRef res;
algorithm
  res := matchcontinue (cr,sub)
    local 
      Type t,t1,t2;
      Boolean b;
      list<DAE.Exp> exps,expl_1;
      list<Boolean> bls;
      list<list<tuple<DAE.Exp, Boolean>>> mexps;
      list<tuple<DAE.Exp, Boolean>> mexpl;
      DAE.Exp e1,e2,cond,exp,start,stop,step;
      Integer istart,istop,istep,ival;
      Real rstart,rstop,rstep,rval;
      DAE.ComponentRef c,c_1;
      list<Subscript> s,s_1;
      Integer n;
      String idn;
      list<DAE.Dimension> dims;
      Integer ndim,nsub;
    
    // simple name subscript
    case (DAE.CREF_IDENT(idn,t2,s),sub) 
      equation
        /* TODO: Make sure that the IDENT has enough dimensions? */
        s_1 = Expression.subscriptsAppend(s, DAE.ICONST(sub));
        c_1 = ComponentReference.makeCrefIdent(idn,t2,s_1);
      then 
        c_1;

    //  qualified name subscript
    case (DAE.CREF_QUAL(idn,t2 as DAE.ET_ARRAY(arrayDimensions=dims),s,c),sub)
      equation
        true = listLength(dims) > listLength(s);
        s_1 = Expression.subscriptsAppend(s, DAE.ICONST(sub));
        c_1 = ComponentReference.makeCrefQual(idn,t2,s_1,c);
      then 
        c_1;

    case (DAE.CREF_QUAL(idn,t2,s,c),sub)
      equation
        c_1 = simplifyAsubCref(c,sub);
        c_1 = ComponentReference.makeCrefQual(idn,t2,s,c_1);
      then 
        c_1;

  end matchcontinue;
end simplifyAsubCref;

protected function simplifyAsub
"function: simplifyAsub
  This function simplifies array subscripts on vector operations"
  input DAE.Exp inExp;
  input DAE.Exp inSub;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp,inSub)
    local
      DAE.Exp e_1,e,e1_1,e2_1,e1,e2,exp,cond,sub;
      Type t,t_1,t2;
      Integer indx,i_1,n;
      Operator op,op2;
      Boolean b;
      list<DAE.Exp> exps,expl_1,expl;
      list<Boolean> bls;
      ComponentRef cr;
      list<list<DAE.Exp>> lstexps;
    
    case (e,sub) 
      equation
        exp = simplifyAsub0(e,Expression.expInt(sub));
      then 
        exp;
    
    case (DAE.UNARY(operator = DAE.UMINUS_ARR(ty = t),exp = e),sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = Expression.typeof(e_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.UMINUS_ARR(t2),DAE.UMINUS(t2));
        exp = DAE.UNARY(op2,e_1);
      then
        exp;
    
    case (DAE.LUNARY(operator = DAE.NOT(ty = t), exp = e), sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = Expression.typeof(e_1);
        exp = DAE.LUNARY(DAE.NOT(t2), e_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.SUB_ARR(t2),DAE.SUB(t2));
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.MUL_ARRAY_SCALAR(t2),DAE.MUL(t2));
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.ADD_ARRAY_SCALAR(t2),DAE.ADD(t2));
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;
    
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.SUB_SCALAR_ARRAY(t2),DAE.SUB(t2));
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;
    
    // For Matrix product M1 * M2
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = t),exp2 = e2),sub)
      equation
        e = simplifyMatrixProduct(e1,e2);
        e = simplifyAsub(e, sub);
      then
        e;
    
    // For scalar product v1 * v2, M * v1 and v1 * M
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(ty = t),exp2 = e2),sub)
      equation
        e = simplifyScalarProduct(e1,e2);
        e = simplifyAsub(e, sub);
      then
        e;
    
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.DIV_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.DIV_SCALAR_ARRAY(t2),DAE.DIV(t2));
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.DIV_ARRAY_SCALAR(t2),DAE.DIV(t2));
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;
    
    case (exp as DAE.BINARY(exp1 = e1,operator = DAE.POW_SCALAR_ARRAY(ty = t),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.POW_SCALAR_ARRAY(t2),DAE.POW(t2));
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARRAY_SCALAR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = Util.if_(b,DAE.POW_ARRAY_SCALAR(t2),DAE.POW(t2));
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.ADD_ARR(t2),DAE.ADD(t2));
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.MUL_ARR(t2),DAE.MUL(t2));
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.DIV_ARR(t2),DAE.DIV(t2));
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;
    
    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARR2(ty = t),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = Util.if_(b,DAE.POW_ARR2(t2),DAE.POW(t2));
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        op = Expression.setOpType(op, t2);
        exp = DAE.LBINARY(e1_1, op, e2_1);
      then
        exp;

    case (DAE.ARRAY(ty = t,scalar = b,array = exps),sub)
      equation
        indx = Expression.expInt(sub);
        i_1 = indx - 1;
        exp = listNth(exps, i_1);
      then
        exp;
    
    case (DAE.MATRIX(ty = t,integer = n,matrix = lstexps),sub)
      equation
        indx = Expression.expInt(sub);
        i_1 = indx - 1;
        (expl) = listNth(lstexps, i_1);
        t_1 = Expression.unliftArray(t);
      then DAE.ARRAY(t_1,true,expl);
    
    case(e as DAE.IFEXP(cond,e1,e2),sub) 
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
      then DAE.IFEXP(cond,e1_1,e2_1);
    
  end matchcontinue;
end simplifyAsub;

protected function simplifyAsubOperator
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input Operator inOperator3;
  output Operator outOperator;
algorithm
  outOperator:=
  matchcontinue (inExp1,inOperator2,inOperator3)
    local Operator sop,aop;
    case (DAE.ARRAY(ty = _),sop,aop) then aop;
    case (DAE.MATRIX(ty = _),sop,aop) then aop;
    case (DAE.RANGE(ty = _),sop,aop) then aop;
    case (_,sop,aop) then sop;
  end matchcontinue;
end simplifyAsubOperator;


protected function simplifyBinaryConst
"function: simplifyBinaryConst
  This function evaluates constant binary expressions."
  input Operator inOperator1;
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := match (inOperator1,inExp2,inExp3)
    local
      Integer ie1,ie2;
      Real e2_1,e1_1,v1,v2;
      Boolean b,b1,b2;
      DAE.Exp exp1,exp2,val;
      Real re1,re2,re3;
      String str,s1,s2;
    
    case (DAE.ADD(ty = _),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
        val = safeIntOp(ie1,ie2,ADDOP());
      then
        val;
    
    case (DAE.ADD(ty = _),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 +. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.ADD(ty = _),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 +. e2_1;
      then
        DAE.RCONST(re3);
    
    case (DAE.ADD(ty = _),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 +. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.ADD(ty = _),DAE.SCONST(string = s1),DAE.SCONST(string = s2))
      equation
        str = s1 +& s2;
      then
        DAE.SCONST(str);
    
    case (DAE.SUB(ty = _),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
         val = safeIntOp(ie1,ie2,SUBOP());
      then
        val;
    
    case (DAE.SUB(ty = _),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 -. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.SUB(ty = _),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 -. e2_1;
      then
        DAE.RCONST(re3);
    
    case (DAE.SUB(ty = _),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 -. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.MUL(ty = _),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
        val = safeIntOp(ie1,ie2,MULOP());
      then
        val;
    
    case (DAE.MUL(ty = _),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 *. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.MUL(ty = _),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 *. e2_1;
      then
        DAE.RCONST(re3);
    
    case (DAE.MUL(ty = _),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 *. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.DIV(ty = _),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
         val = safeIntOp(ie1,ie2,DIVOP());
      then
        val;
    
    case (DAE.DIV(ty = _),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 /. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.DIV(ty = _),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 /. e2_1;
      then
        DAE.RCONST(re3);
    
    case (DAE.DIV(ty = _),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 /. re2;
      then
        DAE.RCONST(re3);
    
    case (DAE.POW(ty = _),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 ^. re2;
      then
        DAE.RCONST(re3);
    
    // Relation operations
    case(DAE.LESS(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 <. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.LESSEQ(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 <=. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.GREATER(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 >. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.GREATEREQ(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 >=. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.EQUAL(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 ==. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.NEQUAL(ty=_),exp1,exp2) 
      equation
        v1 = Expression.getRealConst(exp1);
        v2 = Expression.getRealConst(exp2);
        b = v1 <>. v2;
      then 
        DAE.BCONST(b);
    
    case(DAE.AND(DAE.ET_BOOL()),exp1,exp2) 
      equation
        b1 = Expression.getBoolConst(exp1);
        b2 = Expression.getBoolConst(exp2);
        b = b1 and b2;
      then 
        DAE.BCONST(b);
    
    case(DAE.OR(DAE.ET_BOOL()),exp1,exp2) 
      equation
        b1 = Expression.getBoolConst(exp1);
        b2 = Expression.getBoolConst(exp2);
        b = b1 or b2;
      then 
        DAE.BCONST(b);
    
    // end adrpo added
    /*case (op,exp1,exp2)
      then
        fail();*/
  end match;
end simplifyBinaryConst;

public function safeIntOp
  "Safe mul, add, sub or pow operations for integers.
   The function returns an integer if possible, otherwise a real.
  "
  input Integer val1;
  input Integer val2;
  input IntOp op;
  output DAE.Exp outv;
algorithm
  outv := match(val1, val2, op)
    local
      Real rv1,rv2,rv3;
      Integer ires;
    
    case (val1,val2, MULOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 *. rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;
    
    case (val1,val2, DIVOP())
      equation
        ires = intDiv(val1,val2);
      then
        DAE.ICONST(ires);
        
    case (val1,val2, SUBOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 -. rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;
    
    case (val1,val2, ADDOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 +. rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;
    
    case (val1,val2, POWOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = realPow(rv1,rv2);
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;
  end match;
end safeIntOp;

protected function simplifyBinaryCommutative
  "This function simplifies commutative binary expressions."
  input Operator op;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue (op,lhs,rhs)
    case (op,lhs,rhs) then simplifyBinaryCommutativeWork(op,lhs,rhs);
    case (op,lhs,rhs) then simplifyBinaryCommutativeWork(op,rhs,lhs);
  end matchcontinue;
end simplifyBinaryCommutative;

protected function simplifyBinaryCommutativeWork
  "This function simplifies commutative binary expressions."
  input Operator op;
  input DAE.Exp lhs;
  input DAE.Exp rhs;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue (op,lhs,rhs)
    local
      DAE.Exp e1_1,e3,e4,e,e1,e2,res,e_1,one;
      Operator oper,op1,op2;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b;
      Real r,r1,r2,r3;
    // (a+b)c1 => ac1+bc1, for constant c1 and a or b
    case (DAE.MUL(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty2),exp2 = e2),e3)
      equation
        true = Expression.isConst(e3);
        true = Expression.isConst(e1) or Expression.isConst(e2);
        res = DAE.BINARY(DAE.BINARY(e3,DAE.MUL(ty),e1),DAE.ADD(ty2),DAE.BINARY(e3,DAE.MUL(ty),e2));
      then
        res;
    
    // (a-b)c1 => a/c1-b/c1, for constant c1 and a or b
    case (DAE.MUL(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty2),exp2 = e2),e3)
      equation
        true = Expression.isConst(e3);
        true = Expression.isConst(e1) or Expression.isConst(e2);
        res = DAE.BINARY(DAE.BINARY(e3,DAE.MUL(ty),e1),DAE.SUB(ty2),DAE.BINARY(e3,DAE.MUL(ty),e2));
      then
        res;
    
    // a+(-b)
    case (DAE.ADD(ty = tp),e1,DAE.UNARY(operator = DAE.UMINUS(ty = tp2),exp = e2))
      equation
        e = DAE.BINARY(e1,DAE.SUB(tp),e2);
      then e;

    // (-a)+b
    case (DAE.ADD(ty = tp),DAE.UNARY(operator = DAE.UMINUS(ty = tp2),exp = e1),e2)
      equation
        e = DAE.BINARY(e2,DAE.SUB(tp),e1);
      then e;

    // 0+e => e
    case (DAE.ADD(ty = ty),e1,e2)
      equation
        true = Expression.isZero(e1);
      then
        e2;
    
    // (e1/e2)e3 => (e1e3)/e2
    case (DAE.MUL(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3))
      equation
        res = DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e2),DAE.DIV(tp2),e3);
      then
        res;
    
    // 0 * a = 0
    case (DAE.MUL(ty = ty),_,e2)
      equation
        true = Expression.isZero(e2);
      then
        e2;
    
    // 1 * a = a
    case (DAE.MUL(ty = ty),e1,e2)
      equation
        true = Expression.isConstOne(e2);
      then
        e1;
    
    // -1 * a = -a
    case (DAE.MUL(ty = ty),e1,e2)
      equation
        true = Expression.isConstMinusOne(e2);
        e = DAE.UNARY(DAE.UMINUS(ty),e1);
      then 
        e;
    
    // -a * -b = a * b
    case (DAE.MUL(ty = ty),DAE.UNARY(operator = DAE.UMINUS(ty = ty1),exp = e1),DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e = DAE.BINARY(e1,DAE.MUL(ty),e2);
      then
        e;
    
    // r1 * (r2 * e) => (r1*r2)*e
    case (DAE.MUL(ty = _),DAE.RCONST(real = r1),DAE.BINARY(DAE.RCONST(real = r2),DAE.MUL(DAE.ET_REAL()),e2))
      equation
        r3 = r1 *. r2;
      then
        DAE.BINARY(DAE.RCONST(r3),DAE.MUL(DAE.ET_REAL()),e2);
    
    // r1 * (e * r2) => (r1*r2)*e
    case (DAE.MUL(ty = _),DAE.RCONST(real = r1),DAE.BINARY(e2,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(real = r2)))
      equation
        r3 = r1 *. r2;
      then
        DAE.BINARY(DAE.RCONST(r3),DAE.MUL(DAE.ET_REAL()),e2);

    // (e*e1) + (e*e2) => e*(e1+e2)
    case (op1 as DAE.ADD(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
      equation
        true = Expression.expEqual(e1,e3);
      then
        DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e4));
    case (op1 as DAE.ADD(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
      equation
        true = Expression.expEqual(e1,e4);
      then
        DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e3));
    // (e*e1) - (e*e2) => e*(e1-e2)
    case (op1 as DAE.SUB(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
      equation
        true = Expression.expEqual(e1,e3);
      then
        DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e4));
    case (op1 as DAE.SUB(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
      equation
        true = Expression.expEqual(e1,e4);
      then
        DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e3));

    // sqrt(e) * e => e^1.5
    case (DAE.MUL(ty = _),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),e2)
      equation
        true = Expression.expEqual(e1,e2);
      then
        DAE.BINARY(e1,DAE.POW(DAE.ET_REAL()),DAE.RCONST(1.5));
    // sqrt(e) * e^r => e^(r+0.5)
    case (DAE.MUL(ty = _),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),DAE.BINARY(e2,DAE.POW(ty=_),e))
      equation
        true = Expression.expEqual(e1,e2);
      then
        DAE.BINARY(e1,DAE.POW(DAE.ET_REAL()),DAE.BINARY(e,DAE.ADD(DAE.ET_REAL()),DAE.RCONST(0.5)));
  end matchcontinue;
end simplifyBinaryCommutativeWork;

protected function simplifyBinary
"function: simplifyBinary
  This function simplifies binary expressions."
  input Operator inOperator2;
  input DAE.Exp inExp3 "Note: already simplified"; // lhs
  input DAE.Exp inExp4 "Note: aldready simplified"; // rhs
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inOperator2,inExp3,inExp4)
    local
      DAE.Exp e1_1,e3,e,e1,e2,e4,res,e_1,one;
      Operator oper;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b;
      Real r,r1,r2,r3;
    
    // constants   
    case (oper,e1,e2)
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        //print("simplifyBinaryConst " +& ExpressionDump.printExpStr(e1) +& ExpressionDump.binopSymbol1(oper) +& ExpressionDump.printExpStr(e2) +& "\n");
        e3 = simplifyBinaryConst(oper, e1, e2);
        //print("simplifyBinaryConst " +& ExpressionDump.printExpStr(e1) +& "," +& ExpressionDump.printExpStr(e2) +& " => " +& ExpressionDump.printExpStr(e3) +& "\n");
      then
        e3;
    
    // a^e*b^e => (a*b)^e
    case (DAE.MUL(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = ty2),exp2 = e2),DAE.BINARY(exp1 = e3,operator = DAE.POW(ty = _),exp2 = e4))
      equation
        true = Expression.expEqual(e2,e4);
        res = DAE.BINARY(DAE.BINARY(e1,DAE.MUL(ty),e3),DAE.POW(ty2),e2);
      then res;

    // a^e/b^e => (a/b)^e
    case (DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.POW(ty = ty2),exp2 = e2),DAE.BINARY(exp1 = e3,operator = DAE.POW(ty = _),exp2 = e4))
      equation
        true = Expression.expEqual(e2,e4);
        res = DAE.BINARY(DAE.BINARY(e1,DAE.DIV(ty),e3),DAE.POW(ty2),e2);
      then res;

    // (a+b)/c1 => a/c1+b/c1, for constant c1
    case (DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty2),exp2 = e2),e3)
      equation
        true = Expression.isConst(e3);
        res = DAE.BINARY(DAE.BINARY(e1,DAE.DIV(ty),e3),DAE.ADD(ty2),DAE.BINARY(e2,DAE.DIV(ty),e3));
      then
        res;
    
    // (a-b)/c1 => a/c1-b/c1, for constant c1
    case (DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty2),exp2 = e2),e3)
      equation
        true = Expression.isConst(e3);
        res = DAE.BINARY(DAE.BINARY(e1,DAE.DIV(ty),e3),DAE.SUB(ty2),DAE.BINARY(e2,DAE.DIV(ty),e3));
      then
        res;
    
    // a/(b/c) => (ac)/b)
    case (DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3))
      equation
        e = DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e3),DAE.DIV(tp2),e2);
      then
        e;
    
    // (a/b)/c => a/(bc))
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp2),exp2 = e2),e3)
      equation
        e = DAE.BINARY(e1,DAE.DIV(tp2),DAE.BINARY(e2,DAE.MUL(tp),e3));
      then
        e;
    
    // a / (b*a)  = 1/b
    case (DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3))
      equation
        true = Expression.expEqual(e1,e3);
        e = DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e2);
      then
        e;
    
    // a / (a*b)  = 1/b
    case (DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3))
      equation
        true = Expression.expEqual(e1,e2);
        e = DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e3);
      then
        e;
  
    // (a*b)/ a  = b
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2),e3)
      equation
        true = Expression.expEqual(e1,e3);
      then e2;

    // (a*b)/ b  = a
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2),e3)
      equation
        true = Expression.expEqual(e2,e3);
      then e1;
    
    // (-a*b)/ a  = -b
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e1),operator = DAE.MUL(ty = _),exp2 = e2),e3)
      equation
        true = Expression.expEqual(e1,e3);
        tp2 = Expression.typeof(e2);
        e = DAE.UNARY(DAE.UMINUS(tp2),e2);
      then
        e;
        
    // (-a*b)/ b  = -a
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e1),operator = DAE.MUL(ty = _),exp2 = e2),e3)
      equation
        true = Expression.expEqual(e2,e3);
        tp2 = Expression.typeof(e1);
        e = DAE.UNARY(DAE.UMINUS(tp2),e1);
      then
        e;

    // (a*b)/ -b  = -a
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2),DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e3))
      equation
        true = Expression.expEqual(e2,e3);
        tp2 = Expression.typeof(e1);
        e = DAE.UNARY(DAE.UMINUS(tp2),e1);
      then
        e;

    // (a*b)/ -a  = -b
    case (DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = _),exp2 = e2),DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e3))
      equation
        true = Expression.expEqual(e1,e3);
        tp2 = Expression.typeof(e2);
        e = DAE.UNARY(DAE.UMINUS(tp2),e2);
      then
        e;
    
    // subtract from zero
    case (DAE.SUB(ty = ty),e1,e2)
      equation
        true = Expression.isZero(e1);
        e = DAE.UNARY(DAE.UMINUS(ty),e2);
      then
        e;
    
    // subtract zero
    case (DAE.SUB(ty = ty),e1,e2)
      equation
        true = Expression.isZero(e2);
      then
        e1;
    
    // a - a  = 0
    case (DAE.SUB(ty = ty),e1,e2) 
      equation
        true = Expression.expEqual(e1,e2);
        e1 = Expression.makeConstZero(ty);
      then 
        e1;

    // a-(-b) = a+b
    case (DAE.SUB(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e = DAE.BINARY(e1,DAE.ADD(ty),e2);
      then
        e;
    
    // 0 / x = 0
    case (DAE.DIV(ty = ty),e1,e2)
      equation
        true = Expression.isZero(e1);
        false = Expression.isZero(e2);
      then
        DAE.RCONST(0.0);

    // a / 1 = a
    case (DAE.DIV(ty = ty),e1,e2)
      equation
        true = Expression.isConstOne(e2);
      then
        e1;
    
    // a / -1 = -a
    case (DAE.DIV(ty = ty),e1,e2)
      equation
        true = Expression.isConstMinusOne(e2);
        e = DAE.UNARY(DAE.UMINUS(ty),e1);
      then
        e;
    
    // a / a  = 1
    case (DAE.DIV(ty = ty),e1,e2)
      equation
        true = Expression.expEqual(e1,e2);
        res = Expression.makeConstOne(ty);
        false = Expression.isZero(e2);
      then
        res;
    
    // -a / -b = a / b 
    case (DAE.DIV(ty = ty),DAE.UNARY(operator = DAE.UMINUS(ty = ty1),exp = e1),DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))      
      then
        DAE.BINARY(e1,DAE.DIV(ty),e2);
    
    // e1 / -e2  => -e1 / e2 
    case (DAE.DIV(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e1_1 = DAE.UNARY(DAE.UMINUS(ty),e1);
      then
        DAE.BINARY(e1_1,DAE.DIV(ty),e2);
    
    // e2*e3 / e1 => e3/e1 * e2
    case (DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1)
      equation
        true = Expression.isConst(e3) "(c1x)/c2" ;
        true = Expression.isConst(e1);
        e = DAE.BINARY(e3,DAE.DIV(tp2),e1);
      then
        DAE.BINARY(e,DAE.MUL(tp),e2);
    
    // e2*e3 / e1 => e2 / e1 * e3
    case (DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1)
      equation
        true = Expression.isConst(e2) ;
        true = Expression.isConst(e1);
        e = DAE.BINARY(e2,DAE.DIV(tp2),e1);
      then
        DAE.BINARY(e,DAE.MUL(tp),e3);
    
    // e ^ 1 => e
    case (DAE.POW(ty = _),e1,e)
      equation
        true = Expression.isConstOne(e);
      then
        e1;
    
    // e ^ - 1 =>  1 / e
    case (DAE.POW(ty = tp),e2,e)
      equation
        true = Expression.isConstMinusOne(e);
        one = Expression.makeConstOne(tp);
      then
        DAE.BINARY(one,DAE.DIV(DAE.ET_REAL()),e2);
    
    // e ^ 0 => 1
    case (DAE.POW(ty = _),e1,e)
      equation
        tp = Expression.typeof(e1);
        true = Expression.isZero(e);
        res = Expression.makeConstOne(tp);
      then
        res;
    
    // sqrt(e) ^ 2.0 => e
    case (oper as DAE.POW(ty = _),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e}),DAE.RCONST(r))
      equation
        true = realEq(r,2.0);
      then Expression.makeBuiltinCall("abs", {e}, DAE.ET_REAL());

    // sqrt(e) ^ r => e ^ 0.5*r
    case (oper as DAE.POW(ty = _),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),e)
      then
        DAE.BINARY(e1,oper,DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.ET_REAL()),e));

    // 1 ^ e => 1
    case (DAE.POW(ty = _),e1,e)
      equation
        true = Expression.isConstOne(e1);
      then
        e1;
    
    // (a1a2...an)^e2 => a1^e2a2^e2..an^e2
    case (DAE.POW(ty = _),e1,e2)
      equation
        ((exp_lst as (_ :: _ :: _ :: _))) = Expression.factors(e1);
        exp_lst_1 = simplifyBinaryDistributePow(exp_lst, e2);
        res = Expression.makeProductLst(exp_lst_1);
      then
        res;
    // (e1^e2)^e3 => e1^(e2*e3)
    case (DAE.POW(ty = _),DAE.BINARY(e1,DAE.POW(ty = _),e2),e3)
      equation
        res = DAE.BINARY(e1,DAE.POW(DAE.ET_REAL()),DAE.BINARY(e2,DAE.MUL(DAE.ET_REAL()),e3));
      then
        res;
        
    // e1  -e2 => -e1  e2
    // Note: This rule is *not* commutative 
    case (DAE.MUL(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
      equation
        e1_1 = DAE.UNARY(DAE.UMINUS(ty),e1);
      then
        DAE.BINARY(e1_1,DAE.MUL(ty),e2);    
    
    // relation: cr1 == cr2, where cr1 and cr2 are the same
    case (DAE.EQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_)) 
      equation
        true = ComponentReference.crefEqual(cr1,cr2);
      then 
        DAE.BCONST(true);
    
    // relation: cr1 <> cr2 . where cr1 and cr2 are the same 
    case (DAE.NEQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_)) 
      equation
        true = ComponentReference.crefEqual(cr1,cr2);
      then 
        DAE.BCONST(false);
    
    // true AND e => e
    case (DAE.AND(_),e1 as DAE.BCONST(b),e2) then Util.if_(b,e2,e1);
    case (DAE.AND(_),e1,e2 as DAE.BCONST(b)) then Util.if_(b,e1,e2);
    // false OR e => e
    case (DAE.OR(_),e1 as DAE.BCONST(b),e2) then Util.if_(b,e1,e2);
    case (DAE.OR(_),e1,e2 as DAE.BCONST(b)) then Util.if_(b,e2,e1);
  end matchcontinue;
end simplifyBinary;

protected function simplifyBinaryDistributePow
"function simplifyBinaryDistributePow
  author: PA
  Distributes the pow operator over a list of expressions.
  ({e1,e2,..,en} , pow_e) =>  {e1^pow_e, e2^pow_e,..,en^pow_e}"
  input list<DAE.Exp> inExpLst;
  input DAE.Exp inExp;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst,inExp)
    local
      list<DAE.Exp> es_1,es;
      Type tp;
      DAE.Exp e,pow_e;
    
    // handle emptyness
    case ({},_) then {};
    
     // Remove 1^pow_e
    case ((e :: es),pow_e)
      equation
        true = Expression.isConstOne(e);
        es_1 = simplifyBinaryDistributePow(es, pow_e);
      then es_1;
    
    // move to next 
    case ((e :: es),pow_e)
      equation
        es_1 = simplifyBinaryDistributePow(es, pow_e);
        tp = Expression.typeof(e);
      then
        (DAE.BINARY(e,DAE.POW(tp),pow_e) :: es_1);
  end matchcontinue;
end simplifyBinaryDistributePow;

protected function simplifyUnary
"function: simplifyUnary
  Simplifies unary expressions."
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inOperator2,inExp3)
    local
      Type ty,ty1;
      DAE.Exp e1,e1_1,e_1,e2,e;
      Integer i_1,i;
      Real r_1,r;
      Boolean b1;
    
    // not true => false, not false => true
    case(DAE.NOT(DAE.ET_BOOL()),e1) 
      equation
        b1 = Expression.getBoolConst(e1);
        b1 = not b1;
      then 
        DAE.BCONST(b1);
    
    // -x => 0 - x
    case (DAE.UMINUS(ty = ty),DAE.ICONST(integer = i))
      equation
        i_1 = 0 - i;
      then
        DAE.ICONST(i_1);
    
    // -x => 0.0 - x 
    case (DAE.UMINUS(ty = ty),DAE.RCONST(real = r))
      equation
        r_1 = 0.0 -. r;
      then
        DAE.RCONST(r_1);
    
    // -(a * b) => (-a) * b
    case (DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = ty1),exp2 = e2))
      equation
         e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.MUL(ty1),e2);
      then
        e_1;
    // -(a*b) => (-a)*b
    case (DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.MUL_ARR(ty1),e2);
      then
        e_1;
    // -0 => 0
    case (DAE.UMINUS(ty = ty),e1)
      equation
        true = Expression.isZero(e1);
      then
        e1;
    case (DAE.UMINUS_ARR(ty = ty),e1)
      equation
        true = Expression.isZero(e1);
      then
        e1;
    //  -(a-b) => b - a        
    case (DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(e2,DAE.SUB(ty1),e1);
      then
        e_1;
    case (DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(e2,DAE.SUB_ARR(ty1),e1);
      then
        e_1;
    // -(a + b) => -b - a    
    case (DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.ADD(ty1),DAE.UNARY(DAE.UMINUS(ty),e2));
      then
        e_1;
    case (DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.ADD_ARR(ty1),DAE.UNARY(DAE.UMINUS_ARR(ty),e2));
      then
        e_1;
    // -( a / b) => -a / b
    case (DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.DIV(ty1),e2);
      then
        e_1;
    case (DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.DIV_ARR(ty1),e2);
      then
        e_1;
    // -(a * b) => -a * b    
    case (DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.MUL(ty1),e2);
      then
        e_1;
    case (DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = ty1),exp2 = e2))
      equation
        e_1 = DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.MUL_ARR(ty1),e2);
      then
        e_1;
     // --a => a   
     case (DAE.UMINUS(ty = _),DAE.UNARY(operator = DAE.UMINUS(ty = _),exp = e1)) /* --a => a */
       then e1;
     case (DAE.UMINUS_ARR(ty = _),DAE.UNARY(operator = DAE.UMINUS_ARR(ty = _),exp = e1)) /* --a => a */
       then e1;
  end matchcontinue;
end simplifyUnary;

protected function simplifyVectorScalarMatrix "Help function to simplifyVectorScalar,
handles MATRIX expressions"
  input list<list<DAE.Exp>> mexpl;
  input Operator op;
  input DAE.Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<list<DAE.Exp>> outExp;
algorithm
  outExp := match(mexpl,op,s1,arrayScalar)
    local
      list<DAE.Exp> row;
    case ({},op,s1,arrayScalar) then {};
    case (row::mexpl,op,s1,arrayScalar)
      equation
        row = simplifyVectorScalarMatrixRow(row,op,s1,arrayScalar);
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,arrayScalar);
      then row::mexpl;
  end match;
end simplifyVectorScalarMatrix;

protected function simplifyVectorScalarMatrixRow "Help function to simplifyVectorScalarMatrix,
handles MATRIX row"
  input list<DAE.Exp> row;
  input Operator op;
  input DAE.Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<DAE.Exp> outExp;
algorithm
  outExp := match(row,op,s1,arrayScalar)
  local DAE.Exp e; Boolean scalar;
    case({},op,s1,arrayScalar) then {};
      /* array op scalar */
    case(e::row,op,s1,true)
      equation
        row = simplifyVectorScalarMatrixRow(row,op,s1,true);
      then (DAE.BINARY(e,op,s1)::row);

    /* scalar op array */
    case(e::row,op,s1,false)
      equation
        row = simplifyVectorScalarMatrixRow(row,op,s1,false);
      then (DAE.BINARY(s1,op,e)::row);
  end match;
end simplifyVectorScalarMatrixRow;

protected function simplifyBinarySortConstantsMul
"Helper relation to simplifyBinarySortConstants"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
 protected list<DAE.Exp> e_lst, e_lst_1,const_es1,const_es1_1,notconst_es1;
  DAE.Exp res1,res2;
algorithm
  e_lst  := Expression.factors(inExp);
  //e_lst_1 := List.map(e_lst,simplify2); // simplify2 for recursive
  (const_es1, notconst_es1) := 
    List.splitOnTrue(e_lst, Expression.isConst);
  const_es1_1 := simplifyBinaryMulConstants(const_es1);
  (res1,_) := simplify1(Expression.makeProductLst(const_es1_1)); // simplify1 for basic constant evaluation.
  res2 := Expression.makeProductLst(notconst_es1); // Cannot simplify this, if const_es1_1 empty => infinite recursion.
  outExp := Expression.makeProductLst({res1,res2});
end simplifyBinarySortConstantsMul;

protected function simplifyBuiltinConstantDer 
"returns 0.0 or an array filled with 0.0 if the input is Real, Integer or an array of Real/Integer"
  input DAE.Exp inExp "assumes already simplified constant expression";
  output DAE.Exp outExp;
algorithm
  outExp := match (inExp)
    local
      DAE.Exp e;
      list<DAE.Dimension> dims;
    case DAE.RCONST(_) then DAE.RCONST(0.0);
    case DAE.ICONST(_) then DAE.RCONST(0.0);
    case DAE.ARRAY(ty=DAE.ET_ARRAY(ty=DAE.ET_REAL(), arrayDimensions=dims))
      equation
        (e,_) = Expression.makeZeroExpression(dims);
      then
        e;
    case DAE.ARRAY(ty=DAE.ET_ARRAY(ty=DAE.ET_INT(), arrayDimensions=dims))
      equation
        (e,_) = Expression.makeZeroExpression(dims);
      then
        e;
  end match;
end simplifyBuiltinConstantDer;

protected function removeOperatorDimension "Function: removeOperatorDimension
Helper function for simplifyVectorBinary, removes an dimension from the operator.
"
  input Operator inop;
  output Operator outop;
algorithm outop := match(inop)
  local
    Type ty1,ty2;
    Boolean b;
    Operator op;
  case DAE.ADD_ARR(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = Util.if_(b, DAE.ADD_ARR(ty2), DAE.ADD(ty2));
    then op;
  case DAE.SUB_ARR(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = Util.if_(b, DAE.SUB_ARR(ty2), DAE.SUB(ty2));
    then op;
end match;
end removeOperatorDimension;

public function simplifyRangeBool
  "This function evaluates a Boolean range expression."
  input Boolean inStart;
  input Boolean inStop;
  output list<Boolean> outRange;
algorithm
  outRange := match(inStart, inStop)
    case (false, true)  then {false, true};
    case (false, false) then {false};
    case (true,  true)  then {true};
    case (true,  false) then {};
  end match;
end simplifyRangeBool;

public function simplifyRange
  "This function evaluates an Integer range expression."
  input Integer inStart;
  input Integer inStep;
  input Integer inStop;
  output list<Integer> outValues;
algorithm
  outValues := List.intRange3(inStart, inStep, inStop);
end simplifyRange;

public function simplifyRangeReal
  "This function evaluates a Real range expression."
  input Real inStart;
  input Real inStep;
  input Real inStop;
  output list<Real> outValues;
algorithm
  outValues := matchcontinue(inStart, inStep, inStop)
    local
      list<Values.Value> vals;
      String error_str;

    case (_, _, _)
      equation
        equality(inStep = 0.0);
        error_str = stringDelimitList(
          List.map({inStart, inStep, inStop}, realString), ":");
        Error.addMessage(Error.ZERO_STEP_IN_ARRAY_CONSTRUCTOR, {error_str});
      then
        fail();

    case (_, _, _)
      equation
        equality(inStart = inStop);
      then {inStart};

    case (_, _, _)
      equation
        true = (inStep >. 0.0);
      then simplifyRangeReal2(inStart, inStep, inStop, realGt, {});

    case (_, _, _)
      equation
        true = (inStep <. 0.0);
      then simplifyRangeReal2(inStart, inStep, inStop, realLt, {});
  end matchcontinue;
end simplifyRangeReal;

protected function simplifyRangeReal2
  "Helper function to cevalRangeReal."
  input Real inStart;
  input Real inStep;
  input Real inStop;
  input CompFunc compFunc;
  input list<Real> inValues;
  output list<Real> outValues;

  partial function CompFunc
    input Real inValue1;
    input Real inValue2;
    output Boolean outRes;
  end CompFunc;
algorithm
  outValues := matchcontinue(inStart, inStep, inStop, compFunc, inValues)
    local
      Real next;
      list<Real> vals;

    case (_, _, _, _, _)
      equation
        true = compFunc(inStart, inStop);
      then
        listReverse(inValues);

    case (_, _, _, _, _)
      equation
        next = inStart +. inStep;
        vals = inStart :: inValues;
        vals = simplifyRangeReal2(next, inStep, inStop, compFunc, vals);
      then
        vals;
  end matchcontinue;
end simplifyRangeReal2;
        
protected function simplifyReduction
  input DAE.Exp inReduction;
  input Boolean b;
  output DAE.Exp outValue;
algorithm
  outValue := matchcontinue (inReduction,b)
    local
      DAE.Exp expr, value, cref, range;
      DAE.Ident iter_name;
      list<DAE.Exp> values;
      Option<Values.Value> defaultValue;
      Absyn.Path path;
      Boolean b;
      Values.Value v;
      String str;
      Option<DAE.Exp> foldExp;
      DAE.Type ty;
      DAE.ExpType ety;
      DAE.ReductionInfo reductionInfo;
      list<DAE.ReductionIterator> iterators;

    case (DAE.REDUCTION(iterators = iterators, reductionInfo=DAE.REDUCTIONINFO(defaultValue = SOME(v))),_)
      equation
        true = hasZeroLengthIterator(iterators);
        expr = ValuesUtil.valueExp(v);
      then expr;

    case (DAE.REDUCTION(iterators = iterators),_)
      equation
        true = hasZeroLengthIterator(iterators);
        expr = ValuesUtil.valueExp(Values.META_FAIL());
      then expr;

    case (DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = Absyn.IDENT(str), exprType = ty, defaultValue = defaultValue, foldExp = foldExp), expr = expr, iterators = iterators),_)
      equation
        true = listMember(str,{"array","min","max","sum","product"});
        {DAE.REDUCTIONITER(id = iter_name, guardExp = NONE(), exp = DAE.ARRAY(array = values))} = iterators;
        // TODO: Use foldExp
        ety = Types.elabType(ty);
        cref = DAE.CREF(DAE.CREF_IDENT(iter_name, ety, {}), ety);
        values = List.map(List.map2r(values, Expression.replaceExp, expr, cref), Util.tuple21);
        
        expr = simplifyReductionFoldPhase(str,ety,values,defaultValue);
      then expr;
        
    case (inReduction,true) then inReduction;
    
  end matchcontinue;
end simplifyReduction;

protected function simplifyReductionFoldPhase
  input String str;
  input DAE.ExpType ty;
  input list<DAE.Exp> exps;
  input Option<Values.Value> defaultValue;
  output DAE.Exp exp;
algorithm
  exp := match (str,ty,exps,defaultValue)
    local
      Integer len;
      Values.Value val;
    case (_,_,{},SOME(val)) then ValuesUtil.valueExp(val);
    case (_,_,{},NONE()) then fail();
    case ("array",ty,exps,_)
      then DAE.ARRAY(ty, true, exps);
    case ("min",ty,exps,_)
      equation
        len = listLength(exps);
      then Expression.makeBuiltinCall("min",{DAE.ARRAY(DAE.ET_ARRAY(ty, {DAE.DIM_INTEGER(len)}), true, exps)},ty);
    case ("max",ty,exps,_)
      equation
        len = listLength(exps);
      then Expression.makeBuiltinCall("max",{DAE.ARRAY(DAE.ET_ARRAY(ty, {DAE.DIM_INTEGER(len)}), true, exps)},ty);
    case ("product",ty,exps,_) then Expression.makeProductLst(exps); // TODO: Remove listReverse; it's just needed so I don't need to update expected results
    case ("sum",ty,exps,_) then Expression.makeSum(exps); // TODO: Remove listReverse; it's just needed so I don't need to update expected results
  end match;
end simplifyReductionFoldPhase;

protected function hasZeroLengthIterator
  input list<DAE.ReductionIterator> iters;
  output Boolean b;
algorithm
  b := match iters
    case {} then false;
    case DAE.REDUCTIONITER(guardExp=SOME(DAE.BCONST(false)))::_ then true;
    case DAE.REDUCTIONITER(exp=DAE.LIST({}))::_ then true;
    case DAE.REDUCTIONITER(exp=DAE.ARRAY(array={}))::_ then true;
    case _::iters then hasZeroLengthIterator(iters);
  end match;
end hasZeroLengthIterator;

protected function hasGuardExp
  input list<DAE.ReductionIterator> iters;
  output Boolean b;
algorithm
  b := match iters
    case {} then false;
    case DAE.REDUCTIONITER(guardExp=SOME(_))::_ then true;
    case _::iters then hasGuardExp(iters);
  end match;
end hasGuardExp;

public function simplifyList
  input list<DAE.Exp> expl;
  input list<DAE.Exp> acc;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := match (expl,acc)
    local
      DAE.Exp exp;
      list<DAE.Exp> rest_expl;
    case ({},_) then listReverse(acc);
    case (exp::rest_expl,_)
      equation
        (exp,_) = simplify1(exp);
      then simplifyList(rest_expl,exp::acc);
  end match;
end simplifyList;

end ExpressionSimplify;

