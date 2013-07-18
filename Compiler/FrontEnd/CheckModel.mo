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

encapsulated package CheckModel "
  file:        CheckModel.mo
  package:     CheckModel
  description: Check the Model.

  RCS: $Id: CheckModel.mo 8580 2011-04-11 09:33:31Z sjoelund.se $
"

public import Absyn;
public import DAE;

protected import BaseHashSet;
protected import ClassInf;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import Flags;
protected import HashSet;
protected import List;
protected import Util;

public function checkModel "function: checkModel
  This function perform a model check. Count Variables and equations and
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
  (varSize, eqnSize, eqns, hs) := countVarEqnSize(lst, 0, 0, {}, hs);
  simpleEqnSize := countSympleEqnSize(eqns, 0, hs);
end checkModel;

protected function countVarEqnSize
  input list<DAE.Element> inElements;
  input Integer ivarSize;
  input Integer ieqnSize;
  input list<DAE.Element> ieqnslst;
  input HashSet.HashSet ihs;
  output Integer ovarSize;
  output Integer oeqnSize;
  output list<DAE.Element> oeqnslst;
  output HashSet.HashSet ohs;
algorithm
  (ovarSize, oeqnSize, oeqnslst, ohs) := match(inElements, ivarSize, ieqnSize, ieqnslst, ihs)
    local
      DAE.Element elem;
      list<DAE.Element>  rest, eqns, daeElts;
      Integer varSize, eqnSize, size;
      DAE.Exp e1, ce;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.VarDirection dir;
      DAE.ConnectorType ct;
      Boolean b;
      list<DAE.ComponentRef> crlst;
      DAE.Algorithm alg;
      HashSet.HashSet hs;
      DAE.Type tp;
      DAE.Dimensions dims;

    case ({}, _, _, _, _) then (ivarSize, ieqnSize, ieqnslst, ihs);

    // external Objects
    case (DAE.EXTOBJECTCLASS(path=_)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // external Variables
    case (DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_)))::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // variable Variables
    case (DAE.VAR(componentRef=cr, kind = DAE.VARIABLE(), direction=dir, connectorType = ct, binding=SOME(e1), source=source)::rest, _, _, _, _)
      equation
        b = topLevelInput(cr, dir, ct);
        ce = Expression.crefExp(cr);
        size = Util.if_(b, 0, 1);
        eqns = List.consOnTrue(not b, DAE.EQUATION(ce, e1, source), ieqnslst);
        hs = Debug.bcallret2(not b, BaseHashSet.add, cr, ihs, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize+size, ieqnSize+size, eqns, hs);
      then
        (varSize, eqnSize, eqns, hs);

    // discrete Variables
    case (DAE.VAR(componentRef=cr, kind = DAE.DISCRETE(), direction=dir, connectorType = ct, binding=SOME(e1), source=source)::rest, _, _, _, _)
      equation
        b = topLevelInput(cr, dir, ct);
        ce = Expression.crefExp(cr);
        size = Util.if_(b, 0, 1);
        eqns = List.consOnTrue(not b, DAE.EQUATION(ce, e1, source), ieqnslst);
        hs = Debug.bcallret2(not b, BaseHashSet.add, cr, ihs, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize+size, ieqnSize+size, eqns, hs);
      then
        (varSize, eqnSize, eqns, hs);

    // variable Variables
    case (DAE.VAR(componentRef=cr, kind = DAE.VARIABLE(), direction=dir, connectorType = ct)::rest, _, _, _, _)
      equation
        b = topLevelInput(cr, dir, ct);
        size = Util.if_(b, 0, 1);
        hs = Debug.bcallret2(not b, BaseHashSet.add, cr, ihs, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize+size, ieqnSize, ieqnslst, hs);
      then
        (varSize, eqnSize, eqns, hs);

    // discrete Variables
    case (DAE.VAR(componentRef=cr, kind = DAE.DISCRETE(), direction=dir, connectorType = ct)::rest, _, _, _, _)
      equation
        b = topLevelInput(cr, dir, ct);
        size = Util.if_(b, 0, 1);
        hs = Debug.bcallret2(not b, BaseHashSet.add, cr, ihs, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize+size, ieqnSize, ieqnslst, hs);
      then
        (varSize, eqnSize, eqns, hs);

    // parameter Variables
    case (DAE.VAR(kind = DAE.PARAM())::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // constant Variables
    case (DAE.VAR(kind = DAE.CONST())::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // equations
    case((elem as DAE.EQUATION(exp=e1))::rest, _, _, _, _)
      equation
        size = Expression.sizeOf(Expression.typeof(e1));
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, elem::ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // initial equations
    case (DAE.INITIALEQUATION(exp1 = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // effort variable equality equations
    case ((elem as DAE.EQUEQUATION(cr1 = cr))::rest, _, _, _, _)
      equation
        tp = ComponentReference.crefTypeConsiderSubs(cr);
        size = Expression.sizeOf(tp);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, elem::ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // a solved equation
    case ((elem as DAE.DEFINE(componentRef = cr))::rest, _, _, _, _)
      equation
        tp = ComponentReference.crefTypeConsiderSubs(cr);
        size = Expression.sizeOf(tp);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, elem::ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = e1))::rest, _, _, _, _)
      equation
        size = Expression.sizeOf(Expression.typeof(e1));
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, elem::ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // complex initial equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // array equations
    case ((elem as DAE.ARRAY_EQUATION(dimension=dims))::rest, _, _, _, _)
      equation
        size =  List.fold(Expression.dimensionsSizes(dims), intMul, 1);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, elem::ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // initial array equations
    case (DAE.INITIAL_ARRAY_EQUATION(exp = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // when equations
    case (DAE.WHEN_EQUATION(equations = daeElts)::rest, _, _, _, _)
      equation
        (_, size, _, _) = countVarEqnSize(daeElts, 0, 0, {}, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // if equation with condition false and no else
    case (DAE.IF_EQUATION(condition1 = {DAE.BCONST(false)}, equations3 = {})::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // if equation that cannot be translated to if expression but have initial() as condition
    case (DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))})::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // if equation
    case (DAE.IF_EQUATION(equations2 = daeElts::_)::rest, _, _, _, _)
      equation
        (_, size, _, _) = countVarEqnSize(daeElts, 0, 0, {}, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);
    
    // initial if equation with condition false and no else
    case (DAE.INITIAL_IF_EQUATION(condition1 = {DAE.BCONST(false)}, equations3 = {})::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);
    
    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(condition1 = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // algorithm
    case (DAE.ALGORITHM(algorithm_ = alg)::rest, _, _, _, _)
      equation
        crlst = algorithmOutputs(alg);
        size = listLength(crlst);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize+size, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // flat class / COMP
    case (DAE.COMP(dAElist = daeElts)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(daeElts, ivarSize, ieqnSize, ieqnslst, ihs);
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, varSize, eqnSize, eqns, hs);
      then
        (varSize, eqnSize, eqns, hs);

    // reinit
    case (DAE.REINIT(componentRef = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // assert in equation
    case (DAE.ASSERT(condition = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // terminate in equation section is converted to ALGORITHM
    case (DAE.TERMINATE(message = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    case (DAE.NORETCALL(functionName = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case (DAE.CONSTRAINT(constraints = _)::rest, _, _, _, _)
      equation
        (varSize, eqnSize, eqns, hs) = countVarEqnSize(rest, ivarSize, ieqnSize, ieqnslst, ihs);
      then
        (varSize, eqnSize, eqns, hs);

    case (elem::_, _, _, _, _)
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CheckModel.countVarEqnSize failed on: " +& DAEDump.dumpElementsStr({elem}));
      then
        fail();
  end match;
end countVarEqnSize;

public function topLevelInput "function: topLevelInput
  author: PA
  if variable is input declared at the top level of the model,
  or if it is an input in a connector instance at top level return true."
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output Boolean b;
algorithm
  b := match (inComponentRef, inVarDirection, inConnectorType)
    case (DAE.CREF_IDENT(ident = _), DAE.INPUT(), _) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.INPUT(), DAE.FLOW()) then true;
    case (DAE.CREF_QUAL(componentRef = DAE.CREF_IDENT(ident = _)), DAE.INPUT(), DAE.POTENTIAL()) then true;
    else false;
  end match;
end topLevelInput;

public function algorithmOutputs "function: algorithmOutputs
  This function finds the the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm. If a variable is an
  input and an output it will be treated as an output."
  input DAE.Algorithm inAlgorithm;
  output list<DAE.ComponentRef> outCrefLst;
protected
  list<DAE.Statement> stmts;
algorithm
  DAE.ALGORITHM_STMTS(statementLst=stmts) := inAlgorithm;
  outCrefLst := algorithmStatementListOutputs(stmts);
end algorithmOutputs;

public function algorithmStatementListOutputs "function: algorithmStatementListOutputs
  This function finds the the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm. If a variable is an
  input and an output it will be treated as an output."
  input list<DAE.Statement> inStmts;
  output list<DAE.ComponentRef> outCrefLst;
protected
  HashSet.HashSet hs;
algorithm
  hs := HashSet.emptyHashSet();
  hs := List.fold(inStmts, statementOutputs, hs);
  outCrefLst := BaseHashSet.hashSetList(hs);
end algorithmStatementListOutputs;

protected function statementOutputs "function: statementOutputs
  Helper relation to algorithmOutputs"
  input DAE.Statement inStatement;
  input  HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := matchcontinue (inStatement, iht)
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

    // a := expr;
    case (DAE.STMT_ASSIGN(exp1 = exp1), _) equation
      ((_, ht)) = Expression.traverseExpTopDown(exp1, statementOutputsCrefFinder, iht);
    then ht;
        
    // (a, b, ...) := expr;
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl), _) equation
      ((_, ht)) = Expression.traverseExpListTopDown(expl, statementOutputsCrefFinder, iht);
    then ht;
        
    // a := expr;  // where a is array with an empty list as subscript
    case (DAE.STMT_ASSIGN_ARR(componentRef=cr), _) equation
      {} = ComponentReference.crefLastSubs(cr);
      crlst = ComponentReference.expandCref(cr, true);
      ht = List.fold(crlst, BaseHashSet.add, iht);
    then ht;
    
    // a := expr;  // where a is array
    case (DAE.STMT_ASSIGN_ARR(componentRef=cr), _) equation
      failure({} = ComponentReference.crefLastSubs(cr));
      cr = ComponentReference.crefSetLastSubs(cr, {DAE.WHOLEDIM()});
      crlst = ComponentReference.expandCref(cr, true);
      ht = List.fold(crlst, BaseHashSet.add, iht);
    then ht;
    
    case(DAE.STMT_IF(statementLst = stmts, else_ = elsebranch), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
        ht = statementElseOutputs(elsebranch, ht);
      then ht;
   case(DAE.STMT_FOR(type_=tp, iter = iteratorName, range = e, statementLst = stmts), _)
      equation
        // replace the iterator variable with the range expression
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        (stmts, _) = DAEUtil.traverseDAEEquationsStmts(stmts, Expression.traverseSubexpressionsHelper, (Expression.replaceCref, (cr, e)));
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
   case(DAE.STMT_PARFOR(type_=tp, iter = iteratorName, range = e, statementLst = stmts), _)
      equation
        // replace the iterator variable with the range expression
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        (stmts, _) = DAEUtil.traverseDAEEquationsStmts(stmts, Expression.traverseSubexpressionsHelper, (Expression.replaceCref, (cr, e)));
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
    case(DAE.STMT_WHILE(statementLst = stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
    case (DAE.STMT_WHEN(statementLst = stmts, elseWhen = NONE()), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
    case (DAE.STMT_WHEN(exp = e, statementLst = stmts, elseWhen = SOME(stmt)), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
        ht = statementOutputs(stmt, ht);
      then ht;
    case(DAE.STMT_ASSERT(cond = _), _) then iht;
    case(DAE.STMT_TERMINATE(msg = _), _) then iht;
    // reinit is not a output
    case(DAE.STMT_REINIT(var = _), _)
      then iht;
    case(DAE.STMT_NORETCALL(exp = _), _) then iht;
    case(DAE.STMT_RETURN(_), _) then iht;
    case(DAE.STMT_BREAK(_), _) then iht;
    case(DAE.STMT_ARRAY_INIT(name=_), _) then iht;
    // MetaModelica extension. KS
    case(DAE.STMT_FAILURE(body = stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
     case(DAE.STMT_TRY(tryBody = stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
     case(DAE.STMT_CATCH(catchBody = stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
     case(DAE.STMT_CATCH(catchBody = stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
    case(DAE.STMT_THROW(source=_), _) then iht;
    
    else equation
      str = DAEDump.ppStatementStr(inStatement);
      Debug.fprintln(Flags.FAILTRACE, "- CheckModel.statementOutputs failed for " +& str +& "\n");
    then fail();
  end matchcontinue;
end statementOutputs;

protected function statementElseOutputs "function statementElseOutputs
  Helper function to statementOutputs"
  input DAE.Else inElseBranch;
  input HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := match (inElseBranch, iht)
    local
      list<DAE.Statement> stmts;
      DAE.Else elseBranch;
      HashSet.HashSet ht;

    case(DAE.NOELSE(), _) then iht;

    case(DAE.ELSEIF(statementLst=stmts, else_=elseBranch), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
        ht = statementElseOutputs(elseBranch, ht);
      then ht;

    case(DAE.ELSE(statementLst=stmts), _)
      equation
        ht = List.fold(stmts, statementOutputs, iht);
      then ht;
  end match;
end statementElseOutputs;

protected function statementOutputsCrefFinder "function statementOutputsCrefFinder
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp, HashSet.HashSet > inExp;
  output tuple<DAE.Exp, Boolean, HashSet.HashSet > outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e, exp, e1, e2;
      HashSet.HashSet ht;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
    // Scip Whild
    case((e as DAE.CREF(componentRef=DAE.WILD()), ht))
      then
        ((e, false, ht));
    // Scip time
    case((e as DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time", subscriptLst={})), ht))
      then
        ((e, false, ht));
    // Skip external Objects
    case((e as DAE.CREF(ty=DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_))), ht))
      then
        ((e, false, ht));
        
    case((e as DAE.CREF(componentRef=cr), ht)) equation
      {} = ComponentReference.crefLastSubs(cr);
      crlst = ComponentReference.expandCref(cr, true);
      ht = List.fold(crlst, BaseHashSet.add, ht);
    then ((e, false, ht));
    
    case((e as DAE.CREF(componentRef=cr), ht)) equation
      failure({} = ComponentReference.crefLastSubs(cr));
      cr = ComponentReference.crefSetLastSubs(cr, {DAE.WHOLEDIM()});
      crlst = ComponentReference.expandCref(cr, true);
      ht = List.fold(crlst, BaseHashSet.add, ht);
    then ((e, false, ht));
      
    case((e as DAE.ASUB(exp=exp), ht))
      equation
        ((_, ht)) = Expression.traverseExpTopDown(exp, statementOutputsCrefFinder, ht);
      then
        ((e, false, ht));
    case((e as DAE.RELATION(exp1=_), ht))
      then
        ((e, false, ht));
    case((e as DAE.RANGE(ty=_), ht))
      then
        ((e, false, ht));
    case((e as DAE.IFEXP(expThen=e1, expElse=e2), ht))
      equation
        ((_, ht)) = Expression.traverseExpTopDown(e1, statementOutputsCrefFinder, ht);
        ((_, ht)) = Expression.traverseExpTopDown(e2, statementOutputsCrefFinder, ht);
      then
        ((e, false, ht));
    case((e, ht)) then ((e, true, ht));
  end matchcontinue;
end statementOutputsCrefFinder;

protected function countSympleEqnSize
  input list<DAE.Element> inEqns;
  input Integer isimpleEqnSize;
  input HashSet.HashSet ihs;
  output Integer osimpleEqnSize;
algorithm
  osimpleEqnSize := matchcontinue(inEqns, isimpleEqnSize, ihs)
    local
      DAE.Element elem;
      list<DAE.Element>  rest;
      DAE.Exp e1, e2;
      DAE.ComponentRef cr;
      DAE.Type tp;
      Integer size;
      DAE.Dimensions dims;

    case ({}, _, _) then isimpleEqnSize;

    // equations
    case((elem as DAE.EQUATION(exp=e1, scalar=e2))::rest, _, _)
      equation
        size = simpleEquation(e1, e2, ihs);
      then
        countSympleEqnSize(rest, isimpleEqnSize+size, ihs);

    // effort variable equality equations
    case ((elem as DAE.EQUEQUATION(cr1 = cr))::rest, _, _)
      equation
        tp = ComponentReference.crefTypeConsiderSubs(cr);
        size = Expression.sizeOf(tp);
      then
        countSympleEqnSize(rest, isimpleEqnSize+size, ihs);

    // a solved equation
    case ((elem as DAE.DEFINE(componentRef = cr, exp=e2))::rest, _, _)
      equation
        //tp = ComponentReference.crefLastType(cr);
        //size = Expression.sizeOf(tp);
        e1 = Expression.crefExp(cr);
        size = simpleEquation(e1, e2, ihs);
      then
        countSympleEqnSize(rest, isimpleEqnSize+size, ihs);

    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2))::rest, _, _)
      equation
        size = simpleEquation(e1, e2, ihs);
      then
        countSympleEqnSize(rest, isimpleEqnSize+size, ihs);

    // array equations
    case ((elem as DAE.ARRAY_EQUATION(dimension=dims, exp = e1, array = e2))::rest, _, _)
      equation
        size = simpleEquation(e1, e2, ihs);
      then
        countSympleEqnSize(rest, isimpleEqnSize+size, ihs);

    case (_::rest, _, _)
      then
        countSympleEqnSize(rest, isimpleEqnSize, ihs);
  end matchcontinue;
end countSympleEqnSize;

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
    case (DAE.CREF(componentRef = _), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a = -b;
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a + b = 0
    case (DAE.BINARY(DAE.CREF(componentRef = _), DAE.ADD(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.CREF(componentRef = _), DAE.ADD_ARR(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a - b = 0
    case (DAE.BINARY(DAE.CREF(componentRef = _), DAE.SUB(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.CREF(componentRef = _), DAE.SUB_ARR(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a + b = 0
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.ADD(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.ADD_ARR(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -a - b = 0
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.SUB(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.SUB_ARR(ty=_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isZero(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a + b
    case (_, DAE.BINARY(DAE.CREF(componentRef = _), DAE.ADD(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.CREF(componentRef = _), DAE.ADD_ARR(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a - b
    case (_, DAE.BINARY(DAE.CREF(componentRef = _), DAE.SUB(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.CREF(componentRef = _), DAE.SUB_ARR(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a + b
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.ADD(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.ADD_ARR(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a - b
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.SUB(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (_, DAE.BINARY(DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.SUB_ARR(ty=_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isZero(e1);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // a = der(b);
    case (DAE.CREF(componentRef = _), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // a = -der(b);
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(componentRef = _), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -der(a) = b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), DAE.CREF(componentRef = _), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // -a = der(b);
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = -b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)}), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    // -a = -der(b);
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), _)
      then
        Expression.sizeOf(Expression.typeof(e1));
    // -der(a) = -b;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CALL(path = Absyn.IDENT(name = "der"), expLst = {DAE.CREF(componentRef = _)})), DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _)
      then
        Expression.sizeOf(Expression.typeof(e2));

    // a = const;
    case (DAE.CREF(componentRef = _), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // const = a;
    case (_, DAE.CREF(componentRef = _), _)
      equation
        true = Expression.isConst(e1);
      then
        Expression.sizeOf(Expression.typeof(e2));

    // -a = const;
    case (DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _, _)
      equation
        true = Expression.isConst(e2);
      then
        Expression.sizeOf(Expression.typeof(e1));
    // const = -a;
    case (_, DAE.UNARY(DAE.UMINUS(_), DAE.CREF(componentRef = _)), _)
      equation
        true = Expression.isConst(e1);
      then
        Expression.sizeOf(Expression.typeof(e2));
    case (_, DAE.UNARY(DAE.UMINUS_ARR(_), DAE.CREF(componentRef = _)), _)
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
        ((_, (_, _::{}))) = Expression.traverseExp(Expression.expSub(e1, e2), traversingComponentRefFinder, (ihs, {}));
      then
        Expression.sizeOf(Expression.typeof(e1));

    else
      then
        0;
  end matchcontinue;
end simpleEquation;

protected function traversingComponentRefFinder "function: traversingComponentRefFinder
  author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp, tuple<HashSet.HashSet, list<DAE.ComponentRef>>> inExp;
  output tuple<DAE.Exp, tuple<HashSet.HashSet, list<DAE.ComponentRef>>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      HashSet.HashSet hs;
      list<DAE.ComponentRef> crefs, crlst;
      DAE.ComponentRef cr;
      DAE.Exp e;

    case((e as DAE.CREF(componentRef=cr), (hs, crefs)))
      equation
        crlst = ComponentReference.expandCref(cr, true);
        crefs = getcr(crlst, hs, crefs);
      then
        ((e, (hs, crefs)));

    case _ then inExp;

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

end CheckModel;
