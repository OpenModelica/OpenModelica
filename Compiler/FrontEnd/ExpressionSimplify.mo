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

encapsulated package ExpressionSimplify
" file:        ExpressionSimplify.mo
  package:     ExpressionSimplify
  description: ExpressionSimplify

  RCS: $Id$

  This file contains the module ExpressionSimplify, which contains
  functions to simplify a DAE.Expression."

// public imports
public import Absyn;
public import ClassInf;
public import DAE;
public import Error;
public import ExpressionSimplifyTypes;

protected type ComponentRef = DAE.ComponentRef;
protected type Ident = String;
protected type Operator = DAE.Operator;
protected type Type = DAE.Type;
protected type Subscript = DAE.Subscript;

// protected imports
protected import ComponentReference;
protected import Config;
protected import DAEUtil;
protected import Debug;
protected import FCore;
protected import FGraph;
protected import ErrorExt;
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

protected constant ExpressionSimplifyTypes.Options optionSimplifyOnly = ExpressionSimplifyTypes.optionSimplifyOnly;

public function simplify "Simplifies expressions"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := simplifyWithOptions(inExp,optionSimplifyOnly);
end simplify;

public function condsimplify "Simplifies expressions on condition"
  input Boolean cond;
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := match(cond,inExp)
    local DAE.Exp e;
    case(true,_)
      equation
        (outExp,hasChanged) = simplifyWithOptions(inExp,optionSimplifyOnly);
      then
        (outExp,hasChanged);
    case(false,e)
      then (e,false);
  end match;
end condsimplify;

protected function simplifyWithOptions "Simplifies expressions"
  input DAE.Exp inExp;
  input ExpressionSimplifyTypes.Options options;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := matchcontinue (inExp,options)
    local
      DAE.Exp e, eNew;
      Boolean b;
    case (e,(_,ExpressionSimplifyTypes.DO_EVAL()))
      equation
        (eNew,_) = simplify1WithOptions(e,options); // Basic local simplifications
        Error.assertionOrAddSourceMessage(Expression.isConstValue(eNew), Error.INTERNAL_ERROR, {"eval exp failed"}, Absyn.dummyInfo);
        b = not Expression.expEqual(e,eNew);
      then (eNew,b);
    case (e,_)
      equation
        false = Config.getNoSimplify();
        //print("SIMPLIFY BEFORE->" + ExpressionDump.printExpStr(e) + "\n");
        (eNew,_) = simplify1WithOptions(e,options); // Basic local simplifications
        //print("SIMPLIFY INTERMEDIATE->" + ExpressionDump.printExpStr(eNew) + "\n");
        eNew = simplify2(eNew); // Advanced (global) simplifications
        (eNew,_) = simplify1WithOptions(eNew,options); // Basic local simplifications
        b = not Expression.expEqual(e,eNew);
        //print("SIMPLIFY FINAL->" + ExpressionDump.printExpStr(eNew) + "\n");
      then (eNew,b);
    case (e,_)
      equation
        (eNew,b) = simplify1WithOptions(e,options);
      then (eNew,b);
  end matchcontinue;
end simplifyWithOptions;

public function simplifyTraverseHelper
  input DAE.Exp inExp;
  input A inA;
  output DAE.Exp exp;
  output A a;
  replaceable type A subtypeof Any;
algorithm
  a := inA;
  (exp,_) := simplify(inExp);
end simplifyTraverseHelper;

public function simplify1time "simplify1 with timing"
  input DAE.Exp e;
  output DAE.Exp outE;
protected
  Real t1,t2;
algorithm
  t1 := clock();
  (outE,_) := simplify1(e);
  t2 := clock();
  print(if t2 - t1 > 0.01 then ("simplify1 took "+realString(t2 - t1)+" seconds for exp: "+ExpressionDump.printExpStr(e)+ " \nsimplified to :"+ExpressionDump.printExpStr(outE)+"\n") else "");
end simplify1time;

public function simplifyWork
"This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc.
This function can be optimised to a switch-statement due to all uniontypes being different.
"
  input DAE.Exp inExp;
  input ExpressionSimplifyTypes.Options options;
  output DAE.Exp outExp;
  output ExpressionSimplifyTypes.Options outOptions;
algorithm
  (outExp,outOptions) := match /* switch: keep it as such */ (inExp,options)
    local
      Integer n,i;
      DAE.Exp e,exp,e1,e_1,e2,e3,exp1;
      Type t,tp;
      Boolean b,b2;
      String idn,str;
      list<DAE.Exp> expl,matrix,subs;
      list<Subscript> s;
      ComponentRef c_1;
      Operator op;
      Integer index_;
      Option<tuple<DAE.Exp,Integer,Integer>> isExpisASUB;
      DAE.ReductionInfo reductionInfo;
      DAE.ReductionIterators riters;
      Option<DAE.Exp> oe;

    case (DAE.SIZE(exp=e1,sz=oe),_)
      then (simplifySize(inExp,e1,oe),options);

    /* simplify different casts. Optimized to only run simplify1 once on subexpression e*/
    case (DAE.CAST(ty = tp,exp=e),_)
      equation
        e = simplifyCast(inExp,e,tp);
      then (e,options);

    case (DAE.ASUB(exp = e, sub = subs),_)
      equation
        e = simplifyAsubExp(inExp,e,subs);
      then (e,options);

    case (DAE.TSUB(), _) then (simplifyTSub(inExp),options);

    // unary operations
    case (DAE.UNARY(operator = op,exp = e1), _)
      equation
        e = simplifyUnary(inExp, op, e1);
      then (e,options);

    case (DAE.BINARY(exp1 = e1,operator = op, exp2 = e2), _)
      equation
        e = simplifyBinary(inExp, op, e1, e2);
      then (e,options);

    // relations
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2, index=index_, optionExpisASUB=isExpisASUB),_)
      equation
        e = simplifyRelation(inExp, op, e1, e2,index_,isExpisASUB);
      then (e,options);

    // logical unary expressions
    case (DAE.LUNARY(operator = op,exp = e1),_)
      equation
        e = simplifyUnary(inExp, op, e1);
      then (e,options);

    // logical binary expressions
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2),_)
      equation
        e = simplifyLBinary(inExp, op, e1, e2);
      then (e,options);

    // if true and false branches are equal
    case (DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),_)
      equation
        e = simplifyIfExp(inExp,e1,e2,e3);
      then (e,options);

    // component references
    case (DAE.CREF(componentRef = c_1,ty=t),_)
      equation
        e = simplifyCref(inExp,c_1,t);
      then (e,options);

    case (DAE.REDUCTION(reductionInfo,e1,riters),_)
      equation
        (riters,b2) = simplifyReductionIterators(riters, {}, false);
        exp1 = if b2 then DAE.REDUCTION(reductionInfo,e1,riters) else inExp;
      then (simplifyReduction(exp1),options);

    case (DAE.CALL(),_) then (simplifyCall(inExp),options);

    case (DAE.MATCHEXPRESSION(),_) then (simplifyMatch(inExp),options);
    case (DAE.UNBOX(),_) then (simplifyUnbox(inExp),options);
    case (DAE.BOX(),_) then (simplifyUnbox(inExp),options);
    case (DAE.CONS(),_) then (simplifyCons(inExp),options);

      // Look for things we really *should* have simplified, but only if we did not modify anything!
/*    case ((e,(false,_)))
      equation
        true = Flags.isSet(Flags.CHECK_SIMPLIFY);
        true = Expression.isConst(e);
        false = Expression.isConstValue(e);
        str = ExpressionDump.printExpStr(e);
        Error.addSourceMessage(Error.SIMPLIFY_CONSTANT_ERROR, {str}, Absyn.dummyInfo);
      then fail(); */

    // anything else
    else (inExp,options);
  end match;
end simplifyWork;

protected function simplifyAsubExp
  input DAE.Exp origExp;
  input DAE.Exp inExp;
  input list<DAE.Exp> inSubs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,inExp,inSubs)
    local
      DAE.Type tp;
      DAE.Exp e;
    // ASUB(CAST(e)) -> CAST(liftArray(t), ASUB(e))
    case (_, DAE.CAST(tp,e), _)
      equation
        tp = Expression.unliftArray(tp);
        e = DAE.CAST(tp, DAE.ASUB(e, inSubs));
      then e;

    // Simplify asubs where some of the subscripts are slices.
    case (_, _, _)
      then simplifyAsubSlicing(inExp, inSubs);

    // other subscripting/asub simplifications where e is not simplified first.
    case (_,_,_)
      equation
        _ = List.map(inSubs,Expression.expInt);
      then List.foldr(inSubs,simplifyAsub,inExp);
    else origExp;
  end matchcontinue;
end simplifyAsubExp;

protected function simplifyCall
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue inExp
    local
      DAE.Exp e,e1,e2,exp,zero;
      list<DAE.Exp> matrix,expl;
      DAE.CallAttributes attr;
      DAE.Type tp;
      Boolean b2;
      String idn;
      Integer n;

    // homotopy(e, e) => e
    case DAE.CALL(path=Absyn.IDENT("homotopy"),expLst={e1,e2})
      equation
        true = Expression.expEqual(e1,e2);
      then
        e1;

    // noEvent propagated to relations and event triggering functions
    case DAE.CALL(path=Absyn.IDENT("noEvent"),expLst={e})
      equation
        b2 = Expression.isRelation(e) or Expression.isEventTriggeringFunctionExp(e);
      then if not b2 then simplifyNoEvent(e) else inExp;

    // der(-v) -> -der(v)
    case DAE.CALL(path=Absyn.IDENT("der"), expLst={DAE.UNARY(DAE.UMINUS(tp),e1 as DAE.CREF())},attr=attr)
      then
        DAE.UNARY(DAE.UMINUS(tp),DAE.CALL(Absyn.IDENT("der"),{e1},attr));
    case DAE.CALL(path=Absyn.IDENT("der"), expLst={DAE.UNARY(DAE.UMINUS_ARR(tp),e1 as DAE.CREF())},attr=attr)
      then DAE.UNARY(DAE.UMINUS_ARR(tp),DAE.CALL(Absyn.IDENT("der"),{e1},attr));

    case DAE.CALL(path=Absyn.IDENT("pre"), expLst={DAE.CREF()})
      then inExp;

    case DAE.CALL(path=Absyn.IDENT("previous"), expLst={DAE.CREF()})
      then inExp;

    case DAE.CALL(path=Absyn.IDENT("change"), expLst={DAE.CREF()})
      then inExp;

    case DAE.CALL(path=Absyn.IDENT("edge"), expLst={DAE.CREF()})
      then inExp;

    case DAE.CALL(path=Absyn.IDENT("pre"), expLst={e as DAE.ASUB(exp = exp)})
      equation
        b2 = Expression.isConst(exp);
      then if b2 then e else inExp;
    case DAE.CALL(path=Absyn.IDENT("previous"), expLst={e as DAE.ASUB(exp = exp)})
      equation
        b2 = Expression.isConst(exp);
      then if b2 then e else inExp;
    case DAE.CALL(path=Absyn.IDENT("change"), expLst={DAE.ASUB(exp = exp)})
      equation
        b2 = Expression.isConst(exp);
      then if b2 then DAE.BCONST(false) else inExp;
    case DAE.CALL(path=Absyn.IDENT("edge"), expLst={DAE.ASUB(exp = exp)})
      equation
        b2 = Expression.isConst(exp);
      then if b2 then DAE.BCONST(false) else inExp;

    // move pre inside
    case DAE.CALL(path=Absyn.IDENT("pre"), expLst={e})
      equation
        (e,_) = Expression.traverseExpTopDown(e,preCref,false);
      then e;
    case DAE.CALL(path=Absyn.IDENT("previous"), expLst={e})
      equation
        (e,_) = Expression.traverseExpTopDown(e,previousCref,false);
      then e;
    case DAE.CALL(path=Absyn.IDENT("change"), expLst={e})
      equation
        (e,_) = Expression.traverseExpTopDown(e,changeCref,false);
      then e;
    case DAE.CALL(path=Absyn.IDENT("edge"), expLst={e})
      equation
        (e,_) = Expression.traverseExpTopDown(e,edgeCref,false);
      then e;

    // normal (pure) call
    case DAE.CALL(path=Absyn.IDENT(idn),expLst=expl, attr=DAE.CALL_ATTR(isImpure=false))
      equation
        true = Expression.isConstWorkList(expl, true);
      then simplifyBuiltinConstantCalls(idn,inExp);

    // simplify some builtin calls, like cross, etc
    case DAE.CALL(attr=DAE.CALL_ATTR(builtin = true))
      then simplifyBuiltinCalls(inExp);

    // simplify identity
    case DAE.CALL(path = Absyn.IDENT(name = "identity"), expLst = {DAE.ICONST(n)})
      equation
        matrix = list(DAE.ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(n)},DAE.emptyTypeSource),true,list(if i==j then DAE.ICONST(1) else DAE.ICONST(0) for i in 1:n)) for j in 1:n);
      then DAE.ARRAY(DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT,{DAE.DIM_INTEGER(n),DAE.DIM_INTEGER(n)},DAE.emptyTypeSource),false,matrix);

    case DAE.CALL(path = Absyn.IDENT(name = "diagonal"), expLst = {DAE.ARRAY(array=expl,ty=tp)})
      equation
        n = listLength(expl);
        tp = Types.arrayElementType(tp);
        zero = Expression.makeConstZero(tp);
        matrix = list(DAE.ARRAY(DAE.T_ARRAY(tp,{DAE.DIM_INTEGER(n)},DAE.emptyTypeSource),true,list(if i==j then listGet(expl,i) else zero for i in 1:n)) for j in 1:n);
      then DAE.ARRAY(DAE.T_ARRAY(tp,{DAE.DIM_INTEGER(n),DAE.DIM_INTEGER(n)},DAE.emptyTypeSource),false,matrix);

    // arcxxx(xxx(e)) => e; xxx(arcxxx(e)) => e
    case (DAE.CALL(path=Absyn.IDENT("sin"),expLst={DAE.CALL(path=Absyn.IDENT("asin"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("cos"),expLst={DAE.CALL(path=Absyn.IDENT("acos"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("tan"),expLst={DAE.CALL(path=Absyn.IDENT("atan"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("asin"),expLst={DAE.CALL(path=Absyn.IDENT("sin"),expLst={e})}))
      then e;
    case (DAE.CALL(path=Absyn.IDENT("atan"),expLst={DAE.CALL(path=Absyn.IDENT("tan"),expLst={e})}))
      then e;
    // sin(acos(e)) = sqrt(1-e^2)
    case (DAE.CALL(path=Absyn.IDENT("sin"),expLst={DAE.CALL(path=Absyn.IDENT("acos"),expLst={e})}))
      then Expression.makePureBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},DAE.T_REAL_DEFAULT);
    // cos(asin(e)) = sqrt(1-e^2)
    case (DAE.CALL(path=Absyn.IDENT("cos"),expLst={DAE.CALL(path=Absyn.IDENT("asin"),expLst={e})}))
      then Expression.makePureBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1),DAE.SUB(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},DAE.T_REAL_DEFAULT);
    // sin(atan(e)) = e/sqrt(1+e^2)
    case (DAE.CALL(path=Absyn.IDENT("sin"),expLst={DAE.CALL(path=Absyn.IDENT("atan"),expLst={e})}))
      then DAE.BINARY(e,DAE.DIV(DAE.T_REAL_DEFAULT),Expression.makePureBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},DAE.T_REAL_DEFAULT));
    // cos(atan(e)) = 1/sqrt(1+e^2)
    case (DAE.CALL(path=Absyn.IDENT("cos"),expLst={DAE.CALL(path=Absyn.IDENT("atan"),expLst={e})}))
      then DAE.BINARY(DAE.RCONST(1),DAE.DIV(DAE.T_REAL_DEFAULT),Expression.makePureBuiltinCall("sqrt",{DAE.BINARY(DAE.RCONST(1),DAE.ADD(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.MUL(DAE.T_REAL_DEFAULT),e))},DAE.T_REAL_DEFAULT));
    // atan2(y,0) = sign(y)*pi/2
    case (DAE.CALL(path=Absyn.IDENT("atan2"),expLst={e1,e2}))
     equation
      true = Expression.isZero(e2);
      e = Expression.makePureBuiltinCall("sign", {e1}, DAE.T_REAL_DEFAULT);
     then DAE.BINARY(DAE.RCONST(1.570796326794896619231321691639751442),DAE.MUL(DAE.T_REAL_DEFAULT),e);
    // atan2(0,x) = 0
    case (DAE.CALL(path=Absyn.IDENT("atan2"),expLst={e1 as DAE.RCONST(0.0),_}))
      then e1;
    // abs(-x) = abs(x)
    case(DAE.CALL(path=Absyn.IDENT("abs"),expLst={DAE.UNARY(operator = DAE.UMINUS(ty = tp),exp = e1)}))
      equation
       e = Expression.makePureBuiltinCall("abs", {e1}, tp);
      then e;

    // MetaModelica builtin operators are calls
    case _
      equation
        true = Config.acceptMetaModelicaGrammar();
      then simplifyMetaModelicaCalls(inExp);
    else inExp;
  end matchcontinue;
end simplifyCall;

protected function preCref
  input DAE.Exp ie;
  input Boolean ib;
  output DAE.Exp oe;
  output Boolean cont;
  output Boolean ob;
algorithm
  (oe,cont,ob) := match (ie,ib)
    local
      DAE.Exp e;
      Boolean b;
      DAE.Type ty;
    case (e as DAE.CREF(ty=ty),_) then (Expression.makeBuiltinCall("pre",{e},ty,false),false,true);
    case (e as DAE.CALL(path=Absyn.IDENT("pre")),b) then (e,false,b);
    case (e,b) then (e,not b,b);
  end match;
end preCref;

protected function previousCref
  input DAE.Exp ie;
  input Boolean ib;
  output DAE.Exp oe;
  output Boolean cont;
  output Boolean ob;
algorithm
  (oe,cont,ob) := match (ie,ib)
    local
      DAE.Exp e;
      Boolean b;
      DAE.Type ty;
    case (e as DAE.CREF(ty=ty),_) then (Expression.makeBuiltinCall("previous",{e},ty,false),false,true);
    case (e as DAE.CALL(path=Absyn.IDENT("previous")),b) then (e,false,b);
    case (e,b) then (e,not b,b);
  end match;
end previousCref;

protected function changeCref
  input DAE.Exp ie;
  input Boolean ib;
  output DAE.Exp oe;
  output Boolean cont;
  output Boolean ob;
algorithm
  (oe,cont,ob) := match (ie,ib)
    local
      DAE.Exp e;
      Boolean b;
      DAE.Type ty;
    case (e as DAE.CREF(ty=ty),_) then (Expression.makeBuiltinCall("change",{e},ty,false),false,true);
    case (e as DAE.CALL(path=Absyn.IDENT("change")),b) then (e,false,b);
    case (e,b) then (e,not b,b);
  end match;
end changeCref;

protected function edgeCref
  input DAE.Exp ie;
  input Boolean ib;
  output DAE.Exp oe;
  output Boolean cont;
  output Boolean ob;
algorithm
  (oe,cont,ob) := match (ie,ib)
    local
      DAE.Exp e;
      Boolean b;
      DAE.Type ty;
    case (e as DAE.CREF(ty=ty),_) then (Expression.makeBuiltinCall("edge",{e},ty,false),false,true);
    case (e as DAE.CALL(path=Absyn.IDENT("edge")),b) then (e,false,b);
    case (e,b) then (e,not b,b);
  end match;
end edgeCref;

public function simplify1
"This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := simplify1WithOptions(inExp,optionSimplifyOnly);
end simplify1;

public function simplify1o
"This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input Option<DAE.Exp> inExp;
  output Option<DAE.Exp> outExp;
algorithm
  outExp := match inExp
            local DAE.Exp e;
            case SOME(e)
            equation
              (e,_) = simplify1WithOptions(e,optionSimplifyOnly);
            then SOME(e);
            else inExp;
            end match;
end simplify1o;


public function simplify1WithOptions
"This function does some very basic simplification
  on expressions, like 0*a = 0, [1][1] => 1, etc."
  input DAE.Exp inExp;
  input ExpressionSimplifyTypes.Options options;
  output DAE.Exp outExp;
  output Boolean hasChanged;
algorithm
  (outExp,hasChanged) := simplify1FixP(inExp,options,100,true,false);
  checkSimplify(Flags.isSet(Flags.CHECK_SIMPLIFY),inExp,outExp);
end simplify1WithOptions;

protected function checkSimplify
  "Verifies that the complexity of the expression is lower or equal than before the simplification was performed"
  input Boolean check;
  input DAE.Exp before;
  input DAE.Exp after;
algorithm
  _ := match (check,before,after)
    local
      Integer c1,c2;
      Boolean b;
      String s1,s2,s3,s4;
      DAE.Type ty1,ty2;
    case (false,_,_) then ();
    case (true,_,_)
      equation
        ty1 = Expression.typeof(before);
        ty2 = Expression.typeof(after);
        b = valueEq(ty1,ty2);
        if not b then
          s1 = ExpressionDump.printExpStr(before);
          s2 = ExpressionDump.printExpStr(after);
          s3 = Types.unparseType(ty1);
          s4 = Types.unparseType(ty2);
          Error.addMessage(Error.SIMPLIFICATION_TYPE, {s1,s2,s3,s4});
          fail();
        end if;
        c1 = Expression.complexity(before);
        c2 = Expression.complexity(after);
        b = c1 < c2;
        if b then
          s1 = intString(c2);
          s2 = intString(c1);
          s3 = ExpressionDump.printExpStr(before);
          s4 = ExpressionDump.printExpStr(after);
          Error.addMessage(Error.SIMPLIFICATION_COMPLEXITY, {s1,s2,s3,s4});
          fail();
        end if;
      then ();
  end match;
end checkSimplify;

protected function simplify1FixP
"Does fixpoint simplify1 max n times"
  input DAE.Exp inExp;
  input ExpressionSimplifyTypes.Options inOptions;
  input Integer n;
  input Boolean cont;
  input Boolean hasChanged;
  output DAE.Exp outExp;
  output Boolean outHasChanged;
algorithm
  (outExp,outHasChanged) := match (inExp,inOptions,n,cont,hasChanged)
    local
      DAE.Exp exp,expAfterSimplify;
      Boolean b;
      String str1,str2;
      ExpressionSimplifyTypes.Options options;
    case (exp,_,_,false,_)
      equation
        // print("End fixp: " + ExpressionDump.printExpStr(exp) + "\n");
      then (exp,hasChanged);
    case (exp,options,0,_,_)
      equation
        str1 = ExpressionDump.printExpStr(exp);
        (exp,_) = Expression.traverseExpBottomUp(exp,simplifyWork,options);
        str2 = ExpressionDump.printExpStr(exp);
        Error.addMessage(Error.SIMPLIFY_FIXPOINT_MAXIMUM, {str1,str2});
      then (exp,hasChanged);
    case (exp,options,_,true,_)
      equation
        // print("simplify1 start: " + ExpressionDump.printExpStr(exp) + "\n");
        ErrorExt.setCheckpoint("ExpressionSimplify");
        (expAfterSimplify,options) = Expression.traverseExpBottomUp(exp,simplifyWork,options);
        b = not referenceEq(expAfterSimplify, exp);
        if b then
          ErrorExt.rollBack("ExpressionSimplify");
        else
          ErrorExt.delCheckpoint("ExpressionSimplify");
        end if;
        // print("simplify1 iter: " + ExpressionDump.printExpStr(expAfterSimplify) + "\n");
        (expAfterSimplify,b) = simplify1FixP(expAfterSimplify,options,n-1,b,b or hasChanged);
      then (expAfterSimplify,b);
  end match;
end simplify1FixP;

protected function simplifyReductionIterators
  input list<DAE.ReductionIterator> inIters;
  input list<DAE.ReductionIterator> inAcc;
  input Boolean inChange;
  output list<DAE.ReductionIterator> outIters;
  output Boolean outChange;
algorithm
  (outIters,outChange) := match (inIters,inAcc,inChange)
    local
      String id;
      DAE.Exp exp;
      DAE.Type ty;
      DAE.ReductionIterator iter;
      list<DAE.ReductionIterator> iters,acc;
      Boolean change;

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
  input DAE.Exp origExp;
  input DAE.Exp cond;
  input DAE.Exp tb;
  input DAE.Exp fb;
  output DAE.Exp exp;
algorithm
  exp := match (origExp,cond,tb,fb)
    local
      DAE.Exp e,e1,e2;
      // Condition is constant
    case (_,DAE.BCONST(true),_,_) then tb;
    case (_,DAE.BCONST(false),_,_) then fb;
      // The expression is the condition
    case (_,exp,DAE.BCONST(true),DAE.BCONST(false)) then exp;
    case (_,exp,DAE.BCONST(false),DAE.BCONST(true))
      equation
        exp = DAE.LUNARY(DAE.NOT(DAE.T_BOOL_DEFAULT), exp);
      then exp;
    case (_,e,DAE.BOX(e1),DAE.BOX(e2))
      equation
        e = DAE.IFEXP(e,e1,e2);
      then DAE.BOX(e);
    else // Are the branches equal? Then why bother with the condition
      if Expression.expEqual(tb,fb) then tb else origExp;
  end match;
end simplifyIfExp;

protected function simplifyMetaModelicaCalls "simplifies MetaModelica operators"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := match exp
    local
      DAE.Exp e,e1,e2,e1_1,e2_1;
      Boolean b,b1,b2;
      Absyn.Path path;
      list<DAE.Exp> el;
      Integer i;
      Real r;
      String s;
      Option<DAE.Exp> foldExp;
      Option<Values.Value> v;
      DAE.Type ty;
      DAE.ReductionIterators riters;
      String foldName,resultName;
      Absyn.ReductionIterType rit;

    case DAE.CALL(path=Absyn.IDENT("listAppend"),expLst={DAE.LIST(el),e2})
      equation
        e = List.fold(listReverse(el), Expression.makeCons, e2);
      then e;

    case DAE.CALL(path=Absyn.IDENT("listAppend"),expLst={e1,DAE.LIST(valList={})})
      then e1;

    case DAE.CALL(path=Absyn.IDENT("intString"),expLst={DAE.ICONST(i)})
      equation
        s = intString(i);
      then DAE.SCONST(s);

    case DAE.CALL(path=Absyn.IDENT("realString"),expLst={DAE.RCONST(r)})
      equation
        s = realString(r);
      then DAE.SCONST(s);

    case DAE.CALL(path=Absyn.IDENT("boolString"),expLst={DAE.BCONST(b)})
      equation
        s = boolString(b);
      then DAE.SCONST(s);

    case DAE.CALL(path=Absyn.IDENT("listReverse"),expLst={DAE.LIST(el)})
      equation
        el = listReverse(el);
        e1_1 = DAE.LIST(el);
      then e1_1;

    case DAE.CALL(path=Absyn.IDENT("listReverse"),expLst={DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("list"),rit,ty,v,foldName,resultName,foldExp),e1,riters)})
      equation
        e1 = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("listReverse"),rit,ty,v,foldName,resultName,foldExp),e1,riters);
      then e1;

    case DAE.CALL(path=Absyn.IDENT("listReverse"),expLst={DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("listReverse"),rit,ty,v,foldName,resultName,foldExp),e1,riters)})
      equation
        e1 = DAE.REDUCTION(DAE.REDUCTIONINFO(Absyn.IDENT("list"),rit,ty,v,foldName,resultName,foldExp),e1,riters);
      then e1;

    case DAE.CALL(path=Absyn.IDENT("listLength"),expLst={DAE.LIST(el)})
      equation
        i = listLength(el);
      then DAE.ICONST(i);

    case DAE.CALL(path=Absyn.IDENT("sourceInfo"))
      equation
        print("sourceInfo() - simplify?\n");
      then fail();

  end match;
end simplifyMetaModelicaCalls;

protected function simplifyCons
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := match inExp
    local
      DAE.Exp e;
      list<DAE.Exp> es;
    case DAE.CONS(e,DAE.LIST(es)) then DAE.LIST(e::es);
    else inExp;
  end match;
end simplifyCons;

protected function simplifyUnbox "simplifies both box and unbox expressions"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := match exp
    case DAE.UNBOX(exp=DAE.BOX(outExp)) then outExp;
    case DAE.BOX(DAE.UNBOX(exp=outExp)) then outExp;
    else exp;
  end match;
end simplifyUnbox;

protected function simplifyMatch "simplifies MetaModelica match expressions"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue exp
    local
      DAE.Exp e,e1,e2,e1_1,e2_1;
      Boolean b,b1,b2;
      Absyn.Path path;
      list<DAE.Exp> el;
      Integer i;
      Real r;
      String s;
      Option<DAE.Exp> foldExp;
      Option<Values.Value> v;
      DAE.Type ty;
      DAE.ReductionIterators riters;
    // match () case () then exp; end match => exp
    case DAE.MATCHEXPRESSION(inputs={}, et=ty, localDecls={}, cases={
        DAE.CASE(patterns={},localDecls={},body={},result=SOME(e))
      })
      equation
        false = Types.isTuple(ty);
      then e;

    case DAE.MATCHEXPRESSION(inputs={e}, et=ty, localDecls={}, cases={
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b1))},localDecls={},body={},result=SOME(e1)),
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b2))},localDecls={},body={},result=SOME(e2))
      })
      equation
        false = boolEq(b1,b2);
        false = Types.isTuple(ty);
        e1_1 = if b1 then e1 else e2;
        e2_1 = if b1 then e2 else e1;
        e = DAE.IFEXP(e, e1_1, e2_1);
      then e;

    case DAE.MATCHEXPRESSION(matchType=DAE.MATCH(), et=ty, inputs={e}, localDecls={}, cases={
        DAE.CASE(patterns={DAE.PAT_CONSTANT(exp=DAE.BCONST(b1))},localDecls={},body={},result=SOME(e1)),
        DAE.CASE(patterns={DAE.PAT_WILD()},localDecls={},body={},result=SOME(e2))
      })
      equation
        false = Types.isTuple(ty);
        e1_1 = if b1 then e1 else e2;
        e2_1 = if b1 then e2 else e1;
        e = DAE.IFEXP(e, e1_1, e2_1);
      then e;

     else exp;
  end matchcontinue;
end simplifyMatch;

protected function simplifyCast "help function to simplify1"
  input DAE.Exp origExp;
  input DAE.Exp exp;
  input Type tp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(origExp,exp,tp)
    local
      Real r;
      Integer i,n;
      Boolean b;
      list<DAE.Exp> exps,exps_1;
      Type t,tp_1,tp1,tp2,t1,t2;
      DAE.Exp e1,e2,cond,e1_1,e2_1,e;
      list<list<DAE.Exp>> mexps,mexps_1;
      Option<DAE.Exp> eo;
      DAE.Dimensions dims;
      Absyn.Path p1,p2,p3;
      list<String> fieldNames;

    // Real -> Real
    case(_,DAE.RCONST(r),DAE.T_REAL()) then DAE.RCONST(r);

    // Int -> Real
    case(_,DAE.ICONST(i),DAE.T_REAL())
      equation
        r = intReal(i);
      then
        DAE.RCONST(r);

    // cast of unary
    case(_,DAE.UNARY(DAE.UMINUS_ARR(_),e),_)
      equation
        e = addCast(e,tp);
      then
        DAE.UNARY(DAE.UMINUS_ARR(tp),e);
    // cast of unary
    case(_,DAE.UNARY(DAE.UMINUS(_),e),_)
      equation
        e = addCast(e,tp);
      then
        DAE.UNARY(DAE.UMINUS(tp),e);

    // cast of array
    case(_,DAE.ARRAY(_,b,exps),_)
      equation
        tp_1 = Expression.unliftArray(tp);
        exps_1 = List.map1(exps, addCast, tp_1);
      then
        DAE.ARRAY(tp,b,exps_1);

    // cast of array
    case (_,DAE.RANGE(ty=DAE.T_INTEGER(),start=e1,step=eo,stop=e2),DAE.T_ARRAY(ty=tp2 as DAE.T_REAL()))
      equation
        e1 = addCast(e1,tp2);
        e2 = addCast(e2,tp2);
        eo = Util.applyOption1(eo, addCast, tp2);
      then
        DAE.RANGE(tp2,e1,eo,e2);

    // simplify cast in an if expression
    case (_,DAE.IFEXP(cond,e1,e2),_)
      equation
        e1_1 = DAE.CAST(tp,e1);
        e2_1 = DAE.CAST(tp,e2);
      then DAE.IFEXP(cond,e1_1,e2_1);

    // simplify cast of matrix expressions
    case (_,DAE.MATRIX(_,n,mexps),_)
      equation
        tp1 = Expression.unliftArray(tp);
        tp2 = Expression.unliftArray(tp1);
        mexps_1 = List.map1List(mexps, addCast, tp2);
      then DAE.MATRIX(tp,n,mexps_1);

    // simplify record constructor from one to another
    case (_,DAE.CALL(p1,exps,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p2)))),DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p3)))
      equation
        true = Absyn.pathEqual(p1,p2) "It is a record constructor since it has the same path called as its output type";
      then DAE.CALL(p3,exps,DAE.CALL_ATTR(tp,false,false,false,false,DAE.NO_INLINE(),DAE.NO_TAIL()));

    case (_,DAE.RECORD(_,exps,fieldNames,_),DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(p3)))
      then DAE.RECORD(p3,exps,fieldNames,tp);

    // fill(e, ...) can be simplified
    case(_,DAE.CALL(path=Absyn.IDENT("fill"),expLst=e::exps),_)
      equation
        tp_1 = List.fold(exps,Expression.unliftArrayIgnoreFirst,tp);
        e = DAE.CAST(tp_1,e);
        e = Expression.makePureBuiltinCall("fill",e::exps,tp);
      then e;

    // cat(e, ...) can be simplified
    case(_,DAE.CALL(path=Absyn.IDENT("cat"),expLst=(e as DAE.ICONST(n))::exps),DAE.T_ARRAY(dims=dims))
      equation
        DAE.DIM_UNKNOWN() = listGet(dims,n);
        exps = List.map1(exps,addCast,tp);
      then Expression.makePureBuiltinCall("cat",e::exps,tp);

    // expression already has a specified cast type.
    case(_,e,_)
      equation
        t1 = Expression.arrayEltType(tp);
        t2 = Expression.arrayEltType(Expression.typeof(e));
        true = valueEq(t1, t2);
      then e;
    else origExp;
  end matchcontinue;
end simplifyCast;

protected function addCast
"Adds a cast of a Type to an expression."
  input DAE.Exp inExp;
  input Type inType;
  output DAE.Exp outExp;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outExp:=DAE.CAST(inType,inExp);
end addCast;

protected function simplifyBuiltinCalls "simplifies some builtin calls (with no constant expressions)"
  input DAE.Exp exp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (exp)
    local
      list<list<DAE.Exp>> mexpl;
      list<DAE.Exp> es,expl;
      DAE.Exp e,len_exp,just_exp,e1,e2,e3,e4;
      DAE.Type tp,tp1,tp2;
      DAE.Operator op;
      list<DAE.Exp> v1, v2;
      Boolean scalar,sc;
      list<Values.Value> valueLst;
      Integer i,i1,i2,dim;
      Real r1;
      array<array<DAE.Exp>> marr;
      String name;
      DAE.TypeSource source;

    // If the argument to min/max is an array, try to flatten it.
    case (DAE.CALL(path=Absyn.IDENT(name),expLst={e as DAE.ARRAY()},
        attr=DAE.CALL_ATTR(ty=tp)))
      equation
        true = stringEq(name, "max") or stringEq(name, "min");
        expl = Expression.flattenArrayExpToList(e);
        e1 = Expression.makeScalarArray(expl, tp);
        false = Expression.expEqual(e, e1);
      then
        Expression.makePureBuiltinCall(name, {e1}, tp);

    // min/max function on arrays of only 1 element
    case (DAE.CALL(path=Absyn.IDENT("min"),expLst={DAE.ARRAY(array={e})})) then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),expLst={DAE.ARRAY(array={e})})) then e;

    case (DAE.CALL(path=Absyn.IDENT("max"),expLst={DAE.ARRAY(array=es)},attr=DAE.CALL_ATTR(ty=tp)))
      equation
        i1 = listLength(es);
        es = List.union(es,es);
        i2 = listLength(es);
        if i1 == i2
        then
          SOME(e) = List.fold(es, maxElement, NONE());
          es = List.select(es, removeMinMaxFoldableValues);
          es = e::es;
          i2 = listLength(es);
          true = i2 < i1;
          e = Expression.makeScalarArray(es,tp);
        else
          e = Expression.makeScalarArray(es,tp);
        end if;
      then
        Expression.makePureBuiltinCall("max",{e},tp);

    case (DAE.CALL(path=Absyn.IDENT("min"),expLst={DAE.ARRAY(array=es)},attr=DAE.CALL_ATTR(ty=tp)))
      equation
        i1 = listLength(es);
        es = List.union(es,es);
        i2 = listLength(es);
        if i1 == i2
        then
          SOME(e) = List.fold(es, minElement, NONE());
          es = List.select(es, removeMinMaxFoldableValues);
          es = e::es;
          i2 = listLength(es);
          true = i2 < i1;
          e = Expression.makeScalarArray(es,tp);
        else
          e = Expression.makeScalarArray(es,tp);
        end if;
      then
        Expression.makePureBuiltinCall("min",{e},tp);

    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=tp),expLst={DAE.ARRAY(array={e1,e2})}))
      equation
        e = Expression.makePureBuiltinCall("min",{e1,e2},tp);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=tp),expLst={DAE.ARRAY(array={e1,e2})}))
      equation
        e = Expression.makePureBuiltinCall("max",{e1,e2},tp);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=DAE.T_BOOL()),expLst={e1,e2}))
      equation
        e = DAE.LBINARY(e1,DAE.AND(DAE.T_BOOL_DEFAULT),e2);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=DAE.T_BOOL()),expLst={e1,e2}))
      equation
        e = DAE.LBINARY(e1,DAE.OR(DAE.T_BOOL_DEFAULT),e2);
      then e;
    case (DAE.CALL(path=Absyn.IDENT("min"),attr=DAE.CALL_ATTR(ty=DAE.T_BOOL()),expLst={DAE.ARRAY(array=expl)}))
      equation
        e = Expression.makeLBinary(expl,DAE.AND(DAE.T_BOOL_DEFAULT));
      then e;
    case (DAE.CALL(path=Absyn.IDENT("max"),attr=DAE.CALL_ATTR(ty=DAE.T_BOOL()),expLst={DAE.ARRAY(array=expl)}))
      equation
        e = Expression.makeLBinary(expl,DAE.OR(DAE.T_BOOL_DEFAULT));
      then e;

    case DAE.CALL(path=Absyn.IDENT(name), expLst = {DAE.ARRAY(array = expl as _ :: _ :: _)},
        attr = DAE.CALL_ATTR(ty = tp))
      equation
        true = Config.scalarizeMinMax();
        true = stringEq(name, "max") or stringEq(name, "min");
        e1 :: e2 :: expl = listReverse(expl);
        e1 = Expression.makePureBuiltinCall(name, {e2, e1}, tp);
        e1 = List.fold2(expl, makeNestedReduction, name, tp, e1);
      then
        e1;

    // cross
    case (e as DAE.CALL(path = Absyn.IDENT("cross"), expLst = expl))
      equation
        {DAE.ARRAY(array = v1),DAE.ARRAY(array = v2)} = expl;
        expl = simplifyCross(v1, v2);
        tp = Expression.typeof(e);
        // Since there is a bug somewhere in simplify that gives wrong types for arrays we take the type from cross.
        scalar = not Expression.isArrayType(Expression.unliftArray(tp));
      then
        DAE.ARRAY(tp, scalar,expl);

    case (e as DAE.CALL(path = Absyn.IDENT("skew"), expLst = {DAE.ARRAY(array = v1)}))
      equation
        mexpl = simplifySkew(v1);
        tp = Expression.typeof(e);
      then DAE.MATRIX(tp, 3, mexpl);

    // Simplify built-in function fill. MathCore depends on this being done here, do not remove!
    case (DAE.CALL(path = Absyn.IDENT("fill"), expLst = e::expl))
      equation
        valueLst = List.map(expl, ValuesUtil.expValue);
        (_,outExp,_) = Static.elabBuiltinFill2(FCore.noCache(), FGraph.empty(), e, Expression.typeof(e), valueLst, DAE.C_CONST(), Prefix.NOPRE(), {}, Absyn.dummyInfo);
      then
        outExp;

    case (DAE.CALL(path = Absyn.IDENT("String"), expLst = {e,len_exp,just_exp}))
      then simplifyBuiltinStringFormat(e,len_exp,just_exp);

    case (DAE.CALL(path = Absyn.IDENT("stringAppendList"), expLst = {DAE.LIST(expl)}))
      then simplifyStringAppendList(expl,{},false);

    // sqrt(e ^ r) => e ^ (0.5 * r)
    case DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={DAE.BINARY(e1,DAE.POW(ty = DAE.T_REAL()),e2)})
      equation
        e = DAE.BINARY(e1,DAE.POW(DAE.T_REAL_DEFAULT),DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.T_REAL_DEFAULT),e2));
      then Expression.makePureBuiltinCall("abs",{e},DAE.T_REAL_DEFAULT);

   // sqrt(sqrt(e)) => e ^ (0.25)
    case (DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1})}))
       then DAE.BINARY(e1,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(0.25));

   // sqrt(c*e) => c1*sqrt(e)
    case DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={DAE.BINARY(e1 as DAE.RCONST(r1),DAE.MUL(tp),e2)})
      equation
        true = r1 >= 0.0;
        e = Expression.makePureBuiltinCall("sqrt",{e1},DAE.T_REAL_DEFAULT);
        e3 =  Expression.makePureBuiltinCall("sqrt",{e2},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(e,DAE.MUL(tp),e3);

   // exp(-(...*log(x)*...))
   case (DAE.CALL(path=Absyn.IDENT("exp"),expLst={DAE.UNARY(DAE.UMINUS(),e1)}))
   equation
     expl = Expression.expandFactors(e1);
     ({e2},es) = List.split1OnTrue(expl, Expression.isFunCall, "log");
     DAE.CALL(expLst={e})= e2;
     e3 = Expression.makeProductLst(es);
   then Expression.expPow(e, Expression.negate(e3));

   // exp(...*log(x)*...)
   case (DAE.CALL(path=Absyn.IDENT("exp"),expLst={e1}))
   equation
     expl = Expression.expandFactors(e1);
     ({e2},es) = List.split1OnTrue(expl, Expression.isFunCall, "log");
     DAE.CALL(expLst={e})= e2;
     e3 = Expression.makeProductLst(es);
   then Expression.expPow(e,e3);

   // exp(e)^r = exp(e*r)
   case (DAE.BINARY(DAE.CALL(path=Absyn.IDENT("exp"),expLst={e}),DAE.POW(ty = DAE.T_REAL()),e2))
     equation
      e3 = Expression.expMul(e,e2);
   then Expression.makePureBuiltinCall("exp",{e3},DAE.T_REAL_DEFAULT);

   // log(x^n) = n*log(x)
   case (DAE.CALL(path=Absyn.IDENT("log"),expLst={DAE.BINARY(e1,DAE.POW(ty = DAE.T_REAL()), DAE.RCONST(r1))}))
     equation
       1.0 = realMod(r1,2.0);
       e3 = Expression.makePureBuiltinCall("log",{e1},DAE.T_REAL_DEFAULT);
     then  Expression.expMul(DAE.RCONST(r1), e3);
   // log(1/x) = -log(x)
   case (DAE.CALL(path=Absyn.IDENT("log"),expLst={DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(ty = DAE.T_REAL()), e2)}))
     equation
       e3 = Expression.makePureBuiltinCall("log",{e2},DAE.T_REAL_DEFAULT);
     then DAE.UNARY(DAE.UMINUS(DAE.T_REAL_DEFAULT),e3);
   // log(sqrt(x)) = 0.5*log(x)
   case (DAE.CALL(path=Absyn.IDENT("log"),expLst={DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1})}))
     equation
       e3 = Expression.makePureBuiltinCall("log",{e1},DAE.T_REAL_DEFAULT);
     then DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.T_REAL_DEFAULT),e3);

   // smooth of constant expression
   case DAE.CALL(path=Absyn.IDENT("smooth"),expLst={_,e1})
   guard Expression.isConst(e1)
     then e1;

   // df_der(const) --> 0
   case DAE.CALL(path=Absyn.IDENT("$_DF$DER"),expLst={e1})
   guard Expression.isConst(e1)
     then Expression.makeConstZeroE(e1);

   // delay of constant expression
   case DAE.CALL(path=Absyn.IDENT("delay"),expLst={e1,_,_})
   guard Expression.isConst(e1)
     then e1;

    // delay of constant subexpression
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.BINARY(e1,op,e2),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        true = Expression.isConst(e1);
        e = Expression.makeImpureBuiltinCall("delay",{e2,e3,e4},tp);
      then DAE.BINARY(e1,op,e);

    // delay of constant subexpression
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.BINARY(e1,op,e2),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        true = Expression.isConst(e2);
        e = Expression.makeImpureBuiltinCall("delay",{e1,e3,e4},tp);
      then DAE.BINARY(e,op,e2);

    // delay(-x) = -delay(x)
    case DAE.CALL(path=Absyn.IDENT("delay"),expLst={DAE.UNARY(op,e),e3,e4},attr=DAE.CALL_ATTR(ty=tp))
      equation
        e = Expression.makeImpureBuiltinCall("delay",{e,e3,e4},tp);
      then DAE.UNARY(op,e);

    // To calculate sums, first try matrix concatenation
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.MATRIX(ty=tp1,matrix=mexpl)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        es = List.flatten(mexpl);
        tp1 = Expression.unliftArray(Expression.unliftArray(tp1));
        sc = not Expression.isArrayType(tp1);
        tp1 = if sc then Expression.unliftArray(tp1) else tp1;
        tp1 = if sc then Expression.liftArrayLeft(tp1,DAE.DIM_UNKNOWN()) else tp1;
        dim = listLength(es);
        tp1 = Expression.liftArrayLeft(tp1,DAE.DIM_INTEGER(dim));
        e = DAE.ARRAY(tp1,sc,es);
        e = Expression.makePureBuiltinCall("sum",{e},tp2);
        // print("Matrix sum: " + boolString(sc) + Types.unparseType(tp1) + " " + ExpressionDump.printExpStr(e) + "\n");
      then e;
    // Then try array concatenation
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array=es,ty=tp1,scalar=false)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        es = simplifyCat(1,es);
        tp1 = Expression.unliftArray(tp1);
        sc = not Expression.isArrayType(tp1);
        tp1 = if sc then Expression.unliftArray(tp1) else tp1;
        tp1 = if sc then Expression.liftArrayLeft(tp1,DAE.DIM_UNKNOWN()) else tp1;
        dim = listLength(es);
        tp1 = Expression.liftArrayLeft(tp1,DAE.DIM_INTEGER(dim));
        e = DAE.ARRAY(tp1,sc,es);
        e = Expression.makePureBuiltinCall("sum",{e},tp2);
        // print("Array sum: " + boolString(sc) + Types.unparseType(tp1) + " " + ExpressionDump.printExpStr(e) + "\n");
      then e;
    // Try to reduce the number of dimensions
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array={e},scalar=false)},attr=DAE.CALL_ATTR(ty=tp2))
      equation
        e = Expression.makePureBuiltinCall("sum",{e},tp2);
      then e;
    // The sum of a single array is simply the sum of its elements
    case DAE.CALL(path=Absyn.IDENT("sum"),expLst={DAE.ARRAY(array=es,scalar=true)})
      equation
        e = Expression.makeSum(es);
      then e;

    case DAE.CALL(path=Absyn.IDENT("cat"),expLst=_::{e1}) then e1;

    case DAE.CALL(path=Absyn.IDENT("cat"),expLst=DAE.ICONST(i)::es,attr=DAE.CALL_ATTR(ty=tp))
      equation
        es = simplifyCat(i,es);
        i = listLength(es);
        e = Expression.makePureBuiltinCall("cat",DAE.ICONST(i)::es,tp);
      then e;

    // promote 1-dim to 2-dim
    case DAE.CALL(path=Absyn.IDENT("promote"),expLst=(DAE.ARRAY(tp1 as DAE.T_ARRAY(dims={_}),sc,es))::DAE.ICONST(1)::{})
      equation
        tp = Types.liftArray(Types.unliftArray(tp1), DAE.DIM_INTEGER(1));
        es = List.map2(List.map(es,List.create), Expression.makeArray, tp, sc);
        i = listLength(es);
        tp = Expression.liftArrayLeft(tp, DAE.DIM_INTEGER(i));
      then
        DAE.ARRAY(tp,false,es);

    case DAE.CALL(path=Absyn.IDENT("transpose"),expLst=e::{},attr=DAE.CALL_ATTR())
      equation
        (e, true) = Expression.transposeArray(e);
      then
        e;

    case DAE.CALL(path=Absyn.IDENT("symmetric"),expLst=e::{},attr=DAE.CALL_ATTR(ty=tp))
      equation
        mexpl = Expression.get2dArrayOrMatrixContent(e);
        e = match(mexpl)
          case {{}} then e;
          case {{_}} then e;
          case _ equation
            marr = listArray(List.map(mexpl,listArray));
            true = arrayLength(marr) == arrayLength(arrayGet(marr,1));
            true = arrayLength(marr) > 1;
            simplifySymmetric(marr, arrayLength(marr)-1, arrayLength(marr));
            mexpl = List.map(arrayList(marr), arrayList);
            tp1 = Types.unliftArray(tp);
            es = List.map2(mexpl, Expression.makeArray, tp1, not Types.isArray(tp1));
            e = Expression.makeArray(es, tp, false);
          then e;
        end match;
      then e;

    case DAE.CALL(path=Absyn.IDENT("scalar"),expLst=e::{},attr=DAE.CALL_ATTR(ty=tp))
      equation
        e = simplifyScalar(e,tp);
      then e;

    case DAE.CALL(path=Absyn.IDENT("vector"),expLst=es as (e::_),attr=DAE.CALL_ATTR(ty=DAE.T_ARRAY(tp,_,source)))
      equation
        false = Types.isArray(Expression.typeof(e));
        i = listLength(es);
        tp = DAE.T_ARRAY(tp,{DAE.DIM_INTEGER(i)},source);
      then DAE.ARRAY(tp,true,es);

    case DAE.CALL(path=Absyn.IDENT("vector"),expLst=(e as DAE.ARRAY(scalar=true))::{},attr=DAE.CALL_ATTR())
      then e;

    case DAE.CALL(path=Absyn.IDENT("vector"),expLst=DAE.MATRIX(matrix=mexpl)::{},attr=DAE.CALL_ATTR(ty=tp))
      equation
        es = List.flatten(mexpl);
        es = List.map1(es, Expression.makeVectorCall, tp);
        e = Expression.makePureBuiltinCall("cat", DAE.ICONST(1)::es, tp);
      then e;

    case DAE.CALL(path=Absyn.IDENT("vector"),expLst=DAE.ARRAY(array=es)::{},attr=DAE.CALL_ATTR(ty=tp))
      equation
        es = List.map1(es, Expression.makeVectorCall, tp);
        e = Expression.makePureBuiltinCall("cat", DAE.ICONST(1)::es, tp);
      then e;

  end matchcontinue;
end simplifyBuiltinCalls;

protected function simplifyScalar "Handle the scalar() operator"
  input DAE.Exp inExp;
  input DAE.Type tp;
  output DAE.Exp exp;
algorithm
  exp := match (inExp,tp)
    case (DAE.ARRAY(array={exp}),_)
      then Expression.makePureBuiltinCall("scalar", {exp}, tp);
    case (DAE.MATRIX(matrix={{exp}}),_)
      then Expression.makePureBuiltinCall("scalar", {exp}, tp);
    case (DAE.SIZE(exp=exp,sz=NONE()),_)
      equation
        (_,{_}) = Types.flattenArrayTypeOpt(Expression.typeof(inExp));
      then DAE.SIZE(exp,SOME(DAE.ICONST(1)));
    else
      equation
        (_,{}) = Types.flattenArrayTypeOpt(Expression.typeof(inExp));
      then inExp;
  end match;
end simplifyScalar;

protected function makeNestedReduction
  input DAE.Exp inExp;
  input String inName;
  input DAE.Type inType;
  input DAE.Exp inCall;
  output DAE.Exp outCall;
algorithm
  outCall := Expression.makePureBuiltinCall(inName, {inExp, inCall}, inType);
end makeNestedReduction;

protected function simplifySymmetric
  input array<array<DAE.Exp>> marr;
  input Integer i1;
  input Integer i2;
algorithm
  _ := match (marr,i1,i2)
    local
      array<DAE.Exp> v1,v2;
      DAE.Exp exp;
    case (_,0,1) then ();
    else
      equation
        v1 = arrayGet(marr, i1);
        v2 = arrayGet(marr, i2);
        exp = arrayGet(v1,i2);
        arrayUpdate(v2, i1, exp);
        simplifySymmetric(marr, if i1==1 then (i2-2) else (i1-1), if i1==1 then (i2-1) else i2);
      then ();
  end match;
end simplifySymmetric;

protected function simplifyCat
  input Integer inDim;
  input list<DAE.Exp> inExpList;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := match(inDim, inExpList)
    local
      list<DAE.Exp> expl;

    case (1, _)
      equation
        expl = List.map(inExpList, Expression.matrixToArray);
      then
        simplifyCat2(inDim, expl, {}, false);

    else simplifyCat2(inDim, inExpList, {}, false);

  end match;
end simplifyCat;

protected function simplifyCat2
  input Integer dim;
  input list<DAE.Exp> ies;
  input list<DAE.Exp> acc;
  input Boolean changed;
  output list<DAE.Exp> oes;
algorithm
  oes := matchcontinue (dim,ies,acc,changed)
    local
      list<DAE.Exp> es1,es2,esn,es;
      DAE.Exp e, e2;
      DAE.Dimension ndim,dim1,dim2,dim11;
      DAE.Dimensions dims;
      DAE.Type etp;
      Integer i1,i2,i;
      list<list<DAE.Exp>> ms1,ms2,mss;
      Boolean sc;
      DAE.TypeSource ts;

    case (_,{},_,true) then listReverse(acc);

    case (1,DAE.ARRAY(array=es1,scalar=sc,ty=DAE.T_ARRAY(dims=dim1::dims,ty=etp,source=ts)) ::
            DAE.ARRAY(array=es2,ty=DAE.T_ARRAY(dims=dim2::_))::es,_,_)
      equation
        esn = listAppend(es1,es2);
        ndim = Expression.addDimensions(dim1,dim2);
        etp = DAE.T_ARRAY(etp,ndim::dims,ts);
        e = DAE.ARRAY(etp,sc,esn);
      then simplifyCat2(dim,e::es,acc,true);

    case (2,DAE.MATRIX(matrix=ms1,integer=i,ty=DAE.T_ARRAY(dims=dim11::dim1::dims,ty=etp,source=ts))::DAE.MATRIX(matrix=ms2,ty=DAE.T_ARRAY(dims=_::dim2::_))::es,_,_)
      equation
        mss = List.threadMap(ms1,ms2,listAppend);
        ndim = Expression.addDimensions(dim1,dim2);
        etp = DAE.T_ARRAY(etp,dim11::ndim::dims,ts);
        e = DAE.MATRIX(etp,i,mss);
      then simplifyCat2(dim,e::es,acc,true);

    case (_,e::es,_,_) then simplifyCat2(dim,es,e::acc,changed);
  end matchcontinue;
end simplifyCat2;

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
        str = stringAppendList(List.fill(" ", fill_size)) + inString;
      then
        str;
    // leftJustified is true, append spaces at the end of the string.
    case (_, _, _, true)
      equation
        fill_size = minLength - stringLength;
        str = inString + stringAppendList(List.fill(" ", fill_size));
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
  input list<DAE.Exp> iexpl;
  input list<DAE.Exp> iacc;
  input Boolean ichange;
  output DAE.Exp exp;
algorithm
  exp := match (iexpl,iacc,ichange)
    local
      String s1,s2,s;
      DAE.Exp exp1,exp2;
      list<DAE.Exp> rest,acc;
      Boolean change;

    case ({},{},_) then DAE.SCONST("");
    case ({},{exp},_) then exp;
    case ({},{exp1,exp2},_)
      then DAE.BINARY(exp2,DAE.ADD(DAE.T_STRING_DEFAULT),exp1);
    case ({},acc,true)
      equation
        acc = listReverse(acc);
        exp = DAE.LIST(acc);
      then Expression.makePureBuiltinCall("stringAppendList",{exp},DAE.T_STRING_DEFAULT);
    case (DAE.SCONST(s1)::rest,DAE.SCONST(s2)::acc,_)
      equation
        s = s2 + s1;
      then simplifyStringAppendList(rest,DAE.SCONST(s)::acc,true);
    case (exp::rest,acc,change) then simplifyStringAppendList(rest,exp::acc,change);
  end match;
end simplifyStringAppendList;

protected function simplifyBuiltinConstantCalls "simplifies some builtin calls if constant arguments"
  input String name;
  input DAE.Exp exp "assumes already simplified call arguments";
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (name,exp)
    local
      Real r,v1,v2;
      Integer i, j;
      DAE.Exp e,e1,e2;

    // der(constant) ==> 0
    case ("der",DAE.CALL(expLst ={e}))
      equation
        e1 = simplifyBuiltinConstantDer(e);
      then e1;

    // pre(constant) ==> constant
    case ("pre",DAE.CALL(expLst ={e}))
      then e;

    // previous(constant) ==> constant
    case ("previous",DAE.CALL(expLst ={e}))
      then e;

    // edge(constant) ==> false
    case ("edge",DAE.CALL(expLst ={_}))
      then DAE.BCONST(false);

    // change(constant) ==> false
    case ("change",DAE.CALL(expLst ={_}))
      then DAE.BCONST(false);

    // sqrt function
    case("sqrt",DAE.CALL(expLst={e}))
      equation
        r = sqrt(Expression.toReal(e));
      then
        DAE.RCONST(r);

    // abs on real
    case("abs",DAE.CALL(expLst={DAE.RCONST(r)}))
      equation
        r = abs(r);
      then
        DAE.RCONST(r);

    // abs on integer
    case("abs",DAE.CALL(expLst={DAE.ICONST(i)}))
      equation
        i = abs(i);
      then
        DAE.ICONST(i);

    // sin function
    case("sin",DAE.CALL(expLst={e}))
      equation
        r = sin(Expression.toReal(e));
      then DAE.RCONST(r);

    // cos function
    case("cos",DAE.CALL(expLst={e}))
      equation
        r = cos(Expression.toReal(e));
      then DAE.RCONST(r);

    // sin function
    case("asin",DAE.CALL(expLst={e}))
      equation
        r = Expression.toReal(e);
        true = r >= -1.0 and r <= 1.0;
        r = asin(r);
      then DAE.RCONST(r);

    // cos function
    case("acos",DAE.CALL(expLst={e}))
      equation
        r = Expression.toReal(e);
        true = r >= -1.0 and r <= 1.0;
        r = acos(Expression.toReal(e));
      then DAE.RCONST(r);

    // tangent function
    case("tan",DAE.CALL(expLst={e}))
      equation
        r = tan(Expression.toReal(e));
      then DAE.RCONST(r);

    // DAE.Exp function
    case("exp",DAE.CALL(expLst={e}))
      equation
        r = .exp(Expression.toReal(e));
      then DAE.RCONST(r);

    // log function
    case("log",DAE.CALL(expLst={e}))
      equation
        r = Expression.toReal(e);
        true = r > 0;
        r = log(r);
      then
        DAE.RCONST(r);

    // log10 function
    case("log10",DAE.CALL(expLst={e}))
      equation
        r = Expression.toReal(e);
        true = r > 0;
        r = log10(r);
      then
        DAE.RCONST(r);

    // min function on integers
    case("min",DAE.CALL(expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        i = min(i, j);
      then DAE.ICONST(i);

    // min function on reals
    case("min",DAE.CALL(expLst={e, e1},attr=DAE.CALL_ATTR(ty=DAE.T_REAL())))
      equation
        v1 = Expression.toReal(e);
        v2 = Expression.toReal(e1);
        r = min(v1, v2);
      then DAE.RCONST(r);

    // min function on enumerations
    case("min",DAE.CALL(expLst={e as DAE.ENUM_LITERAL(index=i), e1 as DAE.ENUM_LITERAL(index=j)}))
      equation
        e2 = if i<j then e else e1;
      then e2;

    // max function on integers
    case("max",DAE.CALL(expLst={DAE.ICONST(i), DAE.ICONST(j)}))
      equation
        i = max(i, j);
      then DAE.ICONST(i);

    // max function on reals
    case("max",DAE.CALL(expLst={e, e1},attr=DAE.CALL_ATTR(ty=DAE.T_REAL())))
      equation
        v1 = Expression.toReal(e);
        v2 = Expression.toReal(e1);
        r = max(v1, v2);
      then DAE.RCONST(r);

    // max function on enumerations
    case("max",DAE.CALL(expLst={e as DAE.ENUM_LITERAL(index=i), e1 as DAE.ENUM_LITERAL(index=j)}))
      equation
        e2 = if i>j then e else e1;
      then e2;

    case("sign",DAE.CALL(expLst={DAE.RCONST(r)}))
      equation
        i = if realEq(r,0.0) then 0 else (if realGt(r,0.0) then 1 else -1);
      then DAE.ICONST(i);

  end matchcontinue;
end simplifyBuiltinConstantCalls;

protected function simplifyCref
" Function for simplifying
  x[{y,z,q}] to {x[y], x[z], x[q]}"
  input DAE.Exp origExp;
  input ComponentRef inCREF;
  input Type inType;
  output DAE.Exp exp;
algorithm
  exp := matchcontinue (origExp, inCREF, inType)
    local
      Type t,t2,t3;
      list<Subscript> ssl;
      ComponentRef cr;
      Ident idn,idn2;
      list<DAE.Exp> expl_1;
      DAE.Exp expCref;
      Integer index;

    case(_,DAE.CREF_IDENT(idn,t2,(ssl as ((DAE.SLICE(DAE.ARRAY(_,_,_))) :: _))),t)
      equation
        cr = ComponentReference.makeCrefIdent(idn,t2,{});
        expCref = Expression.makeCrefExp(cr,t);
        exp = simplifyCref2(expCref,ssl);
      then exp;

/*
    case (_, DAE.CREF_QUAL(idn,t2 as DAE.T_METATYPE(DAE.T_METAARRAY()),ssl,DAE.CREF_IDENT(idn2,t3)),t)
      equation
        exp = DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(idn,t2,{}),t2), list(Expression.subscriptIndexExp(s) for s in ssl));
        print(ExpressionDump.printExpStr(exp) + "\n");
        index = match tt as Types.metaArrayElementType(t2)
          // case DAE.T_METARECORD() then t2.fields;
          case DAE.T_METAUNIONTYPE() then List.position(idn2, tt.singletonFields);
        end match;
        exp = DAE.RSUB(exp, index, idn2, t);
        print(ExpressionDump.printExpStr(origExp) + "\n");
        print(ExpressionDump.printExpStr(exp) + "\n");
        print("CREF_QUAL: " + idn + "\n");
        print("CREF_QUAL: " + Types.unparseType(t2) + "\n");
        print("CREF_QUAL: " + Types.unparseType(t) + "\n");
        print("CREF_QUAL: " + Types.unparseType(t3) + "\n");
      then exp;
*/
    case (_, DAE.CREF_QUAL(idn, DAE.T_METATYPE(ty=t2), ssl, cr), t)
      equation
        exp = simplifyCrefMM1(idn, t2, ssl);
        exp = simplifyCrefMM(exp, Expression.typeof(exp), cr);
      then exp;

    else origExp;
  end matchcontinue;
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

    case(DAE.CREF(cr as DAE.CREF_IDENT(_, _,_),t), (((DAE.SLICE(DAE.ARRAY(_,_,(expl_1))))) :: ssl))
      equation
        subs = List.map(expl_1,Expression.makeIndexSubscript);
        crefs = List.map1r(List.map(subs,List.create),ComponentReference.subscriptCref,cr);
        t = Types.unliftArray(t);
        expl = List.map1(crefs,Expression.makeCrefExp,t);
        dim = listLength(expl);
        exp = simplifyCref2(DAE.ARRAY(DAE.T_ARRAY(t,{DAE.DIM_INTEGER(dim)},DAE.emptyTypeSource),true,expl),ssl);
      then
        exp;

    case(DAE.ARRAY(tp,sc,expl), ssl )
      equation
        expl = List.map1(expl,simplifyCref2,ssl);
      then
        DAE.ARRAY(tp,sc,expl);

  end matchcontinue;
end simplifyCref2;

protected function simplifyCrefMM_index
  input DAE.Exp inExp;
  input String ident;
  input DAE.Type ty;
  output DAE.Exp exp;
protected
  Integer index;
  DAE.Type nty,ty2;
  list<DAE.Var> fields;
algorithm
  fields := Types.getMetaRecordFields(ty);
  index := Types.findVarIndex(ident, fields)+1;
  DAE.TYPES_VAR(ty=nty) := listGet(fields, index);
  exp := DAE.RSUB(inExp, index, ident, nty);
end simplifyCrefMM_index;

protected function simplifyCrefMM
  input DAE.Exp inExp;
  input DAE.Type inType;
  input ComponentRef inCref;
  output DAE.Exp exp;
algorithm
  exp := match inCref
    case DAE.CREF_IDENT()
      algorithm
        exp := simplifyCrefMM_index(inExp, inCref.ident, inType);
        exp := if listEmpty(inCref.subscriptLst) then exp else DAE.ASUB(exp, list(Expression.subscriptIndexExp(s) for s in inCref.subscriptLst));
      then exp;
    case DAE.CREF_QUAL()
      algorithm
        exp := simplifyCrefMM_index(inExp, inCref.ident, inType);
        exp := if listEmpty(inCref.subscriptLst) then exp else DAE.ASUB(exp, list(Expression.subscriptIndexExp(s) for s in inCref.subscriptLst));
        exp := simplifyCrefMM(exp, Expression.typeof(exp), inCref.componentRef);
      then exp;
  end match;
end simplifyCrefMM;

protected function simplifyCrefMM1
  input String ident;
  input DAE.Type ty;
  input list<Subscript> ssl;
  output DAE.Exp outExp;
algorithm
  outExp := match (ssl)
    case {} then DAE.CREF(DAE.CREF_IDENT(ident,ty,{}),ty);
    else DAE.ASUB(DAE.CREF(DAE.CREF_IDENT(ident,ty,{}),ty), list(Expression.subscriptIndexExp(s) for s in ssl));
  end match;
end simplifyCrefMM1;

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

    else inExp;

  end matchcontinue;
end simplify2;

protected function simplifyBinaryArray "Simplifies binary array expressions,
  e.g. matrix multiplication, etc."
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp1,inOperator2,inExp3)
    local
      DAE.Exp e_1,e1,e2,res,s1,a1;
      Type tp;
      Operator op;

    case (e1,DAE.MUL_MATRIX_PRODUCT(),e2)
      equation
        e_1 = simplifyMatrixProduct(e1, e2);
      then
        e_1;

    case(e1,op as DAE.ADD_ARR(),e2)
      equation
        a1 = simplifyVectorBinary0(e1,op,e2);
      then
        a1;

    case (e1,op as DAE.SUB_ARR(),e2)
      equation
        a1 = simplifyVectorBinary0(e1, op, e2);
      then
        a1;

    case (e1,op as DAE.MUL_ARR(),e2)
      equation
        _ = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, op, e2);
      then a1;

    case (e1,op as DAE.DIV_ARR(),e2)
      equation
        _ = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, op, e2);
      then a1;

    case (e1,DAE.POW_ARR(),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyMatrixPow(e1, tp, e2);
      then a1;

    case (e1,DAE.POW_ARR2(),e2)
      equation
        tp = Expression.typeof(e1);
        a1 = simplifyVectorBinary(e1, DAE.POW_ARR2(tp), e2);
      then a1;

    // v1 - -v2 => v1 + v2
    case (e1,DAE.SUB_ARR(ty=tp),DAE.UNARY(_,e2))
      then
        DAE.BINARY(e1,DAE.ADD_ARR(tp),e2);

    // v1 + -v2 => v1 - v2
    case (e1,DAE.ADD_ARR(ty=tp),DAE.UNARY(_,e2))
      then
        DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);

   case (a1, op, s1)
      equation
        true = Expression.isArrayScalarOp(op);
        op = unliftOperator(a1, op);
      then
        simplifyVectorScalar(a1, op, s1);

    case (s1, op, a1)
      equation
        true = Expression.isScalarArrayOp(op);
        op = unliftOperator(a1, op);
      then
        simplifyVectorScalar(s1, op, a1);

    case (e1,DAE.MUL_SCALAR_PRODUCT(),e2)
      equation
        res = simplifyScalarProduct(e1, e2);
      then
        res;

    case (e1,op as DAE.ADD_ARR(),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
      then a1;

    case (e1,op as DAE.SUB_ARR(),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
        // print("simplifyMatrixBinary: " + ExpressionDump.printExpStr(e1) + "=>" + ExpressionDump.printExpStr(a1) + "\n");
      then a1;

    case (e1,op as DAE.MUL_ARR(),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
      then a1;

    case (e1,op as DAE.DIV_ARR(),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
      then a1;

    case (e1,op as DAE.POW_ARR2(),e2)
      equation
        a1 = simplifyMatrixBinary(e1, op, e2);
      then a1;

    case (_,DAE.MUL_ARRAY_SCALAR(ty = tp),e2)
      equation
        true = Expression.isZero(e2);
        (a1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then a1;

    case (e1,DAE.DIV_ARR(),_)
      equation
        true = Expression.isZero(e1);
        tp = Expression.typeof(e1);
        (a1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then a1;

    case (e1,DAE.DIV_ARRAY_SCALAR(),_)
      equation
        true = Expression.isZero(e1);
        tp = Expression.typeof(e1);
        (a1, _) = Expression.makeZeroExpression(Expression.arrayDimension(tp));
      then a1;

  end matchcontinue;
end simplifyBinaryArray;

public function simplifyScalarProduct
  "Simplifies the scalar product of two vectors."
  input DAE.Exp inVector1;
  input DAE.Exp inVector2;
  output DAE.Exp outProduct;
algorithm
  outProduct := match(inVector1, inVector2)
    local
      list<DAE.Exp> expl, expl1, expl2;
      DAE.Exp exp;
      Type   tp;

    // Both arrays are empty. The result is defined in the spec by sum, so we
    // return the default value which is 0.
    case (DAE.ARRAY(ty = tp, array = {}), DAE.ARRAY(array = {}))
      then Expression.makeConstZero(tp);

    // Normal scalar product of two vectors.
    case (DAE.ARRAY(array = expl1), DAE.ARRAY(array = expl2))
      equation
        true = Expression.isVector(inVector1) and Expression.isVector(inVector2);
        expl = List.threadMap(expl1, expl2, Expression.expMul);
        exp = List.reduce(expl, Expression.expAdd);
      then
        exp;

  end match;
end simplifyScalarProduct;

protected function unliftOperator
  input DAE.Exp inArray;
  input Operator inOperator;
  output Operator outOperator;
algorithm
  outOperator := match(inArray, inOperator)
    case (DAE.MATRIX(), _) then Expression.unliftOperatorX(inOperator, 2);
    else Expression.unliftOperator(inOperator);
  end match;
end unliftOperator;

protected function simplifyVectorScalar
"Simplifies vector scalar operations."
  input DAE.Exp inLhs;
  input Operator inOperator;
  input DAE.Exp inRhs;
  output DAE.Exp outExp;
algorithm
  outExp := match(inLhs, inOperator, inRhs)
    local
      DAE.Exp s1;
      Operator op;
      Type tp;
      Boolean sc;
      list<DAE.Exp> es;
      list<list<DAE.Exp>> mexpl;
      Integer dims;

    // scalar operator array
    case (_, _, DAE.ARRAY(ty = tp, scalar = sc, array = es))
      equation
        es = List.map2r(es, Expression.makeBinaryExp, inLhs, inOperator);
      then
        DAE.ARRAY(tp, sc, es);

    case (s1,op,DAE.MATRIX(tp,dims,mexpl))
      equation
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,false /*scalar-array*/);
      then
        DAE.MATRIX(tp,dims,mexpl);

    // array operator scalar
    case (DAE.ARRAY(ty = tp, scalar = sc, array = es), _, _)
      equation
        es = List.map2(es, Expression.makeBinaryExp, inOperator, inRhs);
      then
        DAE.ARRAY(tp, sc, es);

    case (DAE.MATRIX(tp,dims,mexpl),op,s1)
      equation
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,true/*array-scalar*/);
      then
        DAE.MATRIX(tp,dims,mexpl);

  end match;
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

    case(_,_,_)
      equation
        a1 = simplifyVectorBinary(e1,op,e2);
      then a1;

    case(_,DAE.ADD(),_)
      equation
        true = Expression.isZero(e1);
      then
        e2;

    case(_,DAE.ADD_ARR(),_)
      equation
        true = Expression.isZero(e1);
      then
        e2;

    case(_,DAE.SUB_ARR(),_)
      equation
        true = Expression.isZero(e1);
      then
        Expression.negate(e2);

    case(_,DAE.SUB(),_)
      equation
        true = Expression.isZero(e1);
      then
        Expression.negate(e2);

    else
      equation
        true = Expression.isZero(e2);
      then
        e1;

  end matchcontinue;
end simplifyVectorBinary0;

protected function simplifyVectorBinary
  input DAE.Exp inLhs;
  input Operator inOperator;
  input DAE.Exp inRhs;
  output DAE.Exp outResult;
protected
  DAE.Type ty;
  Boolean sc;
  list<DAE.Exp> lhs, rhs, res;
  Operator op;
algorithm
  DAE.ARRAY(ty = ty, scalar = sc, array = lhs) := inLhs;
  DAE.ARRAY(array = rhs) := inRhs;
  op := removeOperatorDimension(inOperator);
  res := List.threadMap1(lhs, rhs, simplifyVectorBinary2, op);
  outResult := DAE.ARRAY(ty, sc, res);
end simplifyVectorBinary;

protected function simplifyVectorBinary2
  input DAE.Exp inLhs;
  input DAE.Exp inRhs;
  input Operator inOperator;
  output DAE.Exp outExp;
algorithm
  outExp := DAE.BINARY(inLhs, inOperator, inRhs);
end simplifyVectorBinary2;

protected function simplifyMatrixBinary
  "Simplifies matrix addition and subtraction"
  input DAE.Exp inLhs;
  input Operator inOperator;
  input DAE.Exp inRhs;
  output DAE.Exp outResult;
protected
  list<list<DAE.Exp>> lhs, rhs, res;
  Operator op;
  Integer sz;
  DAE.Type ty;
algorithm
  lhs := Expression.get2dArrayOrMatrixContent(inLhs);
  rhs := Expression.get2dArrayOrMatrixContent(inRhs);
  op := removeOperatorDimension(inOperator);
  res := List.threadMap1(lhs, rhs, simplifyMatrixBinary1, op);
  sz := listLength(res);
  ty := Expression.typeof(inLhs);
  outResult := DAE.MATRIX(ty, sz, res);
end simplifyMatrixBinary;

protected function simplifyMatrixBinary1
  "Simplifies matrix addition and subtraction."
  input list<DAE.Exp> inLhs;
  input list<DAE.Exp> inRhs;
  input Operator inOperator;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := List.threadMap1(inLhs, inRhs, simplifyMatrixBinary2, inOperator);
end simplifyMatrixBinary1;

protected function simplifyMatrixBinary2
  input DAE.Exp inLhs;
  input DAE.Exp inRhs;
  input Operator inOperator;
  output DAE.Exp outExp;
protected
  Operator op;
algorithm
  op := removeOperatorDimension(inOperator);
  outExp := DAE.BINARY(inLhs, op, inRhs);
end simplifyMatrixBinary2;

protected function simplifyMatrixPow
"author: Frenkel TUD
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
    case (DAE.MATRIX(ty = tp1,integer = size1),_,
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
    case (m as DAE.MATRIX(),_,
          DAE.ICONST(integer = i))
      equation
        1=i;
      then
        m;

    // A^2 = A * A
    case (m as DAE.MATRIX(),_, DAE.ICONST(integer = i))
       equation
        2 = i;
        res = simplifyMatrixProduct(m,m);
       then
        res;

    // A^n = A^m*A^m where n = 2*m
    case(m as DAE.MATRIX(ty = tp1),_,DAE.ICONST(integer = i))
       equation
        true = i > 3;
        0 = intMod(i,2);
        i_1 = intDiv(i,2);
        e = simplifyMatrixPow(m,tp1,DAE.ICONST(i_1));
        res = simplifyMatrixProduct(e,e);
       then
        res;

    /* A^i */
    case (m as DAE.MATRIX(ty = tp1),_,
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
"author: Frenkel TUD
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
    case ({},{},_)
      then
        {};
    case (i::{},row::{},e)
      equation
        row1 = List.replaceAt(e,i+1,row);
      then
        {row1};
    case (i::rr,row::rm,e)
      equation
        row1 = List.replaceAt(e,i+1,row);
        rm1 = simplifyMatrixPow1(rr,rm,e);
      then
        row1::rm1;
  end matchcontinue;
end simplifyMatrixPow1;

protected function simplifyMatrixProduct
  "Simplifies matrix multiplication."
  input DAE.Exp inMatrix1;
  input DAE.Exp inMatrix2;
  output DAE.Exp outProduct;
protected
  DAE.Exp mat1, mat2;
algorithm
  // Convert any DAE.MATRIX expressions to DAE.ARRAY.
  mat1 := Expression.matrixToArray(inMatrix1);
  mat2 := Expression.matrixToArray(inMatrix2);
  // Transpose the second matrix. This makes it easier to do the multiplication,
  // since we can do row-row multiplications instead of row-column.
  (mat2, _) := Expression.transposeArray(mat2);
  outProduct := simplifyMatrixProduct2(mat1, mat2);
end simplifyMatrixProduct;

protected function simplifyMatrixProduct2
  "Helper function to simplifyMatrixProduct, does the actual work. Assumes that
   the second matrix has been transposed to make the multiplication easier."
  input DAE.Exp inMatrix1;
  input DAE.Exp inMatrix2;
  output DAE.Exp outProduct;
algorithm
  outProduct := matchcontinue(inMatrix1, inMatrix2)
    local
      DAE.Dimension n, m, p;
      list<DAE.Exp> expl1, expl2;
      DAE.Type ty, row_ty;
      DAE.TypeSource tp;
      list<list<DAE.Exp>> matrix;
      DAE.Exp zero;
      list<DAE.Dimension> dims;

    // The common dimension of the matrices is zero, the result will be an array
    // of zeroes (the default value of sum).
    case (DAE.ARRAY(ty = ty as DAE.T_ARRAY(dims = dims)), DAE.ARRAY())
      equation
        // It's sufficient to check the first array, because the only case where
        // the second array alone determines the result dimensions is the
        // vector-matrix case. The instantiation should just remove the
        // equations in that case, since the result will be an empty array.
        true = Expression.arrayContainZeroDimension(dims);
        zero = Expression.makeConstZero(ty);
        dims = simplifyMatrixProduct4(inMatrix1, inMatrix2);
      then
        Expression.arrayFill(dims, zero);

    // Matrix-vector multiplication, c[n] = a[n, m] * b[m].
    case (DAE.ARRAY(ty = DAE.T_ARRAY(ty, {n, _}, tp), array = expl1),
          DAE.ARRAY(ty = DAE.T_ARRAY(dims = {_})))
      equation
        // c[i] = a[i, :] * b for i in 1:n
        expl1 = List.map1(expl1, simplifyScalarProduct, inMatrix2);
        ty = DAE.T_ARRAY(ty, {n}, tp);
      then
        DAE.ARRAY(ty, true, expl1);

    // Vector-matrix multiplication, c[m] = a[n] * b[n, m].
    case (DAE.ARRAY(ty = DAE.T_ARRAY(dims = {_})),
          DAE.ARRAY(ty = DAE.T_ARRAY(ty, {m, _}, tp), array = expl2))
      equation
        // c[i] = a * b[:, i] for i in 1:m
        expl1 = List.map1r(expl2, simplifyScalarProduct, inMatrix1);
        ty = DAE.T_ARRAY(ty, {m}, tp);
      then
        DAE.ARRAY(ty, true, expl1);

    // Matrix-matrix multiplication, c[n, p] = a[n, m] * b[m, p].
    case (DAE.ARRAY(ty = DAE.T_ARRAY(ty, {n, _}, tp), array = expl1),
          DAE.ARRAY(ty = DAE.T_ARRAY(dims = {p, _}), array = expl2))
      equation
        // c[i, j] = a[i, :] * b[:, j] for i in 1:n, j in 1:p
        matrix = List.map1(expl1, simplifyMatrixProduct3, expl2);
        row_ty = DAE.T_ARRAY(ty, {p}, tp);
        expl1 = List.map2(matrix, Expression.makeArray, row_ty, true);
      then
        DAE.ARRAY(DAE.T_ARRAY(ty, {n, p}, tp), false, expl1);

  end matchcontinue;
end simplifyMatrixProduct2;

protected function simplifyMatrixProduct3
  "Helper function to simplifyMatrixProduct2. Multiplies the given matrix row
   with each row in the given matrix and returns a list with the results."
  input DAE.Exp inRow;
  input list<DAE.Exp> inMatrix;
  output list<DAE.Exp> outRow;
algorithm
  outRow := List.map1r(inMatrix, simplifyScalarProduct, inRow);
end simplifyMatrixProduct3;

protected function simplifyMatrixProduct4
  "Helper function to simplifyMatrixProduct2. Returns the dimensions of the
   matrix multiplication product for two matrices."
  input DAE.Exp inMatrix1;
  input DAE.Exp inMatrix2;
  output list<DAE.Dimension> outDimensions;
algorithm
  outDimensions := match(inMatrix1, inMatrix2)
    local
      DAE.Dimension n, m, p;

    // c[n] = a[n, m] * b[m]
    case (DAE.ARRAY(ty = DAE.T_ARRAY(dims = {n, _})),
          DAE.ARRAY(ty = DAE.T_ARRAY(dims = {_})))
      then {n};

    // c[m] = a[n] * b[n, m]
    case (DAE.ARRAY(ty = DAE.T_ARRAY(dims = {_})),
          DAE.ARRAY(ty = DAE.T_ARRAY(dims = {m, _})))
      then {m};

    // c[n, p] = a[n, m] * b[m, p]
    case (DAE.ARRAY(ty = DAE.T_ARRAY(dims = {n, _})),
          DAE.ARRAY(ty = DAE.T_ARRAY(dims = {p, _})))
      then {n, p};

  end match;
end simplifyMatrixProduct4;

protected function simplifyBinarySortConstants
"author: PA
  Sorts all constants of a sum or product to the
  beginning of the expression.
  Also combines expressions like 2a+4a and aaa+3a^3."
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      list<DAE.Exp> e_lst,const_es1,notconst_es1,const_es1_1;
      DAE.Exp res,e,e1,e2,res1,res2;
      Type tp;

    // e1 * e2
    case ((e as DAE.BINARY(operator = DAE.MUL())))
      equation
        res = simplifyBinarySortConstantsMul(e);
      then
        res;

    // e1 / e2
    case ((DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp),exp2 = e2)))
      equation
        e1 = simplifyBinarySortConstantsMul(e1);
        e2 = simplifyBinarySortConstantsMul(e2);
      then
        DAE.BINARY(e1,DAE.DIV(tp),e2);

    // e1 + e2
    case ((e as DAE.BINARY(operator = DAE.ADD())))
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
    else inExp;

  end matchcontinue;
end simplifyBinarySortConstants;

protected function simplifyBinaryCoeff
"author: PA
  Combines expressions like 2a+4a and aaa+3a^3, etc"
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inExp)
    local
      list<DAE.Exp> e_lst,e_lst_1,e1_lst,e2_lst,e2_lst_1;
      DAE.Exp res,e,e1,e2;
      Type tp;

    case ((e as DAE.BINARY(operator = DAE.MUL())))
      equation
        e_lst = Expression.factors(e);
        e_lst_1 = simplifyMul(e_lst);
        res = Expression.makeProductLst(e_lst_1);
      then
        res;

    case ((DAE.BINARY(exp1 = e1,operator = DAE.DIV(),exp2 = e2)))
      equation
        false = Expression.isZero(e2);
        e1_lst = Expression.factors(e1);
        e2_lst = Expression.factors(e2);
        e2_lst_1 = List.map(e2_lst, Expression.inverseFactors);
        e_lst = listAppend(e1_lst, e2_lst_1);
        e_lst_1 = simplifyMul(e_lst);
        res = Expression.makeProductLst(e_lst_1);
      then
        res;

    case ((e as DAE.BINARY(operator = DAE.ADD())))
      equation
        e_lst = Expression.terms(e);
        e_lst_1 = simplifyAdd(e_lst);
        res = Expression.makeSum(e_lst_1);
      then
        res;

    case ((DAE.BINARY(exp1 = e1,operator = DAE.SUB(),exp2 = e2)))
      equation
        e1_lst = Expression.terms(e1);
        e2_lst = Expression.terms(e2);
        e2_lst = List.map(e2_lst, Expression.negate);
        e_lst = listAppend(e1_lst, e2_lst);
        e_lst_1 = simplifyAdd(e_lst);
        res = Expression.makeSum(e_lst_1);
      then
        res;

    else inExp;

  end matchcontinue;
end simplifyBinaryCoeff;

protected function simplifyBinaryAddConstants
"author: PA
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
        e_1 = simplifyBinaryConst(DAE.ADD(DAE.T_REAL_DEFAULT), e1, e);
      then
        {e_1};

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- ExpressionSimplify.simplifyBinaryAddConstants failed\n");
      then
        fail();
  end matchcontinue;
end simplifyBinaryAddConstants;

protected function simplifyBinaryMulConstants
"author: PA
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
"author: PA
  Simplifies expressions like a*a*a*b*a*b*a"
  input list<DAE.Exp> expl;
  output list<DAE.Exp> expl_1;
protected
  list<tuple<DAE.Exp, Real>> exp_const,exp_const_1;
algorithm
  exp_const := List.map(expl, simplifyBinaryMulCoeff2);
  exp_const_1 := simplifyMulJoinFactors(exp_const);
  expl_1 := simplifyMulMakePow(exp_const_1);
end simplifyMul;

protected function simplifyMulJoinFactors
" author: PA
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
        coeff_1 = coeff + coeff2;
      then
        ((e,coeff_1) :: res);
  end match;
end simplifyMulJoinFactors;

protected function simplifyMulJoinFactorsFind
"author: PA
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
      DAE.Operator op;

    case (_,{}) then (0.0,{});

    case (e,((e2,coeff) :: rest)) /* e1 == e2 */
      equation
        true = Expression.expEqual(e, e2);
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff + coeff2;
      then
        (coeff3,res);

    case (e,((DAE.BINARY(exp1 = e1,operator = op as DAE.DIV(),exp2 = e2),coeff) :: rest)) // pow(a/b,n) * pow(b/a,m) = pow(a/b,n-m)
      equation
        true = if Expression.isOne(e1) then Expression.expEqual(e, e2) else Expression.expEqual(e, DAE.BINARY(e2, op, e1));
        (coeff2,res) = simplifyMulJoinFactorsFind(e, rest);
        coeff3 = coeff2 - coeff;
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
"author: PA
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
        (r == 1.0) = true;
        res = simplifyMulMakePow(xs);
      then
        (e :: res);

    case (((e,r) :: xs))
      equation
        res = simplifyMulMakePow(xs);
      then
        (DAE.BINARY(e,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(r)) :: res);
  end matchcontinue;
end simplifyMulMakePow;

protected function simplifyAdd
"author: PA
  Simplifies terms like 2a+4b+2a+a+b"
  input list<DAE.Exp> inExpLst;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst := matchcontinue (inExpLst)
    local
      list<tuple<DAE.Exp, Real>> exp_const,exp_const_1;
      list<DAE.Exp> expl_1,expl;

    case (_)
      equation
        exp_const = List.map(inExpLst, simplifyBinaryAddCoeff2);
        exp_const_1 = simplifyAddJoinTerms(exp_const);
        expl_1 = simplifyAddMakeMul(exp_const_1);
      then
        expl_1;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- ExpressionSimplify.simplifyAdd failed\n");
      then
        fail();
  end matchcontinue;
end simplifyAdd;

protected function simplifyAddJoinTerms
"author: PA
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
        coeff3 = coeff + coeff2;
      then
        ((e,coeff3) :: res);
  end match;
end simplifyAddJoinTerms;

protected function simplifyAddJoinTermsFind
"author: PA
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
        coeff3 = coeff + coeff2;
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
"author: PA
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
        (r == 1.0) = true;
        res = simplifyAddMakeMul(xs);
      then
        (e :: res);

    case (((e,r) :: xs))
      equation
        DAE.T_INTEGER() = Expression.typeof(e);
        res = simplifyAddMakeMul(xs);
        tmpInt = realInt(r);
      then
        (DAE.BINARY(DAE.ICONST(tmpInt),DAE.MUL(DAE.T_INTEGER_DEFAULT),e) :: res);

    case (((e,r) :: xs))
      equation
        res = simplifyAddMakeMul(xs);
      then
        (DAE.BINARY(DAE.RCONST(r),DAE.MUL(DAE.T_REAL_DEFAULT),e) :: res);
  end matchcontinue;
end simplifyAddMakeMul;

protected function simplifyBinaryAddCoeff2
"This function checks for x+x+x+x and returns (x,4.0)"
  input DAE.Exp inExp;
  output tuple<DAE.Exp, Real> outRes;
algorithm
  outRes := matchcontinue (inExp)
    local
      DAE.Exp exp,e1,e2,e;
      Real coeff,coeff_1;
      Integer icoeff;
      Type tp;

    case ((exp as DAE.CREF())) then ((exp,1.0));

    case (DAE.UNARY(operator = DAE.UMINUS(ty = DAE.T_REAL()), exp = exp))
      equation
        ((exp,coeff)) = simplifyBinaryAddCoeff2(exp);
        coeff = realMul(-1.0,coeff);
      then ((exp,coeff));

    case (DAE.BINARY(exp1 = DAE.RCONST(real = coeff),operator = DAE.MUL(),exp2 = e1))
      then ((e1,coeff));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = DAE.RCONST(real = coeff)))
      then ((e1,coeff));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = DAE.ICONST(integer = icoeff)))
      equation
        coeff_1 = intReal(icoeff);
      then
        ((e1,coeff_1));

    case (DAE.BINARY(exp1 = DAE.ICONST(integer = icoeff),operator = DAE.MUL(),exp2 = e1))
      equation
        coeff_1 = intReal(icoeff);
      then
        ((e1,coeff_1));

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD(),exp2 = e2))
      equation
        true = Expression.expEqual(e1, e2);
      then
        ((e1,2.0));

    else ((inExp,1.0));

  end matchcontinue;
end simplifyBinaryAddCoeff2;

protected function simplifyBinaryMulCoeff2
"This function takes an expression XXXXX
  and return (X,5.0) to be used for X^5."
  input DAE.Exp inExp;
  output tuple<DAE.Exp, Real> outRes;
algorithm
  outRes := matchcontinue (inExp)
    local
      DAE.Exp e,e1,e2;
      ComponentRef cr;
      Real coeff,coeff_1,coeff_2;
      Type tp;
      Integer icoeff;

    case ((e as DAE.CREF()))
      then ((e,1.0));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(),exp2 = DAE.RCONST(real = coeff)))
      then ((e1,coeff));

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW(),exp2 = DAE.UNARY(operator = DAE.UMINUS(), exp = DAE.RCONST(real = coeff))))
      equation
        coeff_1 = 0.0 - coeff;
      then
        ((e1,coeff_1));

    case (DAE.BINARY(exp1 = e1, operator = DAE.POW(), exp2 = DAE.ICONST(integer = icoeff)))
      equation
        coeff_1 = intReal(icoeff);
      then
        ((e1,coeff_1));

    case (DAE.BINARY(exp1 = e1, operator = DAE.POW(), exp2 = DAE.UNARY(operator = DAE.UMINUS(), exp = DAE.ICONST(integer = icoeff))))
      equation
        coeff_1 = 0.0 - intReal(icoeff);
      then
        ((e1,coeff_1));

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2))
      equation
        true = Expression.expEqual(e1, e2);
      then
        ((e1,2.0));

    else ((inExp,1.0));

  end matchcontinue;
end simplifyBinaryMulCoeff2;

public function simplifySumOperatorExpression
"
  In: (a/b + c + d + e/b)
  In: operator in {MUL, DIV}
  In: b
  -> (a/b + c  + d)  operator b
  Out: a' + e' + (c + b) operator b

  where a' = simplified(a operator b) and e' = simplified(e operator b)

  author: Vitalij Ruge
"
  input DAE.Exp iSum;
  input DAE.Operator iop "MUL or DIV";
  input DAE.Exp iExp;
  output DAE.Exp oExp;
protected
  list<DAE.Exp> T = Expression.termsExpandUnary(iSum);
  Boolean b "simplifed?";
  DAE.Exp e, newE, sE;
  DAE.Type tp = Expression.typeofOp(iop);
algorithm
  oExp := Expression.makeConstZero(tp);
  sE := oExp;

  for elem in T loop
    e := DAE.BINARY(elem,iop,iExp);
    newE := simplifyBinaryCoeff(e);
    b := not Expression.expEqual(e, newE);
    if b then
      sE := Expression.expAdd(sE, newE);
    else
      oExp := Expression.expAdd(oExp, elem);
    end if;
  end for;

  e := DAE.BINARY(oExp, iop, iExp);
  oExp := Expression.expAdd(sE, e);

end simplifySumOperatorExpression;


protected function simplifyAsub0 "simplifies asub when expression already has been simplified with simplify1
Earlier these cases were directly in simplify1, but now they are here so simplify1 only is called once for
the subexpression"
  input DAE.Exp ie;
  input Integer sub;
  input DAE.Exp inSubExp;
  output DAE.Exp res;
algorithm
  res := match(ie, sub, inSubExp)
    local
      Type t,t1;
      Boolean b, bstart, bstop;
      list<DAE.Exp> exps;
      list<list<DAE.Exp>> mexps;
      list<DAE.Exp> mexpl;
      DAE.Exp e1,e2,cond,exp,e;
      Integer istart,istop,istep,ival;
      Real rstart,rstop,rstep,rval;
      DAE.ComponentRef c,c_1;
      Integer n;
      list<DAE.ReductionIterator> iters;

    // subscript of an array
    case(DAE.ARRAY(_,_,exps),_, _)
      equation
        exp = listGet(exps, sub);
      then
        exp;

    case (DAE.RANGE(DAE.T_BOOL(), DAE.BCONST(bstart), NONE(), DAE.BCONST(bstop)), _, _)
      equation
        b = listGet(simplifyRangeBool(bstart, bstop), sub);
      then
        DAE.BCONST(b);

    case (DAE.RANGE(DAE.T_INTEGER(),DAE.ICONST(istart),NONE(),DAE.ICONST(istop)),_, _)
      equation
        ival = listGet(simplifyRange(istart,1,istop),sub);
        exp = DAE.ICONST(ival);
      then exp;

    case (DAE.RANGE(DAE.T_INTEGER(),DAE.ICONST(istart),SOME(DAE.ICONST(istep)),DAE.ICONST(istop)),_, _)
      equation
        ival = listGet(simplifyRange(istart,istep,istop),sub);
        exp = DAE.ICONST(ival);
      then exp;

    case (DAE.RANGE(DAE.T_REAL(),DAE.RCONST(rstart),NONE(),DAE.RCONST(rstop)),_, _)
      equation
        rval = listGet(simplifyRangeReal(rstart,1.0,rstop),sub);
        exp = DAE.RCONST(rval);
      then exp;

    case (DAE.RANGE(DAE.T_REAL(),DAE.RCONST(rstart),SOME(DAE.RCONST(rstep)),DAE.RCONST(rstop)),_, _)
      equation
        rval = listGet(simplifyRangeReal(rstart,rstep,rstop),sub);
        exp = DAE.RCONST(rval);
      then exp;

    // subscript of a matrix
    case(DAE.MATRIX(t,_,mexps), _, _)
      equation
        t1 = Expression.unliftArray(t);
        (mexpl) = listGet(mexps, sub);
      then
        DAE.ARRAY(t1,true,mexpl);

    // subscript of an if-expression
    case(DAE.IFEXP(cond,e1,e2), _, _)
      equation
        e1 = Expression.makeASUB(e1,{inSubExp});
        e2 = Expression.makeASUB(e2,{inSubExp});
        e = DAE.IFEXP(cond,e1,e2);
      then
        e;

    // name subscript
    case(DAE.CREF(c,t), _, _)
      equation
        true = Types.isArray(t);
        t = Expression.unliftArray(t);
        c_1 = simplifyAsubCref(c, inSubExp);
        exp = Expression.makeCrefExp(c_1, t);
      then
        exp;

  end match;
end simplifyAsub0;

protected function simplifyAsubCref
  input DAE.ComponentRef cr;
  input DAE.Exp sub;
  output DAE.ComponentRef res;
algorithm
  res := matchcontinue (cr,sub)
    local
      Type t2;
      DAE.ComponentRef c,c_1;
      list<Subscript> s,s_1;
      String idn;
      DAE.Dimensions dims;

    // simple name subscript
    case (DAE.CREF_IDENT(idn,t2,s),_)
      equation
        /* TODO: Make sure that the IDENT has enough dimensions? */
        s_1 = Expression.subscriptsAppend(s, sub);
        c_1 = ComponentReference.makeCrefIdent(idn,t2,s_1);
      then
        c_1;

    //  qualified name subscript
    case (DAE.CREF_QUAL(idn,t2 as DAE.T_ARRAY(dims=dims),s,c),_)
      equation
        true = listLength(dims) > listLength(s);
        s_1 = Expression.subscriptsAppend(s, sub);
        c_1 = ComponentReference.makeCrefQual(idn,t2,s_1,c);
      then
        c_1;

    case (DAE.CREF_QUAL(idn, t2, s, c), _)
      equation
        s = Expression.subscriptsReplaceSlice(s, DAE.INDEX(sub));
      then
        ComponentReference.makeCrefQual(idn, t2, s, c);

    case (DAE.CREF_QUAL(idn,t2,s,c),_)
      equation
        c_1 = simplifyAsubCref(c,sub);
        c_1 = ComponentReference.makeCrefQual(idn,t2,s,c_1);
      then
        c_1;

  end matchcontinue;
end simplifyAsubCref;

protected function simplifyAsub
"This function simplifies array subscripts on vector operations"
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
      list<DAE.Exp> exps,expl;
      list<list<DAE.Exp>> lstexps;
      list<DAE.ReductionIterator> iters;
      DAE.ReductionIterator iter;

    case (e,sub)
      equation
        exp = simplifyAsub0(e,Expression.expInt(sub), inSub);
      then
        exp;

    case (DAE.UNARY(operator = DAE.UMINUS_ARR(),exp = e),sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = Expression.typeof(e_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.UMINUS_ARR(t2) else DAE.UMINUS(t2);
        exp = DAE.UNARY(op2,e_1);
      then
        exp;

    case (DAE.LUNARY(operator = DAE.NOT(), exp = e), sub)
      equation
        e_1 = simplifyAsub(e, sub);
        t2 = Expression.typeof(e_1);
        exp = DAE.LUNARY(DAE.NOT(t2), e_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.SUB_ARR(t2) else DAE.SUB(t2);
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARRAY_SCALAR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.MUL_ARRAY_SCALAR(t2) else DAE.MUL(t2);
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARRAY_SCALAR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.ADD_ARRAY_SCALAR(t2) else DAE.ADD(t2);
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.SUB_SCALAR_ARRAY(),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.SUB_SCALAR_ARRAY(t2) else DAE.SUB(t2);
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;

    // For Matrix product M1 * M2
    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_MATRIX_PRODUCT(),exp2 = e2),sub)
      equation
        e = simplifyMatrixProduct(e1,e2);
        e = simplifyAsub(e, sub);
      then
        e;

    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_SCALAR_ARRAY(),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.DIV_SCALAR_ARRAY(t2) else DAE.DIV(t2);
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARRAY_SCALAR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.DIV_ARRAY_SCALAR(t2) else DAE.DIV(t2);
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_SCALAR_ARRAY(),exp2 = e2),sub)
      equation
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e2_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.POW_SCALAR_ARRAY(t2) else DAE.POW(t2);
        exp = DAE.BINARY(e1,op,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARRAY_SCALAR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op = if b then DAE.POW_ARRAY_SCALAR(t2) else DAE.POW(t2);
        exp = DAE.BINARY(e1_1,op,e2);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.ADD_ARR(t2) else DAE.ADD(t2);
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.MUL_ARR(t2) else DAE.MUL(t2);
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.DIV_ARR(t2) else DAE.DIV(t2);
        exp = DAE.BINARY(e1_1,op2,e2_1);
      then
        exp;

    case (DAE.BINARY(exp1 = e1,operator = DAE.POW_ARR2(),exp2 = e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
        t2 = Expression.typeof(e1_1);
        b = DAEUtil.expTypeArray(t2);
        op2 = if b then DAE.POW_ARR2(t2) else DAE.POW(t2);
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

    case (DAE.ARRAY(array = exps),sub)
      equation
        indx = Expression.expInt(sub);
        exp = listGet(exps, indx);
      then
        exp;

    case (DAE.MATRIX(ty = t,matrix = lstexps),sub)
      equation
        indx = Expression.expInt(sub);
        (expl) = listGet(lstexps, indx);
        t_1 = Expression.unliftArray(t);
      then DAE.ARRAY(t_1,true,expl);

    case(DAE.IFEXP(cond,e1,e2),sub)
      equation
        e1_1 = simplifyAsub(e1, sub);
        e2_1 = simplifyAsub(e2, sub);
      then DAE.IFEXP(cond,e1_1,e2_1);

    case(DAE.REDUCTION(DAE.REDUCTIONINFO(path=Absyn.IDENT("array"),iterType=Absyn.THREAD()),exp,iters), sub)
      equation
        exp = List.fold1(iters,simplifyAsubArrayReduction,sub,exp);
      then exp;

    case(DAE.REDUCTION(DAE.REDUCTIONINFO(path=Absyn.IDENT("array"),iterType=Absyn.COMBINE()),exp,{iter}), sub)
      equation
        exp = simplifyAsubArrayReduction(iter,sub,exp);
      then exp;

  end matchcontinue;
end simplifyAsub;

protected function simplifyAsubArrayReduction
  input DAE.ReductionIterator iter;
  input DAE.Exp sub;
  input DAE.Exp acc;
  output DAE.Exp res;
algorithm
  res := match (iter,sub,acc)
    local
      DAE.Exp exp;
      String id;
    case (DAE.REDUCTIONITER(id=id,exp=exp,guardExp=NONE()),_,_)
      equation
        exp = Expression.makeASUB(exp, {sub});
        exp = replaceIteratorWithExp(exp, acc, id);
      then exp;
  end match;
end simplifyAsubArrayReduction;

protected function simplifyAsubOperator
  input DAE.Exp inExp1;
  input Operator inOperator2;
  input Operator inOperator3;
  output Operator outOperator;
algorithm
  outOperator:=
  match (inExp1)
    case (DAE.ARRAY()) then inOperator3;
    case (DAE.MATRIX()) then inOperator3;
    case (DAE.RANGE()) then inOperator3;
    else inOperator2;
  end match;
end simplifyAsubOperator;

protected function simplifyAsubSlicing
  "Simplifies asubs where some of the subscripts are slices.
    Ex: x[i, 1:3] => {x[i, 1], x[i, 2], x[i, 3]}"
  input DAE.Exp inExp;
  input list<DAE.Exp> inSubscripts;
  output DAE.Exp outAsubArray;
protected
  list<list<DAE.Exp>> indices;
  list<DAE.Exp> asubs;
  Integer sz;
  DAE.Exp elem;
  DAE.Type ty;
algorithm
  // Expand the subscripts.
  indices := List.map(inSubscripts, Expression.splitArray);
  // Make asubs from all combinations of the subscript indices.
  asubs := List.combinationMap1(indices, simplifyAsubSlicing2, inExp);
  // Make sure one or more dimensions were sliced, i.e. we got more than one element.
  elem :: _ :: _ := asubs;
  // Make an array expression from the asub list.
  ty := Expression.typeof(elem);
  outAsubArray := Expression.makeScalarArray(asubs, ty);
end simplifyAsubSlicing;

protected function simplifyAsubSlicing2
  input list<DAE.Exp> inSubscripts;
  input DAE.Exp inExp;
  output DAE.Exp outAsub;
algorithm
  outAsub := Expression.makeASUB(inExp, inSubscripts);
end simplifyAsubSlicing2;

protected function simplifyBinaryConst
"This function evaluates constant binary expressions."
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
      Option<DAE.Exp> oexp;
      DAE.Type ty;

    case (DAE.ADD(),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
        val = safeIntOp(ie1,ie2,ExpressionSimplifyTypes.ADDOP());
      then val;

    case (DAE.ADD(),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 + re2;
      then DAE.RCONST(re3);

    case (DAE.ADD(),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 + e2_1;
      then DAE.RCONST(re3);

    case (DAE.ADD(),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 + re2;
      then DAE.RCONST(re3);

    case (DAE.ADD(),DAE.SCONST(string = s1),DAE.SCONST(string = s2))
      equation
        str = s1 + s2;
      then DAE.SCONST(str);

    case (DAE.SUB(),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
         val = safeIntOp(ie1,ie2,ExpressionSimplifyTypes.SUBOP());
      then val;

    case (DAE.SUB(),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 - re2;
      then DAE.RCONST(re3);

    case (DAE.SUB(),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 - e2_1;
      then DAE.RCONST(re3);

    case (DAE.SUB(),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 - re2;
      then DAE.RCONST(re3);

    case (DAE.MUL(),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
        val = safeIntOp(ie1,ie2,ExpressionSimplifyTypes.MULOP());
      then val;

    case (DAE.MUL(),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 * re2;
      then DAE.RCONST(re3);

    case (DAE.MUL(),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 * e2_1;
      then DAE.RCONST(re3);

    case (DAE.MUL(),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 * re2;
      then DAE.RCONST(re3);

    case (DAE.DIV(),DAE.ICONST(integer = ie1),DAE.ICONST(integer = ie2))
      equation
         val = safeIntOp(ie1,ie2,ExpressionSimplifyTypes.DIVOP());
      then val;

    case (DAE.DIV(),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 / re2;
      then DAE.RCONST(re3);

    case (DAE.DIV(),DAE.RCONST(real = re1),DAE.ICONST(integer = ie2))
      equation
        e2_1 = intReal(ie2);
        re3 = re1 / e2_1;
      then DAE.RCONST(re3);

    case (DAE.DIV(),DAE.ICONST(integer = ie1),DAE.RCONST(real = re2))
      equation
        e1_1 = intReal(ie1);
        re3 = e1_1 / re2;
      then DAE.RCONST(re3);

    case (DAE.POW(),DAE.RCONST(real = re1),DAE.RCONST(real = re2))
      equation
        re3 = re1 ^ re2;
      then DAE.RCONST(re3);

  end match;
end simplifyBinaryConst;


protected function simplifyLBinaryConst
"This function evaluates constant binary expressions."
  input Operator op;
  input Boolean b1;
  input Boolean b2;
  output DAE.Exp outExp;
algorithm
  outExp := match (op,b1,b2)
    local
      Boolean b;

    case(DAE.AND(_),_,_)
      equation
        b = b1 and b2;
      then DAE.BCONST(b);

    case(DAE.OR(_),_,_)
      equation
        b = b1 or b2;
      then DAE.BCONST(b);
  end match;
end simplifyLBinaryConst;

protected function simplifyRelationConst
"This function evaluates constant binary expressions."
  input Operator op;
  input DAE.Exp e1;
  input DAE.Exp e2;
  output Boolean b;
algorithm
  b := match (op,e1,e2)
    local
      Real v1,v2;
      Boolean b1,b2;
      String s1,s2;
    // Relation operations
    case(DAE.LESS(),DAE.BCONST(false),DAE.BCONST(true))
      then true;

    case(DAE.LESS(),DAE.BCONST(_),DAE.BCONST(_))
      then false;

    case(DAE.LESS(),_,_)
      equation
        v1 = Expression.toReal(e1);
        v2 = Expression.toReal(e2);
        b = v1 < v2;
      then b;

    case(DAE.LESSEQ(),DAE.BCONST(true),DAE.BCONST(false))
      then false;

    case(DAE.LESSEQ(),DAE.BCONST(_),DAE.BCONST(_))
      then true;

    case(DAE.LESSEQ(),_,_)
      equation
        v1 = Expression.toReal(e1);
        v2 = Expression.toReal(e2);
        b = v1 <= v2;
      then b;

    case(DAE.EQUAL(),DAE.BCONST(b1),DAE.BCONST(b2))
      then boolEq(b1,b2);

    case(DAE.EQUAL(),DAE.SCONST(s1),DAE.SCONST(s2))
      then stringEqual(s1,s2);

    case(DAE.EQUAL(),_,_)
      equation
        v1 = Expression.toReal(e1);
        v2 = Expression.toReal(e2);
      then realEq(v1,v2);

    // Express GT, GE, NE using LE, LT, EQ
    case (DAE.GREATER(),_,_)
      then not simplifyRelationConst(DAE.LESSEQ(DAE.T_REAL_DEFAULT),e1,e2);

    case (DAE.GREATEREQ(),_,_)
      then not simplifyRelationConst(DAE.LESS(DAE.T_REAL_DEFAULT),e1,e2);

    case(DAE.GREATER(),DAE.BCONST(false),DAE.BCONST(true))
      then not simplifyRelationConst(DAE.LESSEQ(DAE.T_REAL_DEFAULT),e1,e2);

    case(DAE.GREATEREQ(),DAE.BCONST(false),DAE.BCONST(true))
      then not simplifyRelationConst(DAE.LESS(DAE.T_REAL_DEFAULT),e1,e2);

    case(DAE.NEQUAL(),_,_)
      then not simplifyRelationConst(DAE.EQUAL(DAE.T_REAL_DEFAULT),e1,e2);
  end match;
end simplifyRelationConst;

public function safeIntOp
  "Safe mul, add, sub or pow operations for integers.
   The function returns an integer if possible, otherwise a real.
  "
  input Integer val1;
  input Integer val2;
  input ExpressionSimplifyTypes.IntOp op;
  output DAE.Exp outv;
algorithm
  outv := match(val1, val2, op)
    local
      Real rv1,rv2,rv3;
      Integer ires;

    case (_,_, ExpressionSimplifyTypes.MULOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 * rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;

    case (_,_, ExpressionSimplifyTypes.DIVOP())
      equation
        ires = intDiv(val1,val2);
      then
        DAE.ICONST(ires);

    case (_,_, ExpressionSimplifyTypes.SUBOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 - rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;

    case (_,_, ExpressionSimplifyTypes.ADDOP())
      equation
        rv1 = intReal(val1);
        rv2 = intReal(val2);
        rv3 = rv1 + rv2;
        outv = Expression.realToIntIfPossible(rv3);
      then
        outv;

    case (_,_, ExpressionSimplifyTypes.POWOP())
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
    case (_,_,_) then simplifyBinaryCommutativeWork(op,lhs,rhs);
    case (_,_,_) then simplifyBinaryCommutativeWork(op,rhs,lhs);
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
      DAE.Exp e3,e4,e,e1,e2,res;
      Operator op1,op2;
      Type ty,ty2,tp,tp2;
      Real r1,r2,r3;
      /* sin(2*x) = 2*sin(x)*cos(x) */
    case (DAE.MUL(_),DAE.CALL(path=Absyn.IDENT("sin"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("cos"),expLst={e2}))
      equation
        true = Expression.expEqual(e1,e2);
        e = DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.T_REAL_DEFAULT),e1);
        e = Expression.makePureBuiltinCall("sin",{e},DAE.T_REAL_DEFAULT);
      then DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.T_REAL_DEFAULT),e);

      /* sin^2(x)+cos^2(x) = 1 */
    case (DAE.ADD(_),DAE.BINARY(DAE.CALL(path=Absyn.IDENT("sin"),expLst={e1}),DAE.POW(DAE.T_REAL()),DAE.RCONST(real = 2.0)),
                     DAE.BINARY(DAE.CALL(path=Absyn.IDENT("cos"),expLst={e2}),DAE.POW(DAE.T_REAL()),DAE.RCONST(real = 2.0)))
      equation
        true = Expression.expEqual(e1,e2);
      then DAE.RCONST(1.0);

    // tan(e)*cos(e) = sin(e)
    case(DAE.MUL(tp),DAE.CALL(path=Absyn.IDENT("tan"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("cos"),expLst={e2}))
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makePureBuiltinCall("sin",{e1},tp);

      /* sinh^2(x)+cosh^2(x) = 1 */
    case (DAE.ADD(_),DAE.BINARY(DAE.CALL(path=Absyn.IDENT("sinh"),expLst={e1}),DAE.POW(DAE.T_REAL()),DAE.RCONST(real = 2.0)),
                     DAE.BINARY(DAE.CALL(path=Absyn.IDENT("cosh"),expLst={e2}),DAE.POW(DAE.T_REAL()),DAE.RCONST(real = 2.0)))
      equation
        true = Expression.expEqual(e1,e2);
      then DAE.RCONST(1.0);

    // tanh(e)*cosh(e) = sinh(e)
    case(DAE.MUL(tp),DAE.CALL(path=Absyn.IDENT("tanh"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("cosh"),expLst={e2}))
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makePureBuiltinCall("sinh",{e1},tp);

    // a+(-b)
    case (DAE.ADD(ty = tp),e1,DAE.UNARY(operator = DAE.UMINUS(),exp = e2))
      equation
        e = DAE.BINARY(e1,DAE.SUB(tp),e2);
      then e;

    // a + ((-b) op2 c) = a - (b op2 c)
    case (DAE.ADD(ty = tp),e1,DAE.BINARY(DAE.UNARY(operator = DAE.UMINUS(),exp = e2), op2, e3))
      equation
        true = Expression.isMulOrDiv(op2);
        e = DAE.BINARY(e1, DAE.SUB(tp), DAE.BINARY(e2,op2,e3));
      then e;

    // Commutative
    // (-a)+b = b + (-a)
    //case (DAE.ADD(ty = tp),DAE.UNARY(operator = DAE.UMINUS(ty = tp2),exp = e1),e2)
    //  equation
    //    e = DAE.BINARY(e2,DAE.SUB(tp),e1);
    //  then e;

    // 0+e => e
    case (DAE.ADD(),e1,e2)
      equation
        true = Expression.isZero(e1);
      then
        e2;

    // e1*(e2/e3) => (e1e2)/e3
    case (DAE.MUL(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3))
      equation
        (e,true) = simplify1(DAE.BINARY(e1,DAE.MUL(tp),e2));
      then DAE.BINARY(e,DAE.DIV(tp2),e3);

    // 0 * a = 0
    case (DAE.MUL(),_,e2)
      equation
        true = Expression.isZero(e2);
      then
        e2;

    // 1 * a = a
    case (DAE.MUL(),e1,e2)
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

    // done in simplifyBinary
    // -a * -b = a * b
    //case (DAE.MUL(ty = ty),DAE.UNARY(operator = DAE.UMINUS(ty = ty1),exp = e1),DAE.UNARY(operator = DAE.UMINUS(ty = ty2),exp = e2))
    //  equation
    //    e = DAE.BINARY(e1,DAE.MUL(ty),e2);
    //  then
    //    e;

    // (e * e1) * e => e1*e^2
    case (DAE.MUL(),DAE.BINARY(e2,DAE.MUL(ty),e3),e1)
      equation
        true = Expression.expEqual(e2,e1);
        e = DAE.BINARY(e1,DAE.POW(ty),DAE.RCONST(2.0) );
      then
        DAE.BINARY(e3,DAE.MUL(ty),e);

    // e * (e1 * e) => e1*e^2
    case (DAE.MUL(),e1,DAE.BINARY(e2,DAE.MUL(ty),e3))
      equation
        true = Expression.expEqual(e1,e3);
        e = DAE.BINARY(e1,DAE.POW(ty),DAE.RCONST(2.0) );
      then
        DAE.BINARY(e2,DAE.MUL(ty),e);


    // r1 * (r2 * e) => (r1*r2)*e
    case (DAE.MUL(),DAE.RCONST(real = r1),DAE.BINARY(DAE.RCONST(real = r2),DAE.MUL(DAE.T_REAL()),e2))
      equation
        r3 = r1 * r2;
      then
        DAE.BINARY(DAE.RCONST(r3),DAE.MUL(DAE.T_REAL_DEFAULT),e2);

    // r1 * (e * r2) => (r1*r2)*e
    case (DAE.MUL(),DAE.RCONST(real = r1),DAE.BINARY(e2,DAE.MUL(DAE.T_REAL()),DAE.RCONST(real = r2)))
      equation
        r3 = r1 * r2;
      then
        DAE.BINARY(DAE.RCONST(r3),DAE.MUL(DAE.T_REAL_DEFAULT),e2);

    // |e1| /e1 = e1/|e1| => sign(e1)
    case(DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("abs"),expLst={e1}),e2)
     equation
     true = Expression.expEqual(e1,e2);
     res = Expression.makePureBuiltinCall("sign",{e1},ty);
    then
     res;

    // SUB is not commutative
    // (e*e1) - (e*e2) => e*(e1-e2)
    //case (op1 as DAE.SUB(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
    //  equation
    //    true = Expression.expEqual(e1,e3);
    //  then
    //    DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e4));
    // (e*e1) - (e2*e) => e*(e1-e2)
    //case (op1 as DAE.SUB(ty = _),DAE.BINARY(e1,op2 as DAE.MUL(ty=_),e2),DAE.BINARY(e3,DAE.MUL(ty=_),e4))
    //  equation
    //    true = Expression.expEqual(e1,e4);
    //  then
    //    DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e3));

    // e2 + (e*e2) = (1.0 + e)*e2
    // e2 + (e2*e) = (1.0 + e)*e2;
    case (op1 as DAE.ADD(), e1, DAE.BINARY(e2, op2 as DAE.MUL(),e3))
      equation
        false = Expression.isConstValue(e1);
        if Expression.expEqual(e1,e3)
        then
          exp = DAE.BINARY(e1,op2,DAE.BINARY(DAE.RCONST(1.0),op1,e2));
        else if Expression.expEqual(e1,e2)
             then
               exp = DAE.BINARY(e1,op2,DAE.BINARY(DAE.RCONST(1.0),op1,e3));
             else
              fail();
             end if;
        end if;
      then
        exp;

    // sqrt(e) * e => e^1.5
    case (DAE.MUL(),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),e2)
      equation
        true = Expression.expEqual(e1,e2);
      then
        DAE.BINARY(e1,DAE.POW(DAE.T_REAL_DEFAULT),DAE.RCONST(1.5));
    // sqrt(e) * e^r => e^(r+0.5)
    case (DAE.MUL(),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),DAE.BINARY(e2,DAE.POW(),e))
      equation
        true = Expression.expEqual(e1,e2);
      then
        DAE.BINARY(e1,DAE.POW(DAE.T_REAL_DEFAULT),DAE.BINARY(e,DAE.ADD(DAE.T_REAL_DEFAULT),DAE.RCONST(0.5)));
    // x*x^y => x^(y+1)
    case (DAE.MUL(),e1,DAE.BINARY(e3, op1 as DAE.POW(tp),e4))
      equation
        true = Expression.expEqual(e1,e3);
        e = Expression.makeConstOne(tp);
      then
        DAE.BINARY(e1,op1,DAE.BINARY(e,DAE.ADD(tp),e4));

  end matchcontinue;
end simplifyBinaryCommutativeWork;

protected function simplifyBinary
"This function simplifies binary expressions."
  input DAE.Exp origExp;
  input Operator op;
  input DAE.Exp lhs "Note: already simplified";
  input DAE.Exp rhs "Note: aldready simplified";
  output DAE.Exp outExp;
algorithm
  outExp := simplifyBinary2(origExp,op,lhs,rhs,Expression.isConstValue(lhs),Expression.isConstValue(rhs));
end simplifyBinary;

protected function simplifyBinary2
"This function simplifies binary expressions."
  input DAE.Exp origExp;
  input Operator inOperator2;
  input DAE.Exp lhs "Note: already simplified";
  input DAE.Exp rhs "Note: aldready simplified";
  input Boolean lhsIsConstValue;
  input Boolean rhsIsConstValue;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,inOperator2,lhs,rhs,lhsIsConstValue,rhsIsConstValue)
    local
      DAE.Exp e1_1,e3,e,e1,e2,e4,e5,e6,res,one;
      Operator oper, op1 ,op2, op3, op;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b,b2;
      Real r, r1;
      Integer i2;
      Option<DAE.Exp> oexp;


    // binary operations on arrays
    case (_,op,e1,e2,_,_)
      then simplifyBinaryArray(e1, op, e2);

    // binary scalar simplifications
    case (_,op,e1,e2,_,_)
      then simplifyBinaryCommutative(op, e1, e2);

    // constants
    case (_,oper,e1,e2,true,true)
      equation
        // print("simplifyBinaryConst " + ExpressionDump.printExpStr(e1) + ExpressionDump.binopSymbol1(oper) + ExpressionDump.printExpStr(e2) + "\n");
        e3 = simplifyBinaryConst(oper, e1, e2);
        // print("simplifyBinaryConst " + ExpressionDump.printExpStr(e1) + "," + ExpressionDump.printExpStr(e2) + " => " + ExpressionDump.printExpStr(e3) + "\n");
      then e3;

    case (_,oper,DAE.BINARY(e1,op1,e2),DAE.BINARY(e3,op2,e4),_,_)
      then simplifyTwoBinaryExpressions(e1,op1,e2,oper,e3,op2,e4,
              /* These are checked in multiple cases and improve performance */
              Expression.expEqual(e1,e3),
              Expression.expEqual(e1,e4),
              Expression.expEqual(e2,e3),
              Expression.expEqual(e2,e4),
              Expression.isConstValue(e1),
              Expression.isConstValue(e2),
              Expression.isConstValue(e3),
              Expression.operatorEqual(op1,op2)
           );

    // Look for empty arrays
    case (_,oper,e1,e2,_,_)
      equation
        true = Expression.isConstZeroLength(e1) or Expression.isConstZeroLength(e2);
        checkZeroLengthArrayOp(oper);
      then e1;

    // a*(b^(-e)) => a/(b^e)
    case (_,DAE.MUL(),e1,DAE.BINARY(exp1 = e2,operator = DAE.POW(ty = ty2),exp2 = DAE.UNARY(exp=e3,operator=DAE.UMINUS())),_,_)
      equation
        res = DAE.BINARY(e1,DAE.DIV(ty2),DAE.BINARY(e2,DAE.POW(ty2),e3));
      then res;

    // a/(b^(-e)) => a*(b^e)
    case (_,DAE.DIV(),e1,DAE.BINARY(exp1 = e2,operator = DAE.POW(ty = ty2),exp2 = DAE.UNARY(exp=e3,operator=DAE.UMINUS())),_,_)
      equation
        res = DAE.BINARY(e1,DAE.MUL(ty2),DAE.BINARY(e2,DAE.POW(ty2),e3));
      then res;

    // a*(b^(-r)) => a/(b^r)
    case (_,DAE.MUL(),e1,DAE.BINARY(exp1 = e2,operator = DAE.POW(ty = ty2),exp2 = DAE.RCONST(r)),_,_)
      equation
        true = realLt(r,0.0);
        r = realNeg(r);
        res = DAE.BINARY(e1,DAE.DIV(ty2),DAE.BINARY(e2,DAE.POW(ty2),DAE.RCONST(r)));
      then res;

    // a/(b^(-r)) => a*(b^r)
    case (_,DAE.DIV(),e1,DAE.BINARY(exp1 = e2,operator = DAE.POW(ty = ty2),exp2 = DAE.RCONST(r)),_,_)
      equation
        true = realLt(r,0.0);
        r = realNeg(r);
        res = DAE.BINARY(e1,DAE.MUL(ty2),DAE.BINARY(e2,DAE.POW(ty2),DAE.RCONST(r)));
      then res;

    // (a*b op1 c)/b => a op1 c/b
    case (_,DAE.DIV(_),DAE.BINARY(DAE.BINARY(e1, DAE.MUL(_), e2), op1,e3),e4,_,_)
      equation
        true = Expression.expEqual(e2,e4);
        true = Expression.isAddOrSub(op1);
        e = Expression.makeDiv(e3,e4);
        res = DAE.BINARY(e1,op1,e);
      then res;

    // (c op1 a*b)/b =>  c/b  op1 a
    case (_,DAE.DIV(_),DAE.BINARY(e3, op1,DAE.BINARY(e1, DAE.MUL(_), e2)),e4,_,_)
      equation
        true = Expression.expEqual(e2,e4);
        true = Expression.isAddOrSub(op1);
        e = Expression.makeDiv(e3,e4);
        res = DAE.BINARY(e,op1,e1);
      then res;

    // (e1 * e2*e3 op1 e4)/e3 => e1 * e2 op1 e4/e3
    case (_,DAE.DIV(_),DAE.BINARY(DAE.BINARY(e1, op2 as DAE.MUL(), DAE.BINARY(e2, DAE.MUL(_), e3)), op1,e4),e5,_,_)
      equation
        true = Expression.expEqual(e3,e5);
        true = Expression.isAddOrSub(op1);
        e = Expression.makeDiv(e4,e3);
        e1_1 = DAE.BINARY(e1,op2,e2);
        res = DAE.BINARY(e1_1,op1,e);
      then res;

    // |e1| op2 |e2| => |e1 op2 e2|
    case(_,op2,DAE.CALL(path=Absyn.IDENT("abs"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("abs"),expLst={e2}),_,_)
      equation
        ty = Expression.typeof(e1);
        true = Expression.isMulOrDiv(op2);
        res = DAE.BINARY(e1, op2, e2);
      then Expression.makePureBuiltinCall("abs",{res},ty);
    // e1 / exp(e2) => e1*exp(-e2)
    case(_,DAE.DIV(ty),e1,DAE.CALL(path=Absyn.IDENT("exp"),expLst={e2}),_,_)
      equation
        e = DAE.UNARY(DAE.UMINUS(ty),e2);
        (e,_) = simplify1(e);
        e3 = Expression.makePureBuiltinCall("exp",{e},ty);
        res = DAE.BINARY(e1,DAE.MUL(ty),e3);
      then res;
    // exp(e1) * exp(e2) => exp(e1 + e2)
    case(_,DAE.MUL(ty),DAE.CALL(path=Absyn.IDENT("exp"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("exp"),expLst={e2}),_,_)
      equation
        false = Expression.isConstValue(e1) or Expression.isConstValue(e2);
        e = DAE.BINARY(e1, DAE.ADD(ty),e2);
        res = Expression.makePureBuiltinCall("exp",{e},ty);
      then res;

    // (a+b)/c1 => a/c1+b/c1, for constant c1
    case (_,DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty2),exp2 = e2),e3,_,true)
      equation
        (e,b) = simplify1(DAE.BINARY(e1,DAE.DIV(ty),e3));
        (e4,b2) = simplify1(DAE.BINARY(e2,DAE.DIV(ty),e3));
        true = b or b2;
      then DAE.BINARY(e ,DAE.ADD(ty2),e4);

    // (a-b)/c1 => a/c1-b/c1, for constant c1
    case (_,DAE.DIV(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty2),exp2 = e2),e3,_,true)
      equation
        (e,b) = simplify1(DAE.BINARY(e1,DAE.DIV(ty),e3));
        (e4,b2) = simplify1(DAE.BINARY(e2,DAE.DIV(ty),e3));
        true = b or b2;
      then DAE.BINARY(e,DAE.SUB(ty2),e4);

    // a/(b/c) => (ac)/b
    case (_,DAE.DIV(ty = tp),e1,DAE.BINARY(exp1 = e2,operator = DAE.DIV(ty = tp2),exp2 = e3),_,_)
      then DAE.BINARY(DAE.BINARY(e1,DAE.MUL(tp),e3),DAE.DIV(tp2),e2);

    // (a/b)/c => a/(bc))
    case (_,DAE.DIV(ty = tp),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = tp2),exp2 = e2),e3,_,_)
      then DAE.BINARY(e1,DAE.DIV(tp2),DAE.BINARY(e2,DAE.MUL(tp),e3));

    // a / (b*a)  = 1/b
    case (_,DAE.DIV(),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3),_,_)
      equation
        true = Expression.expEqual(e1,e3);
      then DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e2);

    // a / (a*b)  = 1/b
    case (_,DAE.DIV(),e1,DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp2),exp2 = e3),_,_)
      equation
        true = Expression.expEqual(e1,e2);
      then DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(tp2),e3);

    // (a*b)/ a  = b
    case (_,DAE.DIV(),DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2),e3,_,_)
      equation
        true = Expression.expEqual(e1,e3);
      then e2;

    // (a*b)/ b  = a
    case (_,DAE.DIV(),DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2),e3,_,_)
      equation
        true = Expression.expEqual(e2,e3);
      then e1;

    // (-a*b)/ a  = -b
    case (_,DAE.DIV(),DAE.BINARY(exp1 = DAE.UNARY(operator = DAE.UMINUS(),exp = e1),operator = DAE.MUL(),exp2 = e2),e3,_,_)
      equation
        true = Expression.expEqual(e1,e3);
        tp2 = Expression.typeof(e2);
        e = DAE.UNARY(DAE.UMINUS(tp2),e2);
      then e;

    // (-a*b)/ b  = -a
    case (_,DAE.DIV(),DAE.BINARY(exp1 = DAE.UNARY(operator = DAE.UMINUS(),exp = e1),operator = DAE.MUL(),exp2 = e2),e3,_,_)
      equation
        true = Expression.expEqual(e2,e3);
        tp2 = Expression.typeof(e1);
        e = DAE.UNARY(DAE.UMINUS(tp2),e1);
      then e;

    // (a*b)/ -b  = -a
    case (_,DAE.DIV(),DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2),DAE.UNARY(operator = DAE.UMINUS(),exp = e3),_,_)
      equation
        true = Expression.expEqual(e2,e3);
        tp2 = Expression.typeof(e1);
      then DAE.UNARY(DAE.UMINUS(tp2),e1);

    // (a*b)/ -a  = -b
    case (_,DAE.DIV(),DAE.BINARY(exp1 = e1,operator = DAE.MUL(),exp2 = e2),DAE.UNARY(operator = DAE.UMINUS(),exp = e3),_,_)
      equation
        true = Expression.expEqual(e1,e3);
        tp2 = Expression.typeof(e2);
      then DAE.UNARY(DAE.UMINUS(tp2),e2);

    // subtract from zero
    case (_,DAE.SUB(ty = ty),e1,e2,true,_)
      equation
        true = Expression.isZero(e1);
      then DAE.UNARY(DAE.UMINUS(ty),e2);

    // subtract zero
    case (_,DAE.SUB(),e1,e2,_,true)
      equation
        true = Expression.isZero(e2);
      then e1;

    // a - a  = 0
    case (_,DAE.SUB(ty = ty),e1,e2,_,_)
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makeConstZero(ty);

    // a + a  = 2*a
    case (_,DAE.ADD(ty = ty),e1,e2,_,_)
      equation
        true = Types.isRealOrSubTypeReal(ty);
        true = Expression.expEqual(e1,e2);
        e = DAE.RCONST(2.0);
      then DAE.BINARY(e,DAE.MUL(ty),e1);

    // a-(-b) = a+b
    case (_,DAE.SUB(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(),exp = e2),_,_)
      then DAE.BINARY(e1,DAE.ADD(ty),e2);

    // a-(-b)*c = a+b*c
    case (_,DAE.SUB(ty = ty),e1,DAE.BINARY(DAE.UNARY(operator = DAE.UMINUS(),exp = e2),op1 as DAE.MUL(_),e3),_,_)
      then DAE.BINARY(e1,DAE.ADD(ty),DAE.BINARY(e2,op1,e3));

    // a-(-b)/c = a+b/c
    case (_,DAE.SUB(ty = ty),e1,DAE.BINARY(DAE.UNARY(operator = DAE.UMINUS(),exp = e2),op1 as DAE.DIV(_),e3),_,_)
      then DAE.BINARY(e1,DAE.ADD(ty),DAE.BINARY(e2,op1,e3));

    // 0 / x = 0
    case (_,DAE.DIV(),e1,e2,true,false)
      equation
        true = Expression.isZero(e1);
        false = Expression.isZero(e2);
      then DAE.RCONST(0.0);

    // a / 1 = a
    case (_,DAE.DIV(),e1,e2,false,true)
      equation
        true = Expression.isConstOne(e2);
      then e1;

    // a / -1 = -a
    case (_,DAE.DIV(ty = ty),e1,e2,_,_)
      equation
        true = Expression.isConstMinusOne(e2);
        e = DAE.UNARY(DAE.UMINUS(ty),e1);
      then e;

    // a / a  = 1
    case (_,DAE.DIV(ty = ty),e1,e2,_,_)
      equation
        true = Expression.expEqual(e1,e2);
        res = Expression.makeConstOne(ty);
        false = Expression.isZero(e2);
      then res;

    // a * a  = a^2
    case (_,DAE.MUL(ty = ty),e1,e2,_,_)
      equation
        true = Expression.expEqual(e1,e2);
        res = DAE.BINARY(e1,DAE.POW(ty),DAE.RCONST(2.0));
        false = Expression.isZero(e2);
      then res;

    // exp / r = (1/r)*exp
    case(_, DAE.DIV(ty=tp), e1, DAE.RCONST(real=r1), _, _)
      equation
        true = realAbs(r1) > 0.0;
        r = 1.0 / r1;
        r1 = 1e12 * r;
        0.0 = realMod(r1, 1.0);
        e3 = DAE.BINARY(DAE.RCONST(r),DAE.MUL(tp),e1);
      then e3;
    // x / (r*y) = (1/r)*x/y
    case(_, op2 as DAE.DIV(ty=tp), e1, DAE.BINARY(DAE.RCONST(real=r1),DAE.MUL(_),e3), _, _)
      equation
        true = realAbs(r1) > 0.0;
        r = 1.0 / r1;
        r1 = 1e12 * r;
        0.0 = realMod(r1, 1.0);
        then DAE.BINARY(DAE.BINARY(DAE.RCONST(r),DAE.MUL(tp),e1),op2,e3);
    // -a / -b = a / b
    case (_,DAE.DIV(ty = ty),DAE.UNARY(operator = DAE.UMINUS(),exp = e1),DAE.UNARY(operator = DAE.UMINUS(),exp = e2),_,_)
      then DAE.BINARY(e1,DAE.DIV(ty),e2);
    // -a*(b-c) = a*(c -b)
    case (_,op2 as DAE.MUL(),DAE.UNARY(operator = DAE.UMINUS(),exp = e1),DAE.BINARY(e2, op1 as DAE.SUB(_),e3),_,_)
      then DAE.BINARY(e1,op2,DAE.BINARY(e3,op1,e2));
    // -a/(b-c) = a/(c -b)
    case (_,op2 as DAE.DIV(),DAE.UNARY(operator = DAE.UMINUS(),exp = e1),DAE.BINARY(e2, op1 as DAE.SUB(_),e3),_,_)
      then DAE.BINARY(e1,op2,DAE.BINARY(e3,op1,e2));
    // a*(-b-c) = (-a)*(c + b)
    case (_,op2 as DAE.MUL(),e1,DAE.BINARY(DAE.UNARY(operator = op3 as DAE.UMINUS(),exp = e2), DAE.SUB(ty = ty), e3),_,_)
    then DAE.BINARY(DAE.UNARY(op3,e1),op2,DAE.BINARY(e2, DAE.ADD(ty),e3));
    // a/(-b-c) = (-a)/(c + b)
    case (_,op2 as DAE.DIV(),e1,DAE.BINARY(DAE.UNARY(operator = op3 as DAE.UMINUS(),exp = e2), DAE.SUB(ty = ty), e3),_,_)
    then DAE.BINARY(DAE.UNARY(op3,e1),op2,DAE.BINARY(e2, DAE.ADD(ty),e3));
    // (-x)^2 = x^2
    case (_,op2 as DAE.POW(), DAE.UNARY(operator = DAE.UMINUS(),exp = e1), e2 as DAE.RCONST(2.0),_,_)
    then DAE.BINARY(e1, op2, e2);
    // e1 / -e2  => -e1 / e2
    case (_,DAE.DIV(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(),exp = e2),_,_)
      equation
        e1_1 = DAE.UNARY(DAE.UMINUS(ty),e1);
      then DAE.BINARY(e1_1,DAE.DIV(ty),e2);

    // (e2*e3)/e1 => (e3/e1)*e2
    case (_,DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1,_,true)
      equation
        true = Expression.isConstValue(e3);
        (e,true) = simplify1(DAE.BINARY(e3,DAE.DIV(tp2),e1));
      then DAE.BINARY(e,DAE.MUL(tp),e2);

    // e2*e3 / e1 => e2 / e1 * e3
    case (_,DAE.DIV(ty = tp2),DAE.BINARY(exp1 = e2,operator = DAE.MUL(ty = tp),exp2 = e3),e1,_,true)
      equation
        true = Expression.isConstValue(e2);
        (e,true) = simplify1(DAE.BINARY(e2,DAE.DIV(tp2),e1));
      then DAE.BINARY(e,DAE.MUL(tp),e3);

    // e ^ 1 => e
    case (_,DAE.POW(),e1,e,_,true)
      equation
        true = Expression.isConstOne(e);
      then e1;

    // e ^ - 1 =>  1 / e
    case (_,DAE.POW(ty = tp),e2,e,_,_)
      equation
        true = Expression.isConstMinusOne(e);
        one = Expression.makeConstOne(tp);
      then DAE.BINARY(one,DAE.DIV(DAE.T_REAL_DEFAULT),e2);

    // e ^ 0 => 1
    case (_,DAE.POW(),e1,e,_,true)
      equation
        tp = Expression.typeof(e1);
        true = Expression.isZero(e);
      then Expression.makeConstOne(tp);

    // sqrt(e) ^ 2.0 => e
    case (_,DAE.POW(),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e}),DAE.RCONST(2.0),_,_)
      then e;

    // sqrt(e) ^ r => e ^ 0.5*r
    case (_,oper as DAE.POW(),DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e1}),e,_,_)
     then DAE.BINARY(e1,oper,DAE.BINARY(DAE.RCONST(0.5),DAE.MUL(DAE.T_REAL_DEFAULT),e));

    // e/sqrt(e) = sqrt(e)
    case (_,DAE.DIV(),e1, DAE.CALL(path=Absyn.IDENT("sqrt"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makePureBuiltinCall("sqrt",{e1},DAE.T_REAL_DEFAULT);
    // x^y/x => x^(y-1)
    case (_,DAE.DIV(),DAE.BINARY(e1,op1 as DAE.POW(ty), e2), e3,_,_)
       equation
         true = Expression.expEqual(e1,e3);
         e4 = Expression.makeConstOne(ty);
         e4 = DAE.BINARY(e2,DAE.SUB(ty), e4);
       then DAE.BINARY(e1,op1, e4);
    // x^y*z/x = x^(y-1)*z
    case (_,DAE.DIV(),DAE.BINARY(DAE.BINARY(e1,op1 as DAE.POW(ty), e2),op2 as DAE.MUL(_),e5), e3,_,_)
      equation
        true = Expression.expEqual(e1,e3);
        e4 = Expression.makeConstOne(ty);
        e4 = DAE.BINARY(e2,DAE.SUB(ty), e4);
      then DAE.BINARY(DAE.BINARY(e1,op1, e4),op2,e5);
    //x/x^y => x^(1-y)
    case (_,DAE.DIV(),e3, DAE.BINARY(e1,op1 as DAE.POW(ty), e2),_,_)
       equation
         true = Expression.expEqual(e1,e3);
         e4 = Expression.makeConstOne(ty);
         e4 = DAE.BINARY(e4,DAE.SUB(ty), e2);
       then DAE.BINARY(e1,op1, e4);
   //(x/y)^(-r) => (y/x)^r
   case (_,op2 as DAE.POW(),DAE.BINARY(e1, op1 as DAE.DIV(_), e2), DAE.RCONST(r),_,_)
     equation
       true = realLt(r,0.0);
       r = realNeg(r);
     then DAE.BINARY(DAE.BINARY(e2,op1,e1),op2,DAE.RCONST(r));


    // 1 ^ e => 1
    case (_,DAE.POW(),e1,_,true,_)
      equation
        true = Expression.isConstOne(e1);
      then e1;

    // (if b then x1 else y1) op  (if b then x2 else y2)
    // => (if b then x1 op x2 else y1 op y2)
    case (_,op1,DAE.IFEXP(expCond = e1,expThen = e2,expElse = e3),DAE.IFEXP(expCond = e4,expThen = e5,expElse = e6),_,_)
      equation
        true = Expression.expEqual(e1,e4);
        e = DAE.BINARY(e2,op1,e5);
        res = DAE.BINARY(e3,op1,e6);
      then DAE.IFEXP(e1,e,res);

    // (-x) * y - x * z = (-x)*(y+z)
    case (_,DAE.SUB(ty), DAE.BINARY(e as DAE.UNARY(operator = DAE.UMINUS(),exp = e1), op2 as DAE.MUL(), e2), DAE.BINARY(e3,DAE.MUL(),e4) ,false,false)
      equation
       true = Expression.expEqual(e1,e3);
       res = DAE.BINARY(e, op2, DAE.BINARY(e2, DAE.ADD(ty),e4));
      then res;

    // (-x) / y - x / z = -x(1/y+1/z)
    case (_,DAE.SUB(ty), DAE.BINARY(e as DAE.UNARY(operator = DAE.UMINUS(),exp = e1), DAE.DIV(), e2), DAE.BINARY(e3, DAE.DIV(),e4) ,false,false)
      equation
       true = Expression.expEqual(e1,e3);
       res = DAE.BINARY(e, DAE.MUL(ty), DAE.BINARY(Expression.inverseFactors(e2), DAE.ADD(ty), Expression.inverseFactors(e4)));
      then res;


    // a*(x op2 b) op1 c*(x op3 d)
    // x *(a op2 b op1 c op3 d)
    case (_,op1,DAE.BINARY(e1,oper as DAE.MUL(_),DAE.BINARY(e2,op2,e3)), DAE.BINARY(e4,DAE.MUL(_),DAE.BINARY(e5,op3,e6)),false,false)
     equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op2);
       true = Expression.isMulOrDiv(op3);
       true = Expression.expEqual(e2,e5);
     then DAE.BINARY(e5, oper, DAE.BINARY(DAE.BINARY(e1,op2,e3),op1,DAE.BINARY(e4,op3,e6)));

    // a*x op1 c*x op3 d
    // x *(a op1 c op3 d)
    case (_,op1,DAE.BINARY(e1,oper as DAE.MUL(_),e2), DAE.BINARY(e4,DAE.MUL(_),DAE.BINARY(e5,op3,e6)),false,false)
     equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op3);
       true = Expression.expEqual(e2,e5);
     then DAE.BINARY(e5, oper, DAE.BINARY(e1,op1,DAE.BINARY(e4,op3,e6)));

    // a*(x op2 b) op1 c*x
    // x*(a op2 b op1 c)
    // or
    // a*(x op2 b) op1 x*c
    // x*(a op2 b op1 c)
    case (_,op1,DAE.BINARY(e1,oper as DAE.MUL(_),DAE.BINARY(e2,op2,e3)), DAE.BINARY(e4,DAE.MUL(),e5),false,false)
     equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op2);
       if Expression.expEqual(e2,e5)
       then
         outExp = DAE.BINARY(e5, oper, DAE.BINARY(DAE.BINARY(e1,op2,e3),op1,e4));
       else if Expression.expEqual(e2,e4)
            then
              outExp = DAE.BINARY(e4, oper, DAE.BINARY(DAE.BINARY(e1,op2,e3),op1,e5));
            else
              fail();
            end if;
       end if;
     then
       outExp;

    // a*(x op2 b) op1 c*x
    // x*(a op2 b op1 c)
    // or
    // a*(x op2 b) op1 x*c
    // x*(a op2 b op1 c)
    case (_,op1, DAE.BINARY(DAE.BINARY(e1,oper as DAE.MUL(_),e2),op2,e3), DAE.BINARY(e4,DAE.MUL(),e5),false,false)
     equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op2);
       if Expression.expEqual(e2,e5)
       then
         outExp = DAE.BINARY(e5, oper, DAE.BINARY(DAE.BINARY(e1,op2,e3),op1,e4));
       else if Expression.expEqual(e2,e4)
            then
              outExp = DAE.BINARY(e4, oper, DAE.BINARY(DAE.BINARY(e1,op2,e3),op1,e5));
            else
              fail();
            end if;
       end if;
     then
       outExp;

    // (a1a2...an)^e2 => a1^e2a2^e2..an^e2
    case (_,DAE.POW(),e1,e2,_,true)
      equation
        /*
         * Only do this for constant exponent and any constant expression.
         * Exponentation is very expensive compared to the inner expressions.
         */
        ((exp_lst as (_ :: _ :: _ :: _))) = Expression.factors(e1);
        _ = List.selectFirst(exp_lst,Expression.isConstValue);
        exp_lst_1 = simplifyBinaryDistributePow(exp_lst, e2);
      then Expression.makeProductLst(exp_lst_1);
    // (e1^e2)^e3 => e1^(e2*e3)
    case (_,DAE.POW(),DAE.BINARY(e1,DAE.POW(),e2),e3,_,_)
      then DAE.BINARY(e1,DAE.POW(DAE.T_REAL_DEFAULT),DAE.BINARY(e2,DAE.MUL(DAE.T_REAL_DEFAULT),e3));

    // sin(e)/cos(e) => tan(e)
    case(_,DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("sin"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("cos"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makePureBuiltinCall("tan",{e1},ty);
    // tan(e2)/sin(e2) => 1.0/cos(e2)
    case(_,op2 as DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("tan"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("sin"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
        e3 = DAE.RCONST(1.0);
        e4 = Expression.makePureBuiltinCall("cos",{e2},ty);
        e = DAE.BINARY(e3,op2,e4);
      then e;
    // cos(e2)/tan(e2) => sin(e2)
    case(_,DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("cos"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("tan"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
        e = Expression.makePureBuiltinCall("sin",{e2},ty);
      then e;
    // e1/tan(e2) => e1*cos(e2)/sin(e2)
    case(_,op2 as DAE.DIV(ty),e1,DAE.CALL(path=Absyn.IDENT("tan"),expLst={e2}),_,_)
      equation
        e3 = Expression.makePureBuiltinCall("sin",{e2},ty);
        e4 = Expression.makePureBuiltinCall("cos",{e2},ty);
        e = DAE.BINARY(e4,op2,e3);
      then DAE.BINARY(e1,DAE.MUL(ty), e);
    // sinh(e)/cosh(e) => tan(e)
    case(_,DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("sinh"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("cosh"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
      then Expression.makePureBuiltinCall("tanh",{e1},ty);
    // e1/tanh(e2) => e1*cos(e2)/sin(e2)
    case(_,op2 as DAE.DIV(ty),e1,DAE.CALL(path=Absyn.IDENT("tanh"),expLst={e2}),_,_)
      equation
        e3 = Expression.makePureBuiltinCall("sinh",{e2},ty);
        e4 = Expression.makePureBuiltinCall("cosh",{e2},ty);
        e = DAE.BINARY(e4,op2,e3);
      then DAE.BINARY(e1,DAE.MUL(ty), e);
    // tanh(e2)/sinh(e2) => 1.0/cosh(e2)
    case(_,op2 as DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("tanh"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("sinh"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
        e3 = DAE.RCONST(1.0);
        e4 = Expression.makePureBuiltinCall("cosh",{e2},ty);
        e = DAE.BINARY(e3,op2,e4);
      then e;
    // cosh(e2)/tanh(e2) => sinh(e2)
    case(_,DAE.DIV(ty),DAE.CALL(path=Absyn.IDENT("cosh"),expLst={e1}),DAE.CALL(path=Absyn.IDENT("tanh"),expLst={e2}),_,_)
      equation
        true = Expression.expEqual(e1,e2);
        e = Expression.makePureBuiltinCall("sinh",{e2},ty);
      then e;

    // e1  -e2 => -e1  e2
    // Note: This rule is *not* commutative
    case (_,DAE.MUL(ty = ty),e1,DAE.UNARY(operator = DAE.UMINUS(),exp = e2),_,_)
      equation
        e1_1 = DAE.UNARY(DAE.UMINUS(ty),e1);
      then DAE.BINARY(e1_1,DAE.MUL(ty),e2);

    case (_,DAE.ADD(),DAE.RANGE(ty=ty,start = e1,step=oexp,stop=e2),_,_,_)
      equation
        e1 = simplifyBinary(DAE.BINARY(e1,inOperator2,rhs), inOperator2, e1, rhs);
        e2 = simplifyBinary(DAE.BINARY(e2,inOperator2,rhs), inOperator2, e2, rhs);
      then DAE.RANGE(ty,e1,oexp,e2);

    case (_,DAE.ADD(),_,DAE.RANGE(ty=ty,start = e1,step=oexp,stop=e2),_,_)
      equation
        e1 = simplifyBinary(DAE.BINARY(lhs,inOperator2,e1), inOperator2, lhs, e1);
        e2 = simplifyBinary(DAE.BINARY(lhs,inOperator2,e1), inOperator2, lhs, e2);
      then DAE.RANGE(ty,e1,oexp,e2);

    case (_,DAE.SUB(),DAE.RANGE(ty=ty,start = e1,step=oexp,stop=e2),_,_,_)
      equation
        e1 = simplifyBinary(DAE.BINARY(e1,inOperator2,rhs), inOperator2, e1, rhs);
        e2 = simplifyBinary(DAE.BINARY(e2,inOperator2,rhs), inOperator2, e2, rhs);
      then DAE.RANGE(ty,e1,oexp,e2);

    case (_,DAE.SUB(),_,DAE.RANGE(ty=ty,start = e1,step=oexp,stop=e2),_,_)
      equation
        e1 = simplifyBinary(DAE.BINARY(lhs,inOperator2,e1), inOperator2, lhs, e1);
        e2 = simplifyBinary(DAE.BINARY(lhs,inOperator2,e1), inOperator2, lhs, e2);
      then DAE.RANGE(ty,e1,oexp,e2);
    else origExp;
  end matchcontinue;
end simplifyBinary2;

protected function simplifyTwoBinaryExpressions
"This function simplifies a binary expression of two binary expressions:
(e1 lhsOp e2) mainOp (e3 rhsOp e4)
"
  input DAE.Exp e1;
  input Operator lhsOperator;
  input DAE.Exp e2;
  input Operator mainOperator;
  input DAE.Exp e3;
  input Operator rhsOperator;
  input DAE.Exp e4;
  input Boolean expEqual_e1_e3;
  input Boolean expEqual_e1_e4;
  input Boolean expEqual_e2_e3;
  input Boolean expEqual_e2_e4;
  input Boolean isConst_e1;
  input Boolean isConst_e2;
  input Boolean isConst_e3;
  input Boolean operatorEqualLhsRhs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (e1,lhsOperator,e2,mainOperator,e3,rhsOperator,e4,expEqual_e1_e3,expEqual_e1_e4,expEqual_e2_e3,expEqual_e2_e4,isConst_e1,isConst_e2,isConst_e3,operatorEqualLhsRhs)
    local
      DAE.Exp e1_1,e,e_1,e_2,e_3,e_4,e_5,e_6,res,one;
      Operator oper, op1 ,op2, op3, op;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b;
      Real r;
      Option<DAE.Exp> oexp;

    // (e*e1) + (e*e2) => e*(e1+e2)
    case (_,op2 as DAE.MUL(),_,
          op1 as DAE.ADD(),
          _,DAE.MUL(),_,
          true /*e1==e3*/,_,_,_,_,_,_,_)
      then DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e4));

    // (e*e1) + (e2*e) = e*(e1+e2)
    case (_,op2 as DAE.MUL(),_,
          op1 as DAE.ADD(),
          _,DAE.MUL(),_,
          _,true /*e1==e4*/,_,_,_,_,_,_)
      then DAE.BINARY(e1,op2,DAE.BINARY(e2,op1,e3));

    // (e1*e) + (e*e4) = e*(e1+e2)
    case (_,op2 as DAE.MUL(),_,
          op1 as DAE.ADD(),
          _,DAE.MUL(),_,
          _,_,true /*e2==e3*/,_,_,_,_,_)
      then DAE.BINARY(e2,op2,DAE.BINARY(e1,op1,e4));

    // (e1*e) + (e*e4) = e*(e1+e2)
    case (_,op2 as DAE.MUL(),_,
          op1 as DAE.ADD(),
          _,DAE.MUL(),_,
          _,_,_,true /*e2==e4*/,_,_,_,_)
      then DAE.BINARY(e2,op2,DAE.BINARY(e1,op1,e3));

    // a^e*b^e => (a*b)^e
    case (_,DAE.POW(),_,
          DAE.MUL(),
          _,DAE.POW(),_,
          _,_,_,true /*e2==e4*/,_,_,_,_)
      equation
        res = DAE.BINARY(DAE.BINARY(e1,mainOperator,e3),lhsOperator,e2);
      then res;

    // a^e/b^e => (a/b)^e
    case (_,DAE.POW(),_,
          DAE.DIV(),
          _,DAE.POW(),_,
          _,_,_,true /*e2==e4*/,_,_,_,_)
      equation
        res = DAE.BINARY(DAE.BINARY(e1,mainOperator,e3),lhsOperator,e2);
      then res;

    // a^e1*a^e2 => a^(e1+e2)
    case (_,DAE.POW(),_,
          DAE.MUL(),
          _,DAE.POW(),_,
          true /*e1==e3*/,_,_,_,_,_,_,_)
      equation
        res = Expression.expAdd(e2,e4);
        res = Expression.expPow(e1,res);
      then res;

    // a^e1/a^e2 => a^(e1-e2)
    case (_,DAE.POW(),_,
          DAE.DIV(),
          _,DAE.POW(),_,
          true /*e1==e3*/,_,_,_,_,_,_,_)
      equation
        res = Expression.expSub(e2,e4);
        res = Expression.expPow(e1,res);
      then res;

    // (e1 op2 e2) op1 (e3 op3 e4) => (e1 op1 e3) op2 e2
    // e2 = e4; op2=op3 \in {*, /}; op1 \in {+, -}
    case (_,op2,_,
          op1,
          _,_,_,
          _,_,_,true /*e2==e4*/,_,false /*isConst(e2)*/,_,true /*op2==op3*/)
      equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op2);
      then
        DAE.BINARY(DAE.BINARY(e1,op1,e3),op2,e4);

    // (e1 * e2) op1 (e3 / e4) => (e1 * e2) op1 (e1 * (1/ e4) ) => e1*(e2 op1 (1/ e4))
    // e1 = e3; op1 \in {+, -}
    case (_,DAE.MUL(ty),_,
          op1,
          _,DAE.DIV(_),_,
          true /*e1==e3*/,_,_,_,false /*isConst(e1)*/,_,_,_)
      equation
       true = Expression.isAddOrSub(op1);
       one = Expression.makeConstOne(ty);
       e = Expression.makeDiv(one,e4);
      then
        DAE.BINARY(DAE.BINARY(e2,op1,e),DAE.MUL(ty),e1);

    // (e1 / e2) op1 (e3 * e4) => (e1 * (1/e2)) op1 (e1 * e4 ) => e1*(1/e2 op1 e4)
    // e1 = e3; op1 \in {+, -}
    case (_,DAE.DIV(ty),_,
          op1,
          _,DAE.MUL(_),_,
          true /*e1==e3*/,_,_,_,false /*isConst(e1)*/,_,_,_)
      equation
       true = Expression.isAddOrSub(op1);
       one = Expression.makeConstOne(ty);
       e = Expression.makeDiv(one,e2);
      then
        DAE.BINARY(DAE.BINARY(e,op1,e4),DAE.MUL(ty),e1);

    // [x op2 e] op1 [y op2 e] => (x op1 y) op2 e
    // op2 \in {*, /}; op1 \in {+, -}
    case (e1_1, op2, e_3,
          op1,
          e,_,_,
          _,_,_,true /*e2==e4==e_3==e_5*/,_,false /*isConst(e2==e_3)*/,_,true /*op2==op3*/)
      equation
       true = Expression.isAddOrSub(op1);
       true = Expression.isMulOrDiv(op2);
       res = DAE.BINARY(e1_1,op1,e);
      then DAE.BINARY(res,op2,e_3);

    // [(e1 op2 e) * e3] op1 [e4 op2 e] => (e1*e3 op1 e4) op2 e
    // op2 \in {*, /}; op1 \in {+, -}
    case (DAE.BINARY(e_1,op2,e_2),DAE.MUL(ty),e_3,
          op1,
          e,op3,e_6,
          _,_,_,_,_,_,_,_)
      equation
        false = Expression.isConstValue(e_2);
        true = Expression.expEqual(e_2,e_6);
        true = Expression.operatorEqual(op2,op3);
        true = Expression.isAddOrSub(op1);
        true = Expression.isMulOrDiv(op2);
        e1_1 = DAE.BINARY(e_1, DAE.MUL(ty),e_3);
        res = DAE.BINARY(e1_1,op1,e);
      then DAE.BINARY(res,op2,e_2);

    // [(e1 op2 e) * e3] op1 [(e4 op2 e) * e6] => (e1*e3 op1 e4*e6) op2 e
    // op2 \in {*, /}; op1 \in {+, -}
    case (DAE.BINARY(e_1,op2,e_2),DAE.MUL(ty),e_3,
          op1,
          DAE.BINARY(e_4,op3,e_5),DAE.MUL(_),e_6,
          _,_,_,_,_,_,_,_)
      equation
        false = Expression.isConstValue(e_2);
        true = Expression.expEqual(e_2,e_5);
        true = Expression.operatorEqual(op2,op3);
        true = Expression.isAddOrSub(op1);
        true = Expression.isMulOrDiv(op2);

        e1_1 = DAE.BINARY(e_1, DAE.MUL(ty),e_3);
        e = DAE.BINARY(e_4, DAE.MUL(ty),e_6);
        res = DAE.BINARY(e1_1,op1,e);
      then DAE.BINARY(res,op2,e_2);

    // [e1 op2 e] op1 [(e4 op2 e) * e6] => (e1 op1 e4*e6) op2 e
    // op2 \in {*, /}; op1 \in {+, -}
    case (e_1, op2,e_3,
          op1,
          DAE.BINARY(e_4,op3,e_5),DAE.MUL(ty),e_6,
          _,_,_,_,_,false /*isConst(e2==e_3)*/,_,_)
      equation
        true = Expression.expEqual(e_3,e_5);
        true = Expression.operatorEqual(op2,op3);
        true = Expression.isAddOrSub(op1);
        true = Expression.isMulOrDiv(op2);
        e = DAE.BINARY(e_4,DAE.MUL(ty),e_6);
        res = DAE.BINARY(e_1,op1,e);
      then DAE.BINARY(res,op2,e_3);

    // (e*e1) - (e*e2) => e*(e1-e2)
    case (_,DAE.MUL(),_,
          DAE.SUB(),
          _,DAE.MUL(),_,
          true /*e1==e3*/,_,_,_,_,_,_,_)
      then DAE.BINARY(e1,lhsOperator,DAE.BINARY(e2,mainOperator,e4));

    // (e*e1) - (e2*e) => e*(e1-e2)
    case (_,DAE.MUL(),_,
          DAE.SUB(),
          _,DAE.MUL(),_,
          _,true /*e1==e4*/,_,_,_,_,_,_)
      then DAE.BINARY(e1,lhsOperator,DAE.BINARY(e2,mainOperator,e3));

  end matchcontinue;
end simplifyTwoBinaryExpressions;

protected function simplifyLBinary
"This function simplifies logical binary expressions."
  input DAE.Exp origExp;
  input Operator inOperator2;
  input DAE.Exp inExp3 "Note: already simplified"; // lhs
  input DAE.Exp inExp4 "Note: aldready simplified"; // rhs
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,inOperator2,inExp3,inExp4)
    local
      DAE.Exp e1_1,e3,e,e1,e2,e4,e5,e6,res,one;
      Operator oper, op1 ,op2, op3;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b,b1,b2;
      Real r;
      Option<DAE.Exp> oexp;

    // constants
    case (_,oper,e1,e2)
      equation
        b1 = Expression.toBool(e1);
        b2 = Expression.toBool(e2);
        e3 = simplifyLBinaryConst(oper, b1, b2);
      then e3;

    // true AND e => e
    case (_,DAE.AND(_),e1 as DAE.BCONST(b),e2) then if b then e2 else e1;
    case (_,DAE.AND(_),e1,e2 as DAE.BCONST(b)) then if b then e1 else e2;
    // false OR e => e
    case (_,DAE.OR(_),e1 as DAE.BCONST(b),e2) then if b then e1 else e2;
    case (_,DAE.OR(_),e1,e2 as DAE.BCONST(b)) then if b then e2 else e1;

    // a AND not a -> false
    case (_,DAE.AND(_),e1,DAE.UNARY(DAE.NOT(_),e2))
      equation
        true = Expression.expEqual(e1, e2);
      then DAE.BCONST(false);
    case (_,DAE.AND(_),DAE.UNARY(DAE.NOT(_),e1),e2)
      equation
        true = Expression.expEqual(e1, e2);
      then DAE.BCONST(false);
    // a AND a -> a
    case (_,DAE.AND(_),e1,e2)
      equation
        true = Expression.expEqual(e1, e2);
      then e1;
    // a OR a -> a
    case (_,DAE.OR(_),e1,e2)
      equation
        true = Expression.expEqual(e1, e2);
      then e1;
    // a OR not a -> true
    case (_,DAE.OR(_),e1,DAE.UNARY(DAE.NOT(_),e2))
      equation
        true = Expression.expEqual(e1, e2);
      then DAE.BCONST(true);
    case (_,DAE.OR(_),DAE.UNARY(DAE.NOT(_),e1),e2)
      equation
        true = Expression.expEqual(e1, e2);
      then DAE.BCONST(true);

    else origExp;

  end matchcontinue;
end simplifyLBinary;

protected function simplifyRelation
"This function simplifies logical binary expressions."
  input DAE.Exp origExp;
  input Operator inOperator2;
  input DAE.Exp inExp3 "Note: already simplified"; // lhs
  input DAE.Exp inExp4 "Note: aldready simplified"; // rhs
  input Integer index;
  input Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,inOperator2,inExp3,inExp4)
    local
      DAE.Exp e1_1,e3,e,e1,e2,e4,e5,e6,res,one;
      Operator oper, op1 ,op2, op3;
      Type ty,ty2,tp,tp2,ty1;
      list<DAE.Exp> exp_lst,exp_lst_1;
      DAE.ComponentRef cr1,cr2;
      Boolean b ,b1;
      Real r;
      Option<DAE.Exp> oexp;

    // constants
    case (_,oper,e1,e2)
      equation
        true = Expression.isConstValue(e1);
        true = Expression.isConstValue(e2);
        b = simplifyRelationConst(oper, e1, e2);
      then DAE.BCONST(b);

    // relation: cr1 == cr2, where cr1 and cr2 are the same
    case (_,DAE.EQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_))
      equation
        true = ComponentReference.crefEqual(cr1,cr2);
      then DAE.BCONST(true);

    // relation: cr1 <> cr2 . where cr1 and cr2 are the same
    case (_,DAE.NEQUAL(_),DAE.CREF(cr1,_),DAE.CREF(cr2,_))
      equation
        true = ComponentReference.crefEqual(cr1,cr2);
      then DAE.BCONST(false);

    // a >= b
    case(_,DAE.GREATEREQ(),_,_)
      then simplifyRelation2(origExp,inOperator2, inExp3,inExp4, index,optionExpisASUB,Expression.isPositiveOrZero);
     // a > b
    case(_,DAE.GREATER(),_,_)
      then simplifyRelation2(origExp,inOperator2, inExp3,inExp4, index,optionExpisASUB,Expression.isPositiveOrZero);
    // a <= b
    case(_,DAE.LESSEQ(),_,_)
      then simplifyRelation2(origExp,inOperator2, inExp4,inExp3, index,optionExpisASUB,Expression.isPositiveOrZero);
    // a < b
    case(_,DAE.LESS(),_,_)
      then simplifyRelation2(origExp,inOperator2, inExp4,inExp3, index,optionExpisASUB,Expression.isPositiveOrZero);

    else origExp;

  end matchcontinue;
end simplifyRelation;

protected function simplifyRelation2
"This function simplifies logical binary expressions."
  input DAE.Exp origExp;
  input Operator inOp;
  input DAE.Exp lhs "Note: already simplified";
  input DAE.Exp rhs "Note: aldready simplified";
  input Integer index;
  input Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
  input Fun isPositive;
  output DAE.Exp oExp;

  partial function Fun
    input DAE.Exp x;
    output Boolean positive;
  end Fun;

protected
  Boolean b;
  Type tp;
algorithm
  oExp := Expression.expSub(lhs, rhs);
  (oExp,b) := simplify(oExp);
  if Expression.isGreatereqOrLesseq(inOp) and isPositive(oExp) then
    oExp := DAE.BCONST(true);
/*
  elseif b and not (Expression.isConstValue(rhs) or Expression.isConstValue(lhs)) then
    tp := Expression.typeof(oExp);
    oExp := if Expression.isLesseqOrLess(inOp) then
                 DAE.RELATION(Expression.makeConstZero(tp), inOp, oExp, index,optionExpisASUB)
            else DAE.RELATION(oExp, inOp,Expression.makeConstZero(tp),index,optionExpisASUB);
*/
  else
    if Expression.isGreatereqOrLesseq(inOp) then
      oExp := origExp;
    else
      oExp := Expression.negate(oExp);
      (oExp,_) := simplify(oExp);
      oExp := if isPositive(oExp) then DAE.BCONST(false) else origExp;
    end if;
  end if;
end simplifyRelation2;

protected function simplifyBinaryDistributePow
"author: PA
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
"Simplifies unary expressions."
  input DAE.Exp origExp;
  input Operator inOperator2;
  input DAE.Exp inExp3;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,inOperator2,inExp3)
    local
      Type ty,ty1;
      DAE.Exp e1,e_1,e2,e3;
      Integer i_1,i;
      Real r_1,r;
      Boolean b1;
      DAE.CallAttributes attr;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mat;

    // not true => false, not false => true
    case (_,DAE.NOT(DAE.T_BOOL()),e1)
      equation
        b1 = Expression.toBool(e1);
        b1 = not b1;
      then DAE.BCONST(b1);

    // not(not(exp)) -> exp
    case (_,DAE.NOT(_),DAE.LUNARY(DAE.NOT(_),e1))
      then e1;

    // -x => 0 - x
    case (_,DAE.UMINUS(),DAE.ICONST(integer = i))
      equation
        i_1 = intNeg(i);
      then DAE.ICONST(i_1);

    // -x => 0.0 - x
    case (_,DAE.UMINUS(),DAE.RCONST(real = r))
      equation
        r_1 = realNeg(r);
      then DAE.RCONST(r_1);

    // -(a * b) => (-a) * b
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL(ty = ty1),exp2 = e2))
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.MUL(ty1),e2);
    // -(a*b) => (-a)*b
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.MUL_ARR(ty = ty1),exp2 = e2))
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.MUL_ARR(ty1),e2);
    // -0 => 0
    case (_,DAE.UMINUS(),e1)
      equation
        true = Expression.isZero(e1);
      then e1;
    case (_,DAE.UMINUS_ARR(),e1)
      equation
        true = Expression.isZero(e1);
      then e1;
    //  -(a-b) => b - a
    case (_,DAE.UMINUS(),DAE.BINARY(exp1 = e1,operator = DAE.SUB(ty = ty1),exp2 = e2))
      then DAE.BINARY(e2,DAE.SUB(ty1),e1);
    case (_, DAE.UMINUS_ARR(),DAE.BINARY(exp1 = e1,operator = DAE.SUB_ARR(ty = ty1),exp2 = e2))
      then DAE.BINARY(e2,DAE.SUB_ARR(ty1),e1);
    // -(a + b) => -b - a
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD(ty = ty1),exp2 = e2))
      equation
      (e_1,true) = simplify1(DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.ADD(ty1),DAE.UNARY(DAE.UMINUS(ty),e2)));
      then e_1;
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.ADD_ARR(ty = ty1),exp2 = e2))
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.ADD_ARR(ty1),DAE.UNARY(DAE.UMINUS_ARR(ty),e2));
    // -( a / b) => (-a) / b
    case (_,DAE.UMINUS(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV(ty = ty1),exp2 = e2))
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS(ty),e1),DAE.DIV(ty1),e2);
    case (_,DAE.UMINUS_ARR(ty = ty),DAE.BINARY(exp1 = e1,operator = DAE.DIV_ARR(ty = ty1),exp2 = e2))
      then DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(ty),e1),DAE.DIV_ARR(ty1),e2);
     // --a => a
     case (_,DAE.UMINUS(),DAE.UNARY(operator = DAE.UMINUS(),exp = e1)) /* --a => a */
       then e1;
     case (_,DAE.UMINUS_ARR(),DAE.UNARY(operator = DAE.UMINUS_ARR(),exp = e1)) /* --a => a */
       then e1;
    // -semiLinear(-x,sb,sa) = semiLinear(x,sa,sb)
    case (_,DAE.UMINUS(),DAE.CALL(path=Absyn.IDENT("semiLinear"),expLst={DAE.UNARY(exp=e1),e2,e3},attr=attr))
      then DAE.CALL(Absyn.IDENT("semiLinear"),{e1,e3,e2},attr);

    case (_, DAE.UMINUS_ARR(), DAE.ARRAY(ty1, b1, expl))
      equation
        expl = List.map(expl, Expression.negate);
      then
        DAE.ARRAY(ty1, b1, expl);

    case (_, DAE.UMINUS_ARR(), DAE.MATRIX(ty1, i, mat))
      equation
        mat = List.mapList(mat, Expression.negate);
      then
        DAE.MATRIX(ty1, i, mat);

    else origExp;
  end matchcontinue;
end simplifyUnary;

protected function simplifyVectorScalarMatrix "Help function to simplifyVectorScalar,
handles MATRIX expressions"
  input list<list<DAE.Exp>> imexpl;
  input Operator op;
  input DAE.Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<list<DAE.Exp>> outExp;
algorithm
  outExp := match(imexpl,op,s1,arrayScalar)
    local
      list<DAE.Exp> row;
      list<list<DAE.Exp>> mexpl;
    case ({},_,_,_) then {};
    case (row::mexpl,_,_,_)
      equation
        row = simplifyVectorScalarMatrixRow(row,op,s1,arrayScalar);
        mexpl = simplifyVectorScalarMatrix(mexpl,op,s1,arrayScalar);
      then row::mexpl;
  end match;
end simplifyVectorScalarMatrix;

protected function simplifyVectorScalarMatrixRow "Help function to simplifyVectorScalarMatrix,
handles MATRIX row"
  input list<DAE.Exp> irow;
  input Operator op;
  input DAE.Exp s1;
  input Boolean arrayScalar "if true, array op scalar, otherwise scalar op array";
  output list<DAE.Exp> outExp;
algorithm
  outExp := match(irow,op,s1,arrayScalar)
    local
      DAE.Exp e;
      list<DAE.Exp> row;
    case({},_,_,_) then {};
      /* array op scalar */
    case(e::row,_,_,true)
      equation
        row = simplifyVectorScalarMatrixRow(row,op,s1,true);
      then (DAE.BINARY(e,op,s1)::row);

    /* scalar op array */
    case(e::row,_,_,false)
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
      DAE.Dimensions dims;
    case DAE.RCONST(_) then DAE.RCONST(0.0);
    case DAE.ICONST(_) then DAE.RCONST(0.0);
    case DAE.ARRAY(ty=DAE.T_ARRAY(ty=DAE.T_REAL(), dims=dims))
      equation
        (e,_) = Expression.makeZeroExpression(dims);
      then
        e;
    case DAE.ARRAY(ty=DAE.T_ARRAY(ty=DAE.T_INTEGER(), dims=dims))
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
      op = if b then DAE.ADD_ARR(ty2) else DAE.ADD(ty2);
    then op;
  case DAE.SUB_ARR(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = if b then DAE.SUB_ARR(ty2) else DAE.SUB(ty2);
    then op;
  case DAE.DIV_ARR(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = if b then DAE.DIV_ARR(ty2) else DAE.DIV(ty2);
    then op;
  case DAE.MUL_ARR(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = if b then DAE.MUL_ARR(ty2) else DAE.MUL(ty2);
    then op;
  case DAE.POW_ARR2(ty=ty1)
    equation
      ty2 = Expression.unliftArray(ty1);
      b = DAEUtil.expTypeArray(ty2);
      op = if b then DAE.POW_ARR2(ty2) else DAE.POW(ty2);
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
      String error_str;
      Integer steps;

    case (_, _, _)
      equation
        true = realAbs(inStep) <= 1e-14;
        error_str = stringDelimitList(
          List.map({inStart, inStep, inStop}, realString), ":");
        Error.addMessage(Error.ZERO_STEP_IN_ARRAY_CONSTRUCTOR, {error_str});
      then
        fail();

    case (_, _, _)
      equation
        equality(inStart = inStop);
      then {inStart};

    else
      equation
        steps = Util.realRangeSize(inStart, inStep, inStop) - 1;
      then
        simplifyRangeReal2(inStart, inStep, steps, {});

  end matchcontinue;
end simplifyRangeReal;

protected function simplifyRangeReal2
  "Helper function to simplifyRangeReal."
  input Real inStart;
  input Real inStep;
  input Integer inSteps;
  input list<Real> inValues;
  output list<Real> outValues;
algorithm
  outValues := match(inStart, inStep, inSteps, inValues)
    local
      Real next;
      list<Real> vals;

    case (_, _, -1, _) then inValues;

    else
      equation
        next = inStart + inStep * intReal(inSteps);
        vals = next :: inValues;
      then
        simplifyRangeReal2(inStart, inStep, inSteps - 1, vals);

  end match;
end simplifyRangeReal2;

protected function simplifyReduction
  input DAE.Exp inReduction;
  output DAE.Exp outValue;
algorithm
  outValue := matchcontinue inReduction
    local
      DAE.Exp expr, cref, range, foldExpr, foldExpr2;
      DAE.Ident iter_name;
      list<DAE.Exp> values;
      Option<Values.Value> defaultValue;
      Values.Value v;
      String str;
      Option<DAE.Exp> foldExp;
      DAE.Type ty,ty1,ety;
      DAE.ReductionIterator iter;
      list<DAE.ReductionIterator> iterators;
      String foldName,resultName,foldName2,resultName2;
      Absyn.Path path;

    case DAE.REDUCTION(iterators = iterators, reductionInfo=DAE.REDUCTIONINFO(defaultValue = SOME(v)))
      equation
        true = hasZeroLengthIterator(iterators);
        expr = ValuesUtil.valueExp(v);
      then expr;

    case DAE.REDUCTION(iterators = iterators)
      equation
        true = hasZeroLengthIterator(iterators);
        expr = ValuesUtil.valueExp(Values.META_FAIL());
      then expr;

    case DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path, foldName=foldName, resultName=resultName, foldExp=foldExp, exprType = ty, defaultValue = defaultValue), expr = expr, iterators = {DAE.REDUCTIONITER(id = iter_name, guardExp = NONE(), exp = range)})
      equation
        values = Expression.getArrayOrRangeContents(range);
        // TODO: Use foldExp
        //ty = Types.unliftArray(ty);
        ety = Types.simplifyType(ty);
        values = List.map2(values, replaceIteratorWithExp, expr, iter_name);
        expr = simplifyReductionFoldPhase(path,foldExp,foldName,resultName,ety,values,defaultValue);
      then expr;

    // iterType=THREAD() can handle multiple iterators
    case DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path, iterType = Absyn.THREAD(), foldName=foldName, resultName=resultName, exprType = ty, foldExp=foldExp, defaultValue = defaultValue), expr = expr, iterators = iterators)
      equation
        // Start like for the normal reductions
        DAE.REDUCTIONITER(id = iter_name, guardExp = NONE(), exp = range)::iterators = iterators;
        values = Expression.getArrayOrRangeContents(range);
        ety = Types.simplifyType(ty);
        values = List.map2(values, replaceIteratorWithExp, expr, iter_name);
        // Then also fix the rest of the iterators
        values = List.fold(iterators, getIteratorValues, values);
        // And fold
        expr = simplifyReductionFoldPhase(path,foldExp,foldName,resultName,ety,values,defaultValue);
      then expr;

    // array can handle multiple iterators
    case DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path as Absyn.IDENT("array"), iterType = Absyn.COMBINE(), foldName=foldName, resultName=resultName, exprType = ty), expr = expr, iterators = iter::(iterators as _::_))
      equation
        foldName2 = Util.getTempVariableIndex();
        resultName2 = Util.getTempVariableIndex();
        ty1 = Types.unliftArray(ty);
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty1,NONE(),foldName,resultName,NONE()),expr,iterators);
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty,NONE(),foldName2,resultName2,NONE()),expr,{iter});
      then expr;
    // rest can also handle multiple iterators
    case DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path, iterType = Absyn.COMBINE(), foldName=foldName, resultName=resultName, exprType = ty, foldExp=NONE(), defaultValue = defaultValue), expr = expr, iterators = iter::(iterators as _::_))
      equation
        foldName2 = Util.getTempVariableIndex();
        resultName2 = Util.getTempVariableIndex();
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty,defaultValue,foldName2,resultName2,NONE()),expr,{iter});
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty,defaultValue,foldName,resultName,NONE()),expr,iterators);
      then expr;

    case DAE.REDUCTION(reductionInfo = DAE.REDUCTIONINFO(path = path, iterType = Absyn.COMBINE(), foldName=foldName, resultName=resultName, exprType = ty, foldExp=SOME(foldExpr), defaultValue = defaultValue), expr = expr, iterators = iter::(iterators as _::_))
      equation
        foldName2 = Util.getTempVariableIndex();
        resultName2 = Util.getTempVariableIndex();
        (foldExpr2,_) = Expression.traverseExpBottomUp(foldExpr,Expression.renameExpCrefIdent,(foldName,foldName2));
        (foldExpr2,_) = Expression.traverseExpBottomUp(foldExpr2,Expression.renameExpCrefIdent,(resultName,resultName2));
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty,defaultValue,foldName2,resultName2,SOME(foldExpr2)),expr,{iter});
        expr = DAE.REDUCTION(DAE.REDUCTIONINFO(path,Absyn.COMBINE(),ty,defaultValue,foldName,resultName,SOME(foldExpr)),expr,iterators);
      then expr;

    else inReduction;

  end matchcontinue;
end simplifyReduction;

protected function getIteratorValues
  input DAE.ReductionIterator iter;
  input list<DAE.Exp> inValues;
  output list<DAE.Exp> values;
protected
  String iter_name;
  DAE.Exp range;
algorithm
  DAE.REDUCTIONITER(id = iter_name, guardExp = NONE(), exp = range) := iter;
  values := Expression.getArrayOrRangeContents(range);
  values := List.threadMap1(values, inValues, replaceIteratorWithExp, iter_name);
end getIteratorValues;

protected function replaceIteratorWithExp
  input DAE.Exp iterExp;
  input DAE.Exp exp;
  input String name;
  output DAE.Exp outExp;
algorithm
  (outExp,(_,_,true)) := Expression.traverseExpBottomUp(exp, replaceIteratorWithExpTraverser, (name,iterExp,true));
end replaceIteratorWithExp;

protected function replaceIteratorWithExpTraverser
  input DAE.Exp inExp;
  input tuple<String,DAE.Exp,Boolean> inTpl;
  output DAE.Exp outExp;
  output tuple<String,DAE.Exp,Boolean> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      String id,id2,name,replName;
      DAE.Exp iterExp;
      DAE.Type ty,ty1,ty2;
      list<DAE.Subscript> ss;
      Boolean b;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      tuple<String,DAE.Exp,Boolean> tpl;
      Absyn.Path callPath,recordPath;
      list<DAE.Var> varLst;
      list<DAE.Exp> exps;
      Integer i;
    case (_,(_,_,false)) then (inExp,inTpl);
    case (DAE.CREF(DAE.CREF_IDENT(id,_,{}),_),tpl as (name,iterExp,_))
      equation
        true = stringEq(name,id);
      then (iterExp,tpl);
    case (exp as DAE.CREF(componentRef=DAE.CREF_IDENT(ident=id)),(name,iterExp,_))
      equation
        true = stringEq(name,id);
      then (exp,(name,iterExp,false));
    case (DAE.CREF(DAE.CREF_QUAL(id,ty1,ss,cr),ty),tpl as (name,DAE.CREF(componentRef=DAE.CREF_IDENT(ident=replName,subscriptLst={})),_))
      equation
        true = stringEq(name,id);
        exp = DAE.CREF(DAE.CREF_QUAL(replName,ty1,ss,cr),ty);
      then (exp,tpl);
    case (DAE.CREF(DAE.CREF_QUAL(id,ty1,{},cr),ty),tpl as (name,DAE.CREF(componentRef=DAE.CREF_IDENT(ident=replName,subscriptLst=ss)),_))
      equation
        true = stringEq(name,id);
        exp = DAE.CREF(DAE.CREF_QUAL(replName,ty1,ss,cr),ty);
      then (exp,tpl);
    case (DAE.CREF(componentRef=DAE.CREF_QUAL(id,_,{},DAE.CREF_IDENT(id2,_,{}))),tpl as (name,DAE.CALL(expLst=exps,path=callPath,attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(recordPath)))),_))
      equation
        true = stringEq(name,id);
        true = Absyn.pathEqual(callPath,recordPath);
        true = listLength(varLst) == listLength(exps);
        i = List.position1OnTrue(varLst,DAEUtil.typeVarIdentEqual,id2);
        exp = listGet(exps,i);
      then (exp,tpl);
    case (exp as DAE.CREF(componentRef=DAE.CREF_QUAL(ident=id)),(name,iterExp,_))
      equation
        true = stringEq(name,id);
      then (exp,(name,iterExp,false));
    else (inExp,inTpl);
  end matchcontinue;
end replaceIteratorWithExpTraverser;

protected function simplifyReductionFoldPhase
  input Absyn.Path path;
  input Option<DAE.Exp> optFoldExp;
  input String foldName,resultName;
  input DAE.Type ty;
  input list<DAE.Exp> inExps;
  input Option<Values.Value> defaultValue;
  output DAE.Exp exp;
algorithm
  exp := match (path,optFoldExp,foldName,resultName,ty,inExps,defaultValue)
    local
      Values.Value val;
      DAE.Exp arr_exp,foldExp;
      DAE.Type aty,ty2;
      list<DAE.Exp> exps;
      Integer length;

    case (Absyn.IDENT("array"),_,_,_,_,_,_)
      equation
        aty = Types.unliftArray(Types.expTypetoTypesType(ty));
        length = listLength(inExps);
        ty2 = Types.liftArray(aty, DAE.DIM_INTEGER(length)); // The size can be unknown before the reduction...
        exp = Expression.makeArray(inExps, ty2, not Types.isArray(aty));
      then exp;

    case (_,_,_,_,_,{},SOME(val)) then ValuesUtil.valueExp(val);
    case (_,_,_,_,_,{},NONE()) then fail();

    case (Absyn.IDENT("min"),_,_,_,_,_,_)
      equation
        arr_exp = Expression.makeScalarArray(inExps, ty);
      then Expression.makePureBuiltinCall("min", {arr_exp}, ty);

    case (Absyn.IDENT("max"),_,_,_,_,_,_)
      equation
        arr_exp = Expression.makeScalarArray(inExps, ty);
      then Expression.makePureBuiltinCall("max", {arr_exp}, ty);

    case (_,SOME(_),_,_,_,{exp},_)
      then exp;


    // foldExp=(a+b) ; exps={1,2,3,4}
    // step 1: result=4
    // step 2: result= (replace b in (a+b) with 4, a with 3): 3+4
    // ...
    // Why reverse order? Smaller expressions to perform the replacements in
    case (_,SOME(foldExp),_,_,_,exp::exps,_)
      equation
        exp = simplifyReductionFoldPhase2(exps,foldExp,foldName,resultName,exp);
      then exp;

  end match;
end simplifyReductionFoldPhase;

protected function simplifyReductionFoldPhase2
  input list<DAE.Exp> inExps;
  input DAE.Exp foldExp;
  input String foldName,resultName;
  input DAE.Exp acc;
  output DAE.Exp exp;
algorithm
  exp := match (inExps,foldExp,foldName,resultName,acc)
    local
      list<DAE.Exp> exps;

    case ({},_,_,_,_) then acc;
    case (exp::exps,_,_,_,_)
      equation
        exp = replaceIteratorWithExp(exp, foldExp, foldName);
        exp = replaceIteratorWithExp(acc, exp, resultName);
      then simplifyReductionFoldPhase2(exps,foldExp,foldName,resultName,exp);

  end match;
end simplifyReductionFoldPhase2;

protected function hasZeroLengthIterator
  input list<DAE.ReductionIterator> inIters;
  output Boolean b;
algorithm
  b := match inIters
    local list<DAE.ReductionIterator> iters;
    case {} then false;
    case DAE.REDUCTIONITER(guardExp=SOME(DAE.BCONST(false)))::_ then true;
    case DAE.REDUCTIONITER(exp=DAE.LIST({}))::_ then true;
    case DAE.REDUCTIONITER(exp=DAE.ARRAY(array={}))::_ then true;
    case _::iters then hasZeroLengthIterator(iters);
  end match;
end hasZeroLengthIterator;

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

public function simplifyList1
  input list<DAE.Exp> expl;
  input list<DAE.Exp> acc;
  input list<Boolean> accb;
  output list<DAE.Exp> outExpl;
  output list<Boolean> outBool;
algorithm
  (outExpl,outBool) := match (expl,acc,accb)
    local
      DAE.Exp exp;
      Boolean b;
      list<DAE.Exp> rest_expl;
    case ({},_,_) then (listReverse(acc),listReverse(accb));
    case (exp::rest_expl,_,_)
      equation
        (exp,b) = simplify1(exp);
        (outExpl,outBool) = simplifyList1(rest_expl,exp::acc,b::accb);
      then
        (outExpl,outBool);
  end match;
end simplifyList1;

public function condsimplifyList1
  input list<Boolean> blst;
  input list<DAE.Exp> expl;
  input list<DAE.Exp> acc;
  input list<Boolean> accb;
  output list<DAE.Exp> outExpl;
  output list<Boolean> outBool;
algorithm
  (outExpl,outBool) := match (blst,expl,acc,accb)
    local
      DAE.Exp exp;
      Boolean b;
      list<Boolean> rest_blst;
      list<DAE.Exp> rest_expl;
    case ({},_,_,_) then (listReverse(acc),listReverse(accb));
    case (b::rest_blst,exp::rest_expl,_,_)
      equation
        (exp,b) = condsimplify(b,exp);
        (outExpl,outBool) = condsimplifyList1(rest_blst,rest_expl,exp::acc,b::accb);
      then
        (outExpl,outBool);
  end match;
end condsimplifyList1;

protected function checkZeroLengthArrayOp
  "If this succeeds, and either argument to the operation is empty, the whole operation is empty"
  input DAE.Operator op;
algorithm
  _ := match op
    case DAE.ADD_ARR() then ();
    case DAE.SUB_ARR() then ();
    case DAE.MUL_ARR() then ();
    case DAE.DIV_ARR() then ();
    case DAE.POW_ARR() then ();
    case DAE.POW_ARR2() then ();
    case DAE.MUL_ARRAY_SCALAR() then ();
    case DAE.ADD_ARRAY_SCALAR() then ();
    case DAE.DIV_ARRAY_SCALAR() then ();
    case DAE.SUB_SCALAR_ARRAY() then ();
    case DAE.DIV_SCALAR_ARRAY() then ();
    case DAE.MUL_MATRIX_PRODUCT() then ();
  end match;
end checkZeroLengthArrayOp;

public function simplifyAddSymbolicOperation
  input DAE.EquationExp exp;
  input DAE.ElementSource source;
  output DAE.EquationExp outExp;
  output DAE.ElementSource outSource;
algorithm
  (outExp,outSource) := match (exp,source)
    local
      Boolean changed,changed1,changed2;
      DAE.Exp e,e1,e2;
    case (DAE.PARTIAL_EQUATION(e),_)
      equation
        (e,changed) = simplify(e);
        outExp = if changed then DAE.PARTIAL_EQUATION(e) else exp;
        outSource = DAEUtil.condAddSymbolicTransformation(changed,source,DAE.SIMPLIFY(exp,outExp));
      then (outExp,outSource);
    case (DAE.RESIDUAL_EXP(e),_)
      equation
        (e,changed) = simplify(e);
        outExp = if changed then DAE.RESIDUAL_EXP(e) else exp;
        outSource = DAEUtil.condAddSymbolicTransformation(changed,source,DAE.SIMPLIFY(exp,outExp));
      then (outExp,outSource);
    case (DAE.EQUALITY_EXPS(e1,e2),_)
      equation
        (e1,changed1) = simplify(e1);
        (e2,changed2) = simplify(e2);
        changed = changed1 or changed2;
        outExp = if changed then DAE.EQUALITY_EXPS(e1,e2) else exp;
        outSource = DAEUtil.condAddSymbolicTransformation(changed,source,DAE.SIMPLIFY(exp,outExp));
      then (outExp,outSource);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"ExpressionSimplify.simplifyAddSymbolicOperation failed"});
      then fail();
  end match;
end simplifyAddSymbolicOperation;

public function condSimplifyAddSymbolicOperation
  input Boolean cond;
  input DAE.EquationExp exp;
  input DAE.ElementSource source;
  output DAE.EquationExp outExp;
  output DAE.ElementSource outSource;
algorithm
  (outExp,outSource) := match (cond,exp,source)
    case (true,_,_)
      equation
        (outExp,outSource) = simplifyAddSymbolicOperation(exp,source);
      then (outExp,outSource);
    else (exp,source);
  end match;
end condSimplifyAddSymbolicOperation;

protected function simplifySize
  input DAE.Exp origExp;
  input DAE.Exp exp;
  input Option<DAE.Exp> optDim;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (origExp,exp,optDim)
    local
      Integer i,n;
      DAE.Type t;
      DAE.Dimensions dims;
      DAE.Dimension dim;
      DAE.Exp dimExp;

    // simplify size operator
    case (_,_,SOME(dimExp))
      equation
        i = Expression.expInt(dimExp);
        t = Expression.typeof(exp);
        dims = Expression.arrayDimension(t);
        dim = listGet(dims,i);
        n = Expression.dimensionSize(dim);
      then DAE.ICONST(n);
    // TODO: Handle optDim=NONE() when dims are known
    else origExp;
  end matchcontinue;
end simplifySize;

protected function simplifyTSub
  input DAE.Exp origExp;
  output DAE.Exp outExp;
algorithm
  outExp := match origExp
    local
      list<DAE.Exp> expl;
      Integer i;
      DAE.Exp e;

    // NOTE: It should be impossible for TSUB to use an index that becomes out of range, so match is correct here...
    case DAE.TSUB(exp = DAE.CAST(exp = DAE.TUPLE(PR = expl)), ix = i)
      then listGet(expl, i);
    case DAE.TSUB(exp = DAE.TUPLE(PR = expl), ix = i)
      then listGet(expl, i);
    case DAE.TSUB(exp= e as (DAE.RCONST())) then e;
    else origExp;
  end match;
end simplifyTSub;

protected function simplifyNoEvent "Adds noEvent() only to required subexpressions"
  input DAE.Exp inExp;
  output DAE.Exp e;
algorithm
  e := Expression.addNoEventToEventTriggeringFunctions(Expression.addNoEventToRelations(Expression.stripNoEvent(inExp)));
end simplifyNoEvent;

protected function maxElement
  input DAE.Exp e1;
  input Option<DAE.Exp> e2;
  output Option<DAE.Exp> elt;
algorithm
  elt := match (e1,e2)
    local
      Real r1,r2;
      Integer i1,i2;
      Boolean b1,b2;
    case (DAE.RCONST(_),NONE()) then SOME(e1);
    case (DAE.ICONST(_),NONE()) then SOME(e1);
    case (DAE.BCONST(_),NONE()) then SOME(e1);
    case (DAE.RCONST(r1),SOME(DAE.RCONST(r2))) equation r1=realMax(r1,r2); then SOME(DAE.RCONST(r1));
    case (DAE.ICONST(i1),SOME(DAE.ICONST(i2))) equation i1=intMax(i1,i2); then SOME(DAE.ICONST(i1));
    case (DAE.BCONST(b1),SOME(DAE.BCONST(b2))) equation b1= b1 or b2; then SOME(DAE.BCONST(b1));
    else e2;
  end match;
end maxElement;

protected function minElement
  input DAE.Exp e1;
  input Option<DAE.Exp> e2;
  output Option<DAE.Exp> elt;
algorithm
  elt := match (e1,e2)
    local
      Real r1,r2;
      Integer i1,i2;
      Boolean b1,b2;
    case (DAE.RCONST(_),NONE()) then SOME(e1);
    case (DAE.ICONST(_),NONE()) then SOME(e1);
    case (DAE.BCONST(_),NONE()) then SOME(e1);
    case (DAE.RCONST(r1),SOME(DAE.RCONST(r2))) equation r1=realMin(r1,r2); then SOME(DAE.RCONST(r1));
    case (DAE.ICONST(i1),SOME(DAE.ICONST(i2))) equation i1=intMin(i1,i2); then SOME(DAE.ICONST(i1));
    case (DAE.BCONST(b1),SOME(DAE.BCONST(b2))) equation b1= b1 and b2; then SOME(DAE.BCONST(b1));
    else e2;
  end match;
end minElement;

protected function removeMinMaxFoldableValues
  input DAE.Exp e;
  output Boolean filter;
algorithm
  filter := match e
    case DAE.RCONST(_) then false;
    case DAE.ICONST(_) then false;
    case DAE.BCONST(_) then false;
    else true;
  end match;
end removeMinMaxFoldableValues;

public function simplifySkew
  "Simplifies the skew operator."
  input list<DAE.Exp> v1;
  output list<list<DAE.Exp>> res;
protected
  DAE.Exp x1, x2, x3, zero;
algorithm
  {x1, x2, x3} := v1;
  zero := Expression.makeConstZero(Expression.typeof(x1));

  res := {{zero, Expression.negate(x3), x2},
          {x3, zero, Expression.negate(x1)},
          {Expression.negate(x2), x1, zero}};
end simplifySkew;

public function simplifyCross
  "Simplifies the cross operator."
  input list<DAE.Exp> v1;
  input list<DAE.Exp> v2;
  output list<DAE.Exp> res;
protected
  DAE.Exp x1, x2, x3, y1, y2, y3;
algorithm
  {x1, x2, x3} := v1;
  {y1, y2, y3} := v2;

  // res = {x[2]*y[3] - x[3]*y[2], x[3]*y[1] - x[1]*y[3], x[1]*y[2] - x[2]*y[1]}
  res := {Expression.makeDiff(Expression.makeProduct(x2, y3), Expression.makeProduct(x3, y2)),
          Expression.makeDiff(Expression.makeProduct(x3, y1), Expression.makeProduct(x1, y3)),
          Expression.makeDiff(Expression.makeProduct(x1, y2), Expression.makeProduct(x2, y1))};
end simplifyCross;

annotation(__OpenModelica_Interface="frontend");
end ExpressionSimplify;
