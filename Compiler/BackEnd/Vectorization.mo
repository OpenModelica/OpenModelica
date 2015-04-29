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

encapsulated package Vectorization
" file:        Vectorization.mo
  package:     Vectorization
  description: Vectorization

  RCS: $Id: Vectorization.mo 2013-05-24 11:12:35Z vwaurich $
"
public import BackendDAE;
public import DAE;

protected import Absyn;
protected import Algorithm;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Dump;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import SCode;
protected import SCodeDump;
protected import List;
protected import Util;


protected uniontype loopEq
  record LOOPEQ
    BackendDAE.Equation eq;
    Integer startIdx;
    Integer endIdx;
  end LOOPEQ;
end loopEq;

protected uniontype Eq
  record FOR_EQ
    BackendDAE.Equation eq;
    Integer startIdx;
    Integer endIdx;
    Integer step;
  end FOR_EQ;
end Eq;

//--------------------------------
//--------------------------------
//--------------------------------

public function buildForLoops
  input BackendDAE.Variables varsIn;
  input list<BackendDAE.Equation> eqsIn;
  output BackendDAE.Variables varsOut;
  output list<BackendDAE.Equation> eqsOut;
protected
  list<BackendDAE.Equation> loopEqs;
  list<BackendDAE.Var> arrVars;
  list<Absyn.Exp> loopIds;
  list<BackendDAE.LoopInfo> loopInfos;
  list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  list<BackendDAE.Var> varLst, arrayVars;

  list<BackendDAE.Equation> classEqs,mixEqs,nonArrEqs;
  list<Eq> mixLoop, classLoop;
algorithm
    //BackendDump.dumpEquationList(eqsIn,"eqsIn");
    //BackendDump.dumpVariables(varsIn,"varsIn");
  varLst := BackendVariable.varList(varsIn);
  (varLst, arrayVars) := List.fold(varLst, getArrayVars,({},{}));
    //BackendDump.dumpVarList(varLst,"varLst");

  // get the arrayCrefs
  (arrayCrefs,_) := List.fold(arrayVars,getArrayVarCrefs,({},{}));
    //BackendDump.dumpVarList(arrayVars,"arrayVars");
    //print("arrayCrefs: "+stringDelimitList(List.map(List.map(arrayCrefs,Util.tuple31),ComponentReference.printComponentRefStr),"\n|")+"\n\n");
    //print("ranges: "+stringDelimitList(List.map(List.map(arrayCrefs,Util.tuple32),intString),"\n|")+"\n\n");
    //print("tails: "+stringDelimitList(List.map(List.map(arrayCrefs,Util.tuple33),ComponentReference.printComponentRefListStr),"\n|")+"\n\n");

  // dispatch the equations in classequations, mixedequations, non-array equations
  ((classEqs,mixEqs,nonArrEqs)) := List.fold1(eqsIn, dispatchLoopEquations,List.map(arrayCrefs,Util.tuple31),({},{},{}));

  //classEqs := List.map1({6,13},List.getIndexFirst,classEqs);
    //BackendDump.dumpEquationList(classEqs,"classEqs");
    //BackendDump.dumpEquationList(mixEqs,"mixEqs");
    //BackendDump.dumpEquationList(nonArrEqs,"nonArrEqs");

  //add loopinfos
  classEqs := addLoopInfosForClassEqs(classEqs, List.map(arrayCrefs,Util.tuple31), {});
  mixEqs := addLoopInfosForMixEqs(mixEqs, List.map(arrayCrefs,Util.tuple31), {});
    //BackendDump.dumpEquationList(classEqs,"classEqs2");
    //BackendDump.dumpEquationList(mixEqs,"mixEqs2");
    //BackendDump.dumpEquationList(nonArrEqs,"nonArrEqs2");

  //reduce accumulated loop equations, build loop equations
  mixEqs := List.fold1(mixEqs,buildIteratedEquation,arrayCrefs,{});

  classEqs := List.fold1(classEqs,buildIteratedEquation,arrayCrefs,{});
    //BackendDump.dumpEquationList(classEqs,"classEqs3");
    //BackendDump.dumpEquationList(mixEqs,"mixEqs3");
  eqsOut := listAppend(listAppend(nonArrEqs,listAppend(classEqs,mixEqs)));
    //BackendDump.dumpEquationList(eqsOut,"eqsOut");

  //shorten the array variables
  arrVars := List.fold2(arrayCrefs,shortenArrayVars,BackendVariable.listVar1(arrayVars),2,{});
  varLst := listAppend(varLst,arrVars);
    //BackendDump.dumpVarList(varLst,"varsOut");
  varsOut := BackendVariable.listVar1(varLst);
end buildForLoops;

protected function shortenArrayVars
  input tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>> arrayCref;
  input BackendDAE.Variables arrayVars;
  input Integer size;
  input list<BackendDAE.Var> varLstIn;
  output list<BackendDAE.Var> varLstOut;
algorithm
  varLstOut := matchcontinue(arrayCref,arrayVars,size,varLstIn)
    local
      Integer subRange;
      DAE.ComponentRef headCref;
      list<BackendDAE.Var> varLst;
      list<list<BackendDAE.Var>> varLstLst;
      list<DAE.ComponentRef> tailCrefs, headsWithSubs;
  case((headCref,subRange,tailCrefs),_,_,_)
    equation
      headsWithSubs = List.map1r(List.intRange(size),ComponentReference.subscriptCrefWithInt,headCref);
      headsWithSubs = List.flatten(List.map1(headsWithSubs,joinWithCrefLst,tailCrefs));
        //print("headsWithSubs2: "+stringDelimitList(List.map(headsWithSubs,ComponentReference.printComponentRefStr),"\n|")+"\n\n");
      (varLstLst,_) = List.map1_2(headsWithSubs, BackendVariable.getVar,arrayVars);
      varLst = List.flatten(varLstLst);
  then varLst;
  else
    then varLstIn;
  end matchcontinue;
end shortenArrayVars;

protected function joinWithCrefLst
  input DAE.ComponentRef cref;
  input list<DAE.ComponentRef> crefLstIn;
  output list<DAE.ComponentRef> crefLstOut;
algorithm
  crefLstOut := List.map1r(crefLstIn,ComponentReference.joinCrefs,cref);
end joinWithCrefLst;

protected function reduceLoopEquations
  input BackendDAE.Equation eqIn;
  input list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  input Integer maxSize;
  output BackendDAE.Equation eqOut;
algorithm
  eqOut := matchcontinue(eqIn,arrayCrefs,maxSize)
    local
      DAE.Exp lhs,rhs, startIt, endIt;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      list<BackendDAE.IterCref> iterCrefs;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr as BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs={BackendDAE.ACCUM_ITER_CREF()}))),_,_)
    equation
      // strip the higher indexes in accumulated iterations
      (lhs,_) = reduceLoopExpressions(lhs,maxSize);
      (rhs,_) = reduceLoopExpressions(rhs,maxSize);
  then BackendDAE.EQUATION(lhs,rhs,source,attr);
  else
    equation
    then eqIn;
  end matchcontinue;
end reduceLoopEquations;

protected function buildIteratedEquation
  input BackendDAE.Equation eqIn;
  input list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(eqIn,arrayCrefs,foldIn)
    local
      Integer startIt,endIt, maxItOffset;
      list<Integer> idxOffsets;
      DAE.Exp lhs,rhs;
      DAE.ElementSource source;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.IterCref> iterCrefs;

  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=iterCrefs as BackendDAE.ITER_CREF()::_, startIt=DAE.ICONST(startIt),endIt=DAE.ICONST(endIt)))),_,_)
    algorithm
      // handle no accumulated equations here
      eqLst := {};
      idxOffsets := List.map(iterCrefs,getIterationCrefIterator);
      maxItOffset := List.fold(idxOffsets,intMax,listHead(idxOffsets));
        //print("maxItOffset "+intString(maxItOffset)+"\n");
        //print("start "+intString(startIt)+"\n");
        //print("end "+intString(startIt)+"\n");
      for i in  startIt:intMin(endIt,2-maxItOffset) loop
        eq := buildIteratedEquation1(eqIn,i,arrayCrefs);
        eqLst := eq::eqLst;
      end for;
      eqLst := listAppend(eqLst,foldIn);
  then eqLst;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=BackendDAE.ACCUM_ITER_CREF()::_, startIt=DAE.ICONST(startIt),endIt=DAE.ICONST(endIt)))),_,_)
    algorithm
      // accumulated equations, remove higher subscripts, no duplication
      eq := reduceLoopEquations(eqIn,arrayCrefs,2);
    then eq::foldIn;
  else
    then eqIn::foldIn;
  end matchcontinue;
end buildIteratedEquation;

protected function buildIteratedEquation1
  input BackendDAE.Equation eqIn;
  input Integer idx;
  input list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  output BackendDAE.Equation eqOut;
algorithm
  eqOut := matchcontinue(eqIn,idx,arrayCrefs)
    local
      DAE.Exp lhs,rhs, startIt, endIt;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      list<BackendDAE.IterCref> iterCrefs;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr as BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=iterCrefs))),_,_)
    equation
      (lhs,(_,iterCrefs)) = Expression.traverseExpTopDown(lhs,setIteratedSubscriptInCref,(DAE.ICONST(idx),iterCrefs));
      (rhs,(_,iterCrefs)) = Expression.traverseExpTopDown(rhs,setIteratedSubscriptInCref,(DAE.ICONST(idx),iterCrefs));
  then BackendDAE.EQUATION(lhs,rhs,source,attr);
  else
    then eqIn;
  end matchcontinue;
end buildIteratedEquation1;

public function setIteratedSubscriptInCref "sets the subscript in the cref according the given iteration idx"
  input DAE.Exp expIn;
  input tuple<DAE.Exp, list<BackendDAE.IterCref>> tplIn; //idx, iterCrefs
  output DAE.Exp expOut;
  output Boolean cont;
  output tuple<DAE.Exp, list<BackendDAE.IterCref>> tplOut;
algorithm
  (expOut,cont,tplOut) := matchcontinue(expIn,tplIn)
    local
     Integer idxOffset;
     DAE.ComponentRef cref;
     DAE.Exp itExp, idxExp;
     DAE.Type ty;
     list<BackendDAE.IterCref> iterCrefs,restIterCrefs;
  case(_,(_,{}))
    then (expIn,false,tplIn);
  case(DAE.CREF(componentRef=cref, ty=ty),(idxExp,iterCrefs))
    equation
      // for loop
      (BackendDAE.ITER_CREF(iterator=DAE.ICONST(idxOffset))::restIterCrefs,iterCrefs) = List.split1OnTrue(iterCrefs, isIterCref, cref);
      idxExp = DAE.BINARY(idxExp, DAE.ADD(ty=DAE.T_INTEGER_DEFAULT), DAE.ICONST(idxOffset));
      idxExp = ExpressionSimplify.simplify(idxExp);
      cref = replaceFirstSubInCref(cref,DAE.INDEX(idxExp));
  then (DAE.CREF(cref, ty),true,(idxExp,listAppend(restIterCrefs,iterCrefs)));
  case(DAE.CREF(componentRef=cref, ty=ty),(idxExp,iterCrefs))
    equation
      // accumulated expressions
      (BackendDAE.ACCUM_ITER_CREF()::restIterCrefs,iterCrefs) = List.split1OnTrue(iterCrefs, isIterCref, cref);
      cref = replaceFirstSubInCref(cref, DAE.INDEX(idxExp));
  then (DAE.CREF(cref, ty),true,(idxExp,listAppend(restIterCrefs,iterCrefs)));
  else
     then (expIn,true,tplIn);
  end matchcontinue;
end setIteratedSubscriptInCref;

protected function replaceFirstSubInCref"replaces the first occuring subscript in the cref"
  input DAE.ComponentRef crefIn;
  input DAE.Subscript sub;
  output DAE.ComponentRef crefOut;
algorithm
  crefOut := matchcontinue(crefIn,sub)
    local
      DAE.Ident ident;
      DAE.Type identType;
      list<DAE.Subscript> subscriptLst;
      DAE.ComponentRef cref;
  case(DAE.CREF_QUAL(ident=ident, identType=identType, subscriptLst=subscriptLst, componentRef=cref),_)
    equation
      if List.hasOneElement(subscriptLst) then  subscriptLst = {sub}; end if;
    then DAE.CREF_QUAL(ident, identType, subscriptLst, cref);
  case(DAE.CREF_IDENT(ident=ident, identType=identType, subscriptLst=subscriptLst),_)
    equation
      if List.hasOneElement(subscriptLst) then  subscriptLst = {sub}; end if;
    then DAE.CREF_IDENT(ident, identType, subscriptLst);
  else
    then crefIn;
  end matchcontinue;
end replaceFirstSubInCref;

public function reduceLoopExpressions "strip the higher indexes in accumulated iterations"
  input DAE.Exp expIn;
  input Integer maxSub;
  output DAE.Exp expOut;
  output Boolean notRemoved;
algorithm
  (expOut,notRemoved) := matchcontinue(expIn,maxSub)
    local
      Boolean b, b1, b2;
      DAE.ComponentRef cref;
      DAE.Exp exp, exp1, exp2;
      DAE.Type ty;
      DAE.Operator op;
  case(DAE.CREF(componentRef=cref),_)
    equation
      b = intLe(getIndexSubScript(listHead(ComponentReference.crefSubs(cref))),maxSub);
        //print("crerfsub: "+intString(getIndexSubScript(listHead(ComponentReference.crefSubs(cref))))+" <> "+intString(maxSub)+"\n");
        //print("reduce cref: "+ComponentReference.crefStr(cref)+" is higher sub: "+boolString(b)+"\n");
  then (expIn,b);

  case(DAE.BINARY(exp1=exp1, operator=op, exp2=exp2),_)
    equation
      (exp1,b1) = reduceLoopExpressions(exp1,maxSub);
      (exp2,b2) = reduceLoopExpressions(exp2,maxSub);
        //print("exp: "+ExpressionDump.printExpStr(expIn)+" b1: "+boolString(b1)+" b2: "+boolString(b2)+"\n");
      if b1 and not b2 then
        exp = exp1;
      elseif b2 and not b1 then
        exp = exp2;
      else
        exp = DAE.BINARY(exp1,op,exp2);
      end if;
        //print("expOut: "+ExpressionDump.printExpStr(exp)+"\n");
  then (exp,boolOr(b1,b2));

  case(DAE.UNARY(operator=op, exp=exp),_)
    equation
      (exp,b) = reduceLoopExpressions(exp,maxSub);
  then (exp,b);
   else
     equation
         //print("else: "+ExpressionDump.dumpExpStr(expIn,0)+"\n");
     then (expIn,true);
  end matchcontinue;
end reduceLoopExpressions;

protected function addLoopInfosForClassEqs
  input list<BackendDAE.Equation> classEqs;
  input list<DAE.ComponentRef> arrayCrefs;
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(classEqs, arrayCrefs, foldIn)
    local
      BackendDAE.Equation eq;
      BackendDAE.LoopInfo loopInfo;
      list<BackendDAE.Equation> similarEqs, rest;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrayCrefs;
      list<DAE.Subscript> subs;
      list<Integer> idxs;
      list<BackendDAE.IterCref> iterCrefs;
      Integer start, range;
  case({},_,_)
    equation
      then foldIn;
  case(eq::rest,_,_)
    equation
      //get similar equations
      (similarEqs,rest) = List.separate1OnTrue(classEqs,equationEqualNoCrefSubs,eq);
        //BackendDump.dumpEquationList(similarEqs,"similarEqs");
      range = listLength(similarEqs)-1;
        //print("range: "+intString(range)+"\n");
      (iterCrefs,start) = getIterCrefsFromEqs(similarEqs,arrayCrefs);
        //print("iterCrfs "+stringDelimitList(List.map(iterCrefs,BackendDump.printIterCrefStr),"\n")+"\n");
      loopInfo = BackendDAE.LOOP(DAE.ICONST(start),DAE.ICONST(intAdd(start,range)),listReverse(iterCrefs));
        //print("loopInfo "+BackendDump.printLoopInfoStr(loopInfo)+"\n");
      eq = setLoopInfoInEq(loopInfo,eq);
        //print("eq "+BackendDump.equationString(eq)+"\n");
      rest = addLoopInfosForClassEqs(rest, arrayCrefs, eq::foldIn);
    then
      rest;
  else
    then foldIn;
  end matchcontinue;
end addLoopInfosForClassEqs;

protected function addLoopInfosForMixEqs
  input list<BackendDAE.Equation> mixEqs;
  input list<DAE.ComponentRef> arrayCrefs;
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(mixEqs, arrayCrefs, foldIn)
    local
      BackendDAE.Equation eq;
      BackendDAE.LoopInfo loopInfo;
      list<BackendDAE.Equation> similarEqs, rest;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrayCrefs;
      list<DAE.Subscript> subs;
      list<Integer> idxs;
      list<BackendDAE.IterCref> iterCrefs;
      Integer startIt, range, endIt;
  case({},_,_)
    equation
      then foldIn;
  case(eq::rest,_,_)
    equation
      //get similar equations
      (similarEqs,rest) = List.separate1OnTrue(mixEqs,equationEqualNoCrefSubs,eq);
        //BackendDump.dumpEquationList(similarEqs,"similarEqs");
      range = listLength(similarEqs)-1;
        //print("range: "+intString(range)+"\n");
      if intNe(range,0) then
        // there are iteraded equations
        (iterCrefs,startIt) = getIterCrefsFromEqs(similarEqs,arrayCrefs);
          //print("iters "+stringDelimitList(List.map(iterCrefs,BackendDump.printIterCrefStr),"\n")+"\n");
        loopInfo = BackendDAE.LOOP(DAE.ICONST(startIt),DAE.ICONST(intAdd(startIt,range)),iterCrefs);
      else
        // there is an iterated operation e.g. x[1]+x[2]+x[3]+...
        (iterCrefs,startIt,endIt) = getAccumulatedIterCrefsFromEqs(similarEqs,arrayCrefs);
        if listEmpty(iterCrefs) then loopInfo = BackendDAE.NO_LOOP();
        else loopInfo = BackendDAE.LOOP(DAE.ICONST(startIt),DAE.ICONST(endIt),iterCrefs);
        end if;
      end if;
      eq = setLoopInfoInEq(loopInfo,eq);
      rest = addLoopInfosForMixEqs(rest, arrayCrefs, eq::foldIn);
    then
      rest;
  else
    then foldIn;
  end matchcontinue;
end addLoopInfosForMixEqs;

protected function getIterCrefsFromEqs
  input list<BackendDAE.Equation> eqs;
  input list<DAE.ComponentRef> arrCrefs;
  output list<BackendDAE.IterCref> iterCrefs;
  output Integer start;
protected
  list<DAE.ComponentRef> crefs;
  list<DAE.Subscript> subs;
  list<Integer> idxs, idxs0 = {};
  list<DAE.Exp> idxExps;
  Integer min = 1, max = 1;
algorithm
  for eq in eqs loop
    crefs := BackendEquation.equationCrefs(eq);
    crefs := List.filter1OnTrue(crefs,crefPartlyEqualToCrefs,arrCrefs);
    subs := List.flatten(List.map(crefs,ComponentReference.crefSubs));
    idxs := List.map(subs,getIndexSubScript);
      //print("idxs "+stringDelimitList(List.map(idxs,intString),", ")+"\n");
    if listEmpty(idxs0) then idxs0 := idxs; end if;
    idxs0 := List.threadMap(idxs0,idxs,intMin);
      //print("idxs0 "+stringDelimitList(List.map(idxs0,intString),", ")+"\n");
    min := intMin(List.fold(idxs,intMin,listHead(idxs)),min);
  end for;
  idxs0 := List.map1(idxs0,intSub,min);
  idxExps := List.map(idxs0,Expression.makeIntegerExp);
  iterCrefs := List.threadMap(crefs,idxExps,makeIterCref);
  start := min;
end getIterCrefsFromEqs;

protected function getAccumulatedIterCrefsFromEqs
  input list<BackendDAE.Equation> eqs;
  input list<DAE.ComponentRef> arrCrefs;
  output list<BackendDAE.IterCref> iterCrefs;
  output Integer startIt;
  output Integer endIt;
protected
  list<DAE.ComponentRef> crefs;
  list<DAE.Subscript> subs;
  list<Integer> idxs,idxs0 = {};
  list<DAE.Exp> idxExps;
  Integer min = 1, max = 1;
algorithm
  for eq in eqs loop
    crefs := BackendEquation.equationCrefs(eq);
    crefs := List.filter1OnTrue(crefs,crefPartlyEqualToCrefs,arrCrefs);
    //print("shared Crefs: "+stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr),"\n|")+"\n\n");
    subs := List.flatten(List.map(crefs,ComponentReference.crefSubs));
    idxs := List.map(subs,getIndexSubScript);
    //print("idxs "+stringDelimitList(List.map(idxs,intString),", ")+"\n");
    min := List.fold(idxs,intMin,listHead(idxs));
    max := List.fold(idxs,intMax,listHead(idxs));
  end for;
    //print("min "+intString(min)+" max "+intString(max)+"\n");
  if intNe(min,max) then
    iterCrefs := {BackendDAE.ACCUM_ITER_CREF(listHead(crefs),DAE.ADD(DAE.T_REAL_DEFAULT))};
  else
    iterCrefs := {};
  end if;
  startIt := min;
  endIt := max;
end getAccumulatedIterCrefsFromEqs;

protected function getIndexSubScript
  input DAE.Subscript sub;
  output Integer int;
algorithm
  DAE.INDEX(DAE.ICONST(int)) := sub;
end getIndexSubScript;

protected function dispatchLoopEquations
  input BackendDAE.Equation eqIn;
  input list<DAE.ComponentRef> arrayCrefs; //headCrefs
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tplIn; //classEqs,mixEqs,nonArrEqs
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tplOut;//classEqs,mixEqs,nonArrEqs
algorithm
  tplOut := matchcontinue(eqIn,arrayCrefs,tplIn)
    local
      list<BackendDAE.Equation> classEqs,mixEqs,nonArrEqs;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrCrefs;
      tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tpl;
    case(_,_,(classEqs,mixEqs,nonArrEqs))
      equation
        crefs = BackendEquation.equationCrefs(eqIn);
        (arrCrefs,nonArrCrefs) = List.separate1OnTrue(crefs,crefPartlyEqualToCrefs,arrayCrefs);
        if listEmpty(nonArrCrefs) then
          classEqs = eqIn::classEqs;
        elseif listEmpty(arrCrefs) then
          nonArrEqs = eqIn::nonArrEqs;
        else
          mixEqs = eqIn::mixEqs;
        end if;
      then (classEqs,mixEqs,nonArrEqs);
  end matchcontinue;
end dispatchLoopEquations;

protected function crefPartlyEqualToCrefs
  input DAE.ComponentRef cref0;
  input list<DAE.ComponentRef> crefLst;
  output Boolean b;
algorithm
  b := List.exist1(crefLst,crefPartlyEqual,cref0);
end crefPartlyEqualToCrefs;

protected function crefPartlyEqual
  input DAE.ComponentRef cref0;
  input DAE.ComponentRef cref1;
  output Boolean partlyEq;
algorithm
  partlyEq := matchcontinue(cref0,cref1)
    local
      Boolean b;
      DAE.ComponentRef cref01, cref11;
  case(DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then cref0.ident ==cref1.ident;
  case(DAE.CREF_QUAL(componentRef=cref01), DAE.CREF_QUAL(componentRef=cref01))
    equation
      if cref0.ident ==cref1.ident then b = crefPartlyEqual(cref01,cref01);
      else  b = false;
      end if;
    then b;
  case(DAE.CREF_QUAL(), DAE.CREF_IDENT())
      then cref0.ident ==cref1.ident;
  case(DAE.CREF_IDENT(), DAE.CREF_QUAL())
      then cref0.ident ==cref1.ident;
  else
    then false;
  end matchcontinue;
end crefPartlyEqual;

protected function getArrayVarCrefs"gets the array-cref and its dimension from a var."
  input BackendDAE.Var varIn;
  input tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tplIn; //{headCref,range,tailcrefs},arrVarlst
  output tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tplOut;
algorithm
  tplOut := matchcontinue(varIn,tplIn)
    local
      Integer idx;
      list<Integer> ranges;
      list<BackendDAE.Var> arrVars;
      DAE.ComponentRef cref, crefHead, crefTail;
      Option<DAE.ComponentRef> crefTailOpt;
      list<DAE.ComponentRef> crefLst;
      list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> tplLst;
      tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tpl;
  case(BackendDAE.VAR(varName=cref),(tplLst,arrVars))
    equation
    true = ComponentReference.isArrayElement(cref);
    (crefHead,idx,crefTailOpt) = ComponentReference.stripArrayCref(cref);
    if Util.isSome(crefTailOpt) then
      crefLst = {Util.getOption(crefTailOpt)};
    else
      crefLst = {};
    end if;
    (tplLst,arrVars) = addToArrayCrefLst(tplLst,varIn,(crefHead,idx,crefLst),{},arrVars);
    tpl = (tplLst,arrVars);
  then tpl;
  else
    then tplIn;
  end matchcontinue;
end getArrayVarCrefs;

protected function addToArrayCrefLst"checks if the tplRef-cref is already in the list, if not append, if yes update index"
  input list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> tplLstIn;
  input BackendDAE.Var varIn;
  input tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>> tplRef;
  input list<tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>>> tplLstFoldIn;
  input list<BackendDAE.Var> varLstIn;
  output list<tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>>> tplLstFoldOut;
  output list<BackendDAE.Var> varLstOut;
algorithm
  (tplLstFoldOut,varLstOut) := matchcontinue(tplLstIn,varIn,tplRef,tplLstFoldIn,varLstIn)
    local
      Integer idx0,idx1;
      list<BackendDAE.Var> varLst;
      DAE.ComponentRef cref0,cref1,crefTailRef;
      list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> rest, tplLst;
      list<DAE.ComponentRef> tailCrefs0, tailCrefs1;
  case((cref0,idx0,tailCrefs0)::rest,_,(cref1,idx1,{crefTailRef}),_,_)
    equation
    // this cref already exist, update idx, append tailCrefs if necessary
    true = ComponentReference.crefEqual(cref0,cref1);
    if List.notMember(crefTailRef,tailCrefs0) then
      tailCrefs0 = crefTailRef::tailCrefs0;
      //append var with new tail
      varLst =varIn::varLstIn;
    else
      varLst = varLstIn;
    end if;
    tplLst = (cref0,intMax(idx0,idx1),tailCrefs0)::rest;
    tplLst = listAppend(listReverse(tplLst),tplLstFoldIn);
  then (tplLst,varLst);

  case((cref0,idx0,tailCrefs0)::rest,_,(cref1,idx1,tailCrefs1),_,_)
    equation
      // this cref is not the same, continue
    false = ComponentReference.crefEqual(cref0,cref1);
    (tplLst,varLst) = addToArrayCrefLst(rest,varIn,tplRef,(cref0,idx0,tailCrefs0)::tplLstFoldIn,varLstIn);
  then (tplLst,varLst);

  case({},_,(cref1,idx1,tailCrefs1),_,_)
    equation
      // this cref is new, append
    tplLst = (cref1,idx1,tailCrefs1)::tplLstFoldIn;
  then (tplLst,varIn::varLstIn);

  end matchcontinue;
end addToArrayCrefLst;


protected function getArrayVars
  input BackendDAE.Var varIn;
  input tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplIn; //non-array vars,arrayVars
  output tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplOut;
algorithm
  tplOut := matchcontinue(varIn,tplIn)
    local
      DAE.ComponentRef cref;
      list<BackendDAE.Var> varLstIn, arrVarLstIn;
  case(BackendDAE.VAR(varName=cref),(varLstIn, arrVarLstIn))
    equation
    true = ComponentReference.isArrayElement(cref);
  then(varLstIn, varIn::arrVarLstIn);
  case(_,(varLstIn, arrVarLstIn))
    equation
  then(varIn::varLstIn, arrVarLstIn);
  end matchcontinue;
end getArrayVars;

protected function setLoopInfoInEquationAttributes
  input BackendDAE.LoopInfo loopInfo;
  input BackendDAE.EquationAttributes eqAttIn;
  output BackendDAE.EquationAttributes eqAttOut;
protected
  Boolean differentiated;
  BackendDAE.EquationKind kind;
  Integer subPartitionIndex;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(differentiated=differentiated, kind=kind, subPartitionIndex=subPartitionIndex) := eqAttIn;
  eqAttOut := BackendDAE.EQUATION_ATTRIBUTES(differentiated, kind, subPartitionIndex, loopInfo);
end setLoopInfoInEquationAttributes;

protected function setLoopInfoInEq
  input BackendDAE.LoopInfo loopInfo;
  input BackendDAE.Equation eqIn;
  output BackendDAE.Equation eqOut;
algorithm
  eqOut := match(loopInfo,eqIn)
    local
      DAE.Exp e11,e12;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
    case (_,BackendDAE.EQUATION(exp=e11, scalar=e12, source=source, attr=attr))
      equation
        attr = setLoopInfoInEquationAttributes(loopInfo,attr);
    then BackendDAE.EQUATION(e11, e12, source, attr=attr);
  end match;
end setLoopInfoInEq;

protected function makeIterCref "makes a IteratedCref with the given cref and iterator exp."
  input DAE.ComponentRef cref;
  input DAE.Exp exp;
  output BackendDAE.IterCref itcref;
algorithm
  itcref := BackendDAE.ITER_CREF(cref,exp);
end makeIterCref;

public function equationEqualNoCrefSubs "
  Returns true if two equations are equal without considering subscripts"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue (e1, e2)
    local
      DAE.Exp e11, e12, e21, e22, exp1, exp2;
      DAE.ComponentRef cr1, cr2;
      DAE.Algorithm alg1, alg2;
      list<DAE.Exp> explst1, explst2;
    case (_, _) equation
      true = referenceEq(e1, e2);
    then true;
    case (BackendDAE.EQUATION(exp=e11, scalar=e12), BackendDAE.EQUATION(exp=e21, scalar=e22)) equation
      res = boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22));
    then res;
    case (BackendDAE.ARRAY_EQUATION(left=e11, right=e12), BackendDAE.ARRAY_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22));
    then res;
    case (BackendDAE.COMPLEX_EQUATION(left=e11, right=e12), BackendDAE.COMPLEX_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22));
    then res;
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr1, exp=exp1), BackendDAE.SOLVED_EQUATION(componentRef=cr2, exp=exp2)) equation
      res = boolAnd(ComponentReference.crefEqualWithoutSubs(cr1, cr2), expEqualNoCrefSubs(exp1, exp2));
    then res;
    case (BackendDAE.RESIDUAL_EQUATION(exp=exp1), BackendDAE.RESIDUAL_EQUATION(exp=exp2)) equation
      res = expEqualNoCrefSubs(exp1, exp2);
    then res;
    case (BackendDAE.ALGORITHM(alg=alg1), BackendDAE.ALGORITHM(alg=alg2)) equation
      explst1 = Algorithm.getAllExps(alg1);
      explst2 = Algorithm.getAllExps(alg2);
      res = List.isEqualOnTrue(explst1, explst2, expEqualNoCrefSubs);
    then res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left=cr1, right=exp1)), BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_EQ(left=cr2, right=exp2))) equation
      res = boolAnd(ComponentReference.crefEqualWithoutSubs(cr1, cr2), expEqualNoCrefSubs(exp1, exp2));
    then res;
    else false;
  end matchcontinue;
end equationEqualNoCrefSubs;

public function expEqualNoCrefSubs
  "Returns true if the two expressions are equal, otherwise false."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outEqual;
algorithm
  // Return true if the references are the same.
  if referenceEq(inExp1, inExp2) then
    outEqual := true;
    return;
  end if;

  // Return false if the expressions are not of the same type.
  if valueConstructor(inExp1) <> valueConstructor(inExp2) then
    outEqual := false;
    return;
  end if;

  // Otherwise, check if the expressions are equal or not.
  // Since the expressions have already been verified to be of the same type
  // above we can match on only one of them to allow the pattern matching to
  // optimize this to jump directly to the correct case.
  outEqual := match(inExp1)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.Path p;
      DAE.Exp e, e1, e2;
      Option<DAE.Exp> oe;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
      DAE.Operator op;
      DAE.ComponentRef cr;
      DAE.Type ty;

    case DAE.ICONST()
      algorithm
        DAE.ICONST(integer = i) := inExp2;
      then
        inExp1.integer == i;

    case DAE.RCONST()
      algorithm
        DAE.RCONST(real = r) := inExp2;
      then
        inExp1.real == r;

    case DAE.SCONST()
      algorithm
        DAE.SCONST(string = s) := inExp2;
      then
        inExp1.string == s;

    case DAE.BCONST()
      algorithm
        DAE.BCONST(bool = b) := inExp2;
      then
        inExp1.bool == b;

    case DAE.ENUM_LITERAL()
      algorithm
        DAE.ENUM_LITERAL(name = p) := inExp2;
      then
        Absyn.pathEqual(inExp1.name, p);

    case DAE.CREF()
      algorithm
        DAE.CREF(componentRef = cr) := inExp2;
      then
        ComponentReference.crefEqualWithoutSubs(inExp1.componentRef, cr);

    case DAE.ARRAY()
      algorithm
        DAE.ARRAY(ty = ty, array = expl) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubsList(inExp1.array, expl);

    case DAE.MATRIX()
      algorithm
        DAE.MATRIX(ty = ty, matrix = mexpl) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubsListList(inExp1.matrix, mexpl);

    case DAE.BINARY()
      algorithm
        DAE.BINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.LBINARY()
      algorithm
        DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.UNARY()
      algorithm
        DAE.UNARY(exp = e, operator = op) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.LUNARY()
      algorithm
        DAE.LUNARY(exp = e, operator = op) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.RELATION()
      algorithm
        DAE.RELATION(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.IFEXP()
      algorithm
        DAE.IFEXP(expCond = e, expThen = e1, expElse = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.expCond, e) and
        expEqualNoCrefSubs(inExp1.expThen, e1) and
        expEqualNoCrefSubs(inExp1.expElse, e2);

    case DAE.CALL()
      algorithm
        DAE.CALL(path = p, expLst = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.expLst, expl);

    case DAE.RECORD()
      algorithm
        DAE.RECORD(path = p, exps = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.exps, expl);

    case DAE.PARTEVALFUNCTION()
      algorithm
        DAE.PARTEVALFUNCTION(path = p, expList = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.expList, expl);

    case DAE.RANGE()
      algorithm
        DAE.RANGE(start = e1, step = oe, stop = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.start, e1) and
        expEqualNoCrefSubs(inExp1.stop, e2) and
        expEqualNoCrefSubsOpt(inExp1.step, oe);

    case DAE.TUPLE()
      algorithm
        DAE.TUPLE(PR = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.PR, expl);

    case DAE.CAST()
      algorithm
        DAE.CAST(ty = ty, exp = e) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.ASUB()
      algorithm
        DAE.ASUB(exp = e, sub = expl) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e) and expEqualNoCrefSubsList(inExp1.sub, expl);

    case DAE.SIZE()
      algorithm
        DAE.SIZE(exp = e, sz = oe) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e) and expEqualNoCrefSubsOpt(inExp1.sz, oe);

    case DAE.REDUCTION()
      // Reductions contain too much information to compare in a sane manner.
      then valueEq(inExp1, inExp2);

    case DAE.LIST()
      algorithm
        DAE.LIST(valList = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.valList, expl);

    case DAE.CONS()
      algorithm
        DAE.CONS(car = e1, cdr = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.car, e1) and expEqualNoCrefSubs(inExp1.cdr, e2);

    case DAE.META_TUPLE()
      algorithm
        DAE.META_TUPLE(listExp = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.listExp, expl);

    case DAE.META_OPTION()
      algorithm
        DAE.META_OPTION(exp = oe) := inExp2;
      then
        expEqualNoCrefSubsOpt(inExp1.exp, oe);

    case DAE.METARECORDCALL()
      algorithm
        DAE.METARECORDCALL(path = p, args = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and expEqualNoCrefSubsList(inExp1.args, expl);

    case DAE.MATCHEXPRESSION()
      then valueEq(inExp1, inExp2);

    case DAE.BOX()
      algorithm
        DAE.BOX(exp = e) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.UNBOX()
      algorithm
        DAE.UNBOX(exp = e) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.SHARED_LITERAL()
      algorithm
        DAE.SHARED_LITERAL(index = i) := inExp2;
      then
        inExp1.index == i;

    else false;
  end match;
end expEqualNoCrefSubs;


protected function expEqualNoCrefSubsOpt
  input Option<DAE.Exp> inExp1;
  input Option<DAE.Exp> inExp2;
  output Boolean outEqual;
protected
  DAE.Exp e1, e2;
algorithm
  outEqual := match(inExp1, inExp2)
    case (NONE(), NONE()) then true;
    case (SOME(e1), SOME(e2)) then expEqualNoCrefSubs(e1, e2);
    else false;
  end match;
end expEqualNoCrefSubsOpt;

protected function expEqualNoCrefSubsList
  input list<DAE.Exp> inExpl1;
  input list<DAE.Exp> inExpl2;
  output Boolean outEqual;
protected
  DAE.Exp e2;
  list<DAE.Exp> rest_expl2 = inExpl2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  if listLength(inExpl1) <> listLength(inExpl2) then
    outEqual := false;
    return;
  end if;

  for e1 in inExpl1 loop
    e2 :: rest_expl2 := rest_expl2;

    // Return false if the expressions are not equal.
    if not expEqualNoCrefSubs(e1, e2) then
      outEqual := false;
      return;
    end if;
  end for;

  outEqual := true;
end expEqualNoCrefSubsList;

protected function expEqualNoCrefSubsListList
  input list<list<DAE.Exp>> inExpl1;
  input list<list<DAE.Exp>> inExpl2;
  output Boolean outEqual;
protected
  list<DAE.Exp> expl2;
  list<list<DAE.Exp>> rest_expl2 = inExpl2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  if listLength(inExpl1) <> listLength(inExpl2) then
    outEqual := false;
    return;
  end if;

  for expl1 in inExpl1 loop
    expl2 :: rest_expl2 := rest_expl2;

    // Return false if the expression lists are not equal.
    if not expEqualNoCrefSubsList(expl1, expl2) then
      outEqual := false;
      return;
    end if;
  end for;

  outEqual := true;
end expEqualNoCrefSubsListList;

protected function getIterationCrefIterator
  input BackendDAE.IterCref cref;
  output Integer i;
algorithm
  BackendDAE.ITER_CREF(iterator = DAE.ICONST(i)) := cref;
end getIterationCrefIterator;

protected function isIterCref"the iteration cref is a equal to the cref"
  input BackendDAE.IterCref iterCref;
  input DAE.ComponentRef cref;
  output Boolean b;
algorithm
  b := match(iterCref,cref)
    local
      DAE.ComponentRef cref1;
  case(BackendDAE.ITER_CREF(cref=cref1),_)
    then ComponentReference.crefEqualWithoutSubs(cref1,cref);
  case(BackendDAE.ACCUM_ITER_CREF(cref=cref1),_)
    then ComponentReference.crefEqualWithoutSubs(cref1,cref);
  else then false;
  end match;
end isIterCref;

public function isLoopEquation
  input BackendDAE.Equation eqIn;
  output Boolean isLoopEq;
algorithm
  isLoopEq := match(eqIn)
  case(BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP())))
    then true;
  case(BackendDAE.SOLVED_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP())))
    then true;
  else
    then false;
  end match;
end isLoopEquation;

public function isAccumLoopEquation
  input BackendDAE.Equation eqIn;
  output Boolean isLoopEq;
algorithm
  isLoopEq := match(eqIn)
  case(BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=BackendDAE.ACCUM_ITER_CREF()::_))))
    then true;
  case(BackendDAE.SOLVED_EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=BackendDAE.ACCUM_ITER_CREF()::_))))
    then true;
  else
    then false;
  end match;
end isAccumLoopEquation;

public function insertSUMexp "exp traversal function for insertSUMexp"
  input DAE.Exp expIn;
  input tuple<DAE.ComponentRef, DAE.Exp> tplIn; //<to be replaced, replace with>
  output DAE.Exp expOut;
  output tuple<DAE.ComponentRef, DAE.Exp> tplOut;
algorithm
  (expOut,tplOut) := matchcontinue(expIn,tplIn)
    local
      DAE.ComponentRef cref0,cref1;
      DAE.Exp repl, exp1, exp2;
      DAE.Operator op;
   case(DAE.BINARY(exp1=exp1, operator=op,exp2=exp2),(cref0,repl))
     equation
       (exp1,_) = insertSUMexp(exp1,tplIn);
       (exp2,_) = insertSUMexp(exp2,tplIn);
     then(DAE.BINARY(exp1,op,exp2),tplIn);
   case(DAE.UNARY(operator=op,exp=exp1),(cref0,repl))
     equation
       (exp1,_) = insertSUMexp(exp1,tplIn);
     then(DAE.UNARY(op,exp1),tplIn);
   case(DAE.CREF(componentRef=cref1),(cref0,repl))
     equation
       true = crefPartlyEqual(cref0,cref1);
     then(repl,tplIn);
   else
     then (expIn,tplIn);
   end matchcontinue;
end insertSUMexp;

public function rollOutArrays
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
protected
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst;
  BackendDAE.EquationArray eqs "ordered Equations";
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets "the statesets of the system";
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs, m=m, mT=mT, matching=matching, stateSets=stateSets, partitionKind=partitionKind) := sysIn;
  varLst := BackendVariable.varList(vars);
    //BackendDump.dumpVarList(varLst,"varLst1");
  varLst := List.fold(varLst,rollOutArrays1,{});
    //BackendDump.dumpVarList(varLst,"varLst2");
  vars := BackendVariable.listVar(varLst);
  sysOut := BackendDAE.EQSYSTEM(vars,eqs,m,mT,matching,stateSets,partitionKind);
  sharedOut := sharedIn;
end rollOutArrays;

protected function rollOutArrays1
  input BackendDAE.Var inVar;
  input list<BackendDAE.Var> foldIn;
  output list<BackendDAE.Var> foldOut;
algorithm
  foldOut := matchcontinue(inVar, foldIn)
    local
      Integer i,dim;
      DAE.ComponentRef cref;
      DAE.Subscript sub;
      list<BackendDAE.Var> varLst;
      list<DAE.ComponentRef> crefLst;
      list<DAE.Subscript> subs;
  case(BackendDAE.VAR(varName=cref, arryDim={DAE.DIM_INTEGER(integer=dim)}),_)
   equation
    {DAE.INDEX(DAE.ICONST(integer = i))} = ComponentReference.crefSubs(cref);
    if intEq(i,1) then
      subs = List.map(List.intRange(dim),Expression.intSubscript);
      crefLst = List.map1r(subs,replaceFirstSubInCref,cref);
      varLst = List.map1(crefLst,BackendVariable.copyVarNewName,inVar);
    else
      varLst = {};
    end if;
   then listAppend(varLst,foldIn);
  else
    then inVar::foldIn;
  end matchcontinue;
end rollOutArrays1;


annotation(__OpenModelica_Interface="backend");
end Vectorization;
