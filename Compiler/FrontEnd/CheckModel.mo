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

public function checkModel
"function: checkModel
  This function perform a model check. Cound Variables and equations and
  detect the simple equations."
  input DAE.DAElist inDAELst;
  output Integer varSize;
  output Integer eqnSize;
  output Integer simpleEqnSize;
protected
  list<DAE.Element> eqns,lst;
algorithm
  DAE.DAE(lst) := inDAELst;
  (varSize,eqnSize,eqns) := countVarEqnSize(lst,0,0,{});
  simpleEqnSize := countSympleEqnSize(eqns,0);
end checkModel;

protected function countVarEqnSize
  input list<DAE.Element> inElements;
  input Integer ivarSize;
  input Integer ieqnSize;
  input list<DAE.Element> ieqnslst;
  output Integer ovarSize;
  output Integer oeqnSize;
  output list<DAE.Element> oeqnslst; 
algorithm
  (ovarSize,oeqnSize,oeqnslst) := match(inElements,ivarSize,ieqnSize,ieqnslst)
    local 
      DAE.Element elem;
      list<DAE.Element>  rest,eqns,daeElts; 
      Integer varSize,eqnSize,size;
      DAE.Exp e1,ce;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
    case ({},_,_,_) then (ivarSize,ieqnSize,ieqnslst);

    // external Objects 
    case (DAE.EXTOBJECTCLASS(path=_)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns); 

    // external Variables 
    case (DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_)))::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns); 
  
    // variable Variables
    case (DAE.VAR(componentRef=cr,kind = DAE.VARIABLE(),binding=SOME(e1),source=source)::rest,_,_,_)
      equation
        ce = Expression.crefExp(cr);
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize+1,ieqnSize+1,DAE.EQUATION(ce,e1,source)::ieqnslst);
      then
        (varSize,eqnSize,eqns);
  
    // discrete Variables
    case (DAE.VAR(componentRef=cr,kind = DAE.DISCRETE(),binding=SOME(e1),source=source)::rest,_,_,_)
      equation
        ce = Expression.crefExp(cr);
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize+1,ieqnSize+1,DAE.EQUATION(ce,e1,source)::ieqnslst);
      then
        (varSize,eqnSize,eqns);   
    
    // variable Variables
    case (DAE.VAR(kind = DAE.VARIABLE())::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize+1,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
  
    // discrete Variables
    case (DAE.VAR(kind = DAE.DISCRETE())::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize+1,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);  
        
    // equations
    case((elem as DAE.EQUATION(exp=e1))::rest,_,_,_)
      equation
        size = Expression.sizeOf(Expression.typeof(e1));
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize+size,elem::ieqnslst);
      then
        (varSize,eqnSize,eqns);    
         
    // initial equations
    case (DAE.INITIALEQUATION(exp1 = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // effort variable equality equations
    case ((elem as DAE.EQUEQUATION(cr1 = _))::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize+1,elem::ieqnslst);
      then
        (varSize,eqnSize,eqns);    
        
    // a solved equation 
    case ((elem as DAE.DEFINE(componentRef = _))::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize+1,elem::ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = e1))::rest,_,_,_)
      equation
        size = Expression.sizeOf(Expression.typeof(e1));
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize+size,elem::ieqnslst);
      then
        (varSize,eqnSize,eqns); 
 
    // complex initial equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // array equations
    case ((elem as DAE.ARRAY_EQUATION(exp = e1))::rest,_,_,_)
      equation
        size = Expression.sizeOf(Expression.typeof(e1));
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize+size,elem::ieqnslst);
      then
        (varSize,eqnSize,eqns); 
       
    // initial array equations
    case (DAE.INITIAL_ARRAY_EQUATION(exp = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
               
    // when equations
    case (DAE.WHEN_EQUATION(equations = daeElts)::rest,_,_,_)
      equation
        (varSize,eqnSize,_) = countVarEqnSize(daeElts,ivarSize,ieqnSize,{});
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,varSize,eqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // if equation that cannot be translated to if expression but have initial() as condition
    case (DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))})::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // if equation
    case (DAE.IF_EQUATION(equations2 = daeElts::_)::rest,_,_,_)
      equation
        (varSize,eqnSize,_) = countVarEqnSize(daeElts,ivarSize,ieqnSize,{});
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,varSize,eqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(condition1 = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
        
    // algorithm
    case (DAE.ALGORITHM(algorithm_ = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
           
    // flat class / COMP
    case (DAE.COMP(dAElist = daeElts)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(daeElts,ivarSize,ieqnSize,ieqnslst);
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,varSize,eqnSize,eqns);
      then
        (varSize,eqnSize,eqns);
   
    // reinit 
    case (DAE.REINIT(componentRef = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);   
    
    // assert in equation 
    case (DAE.ASSERT(condition = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
         
    // terminate in equation section is converted to ALGORITHM
    case (DAE.TERMINATE(message = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
            
    case (DAE.NORETCALL(functionName = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
         
    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case (DAE.CONSTRAINT(constraints = _)::rest,_,_,_)
      equation
        (varSize,eqnSize,eqns) = countVarEqnSize(rest,ivarSize,ieqnSize,ieqnslst);
      then
        (varSize,eqnSize,eqns);
            
    case (elem::_,_,_,_)
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- CheckModel.countVarEqnSize failed on: " +& DAEDump.dumpElementsStr({elem}));
      then
        fail();    
  end match;
end countVarEqnSize;

public function algorithmOutputs
"function: algorithmOutputs
  This function finds the the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm. If a variable is an 
  input and an output it will be treated as an output."
  input DAE.Algorithm inAlgorithm;
  output list<DAE.ComponentRef> outCrefLst;
protected
  list<DAE.Statement> ss;
  HashSet.HashSet hs;
algorithm
  DAE.ALGORITHM_STMTS(statementLst = ss) := inAlgorithm;
  hs := HashSet.emptyHashSet();
  hs := List.fold(ss,statementOutputs,hs);
  outCrefLst := BaseHashSet.hashSetList(hs);
end algorithmOutputs;

protected function statementOutputs
"function: statementOutputs
  Helper relation to algorithmOutputs"
  input DAE.Statement inStatement;
  input  HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := matchcontinue (inStatement,iht)
    local
      HashSet.HashSet ht;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      DAE.Exp e, exp1, e1, e2;
      DAE.Statement stmt;
      list<DAE.Statement> stmts;
      DAE.Else elsebranch;
      list<DAE.Exp> expl,inputs,inputs1,inputs2,inputs3,outputs,outputs1,outputs2;
      DAE.Type tp;
      DAE.Ident iteratorName;
      DAE.Exp iteratorExp;
      list<DAE.Exp> arrayVars, nonArrayVars;
      list<list<DAE.Exp>> arrayElements;
      list<DAE.Exp> flattenedElements;
      list<tuple<DAE.ComponentRef,Integer>> tplcrintlst;
      String str;
            
      // a := expr;
    case (DAE.STMT_ASSIGN(exp1 = exp1),_)
      equation
        ((_,ht)) = Expression.traverseExpTopDown(exp1, statementOutputsCrefFinder, iht);
      then
        ht;
      // (a,b,c) := foo(...)
    case (DAE.STMT_TUPLE_ASSIGN(expExpLst = expl),_)
      equation
        ((_,ht)) = Expression.traverseExpListTopDown(expl, statementOutputsCrefFinder, iht);
      then
        ht;
    // v := expr   where v is array.
    case (DAE.STMT_ASSIGN_ARR(componentRef = cr),_)
      equation
        crlst = ComponentReference.expandCref(cr,true);
        //tplcrintlst = List.map1(crlst, Util.makeTuple,0);
        ht = List.fold(crlst,BaseHashSet.add,iht);
      then ht;
    case(DAE.STMT_IF(statementLst = stmts, else_ = elsebranch),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
        ht = statementElseOutputs(elsebranch,ht);
      then ht;
   case(DAE.STMT_FOR(type_=tp, iter = iteratorName, range = e, statementLst = stmts),_)
      equation
        // replace the iterator variable with the range expression
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        (stmts,_) = DAEUtil.traverseDAEEquationsStmts(stmts,Expression.traverseSubexpressionsHelper,(Expression.replaceCref,(cr,e)));
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
    case(DAE.STMT_WHILE(statementLst = stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
    case (DAE.STMT_WHEN(statementLst = stmts,elseWhen = NONE()),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
    case (DAE.STMT_WHEN(exp = e,statementLst = stmts,elseWhen = SOME(stmt)),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
        ht = statementOutputs(stmt,ht);
      then ht;
    case(DAE.STMT_ASSERT(cond = _),_) then iht;
    case(DAE.STMT_TERMINATE(msg = _),_) then iht;
    // reinit is not a output
    case(DAE.STMT_REINIT(var = _),_)
      then iht;
    case(DAE.STMT_NORETCALL(exp = _),_) then iht;
    case(DAE.STMT_RETURN(_),_) then iht;
    // MetaModelica extension. KS  
    case(DAE.STMT_FAILURE(body = stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
     case(DAE.STMT_TRY(tryBody = stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
     case(DAE.STMT_CATCH(catchBody = stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
     case(DAE.STMT_CATCH(catchBody = stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
    case(DAE.STMT_THROW(source=_),_) then iht;
    case(_, _)
      equation
        str = DAEDump.ppStatementStr(inStatement);
        Debug.fprintln(Flags.FAILTRACE, "- BackendDAECreate.statementOutputs failed for " +& str +& "\n");
      then 
        fail();
  end matchcontinue;
end statementOutputs;

protected function statementElseOutputs
"Helper function to statementOutputs"
  input DAE.Else inElseBranch;
  input HashSet.HashSet iht;
  output HashSet.HashSet oht;
algorithm
  oht := match (inElseBranch,iht)
    local
      list<DAE.Statement> stmts;
      DAE.Else elseBranch;
      HashSet.HashSet ht;

    case(DAE.NOELSE(),_) then iht;

    case(DAE.ELSEIF(statementLst=stmts,else_=elseBranch),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
        ht = statementElseOutputs(elseBranch,ht);
      then ht;

    case(DAE.ELSE(statementLst=stmts),_)
      equation
        ht = List.fold(stmts,statementOutputs,iht);
      then ht;
  end match;
end statementElseOutputs;

protected function statementOutputsCrefFinder "
Author: Frenkel TUD 2012-06"
  input tuple<DAE.Exp, HashSet.HashSet > inExp;
  output tuple<DAE.Exp, Boolean, HashSet.HashSet > outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      DAE.Exp e,exp,e1,e2;
      HashSet.HashSet ht;
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      //list<tuple<DAE.ComponentRef,Integer>> tplcrintlst;
    case((e as DAE.CREF(componentRef=cr),ht))
      equation
        crlst = ComponentReference.expandCref(cr,true);
        //tplcrintlst = List.map1(crlst, Util.makeTuple,0);
        ht = List.fold(crlst,BaseHashSet.add,ht);
      then
        ((e,false,ht));    
    case((e as DAE.ASUB(exp=exp),ht))
      equation
        ((_,ht)) = Expression.traverseExpTopDown(exp, statementOutputsCrefFinder, ht);
      then
        ((e,false,ht));    
    case((e as DAE.RELATION(exp1=_),ht))
      then
        ((e,false,ht));    
    case((e as DAE.RANGE(ty=_),ht))
      then
        ((e,false,ht));    
    case((e as DAE.IFEXP(expThen=e1,expElse=e2),ht))
      equation
        ((_,ht)) = Expression.traverseExpTopDown(e1, statementOutputsCrefFinder, ht);
        ((_,ht)) = Expression.traverseExpTopDown(e2, statementOutputsCrefFinder, ht);
      then
        ((e,false,ht));    
    case((e,ht)) then ((e,true,ht));    
  end matchcontinue;
end statementOutputsCrefFinder;


protected function countSympleEqnSize
  input list<DAE.Element> inEqns;
  input Integer isimpleEqnSize;
  output Integer osimpleEqnSize; 
algorithm
  osimpleEqnSize := matchcontinue(inEqns,isimpleEqnSize)
    local 
      DAE.Element elem;
      list<DAE.Element>  rest; 
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      DAE.Type tp;
      Integer size;
    case ({},_) then isimpleEqnSize;
      
    // equations
    case((elem as DAE.EQUATION(exp=e1,scalar=e2))::rest,_)
      equation
        size = simpleEquation(e1,e2);
      then
        countSympleEqnSize(rest,isimpleEqnSize+size);

        
    // effort variable equality equations
    case ((elem as DAE.EQUEQUATION(cr1 = cr))::rest,_)
      equation
        tp = ComponentReference.crefLastType(cr);
        size = Expression.sizeOf(tp);
      then
        countSympleEqnSize(rest,isimpleEqnSize+size);
        
    // a solved equation 
    case ((elem as DAE.DEFINE(componentRef = cr))::rest,_)
      equation
        tp = ComponentReference.crefLastType(cr);
        size = Expression.sizeOf(tp);
      then
        countSympleEqnSize(rest,isimpleEqnSize+size);
        
    // complex equations
    case ((elem as DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2))::rest,_)
      equation
        size = simpleEquation(e1,e2);
      then
        countSympleEqnSize(rest,isimpleEqnSize+size);
        
    // array equations
    case ((elem as DAE.ARRAY_EQUATION(exp = e1, array = e2))::rest,_)
      equation
        size = simpleEquation(e1,e2);
      then
        countSympleEqnSize(rest,isimpleEqnSize+size);
        
    case (_::rest,_)
      then
        countSympleEqnSize(rest,isimpleEqnSize); 
  end matchcontinue;
end countSympleEqnSize;

protected function simpleEquation
  input DAE.Exp e1;
  input DAE.Exp e2;
  output Integer osimpleEqnSize; 
algorithm
  osimpleEqnSize := matchcontinue(e1,e2)
    local
      list<DAE.Exp> ea1,ea2;
    // a = b;
    case (DAE.CREF(componentRef = _),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // a = -b;
    case (DAE.CREF(componentRef = _),DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(componentRef = _),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // -a = b;
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // a + b = 0
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // a - b = 0
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // -a + b = 0
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // -a - b = 0
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = _)),_)
      equation
        true = Expression.isZero(e2);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a + b 
    case (_,DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (_,DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = a - b 
    case (_,DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (_,DAE.BINARY(e1 as DAE.CREF(componentRef = _),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a + b 
    case (_,DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.ADD(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (_,DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.ADD_ARR(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // 0 = -a - b 
    case (_,DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.SUB(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (_,DAE.BINARY(e1 as DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.SUB_ARR(ty=_),e2 as DAE.CREF(componentRef = _)))
      equation
        true = Expression.isZero(e1);
      then 
        Expression.sizeOf(Expression.typeof(e1));   
    // a = der(b);
    case (DAE.CREF(componentRef = _),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    // a = -der(b);
    case (DAE.CREF(componentRef = _),DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.CREF(componentRef = _),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // -der(a) = b;
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})),DAE.CREF(componentRef = _))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    // -a = der(b);
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)), DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    // der(a) = -b;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}),DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)}),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    // -a = -der(b);
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)),DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})))
      then 
        Expression.sizeOf(Expression.typeof(e1));
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})))
      then 
        Expression.sizeOf(Expression.typeof(e1));    
    // -der(a) = -b;
    case (DAE.UNARY(DAE.UMINUS(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})),DAE.UNARY(DAE.UMINUS(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e2));
    case (DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = _)})),DAE.UNARY(DAE.UMINUS_ARR(_),DAE.CREF(componentRef = _)))
      then 
        Expression.sizeOf(Expression.typeof(e2));
          
    case(_,_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then
        simpleEquations(ea1,ea2,0);
               
    else 
      then 
        0;  
  end matchcontinue;
end simpleEquation;

protected function simpleEquations
  input list<DAE.Exp> e1lst;
  input list<DAE.Exp> e2lst;
  input Integer isimpleEqnSize; 
  output Integer osimpleEqnSize; 
algorithm
  osimpleEqnSize := match(e1lst,e2lst,isimpleEqnSize)
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> r1,r2;
      Integer size;
    case ({},{},_) then isimpleEqnSize;
    case (e1::r1,e2::r2,_)
      equation
        size = simpleEquation(e1,e2);
      then
        simpleEquations(r1,r2,size+isimpleEqnSize);
  end match;
end simpleEquations;

end CheckModel;