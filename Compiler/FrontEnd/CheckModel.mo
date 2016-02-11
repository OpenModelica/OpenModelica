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

encapsulated package CheckModel "
  file:        CheckModel.mo
  package:     CheckModel
  description: Check the Model.

"

public import Absyn;
public import DAE;

protected import BaseHashSet;
protected import ClassInf;
protected import ConnectUtil;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import Flags;
protected import HashSet;
protected import List;
protected import Util;
protected import Error;

public function checkModel "This function perform a model check. Count Variables and equations and
  detect the simple equations."
  input DAE.DAElist inDAELst;
  output Integer varSize;
  output Integer eqnSize;
  output Integer simpleEqnSize;
protected
  list<DAE.Element> eqns, lst;
  HashSet.HashSet hs;
algorithm
  DAE.DAE(lst) := inDAELst;
  hs := HashSet.emptyHashSet();
  (varSize, eqnSize, eqns, hs) := List.fold(lst, countVarEqnSize, (0, 0, {}, hs));
  simpleEqnSize := countSimpleEqnSize(eqns, 0, hs);
end checkModel;

protected type CountVarEqnFoldArg =
  tuple<Integer/*varSize*/, Integer/*eqnSize*/, list<DAE.Element>/*eqns*/, HashSet.HashSet/*vars*/>;

protected function countVarEqnSize
  input DAE.Element inElt;
  input CountVarEqnFoldArg inArg;
  output CountVarEqnFoldArg outAtg;
algorithm
  outAtg := match inElt
    local
      Boolean b;
      DAE.Exp e, ce;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.ConnectorType ct;
      DAE.VarDirection dir;
      Integer varSize, eqnSize, size;
      list<DAE.Element> eqns, daeElts;
      HashSet.HashSet hs;
      DAE.Dimensions dims;
      DAE.Algorithm alg;
      list<DAE.ComponentRef> crlst;
      DAE.Type tp;

    // external Objects
    case DAE.EXTOBJECTCLASS()
      then inArg;

    // external Variables
    case DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()))
      then inArg;

    // variable Variables with binding
    case DAE.VAR(componentRef=cr, kind = DAE.VARIABLE(), direction=dir, connectorType = ct, binding=SOME(e), source=source)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        b = DAEUtil.topLevelInput(cr, dir, ct);
        ce = Expression.crefExp(cr);
        size = if b then 0 else 1;
        eqns = List.consOnTrue(not b, DAE.EQUATION(ce, e, source), eqns);
        hs = if not b then BaseHashSet.add(cr, hs) else hs;
      then (varSize+size, eqnSize+size, eqns, hs);

    // discrete Variables with binding
    case DAE.VAR(componentRef=cr, kind = DAE.DISCRETE(), direction=dir, connectorType = ct, binding=SOME(e), source=source)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        b = DAEUtil.topLevelInput(cr, dir, ct);
        ce = Expression.crefExp(cr);
        size = if b then 0 else 1;
        eqns = List.consOnTrue(not b, DAE.EQUATION(ce, e, source), eqns);
        hs = if not b then BaseHashSet.add(cr, hs) else hs;
      then (varSize+size, eqnSize+size, eqns, hs);

    // variable Variables
    case DAE.VAR(componentRef=cr, kind = DAE.VARIABLE(), direction=dir, connectorType = ct)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        b = DAEUtil.topLevelInput(cr, dir, ct);
        size = if b then 0 else 1;
        hs = if not b then BaseHashSet.add(cr, hs) else hs;
      then (varSize+size, eqnSize, eqns, hs);

    // discrete Variables
    case DAE.VAR(componentRef=cr, kind = DAE.DISCRETE(), direction=dir, connectorType = ct)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        b = DAEUtil.topLevelInput(cr, dir, ct);
        size = if b then 0 else 1;
        hs = if not b then BaseHashSet.add(cr, hs) else hs;
      then (varSize+size, eqnSize, eqns, hs);

    // parameter Variables
    case DAE.VAR(kind = DAE.PARAM())
      then inArg;

    // constant Variables
    case DAE.VAR(kind = DAE.CONST())
      then inArg;

    // equations
    case DAE.EQUATION(exp=e)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        size = Expression.sizeOf(Expression.typeof(e));
      then (varSize, eqnSize+size, inElt::eqns, hs);

    // initial equations
    case DAE.INITIALEQUATION()
      then inArg;

    // effort variable equality equations
    case DAE.EQUEQUATION(cr1 = cr)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        tp = ComponentReference.crefTypeConsiderSubs(cr);
        size = Expression.sizeOf(tp);
      then (varSize, eqnSize+size, inElt::eqns, hs);

    // a solved equation
    case DAE.DEFINE(componentRef = cr)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        tp = ComponentReference.crefTypeConsiderSubs(cr);
        size = Expression.sizeOf(tp);
      then (varSize, eqnSize+size, inElt::eqns, hs);

    // complex equations
    case DAE.COMPLEX_EQUATION(lhs = e)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        size = Expression.sizeOf(Expression.typeof(e));
      then (varSize, eqnSize+size, inElt::eqns, hs);

    // complex initial equations
    case DAE.INITIAL_COMPLEX_EQUATION()
      then inArg;

    // array equations
    case DAE.ARRAY_EQUATION(dimension=dims)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        size =  List.fold(Expression.dimensionsSizes(dims), intMul, 1);
      then (varSize, eqnSize+size, inElt::eqns, hs);

    // initial array equations
    case DAE.INITIAL_ARRAY_EQUATION()
      then inArg;

    // when equations
    case DAE.WHEN_EQUATION(equations = daeElts)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        (_, size, _, _) = List.fold(daeElts, countVarEqnSize, (0, 0, {}, hs));
      then (varSize, eqnSize+size, eqns, hs);

    // if equation with condition false and no else
    case DAE.IF_EQUATION(condition1 = {DAE.BCONST(false)}, equations3 = {})
       then inArg;

    // if equation that cannot be translated to if expression but have initial() as condition
    case DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))})
      then inArg;

    // if equation
    case DAE.IF_EQUATION(equations2 = daeElts::_)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        (_, size, _, _) = List.fold(daeElts, countVarEqnSize, (0, 0, {}, hs));
      then (varSize, eqnSize+size, eqns, hs);

    // initial if equation with condition false and no else
    case DAE.INITIAL_IF_EQUATION(condition1 = {DAE.BCONST(false)}, equations3 = {})
      then inArg;

    // initial if equation
    case DAE.INITIAL_IF_EQUATION()
      then inArg;

    // algorithm
    case DAE.ALGORITHM(algorithm_ = alg, source = source)
      equation
        (varSize, eqnSize, eqns, hs) = inArg;
        crlst = checkAndGetAlgorithmOutputs(alg, source, DAE.EXPAND());
        size = listLength(crlst);
      then
        (varSize, eqnSize+size, eqns, hs);

    // initial algorithm
    case DAE.INITIALALGORITHM()
      then inArg;

    // flat class / COMP
    case DAE.COMP(dAElist = daeElts)
      then List.fold(daeElts, countVarEqnSize, inArg);

    // reinit
    case DAE.REINIT()
      then inArg;

    // assert in equation
    case DAE.ASSERT()
      then inArg;

    // terminate in equation section is converted to ALGORITHM
    case DAE.TERMINATE()
      then inArg;

    case DAE.NORETCALL()
      then inArg;

    case DAE.INITIAL_NORETCALL()
      then inArg;

    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case DAE.CONSTRAINT()
      then inArg;

    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CheckModel.countVarEqnSize failed on: " + DAEDump.dumpElementsStr({inElt}));
      then
        fail();
  end match;
end countVarEqnSize;

public function checkAndGetAlgorithmOutputs
"mahge:
counts the ouputs of algorithms depending on where the
section came from. If the algorithm section came from a scalar
component the it is counted acorrding to the inCrefExpansionRule.
However in some cases where algorithms come from a member of an array
of components expanding arrays and counting them as full in every
algorithm secion will cause duplicate countings.
See spec 3.3 Modelica spec 3.3 rev 11.1.2 and ticket 2452
"
  input DAE.Algorithm inAlgorithm;
  input DAE.ElementSource inSource;
  input DAE.Expand inCrefExpansionRule;
  output list<DAE.ComponentRef> outCrefLst;
algorithm
  outCrefLst := matchcontinue(inAlgorithm, inSource, inCrefExpansionRule)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefLst;

    case (_, DAE.SOURCE(instanceOpt = NONE()), _)
      then algorithmOutputs(inAlgorithm, inCrefExpansionRule);

    // the algorithm came from a component that is member of an array or not
    case (_, DAE.SOURCE(instanceOpt = SOME(cr)), _)
      then
        if ComponentReference.crefHaveSubs(cr)
        then algorithmOutputs(inAlgorithm, DAE.NOT_EXPAND())
        else algorithmOutputs(inAlgorithm, inCrefExpansionRule);

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"checkAndGetAlgorithmOutputs failed."});
      then fail();
  end matchcontinue;
end checkAndGetAlgorithmOutputs;

protected function algorithmOutputs "This function finds the the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm. If a variable is an
  input and an output it will be treated as an output."
  input DAE.Algorithm inAlgorithm;
  input DAE.Expand inCrefExpansion "expand array to full dimension?";
  output list<DAE.ComponentRef> outCrefLst;
protected
  list<DAE.Statement> stmts;
algorithm
  DAE.ALGORITHM_STMTS(statementLst=stmts) := inAlgorithm;
  outCrefLst := algorithmStatementListOutputs(stmts, inCrefExpansion);
end algorithmOutputs;

public function algorithmStatementListOutputs "This function finds the the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm. If a variable is an
  input and an output it will be treated as an output."
  input list<DAE.Statement> inStmts;
  input DAE.Expand inCrefExpansion "expand array to full dimension?";
  output list<DAE.ComponentRef> outCrefLst;
protected
  HashSet.HashSet hs;
algorithm
  hs := HashSet.emptyHashSet();
  hs := List.fold1(inStmts, statementOutputs, inCrefExpansion, hs);
  outCrefLst := BaseHashSet.hashSetList(hs);
end algorithmStatementListOutputs;

protected function statementOutputs "Helper relation to algorithmOutputs"
  input DAE.Statement inStatement;
  input DAE.Expand inCrefExpansion "expand array to full dimension?";
  input  HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := matchcontinue (inStatement, inCrefExpansion, iht)
    local
      HashSet.HashSet ht;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      DAE.Exp e, exp1;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      DAE.Else elsebranch;
      list<DAE.Exp> expl;
      DAE.Type tp;
      DAE.Ident iteratorName;
      String str;
      DAE.Ident ident;
      list<DAE.Subscript> subs;

    // a := expr;
    case (DAE.STMT_ASSIGN(exp1 = exp1), _, _)
      equation
        (_, (_, ht)) = Expression.traverseExpTopDown(exp1, statementOutputsCrefFinder, (inCrefExpansion, iht));
      then ht;

    // (a, b, ...) := expr;
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl), _, _)
      equation
        (_, (_, ht)) = Expression.traverseExpListTopDown(expl, statementOutputsCrefFinder, (inCrefExpansion, iht));
      then ht;

    // a := expr;  // where a is array
    case (DAE.STMT_ASSIGN_ARR(lhs=exp1), _, _)
      equation
        // (_, (_, ht)) = Expression.traverseExpTopDown(exp1, statementOutputsCrefFinder, (inCrefExpansion, iht));
        cr = Expression.expCref(exp1);
        subs = ComponentReference.crefLastSubs(cr);
        if not listEmpty(subs) // not an empty subs list
        then
          subs = List.fill(DAE.WHOLEDIM(), listLength(subs));
          cr = ComponentReference.crefSetLastSubs(cr, subs);
        end if;
        crlst = ComponentReference.expandCref(cr, true);
        ht = List.fold(crlst, BaseHashSet.add, iht);
      then ht;

    case(DAE.STMT_IF(statementLst = stmts, else_ = elsebranch), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
        ht = statementElseOutputs(elsebranch, inCrefExpansion, ht);
      then ht;

    case(DAE.STMT_FOR(type_=tp, iter = iteratorName, range = e, statementLst = stmts), _, _)
      equation
        // replace the iterator variable with the range expression
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        (stmts, _) = DAEUtil.traverseDAEEquationsStmts(stmts, Expression.traverseSubexpressionsHelper, (Expression.replaceCref, (cr, e)));
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;

    case(DAE.STMT_PARFOR(type_=tp, iter = iteratorName, range = e, statementLst = stmts), _, _)
      equation
        // replace the iterator variable with the range expression
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        (stmts, _) = DAEUtil.traverseDAEEquationsStmts(stmts, Expression.traverseSubexpressionsHelper, (Expression.replaceCref, (cr, e)));
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;

    case(DAE.STMT_WHILE(statementLst = stmts), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;

    case (DAE.STMT_WHEN(statementLst = stmts, elseWhen = NONE()), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;

    case (DAE.STMT_WHEN(statementLst = stmts, elseWhen = SOME(stmt)), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
        ht = statementOutputs(stmt, inCrefExpansion, ht);
      then ht;

    case(DAE.STMT_ASSERT(), _, _) then iht;
    case(DAE.STMT_TERMINATE(), _, _) then iht;

    // reinit is not a output
    case(DAE.STMT_REINIT(), _, _) then iht;
    case(DAE.STMT_NORETCALL(), _, _) then iht;
    case(DAE.STMT_RETURN(_), _, _) then iht;
    case(DAE.STMT_BREAK(_), _, _) then iht;
    case(DAE.STMT_CONTINUE(_), _, _) then iht;
    case(DAE.STMT_ARRAY_INIT(), _, _) then iht;
    // MetaModelica extension. KS
    case(DAE.STMT_FAILURE(body = stmts), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = DAEDump.ppStatementStr(inStatement);
        Debug.traceln("- CheckModel.statementOutputs failed for " + str);
    then
      fail();

  end matchcontinue;
end statementOutputs;

protected function statementElseOutputs "Helper function to statementOutputs"
  input DAE.Else inElseBranch;
  input DAE.Expand inCrefExpansion "expand array to full dimension?";
  input HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := match (inElseBranch, inCrefExpansion, iht)
    local
      list<DAE.Statement> stmts;
      DAE.Else elseBranch;
      HashSet.HashSet ht;

    case(DAE.NOELSE(), _, _) then iht;

    case(DAE.ELSEIF(statementLst=stmts, else_=elseBranch), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
        ht = statementElseOutputs(elseBranch, inCrefExpansion, ht);
      then ht;

    case(DAE.ELSE(statementLst=stmts), _, _)
      equation
        ht = List.fold1(stmts, statementOutputs, inCrefExpansion, iht);
      then ht;
  end match;
end statementElseOutputs;

protected function statementOutputsCrefFinder "author: Frenkel TUD 2012-06"
  input DAE.Exp inExp;
  input tuple<DAE.Expand, HashSet.HashSet> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.Expand, HashSet.HashSet> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp,inTpl)
    local
      DAE.Exp e, exp, e1, e2;
      HashSet.HashSet ht;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      list<DAE.Subscript> subs;
      DAE.Expand expand;

    // Skip wild
    case (e as DAE.CREF(componentRef=DAE.WILD()), (expand,ht))
      then (e, false, (expand,ht));

    // Skip time
    case (e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time", subscriptLst={})), (expand,ht))
      then (e, false, (expand,ht));

    // Skip external Objects
    case (e as DAE.CREF(ty=DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ())), (expand,ht))
      then (e, false, (expand,ht));

    // NOT_EXPAND strategy (needed for equations translated to algorithms)
    case (e as DAE.CREF(componentRef=cr), (expand as DAE.NOT_EXPAND(),ht))
      equation
        ht = List.fold({cr}, BaseHashSet.add, ht);
      then (e, false, (expand,ht));

    // EXPAND
    /* mahge:
      Modelica spec 3.3 rev 11.1.2
      "If at least one element of an array appears on the left hand side of the assignment operator, then the
       complete array is initialized in this algorithm section"
      So we strip the subs and send the whole array to expansion. i.e. we consider the whole array as modified.
    */
    case (e as DAE.CREF(componentRef=cr), (expand,ht))
      equation
        cr = ComponentReference.crefStripSubs(cr);
        crlst = ComponentReference.expandCref(cr, true);
        ht = List.fold(crlst, BaseHashSet.add, ht);
      then (e, false, (expand,ht));

    case (e as DAE.ASUB(exp=exp), (expand,ht))
      equation
        (_, (expand,ht)) = Expression.traverseExpTopDown(exp, statementOutputsCrefFinder, (expand,ht));
      then (e, false, (expand,ht));

    case (e as DAE.TSUB(exp=exp), (expand,ht))
      equation
        (_, (expand,ht)) = Expression.traverseExpTopDown(exp, statementOutputsCrefFinder, (expand,ht));
      then (e, false, (expand,ht));

    case (e as DAE.RELATION(), (expand,ht))
      then (e, false, (expand,ht));

    case (e as DAE.RANGE(), (expand,ht))
      then (e, false, (expand,ht));

    case (e as DAE.IFEXP(expThen=e1, expElse=e2), (expand,ht))
      equation
        (_, (expand,ht)) = Expression.traverseExpTopDown(e1, statementOutputsCrefFinder, (expand,ht));
        (_, (expand,ht)) = Expression.traverseExpTopDown(e2, statementOutputsCrefFinder, (expand,ht));
      then (e, false, (expand,ht));

    case (e, (expand,ht)) then (e, true, (expand,ht));

  end matchcontinue;
end statementOutputsCrefFinder;

protected function countSimpleEqnSize
  input list<DAE.Element> inEqns;
  input Integer isimpleEqnSize;
  input HashSet.HashSet ihs;
  output Integer osimpleEqnSize;
algorithm
  osimpleEqnSize := List.fold(List.map1(inEqns, countSimpleEqnSizeWork, ihs), intAdd, 0);
end countSimpleEqnSize;

protected function countSimpleEqnSizeWork
  input DAE.Element inEqns;
  input HashSet.HashSet ihs;
  output Integer osimpleEqnSize;
algorithm
  osimpleEqnSize := matchcontinue(inEqns, ihs)
    local
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      DAE.Type tp;
      Integer size;
      DAE.Dimensions dims;

    // equations
    case(DAE.EQUATION(exp=e1, scalar=e2), _)
      then simpleEquation(e1, e2, ihs);

    // effort variable equality equations
    case (DAE.EQUEQUATION(cr1 = cr), _)
      equation
        tp = ComponentReference.crefTypeConsiderSubs(cr);
      then Expression.sizeOf(tp);

    // a solved equation
    case (DAE.DEFINE(componentRef = cr, exp=e2), _)
      equation
        e1 = Expression.crefExp(cr);
      then simpleEquation(e1, e2, ihs);

    // complex equations
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2), _)
      then simpleEquation(e1, e2, ihs);

    // array equations
    case (DAE.ARRAY_EQUATION(exp = e1, array = e2), _)
      then simpleEquation(e1, e2, ihs);

    else 0;
  end matchcontinue;
end countSimpleEqnSizeWork;

protected function simpleEquation
  input DAE.Exp e1;
  input DAE.Exp e2;
  input HashSet.HashSet ihs;
  output Integer osimpleEqnSize;
algorithm
  osimpleEqnSize := matchcontinue(e1, e2, ihs)
    local
      list<DAE.Exp> ea1, ea2;
    // a = b;
    case (DAE.CREF(), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a = -b;
    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a + b = 0
    case (DAE.BINARY(DAE.CREF(), DAE.ADD(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.CREF(), DAE.ADD_ARR(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a - b = 0
    case (DAE.BINARY(DAE.CREF(), DAE.SUB(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.CREF(), DAE.SUB_ARR(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a + b = 0
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.ADD(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.ADD_ARR(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a - b = 0
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.SUB(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.SUB_ARR(), DAE.CREF()), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a + b
    case (_, DAE.BINARY(DAE.CREF(), DAE.ADD(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.CREF(), DAE.ADD_ARR(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a - b
    case (_, DAE.BINARY(DAE.CREF(), DAE.SUB(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.CREF(), DAE.SUB_ARR(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a + b
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.ADD(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.ADD_ARR(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a - b
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.SUB(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.SUB_ARR(), DAE.CREF()), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a = der(b);
    case (DAE.CREF(), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // a = -der(b);
    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -der(a) = b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), DAE.CREF(), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // -a = der(b);
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = -b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()}), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // -a = -der(b);
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -der(a) = -b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF()})), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _)
      then
        Expression.sizeOf(Expression.typeof(e2));

    // a = const;
    case (DAE.CREF(), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // const = a;
    case (_, DAE.CREF(), _)
      equation
        true = Expression.isConst(e1);
      then
        Expression.sizeOf(Expression.typeof(e2));

    // -a = const;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // const = -a;
    case (_, DAE.UNARY(DAE.UMINUS(_), DAE.CREF()), _)
      equation
        true = Expression.isConst(e1);
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (_, DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF()), _)
      equation
        true = Expression.isConst(e1);
      then
        Expression.sizeOf(Expression.typeof(e2));

    case(_, _, _)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then
        simpleEquations(ea1, ea2, 0, ihs);

    case(_, _, _)
      equation
        (_, (_, _::{})) = Expression.traverseExpBottomUp(Expression.expSub(e1, e2), traversingComponentRefFinder, (ihs, {}));
      then
        Expression.sizeOf(Expression.typeof(e1));

    else
      then
        0;
  end matchcontinue;
end simpleEquation;

protected function traversingComponentRefFinder
  input DAE.Exp inExp;
  input tuple<HashSet.HashSet, list<DAE.ComponentRef>> inTpl;
  output DAE.Exp outExp;
  output tuple<HashSet.HashSet, list<DAE.ComponentRef>> outTpl;
algorithm
  (outExp,outTpl) := matchcontinue (inExp,inTpl)
    local
      HashSet.HashSet hs;
      list<DAE.ComponentRef> crefs, crlst;
      DAE.ComponentRef cr;
      DAE.Exp e;

    case (DAE.CREF(componentRef = DAE.WILD()), (_, _))
      then (inExp,inTpl);

    case (e as DAE.CREF(componentRef=cr), (hs, crefs))
      equation
        crlst = ComponentReference.expandCref(cr, true);
        crefs = getcr(crlst, hs, crefs);
      then (e, (hs, crefs));

    else (inExp,inTpl);

  end matchcontinue;
end traversingComponentRefFinder;

protected function getcr
  input list<DAE.ComponentRef> crefs;
  input HashSet.HashSet hs;
  input list<DAE.ComponentRef> iAcc;
  output list<DAE.ComponentRef> oAcc;
algorithm
  oAcc := match(crefs, hs, iAcc)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> rest, crlst;
    case ({}, _, _) then iAcc;
    case(cr::rest, _, _)
      equation
        _ = BaseHashSet.get(cr, hs);
        crlst = List.unionEltOnTrue(cr, iAcc, ComponentReference.crefEqual);
      then
        getcr(rest, hs, crlst);
    case(_::rest, _, _)
      then
        getcr(rest, hs, iAcc);
  end match;
end getcr;

protected function simpleEquations
  input list<DAE.Exp> e1lst;
  input list<DAE.Exp> e2lst;
  input Integer isimpleEqnSize;
  input HashSet.HashSet ihs;
  output Integer osimpleEqnSize;
algorithm
  osimpleEqnSize := match(e1lst, e2lst, isimpleEqnSize, ihs)
    local
      DAE.Exp e1, e2;
      list<DAE.Exp> r1, r2;
      Integer size;
    case ({}, {}, _, _) then isimpleEqnSize;
    case (e1::r1, e2::r2, _, _)
      equation
        size = simpleEquation(e1, e2, ihs);
      then
        simpleEquations(r1, r2, size+isimpleEqnSize, ihs);
  end match;
end simpleEquations;

annotation(__OpenModelica_Interface="frontend");
end CheckModel;
