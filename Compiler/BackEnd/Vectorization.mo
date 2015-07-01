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
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import Dump;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import List;
protected import SimCode;
protected import SimCodeVar;
protected import Util;

//--------------------------------
//--------------------------------
//--------------------------------

public function buildForLoops
  input BackendDAE.Variables varsIn;
  input list<BackendDAE.Equation> eqsIn;
  output BackendDAE.Variables varsOut;
  output list<BackendDAE.Equation> eqsOut;
protected
  Integer idx;
  list<BackendDAE.Equation> loopEqs;
  list<BackendDAE.Var> arrVars;
  list<Absyn.Exp> loopIds;
  list<BackendDAE.LoopInfo> loopInfos;
  list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  list<BackendDAE.Var> varLst, arrayVars;
  list<BackendDAE.Equation> classEqs,mixEqs,nonArrEqs;
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

    //BackendDump.dumpEquationList(classEqs,"classEqs");
    //BackendDump.dumpEquationList(mixEqs,"mixEqs");
    //BackendDump.dumpEquationList(nonArrEqs,"nonArrEqs");

  if true then

  //add loopinfos
  (idx,classEqs) := addLoopInfosForClassEqs(classEqs, List.map(arrayCrefs,Util.tuple31), (1,{}));
  (idx,mixEqs) := addLoopInfosForMixEqs(mixEqs, List.map(arrayCrefs,Util.tuple31), (idx,{}));
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

  else
    classEqs := buildBackendDAEForEquations(classEqs,{});
    //BackendDump.dumpEquationList(classEqs,"classEqs2");
    varsOut := varsIn;
    eqsOut := eqsIn;
  end if;
end buildForLoops;

//-----------------------------------------------
// the implementation for BackendDAE.FOR_EQUATION
//-----------------------------------------------

protected function buildBackendDAEForEquations"creates BackendDAE.FOR_EQUATION for similar equations"
  input list<BackendDAE.Equation> classEqs;
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(classEqs, foldIn)
    local
      Integer min, max, numCrefs;
      BackendDAE.Equation eq;
      DAE.Exp lhs,rhs, iterator;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      list<BackendDAE.Equation> similarEqs, rest, foldEqs;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax;
  case({},_)
    algorithm
      then foldIn;
  case(eq::rest,_)
    algorithm
      BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr) := eq;
      //get similar equations
      (similarEqs,rest) := List.separate1OnTrue(classEqs,equationEqualNoCrefSubs,eq);
      crefs := BackendEquation.equationCrefs(eq);
      numCrefs := listLength(crefs);
      // all crefs and their minimum as well as their max iterator
      crefMinMax := List.thread3Map(listReverse(crefs),List.fill(10,numCrefs),List.fill(0,numCrefs),Util.make3Tuple);
      crefMinMax :=  List.fold(similarEqs,getCrefIdcsForEquation,crefMinMax);

      min := List.fold(List.map(crefMinMax,Util.tuple32),intMin,10);
      max := List.fold(List.map(crefMinMax,Util.tuple33),intMax,0);
      // update crefs in equation
      iterator := DAE.CREF(DAE.CREF_IDENT("i",DAE.T_INTEGER_DEFAULT,{}),DAE.T_INTEGER_DEFAULT);
      (BackendDAE.EQUATION(exp=lhs,scalar=rhs),_) := BackendEquation.traverseExpsOfEquation(eq,setIteratorSubscriptCrefinEquation,(crefMinMax,iterator));
      eq := BackendDAE.FOR_EQUATION(iterator,DAE.ICONST(min),DAE.ICONST(max),lhs,rhs,source,attr);
      foldEqs := buildBackendDAEForEquations(rest,(eq::foldIn));
    then
      foldEqs;
  else
    then foldIn;
  end matchcontinue;
end buildBackendDAEForEquations;

protected function setIteratorSubscriptCrefinEquation"traverse function that replaces crefs in the exp according to the iterated crefMinMax"
  input DAE.Exp inExp;
  input tuple<list<tuple<DAE.ComponentRef,Integer,Integer>>,DAE.Exp> tplIn; //creMinMax,iterator
  output DAE.Exp outExp;
  output tuple<list<tuple<DAE.ComponentRef,Integer,Integer>>,DAE.Exp> tplOut;
algorithm
  (outExp,tplOut) := matchcontinue(inExp,tplIn)
    local
      Integer min, max;
      DAE.ComponentRef cref, refCref;
      DAE.Exp exp1, exp2,iterator, iterator1;
      DAE.Operator op;
      DAE.Type ty;
      tuple<DAE.ComponentRef,Integer,Integer> refCrefMinMax;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax0, crefMinMax1;

  case(DAE.CREF(componentRef=cref,ty=ty),(crefMinMax0,iterator))
    algorithm
      crefMinMax1 := {};
      for refCrefMinMax in crefMinMax0 loop
        (refCref,min,max) := refCrefMinMax;
         // if the cref fits the refCref, update the iterator
        if ComponentReference.crefEqualWithoutSubs(refCref,cref) then
          iterator1 := ExpressionSimplify.simplify(DAE.BINARY(iterator,DAE.ADD(DAE.T_INTEGER_DEFAULT),DAE.ICONST(min-1)));
          cref := replaceFirstSubInCref(cref,DAE.INDEX(iterator1));
        else
          // add the non used crefs to the fold list
          crefMinMax1 := refCrefMinMax::crefMinMax1;
        end if;
      end for;
    then (DAE.CREF(cref,ty),(crefMinMax1,iterator));

  case(DAE.BINARY(exp1=exp1,operator=op,exp2=exp2),(crefMinMax0,iterator))
    algorithm
      // continue traversing
      (exp1,(crefMinMax0,iterator))  := setIteratorSubscriptCrefinEquation(exp1,tplIn);
      (exp2,(crefMinMax0,iterator))  := setIteratorSubscriptCrefinEquation(exp2,(crefMinMax0,iterator));
    then (DAE.BINARY(exp1,op,exp2),(crefMinMax0,iterator));

  case(DAE.UNARY(operator=op,exp=exp1),(crefMinMax0,iterator))
    algorithm
      // continue traversing
      (exp1,(crefMinMax0,iterator))  := setIteratorSubscriptCrefinEquation(exp1,tplIn);
    then (DAE.UNARY(op,exp1),(crefMinMax0,iterator));

  else
    then (inExp,tplIn);
  end matchcontinue;
end setIteratorSubscriptCrefinEquation;


protected function getCrefIdcsForEquation"gets all crefs of the equation and dispatches the information about min and max subscript to crefMinMax"
  input BackendDAE.Equation eq;
  input list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMaxIn;
  output list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMaxOut;
algorithm
  crefMinMaxOut := matchcontinue(eq,crefMinMaxIn)
    local
      Integer pos,max,min,sub;
      DAE.ComponentRef cref, refCref;
      tuple<DAE.ComponentRef,Integer,Integer> refCrefMinMax;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax;
      list<DAE.ComponentRef> eqCrefs, crefs;
  case(BackendDAE.EQUATION(_),crefMinMax)
    algorithm
      eqCrefs := BackendEquation.equationCrefs(eq);
      //traverse all crefs of the equation
      for cref in eqCrefs loop
        {DAE.INDEX(DAE.ICONST(sub))} := ComponentReference.crefSubs(cref);
        pos := 1;
        for refCrefMinMax in crefMinMax loop
          (refCref,min,max) := refCrefMinMax;
          // if the cref fits the refCref, update min max
          if ComponentReference.crefEqualWithoutSubs(refCref,cref) then
            max := intMax(max,sub);
            min := intMin(min,sub);
            crefMinMax := List.replaceAt((refCref,min,max),pos,crefMinMax);
          end if;
          pos := pos+1;
        end for;
      end for;
    then crefMinMax;
  else
    then crefMinMaxIn;
  end matchcontinue;
end getCrefIdcsForEquation;

//-----------------------------------------------
//-----------------------------------------------

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
  then listAppend(varLst,varLstIn);
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
      Integer startIt,endIt, maxItOffset, endRange;
      list<Integer> idxOffsets;
      DAE.Exp lhs,rhs;
      DAE.ElementSource source;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqLst;
      list<BackendDAE.IterCref> iterCrefs;

  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=iterCrefs as BackendDAE.ITER_CREF()::_, startIt=DAE.ICONST(startIt),endIt=DAE.ICONST(endIt)))),_,_)
    algorithm
      // handle no accumulated equations here
       //print("eq: "+BackendDump.equationString(eqIn)+"\n");
      eqLst := {};
      idxOffsets := List.fold(iterCrefs,getIterationCrefIterator,{});
      maxItOffset := List.fold(idxOffsets,intMax,listHead(idxOffsets));
      endRange := intMin(endIt,2-maxItOffset);
        //print("maxItOffset "+intString(maxItOffset)+"\n");
        //print("start "+intString(startIt)+"\n");
        //print("end "+intString(endIt)+"\n");
        //print("endRange "+intString(endRange)+"\n");
      eqLst := buildIteratedEquation1(eqIn,startIt,endRange,{});
        //print("eqsOut: "+stringDelimitList(List.map(eqLst,BackendDump.equationString),"\n")+"\n");
      eqLst := listAppend(eqLst,foldIn);
  then eqLst;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=BackendDAE.ACCUM_ITER_CREF()::_, startIt=DAE.ICONST(startIt),endIt=DAE.ICONST(endIt)))),_,_)
    algorithm
      // accumulated equations, remove higher subscripts, no duplication
      eq := reduceLoopEquations(eqIn,arrayCrefs,2);
    then eq::foldIn;
  else
    algorithm
      // in case there is a higher idx
      (eq,_) := BackendEquation.traverseExpsOfEquation(eqIn,limitCrefSubscripts,2);
    then eq::foldIn;
  end matchcontinue;
end buildIteratedEquation;

protected function limitCrefSubscripts
  input DAE.Exp inExp;
  input Integer maxSubIn;
  output DAE.Exp outExp;
  output Integer maxSubOut;
algorithm
  (outExp,maxSubOut) := matchcontinue(inExp,maxSubIn)
    local
      Integer idx;
      DAE.ComponentRef cref;
      DAE.Type ty;
  case(DAE.CREF(componentRef=cref,ty=ty),_)
    equation
      {DAE.INDEX(DAE.ICONST(idx))} = ComponentReference.crefSubs(cref);
      true = intGt(idx,maxSubIn);
      cref = replaceFirstSubInCref(cref,DAE.INDEX(DAE.ICONST(maxSubIn)));
    then (DAE.CREF(cref,ty),maxSubIn);
  else
    then (inExp,maxSubIn);
  end matchcontinue;
end limitCrefSubscripts;

protected function buildIteratedEquation1
  input BackendDAE.Equation eqIn;
  input Integer idx;
  input Integer maxIdx; // used to shorten constant interators
  input list<BackendDAE.Equation> eqLstIn;
  output list<BackendDAE.Equation> eqLstOut;
algorithm
  eqLstOut := matchcontinue(eqIn,idx,maxIdx,eqLstIn)
    local
      DAE.Exp lhs,rhs, startIt, endIt;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Equation eq;
      list<BackendDAE.IterCref> iterCrefs;
      list<BackendDAE.Equation> eqLst;
  case(BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr as BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(crefs=iterCrefs))),_,_,eqLst)
    equation
      // its a loop equation
      true = intLe(idx,maxIdx);
      (lhs,(_,_,iterCrefs)) = Expression.traverseExpTopDown(lhs,setIteratedSubscriptInCref,(DAE.ICONST(idx),maxIdx,iterCrefs));
      (rhs,(_,_,iterCrefs)) = Expression.traverseExpTopDown(rhs,setIteratedSubscriptInCref,(DAE.ICONST(idx),maxIdx,iterCrefs));
      if Expression.expEqual(lhs,rhs) then
        eqLst = eqLst;
      else
        eqLst = buildIteratedEquation1(eqIn,idx+1,maxIdx,BackendDAE.EQUATION(lhs,rhs,source,attr)::eqLst);
      end if;
  then eqLst;
  else
    then eqLstIn;
  end matchcontinue;
end buildIteratedEquation1;

public function setIteratedSubscriptInCref "sets the subscript in the cref according the given iteration idx"
  input DAE.Exp expIn;
  input tuple<DAE.Exp, Integer, list<BackendDAE.IterCref>> tplIn; //idx, maxIdx, iterCrefs
  output DAE.Exp expOut;
  output Boolean cont;
  output tuple<DAE.Exp, Integer, list<BackendDAE.IterCref>> tplOut;
algorithm
  (expOut,cont,tplOut) := matchcontinue(expIn,tplIn)
    local
     Integer idxOffset,maxIdx,constIdx;
     String constIdxOffset;
     DAE.ComponentRef cref;
     DAE.Exp itExp, idxExp, idxExp0;
     DAE.Type ty;
     list<BackendDAE.IterCref> iterCrefs,restIterCrefs;
  case(_,(_,_,{}))
    then (expIn,false,tplIn);
  case(DAE.CREF(componentRef=cref, ty=ty),(idxExp0,maxIdx,iterCrefs))
    equation
      // iterated cref in a for-loop
      (BackendDAE.ITER_CREF(iterator=DAE.ICONST(idxOffset))::restIterCrefs,iterCrefs) = List.split1OnTrue(iterCrefs, isIterCref, cref);
      idxExp = DAE.BINARY(idxExp0, DAE.ADD(ty=DAE.T_INTEGER_DEFAULT), DAE.ICONST(idxOffset));
        //print("for "+ComponentReference.printComponentRefStr(cref)+" offset: "+intString(idxOffset)+" idxExp: "+ExpressionDump.printExpStr(idxExp)+"\n");
      idxExp = ExpressionSimplify.simplify(idxExp);
      cref = replaceFirstSubInCref(cref,DAE.INDEX(idxExp));
  then (DAE.CREF(cref, ty),true,(idxExp0,maxIdx,listAppend(restIterCrefs,iterCrefs)));

  case(DAE.CREF(componentRef=cref, ty=ty),(idxExp0,maxIdx,iterCrefs))
    equation
      // constant cref in a for-loop
      (BackendDAE.ITER_CREF(iterator=DAE.SCONST(constIdxOffset))::restIterCrefs,iterCrefs) = List.split1OnTrue(iterCrefs, isIterCref, cref);
      constIdx = stringInt(constIdxOffset);
      idxExp = DAE.ICONST(intMin(constIdx,maxIdx));
        //print("for "+ComponentReference.printComponentRefStr(cref)+" constIdx: "+intString(constIdx)+" idxExp: "+ExpressionDump.printExpStr(idxExp)+"\n");
      cref = replaceFirstSubInCref(cref,DAE.INDEX(idxExp));
  then (DAE.CREF(cref, ty),true,(idxExp0,maxIdx,listAppend(restIterCrefs,iterCrefs)));

  case(DAE.CREF(componentRef=cref, ty=ty),(idxExp0,maxIdx,iterCrefs))
    equation
      // accumulated expressions
      (BackendDAE.ACCUM_ITER_CREF()::restIterCrefs,iterCrefs) = List.split1OnTrue(iterCrefs, isIterCref, cref);
      cref = replaceFirstSubInCref(cref, DAE.INDEX(idxExp0));
  then (DAE.CREF(cref, ty),true,(idxExp0,maxIdx,listAppend(restIterCrefs,iterCrefs)));
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
      cref = replaceFirstSubInCref(cref,sub);
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
  input tuple<Integer,list<BackendDAE.Equation>> foldIn;
  output tuple<Integer,list<BackendDAE.Equation>> foldOut;
algorithm
  foldOut := matchcontinue(classEqs, arrayCrefs, foldIn)
    local
      BackendDAE.Equation eq;
      BackendDAE.LoopInfo loopInfo;
      list<BackendDAE.Equation> similarEqs, rest, foldEqs;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrayCrefs;
      list<DAE.Subscript> subs;
      list<Integer> idxs;
      list<BackendDAE.IterCref> iterCrefs;
      Integer start, range, idx;
      tuple<Integer,list<BackendDAE.Equation>> tpl;
  case({},_,_)
    equation
      then foldIn;
  case(eq::rest,_,(idx,foldEqs))
    equation
      //get similar equations
      (similarEqs,rest) = List.separate1OnTrue(classEqs,equationEqualNoCrefSubs,eq);
        //BackendDump.dumpEquationList(similarEqs,"similarEqs");
      range = listLength(similarEqs)-1;
        //print("range: "+intString(range)+"\n");
      (iterCrefs,start) = getIterCrefsFromEqs(similarEqs,arrayCrefs);
        //print("iterCrfs "+stringDelimitList(List.map(iterCrefs,BackendDump.printIterCrefStr),"\n")+"\n");
      loopInfo = BackendDAE.LOOP(idx,DAE.ICONST(start),DAE.ICONST(intAdd(start,range)),listReverse(iterCrefs));
        //print("loopInfo "+BackendDump.printLoopInfoStr(loopInfo)+"\n");
      eq = setLoopInfoInEq(loopInfo,eq);
        //print("eq "+BackendDump.equationString(eq)+"\n");
      tpl = addLoopInfosForClassEqs(rest, arrayCrefs, (idx+1,eq::foldEqs));
    then
      tpl;
  else
    then foldIn;
  end matchcontinue;
end addLoopInfosForClassEqs;

protected function addLoopInfosForMixEqs
  input list<BackendDAE.Equation> mixEqs;
  input list<DAE.ComponentRef> arrayCrefs;
  input tuple<Integer,list<BackendDAE.Equation>> foldIn;
  output tuple<Integer,list<BackendDAE.Equation>> foldOut;
algorithm
  foldOut := matchcontinue(mixEqs, arrayCrefs, foldIn)
    local
      BackendDAE.Equation eq;
      BackendDAE.LoopInfo loopInfo;
      list<BackendDAE.Equation> similarEqs, rest, foldEqs;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrayCrefs;
      list<DAE.Subscript> subs;
      list<Integer> idxs;
      list<BackendDAE.IterCref> iterCrefs;
      Integer startIt, range, endIt, idx;
      tuple<Integer,list<BackendDAE.Equation>> tpl;
  case({},_,_)
    equation
      then foldIn;
  case(eq::rest,_,(idx,foldEqs))
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
        loopInfo = BackendDAE.LOOP(idx,DAE.ICONST(startIt),DAE.ICONST(intAdd(startIt,range)),iterCrefs);
      else
        // there is an iterated operation e.g. x[1]+x[2]+x[3]+...
        (iterCrefs,startIt,endIt) = getAccumulatedIterCrefsFromEqs(similarEqs,arrayCrefs);
        if listEmpty(iterCrefs) then loopInfo = BackendDAE.NO_LOOP();
        else loopInfo = BackendDAE.LOOP(idx,DAE.ICONST(startIt),DAE.ICONST(endIt),iterCrefs);
        end if;
      end if;
      eq = setLoopInfoInEq(loopInfo,eq);
      tpl = addLoopInfosForMixEqs(rest, arrayCrefs, (idx+1,eq::foldEqs));
    then
      tpl;
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
  list<list<Integer>> idxLst;
  list<DAE.Exp> idxExps;
  Integer min = 1, max = 1;
algorithm
  idxLst := {};
  for eq in eqs loop
    crefs := BackendEquation.equationCrefs(eq);
    crefs := List.filter1OnTrue(crefs,crefPartlyEqualToCrefs,arrCrefs);
    subs := List.flatten(List.map(crefs,ComponentReference.crefSubs));
    idxs := List.map(subs,getIndexSubScript);
      //print("idxs "+stringDelimitList(List.map(idxs,intString),", ")+"\n");
    if listEmpty(idxLst) then idxLst := List.map(idxs,List.create);
    else idxLst := List.threadMap(idxs,idxLst,List.cons); end if;
      //print("idxLst "+stringDelimitList(List.map(idxLst,intLstString),"\n")+"\n");
    min := intMin(List.fold(idxs,intMin,listHead(idxs)),min);
      //print("min "+intString(min)+"\n");
  end for;
    //print("idxLst! "+stringDelimitList(List.map(idxLst,intLstString),"\n")+"\n");
  idxExps := List.map(idxLst,getIterCrefsFromEqs1);
  iterCrefs := List.threadMap(crefs,idxExps,makeIterCref);
  start := min;
end getIterCrefsFromEqs;

protected function getIterCrefsFromEqs1
  input list<Integer> iLstIn;
  output DAE.Exp eOut;
protected
  DAE.Exp e;
  Integer min,max,range;
algorithm
  if intEq(listLength(List.unique(iLstIn)),1) then
    //the iterated var does not change
    e := DAE.SCONST(intString(listGet(iLstIn,1)));
  else
    //get the offset
    min := List.fold(iLstIn,intMin,listHead(iLstIn));
    max := List.fold(iLstIn,intMax,listHead(iLstIn));
    range := listLength(iLstIn);
    e := DAE.ICONST(min-1);
  end if;
  eOut := e;
end getIterCrefsFromEqs1;

protected function intLstString
  input list<Integer> i1;
  output String s;
algorithm
  s := stringDelimitList(List.map(i1,intString),",");
end intLstString;

protected function intDiff
  input Integer i1;
  input Integer i2;
  output Integer i3;
algorithm
  i3 := intAbs(intSub(i1,i2));
end intDiff;

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
  case(DAE.CREF_QUAL(componentRef=cref01), DAE.CREF_QUAL(componentRef=cref11))
    equation
      if cref0.ident ==cref1.ident then b = crefPartlyEqual(cref01,cref11);
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
  BackendDAE.EQUATION_ATTRIBUTES attrs;
algorithm
  BackendDAE.EQUATION_ATTRIBUTES(differentiated=differentiated, kind=kind) := eqAttIn;
  eqAttOut := BackendDAE.EQUATION_ATTRIBUTES(differentiated, kind, loopInfo);
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
      list<DAE.Exp> explst1, explst2, terms1,terms2,commTerms;
      list<DAE.ComponentRef> crefs1,crefs2,commCrefs;
    case (_, _) equation
      true = referenceEq(e1, e2);
    then true;
    case (BackendDAE.EQUATION(exp=e11, scalar=e12), BackendDAE.EQUATION(exp=e21, scalar=e22)) equation
      if boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22)) then
        //its completely identical
        res=true;
      else
        // at least the crefs should be equal
        crefs1 = BackendEquation.equationCrefs(e1);
        crefs2 = BackendEquation.equationCrefs(e2);
        commCrefs = List.intersectionOnTrue(crefs1,crefs2,ComponentReference.crefEqualWithoutSubs);
        if intEq(listLength(crefs1),listLength(commCrefs)) and intEq(listLength(crefs2),listLength(commCrefs)) then
          //compare terms
          terms1 = listAppend(Expression.allTerms(e11),Expression.allTerms(e12));
          terms2 = listAppend(Expression.allTerms(e21),Expression.allTerms(e22));
            //print("We have to check the terms:\n");
            //print("terms1: "+stringDelimitList(List.map(terms1,ExpressionDump.printExpStr),"| ")+"\n");
            //print("terms2: "+stringDelimitList(List.map(terms2,ExpressionDump.printExpStr),"| ")+"\n");
          (commTerms,terms1,terms2) = List.intersection1OnTrue(terms1,terms2,expEqualNoCrefSubs);
          res =  listEmpty(terms1) and listEmpty(terms2);
            //print("is it the same: "+boolString(res)+"\n");
        else
          res = false;
        end if;
      end if;
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
  input list<Integer> iLstIn;
  output list<Integer> iLstOut;
protected
  Integer i;
algorithm
  try
    BackendDAE.ITER_CREF(iterator = DAE.ICONST(i)) := cref;
    iLstOut := i::iLstIn;
  else
    iLstOut := iLstIn;
  end try;
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

public function prepareVectorizedDAE0
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
algorithm
  (sysOut, sharedOut) := match (sysIn, sharedIn)
    local
      BackendDAE.Shared shared;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Var> varLst, addAlias, aliasLst, knownLst;
      list<BackendDAE.Equation> eqLst;
    case ( syst as BackendDAE.EQSYSTEM(),
           shared as BackendDAE.SHARED() )
      algorithm
        eqLst := BackendEquation.equationList(syst.orderedEqs);
        //BackendDump.dumpEquationList(eqLst,"eqsIn");
        //remove partly unrolled for-equations
        // occasionally, there is a constantly indexed var in the for-equation
        (eqLst,_) := updateIterCrefs(eqLst,({},{}));
        // (eqLst,_) := List.fold(eqLst,markUnrolledForEqs,({},{}));

        // set subscripts at end of equation crefs
        eqLst := List.map(listReverse(eqLst),setSubscriptsAtEndForEquation);

        // set subscripts at end of vars
        varLst := BackendVariable.varList(syst.orderedVars);
        aliasLst := BackendVariable.varList(shared.aliasVars);
        knownLst := BackendVariable.varList(shared.knownVars);
        varLst := List.map(varLst,appendSubscriptsInVar);
        aliasLst := List.map(aliasLst,appendSubscriptsInVar);
        knownLst := List.map(knownLst,appendSubscriptsInVar);
        syst.orderedVars := BackendVariable.listVar1(varLst);
        shared.aliasVars := BackendVariable.listVar1(aliasLst);
        shared.knownVars := BackendVariable.listVar1(knownLst);
        shared.removedEqs := BackendEquation.listEquation({});
        syst.orderedEqs := BackendEquation.listEquation(eqLst);
        //BackendDump.dumpEquationList(eqLst,"eqsOut");
        //BackendDump.dumpVariables(vars,"VARSOUT");
      then (syst, shared);
  end match;
end prepareVectorizedDAE0;

protected function setSubscriptsAtEndForEquation
  input BackendDAE.Equation eqIn;
  output BackendDAE.Equation eqOut;
algorithm
  eqOut := matchcontinue(eqIn)
    local
      DAE.Exp lhs,rhs;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      BackendDAE.LoopInfo loopInfo;
      BackendDAE.Equation eq;
      list<BackendDAE.IterCref> iterCrefs;
      Integer loopId;
      DAE.Exp startIt;
      DAE.Exp endIt;
  case(BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source, attr = attr as BackendDAE.EQUATION_ATTRIBUTES(loopInfo=
    BackendDAE.LOOP(loopId=loopId,startIt=startIt,endIt=endIt,crefs=iterCrefs))))
    algorithm
      lhs := Expression.traverseExpBottomUp(lhs,appendSubscriptsInExp,"bla");
      rhs := Expression.traverseExpBottomUp(rhs,appendSubscriptsInExp,"bla");
      eq := BackendDAE.EQUATION(lhs,rhs,source,attr);
      iterCrefs := List.map(iterCrefs,setSubscriptAtEndForIterCref);
      loopInfo := BackendDAE.LOOP(loopId,startIt,endIt,iterCrefs);
      eq := setLoopInfoInEq(loopInfo,eq);
    then eq;
  case(BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source, attr=attr))
    algorithm
      lhs := Expression.traverseExpBottomUp(lhs,appendSubscriptsInExp,"bla");
      rhs := Expression.traverseExpBottomUp(rhs,appendSubscriptsInExp,"bla");
      eq := BackendDAE.EQUATION(lhs,rhs,source,attr);
    then eq;
  end matchcontinue;
end setSubscriptsAtEndForEquation;

protected function setSubscriptAtEndForIterCref
  input BackendDAE.IterCref crefIn;
  output BackendDAE.IterCref crefOut;
algorithm
  crefOut := matchcontinue(crefIn)
    local
      DAE.ComponentRef cr;
      DAE.Exp iterator;
      DAE.Operator op;
      DAE.Subscript sub;
  case(BackendDAE.ITER_CREF(cref=cr, iterator=iterator))
    algorithm
      {sub} := ComponentReference.crefSubs(cr);
      cr := replaceSubscriptAtEnd(sub,cr);
  then (BackendDAE.ITER_CREF(cr,iterator));
  case(BackendDAE.ACCUM_ITER_CREF(cref=cr, op=op))
    algorithm
      {sub} := ComponentReference.crefSubs(cr);
      cr := replaceSubscriptAtEnd(sub,cr);
  then (BackendDAE.ACCUM_ITER_CREF(cr,op));
  else
    then crefIn;
  end matchcontinue;
end setSubscriptAtEndForIterCref;

protected function updateIterCrefs"checks if the iterated crefs still refer to an iterated index"
  input list<BackendDAE.Equation> eqLstIn;
  input tuple<list<BackendDAE.Equation>,list<Integer>> tplIn;  //eqsFoldIn, indxFold
  output tuple<list<BackendDAE.Equation>,list<Integer>> tplOut;
algorithm
  tplOut := matchcontinue(eqLstIn,tplIn)
    local
      Integer id,idx;
      list<Integer> idxsIn, idxs;
      BackendDAE.Equation eq;
      DAE.ComponentRef cref;
      DAE.Exp startIt,endIt;
      list<BackendDAE.Equation> eqLst,eqFold,eqFoldIn,similarEqs,rest;
      list<BackendDAE.IterCref> iterCrefs, iterCrefs1;
      list<DAE.ComponentRef> allCrefs,crefs;
      list<DAE.Subscript> subs;
      BackendDAE.IterCref itCref;
      BackendDAE.LoopInfo loopInfo;
  case({},_)
    then (tplIn);
  case(BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(loopId=id,startIt=startIt,endIt=endIt,crefs=iterCrefs)))::rest,(eqFoldIn,idxsIn))
    algorithm
      if List.exist1(idxsIn,intEq,id) then
        // the equation will be removed
        idxs := idxsIn;
        id := -1;
        iterCrefs1 := {};
      else
        idxs := id::idxsIn;

        (similarEqs,_) := List.separate1OnTrue(eqLstIn,equationEqualNoCrefSubs,listHead(eqLstIn));
          //BackendDump.dumpEquationList(similarEqs,"simEqs");
        allCrefs := BackendEquation.equationsCrefs(similarEqs);
        iterCrefs1 := {};
        //update iterCrefs
        for itCref in iterCrefs loop
          BackendDAE.ITER_CREF(cref=cref) := itCref;
          crefs := List.filter1OnTrue(allCrefs,crefPartlyEqual,cref);
          subs := List.unique(List.flatten(List.map(crefs,ComponentReference.crefSubs)));
          if intGt(listLength(subs),1) then
            iterCrefs1 := itCref::iterCrefs1;
          end if;
        end for;
      end if;

      loopInfo := BackendDAE.LOOP(id,startIt,endIt,listReverse(iterCrefs1));
      eq := setLoopInfoInEq(loopInfo,listHead(eqLstIn));
      (eqFold,idxs) := updateIterCrefs(rest,(eq::eqFoldIn,idxs));
    then (eqFold,idxs);
  case(eq::rest,(eqFoldIn,idxsIn))
    algorithm
      (eqFold,idxs) := updateIterCrefs(rest,(eq::eqFoldIn,idxsIn));
  then (eqFold,idxs);
  end matchcontinue;
end updateIterCrefs;

public function enlargeIteratedArrayVars
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
protected
  BackendDAE.Variables vars, aliasVars, knownVars;
  list<BackendDAE.Var> varLst, aliasLst, knownLst, knownLst2;
  list<BackendDAE.Equation> eqLst;
  BackendDAE.EquationArray eqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StrongComponents compsIn, comps;
  BackendDAE.StateSets stateSets;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  (sysOut, sharedOut) := match (sysIn, sharedIn)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
    case (syst as BackendDAE.EQSYSTEM(), shared as BackendDAE.SHARED())
      algorithm
        varLst := BackendVariable.varList(syst.orderedVars);
        aliasLst := BackendVariable.varList(shared.aliasVars);
        knownLst := BackendVariable.varList(shared.knownVars);
        (varLst, aliasLst) := enlargeIteratedArrayVars1(varLst, aliasLst, {}, {});
        (knownLst, knownLst2) := enlargeIteratedArrayVars1(knownLst, {}, {}, {});
        syst.orderedVars := BackendVariable.listVar1(varLst);
        shared.aliasVars := BackendVariable.listVar1(aliasLst);
        shared.knownVars := BackendVariable.listVar1(knownLst);
        //BackendDump.dumpVarList(varLst,"varLst0");
        //BackendDump.dumpVarList(aliasLst,"aliasVars0");
        //BackendDump.dumpVarList(knownLst,"knownLst0");
        //BackendDump.dumpVarList(aliasLst,"aliasVars0");
        //BackendDump.dumpVarList(varLst,"varLst1");
        //BackendDump.dumpVarList(aliasLst,"aliasVars1");
        //BackendDump.dumpVarList(knownLst,"knownLst1");
      then (syst, shared);
  end match;
end enlargeIteratedArrayVars;


protected function enlargeIteratedArrayVars1
  input list<BackendDAE.Var> varLstIn;
  input list<BackendDAE.Var> aliasLstIn;
  input list<BackendDAE.Var> varLstFoldIn;
  input list<BackendDAE.Var> aliasFoldIn;
  output list<BackendDAE.Var> varLstFoldOut;
  output list<BackendDAE.Var> aliasFoldOut;
algorithm
  (varLstFoldOut,aliasFoldOut) := matchcontinue(varLstIn,aliasLstIn,varLstFoldIn,aliasFoldIn)
    local
      Integer dim;
      BackendDAE.Var var;
      DAE.ComponentRef cref, name;
      DAE.Exp bindExp;
      DAE.Subscript sub;
      list<DAE.ComponentRef> crefLst;
      list<DAE.Subscript> subs;
      list<BackendDAE.Var> varLst, rest, restAlias, simVars, simAlias, varFold, aliasFold;
  case({},{},_,_)
    algorithm
  then (listReverse(varLstFoldIn),listReverse(aliasFoldIn));

  case(BackendDAE.VAR(varName = name, arryDim=({DAE.DIM_INTEGER(integer=dim)}))::rest,_,_,_)
    algorithm
      // expand this simulation var
        //print("check var: "+BackendDump.varString(listHead(varLstIn))+"\n");
      (simVars,rest) := List.separate1OnTrue(varLstIn,isSimilarVarNoBind,listHead(varLstIn));
      (simAlias,restAlias) := List.separate1OnTrue(aliasLstIn,isSimilarVarNoBind,listHead(varLstIn));
          //BackendDump.dumpVarList(simVars,"similarVars");
          //BackendDump.dumpVarList(simAlias,"similarAlias");

      if listLength(simVars)+listLength(simAlias) == dim then
        // everything is correct, set subscripts at end
        varFold := varLstFoldIn;
        for var in simVars loop
          var := appendSubscriptsInVar(var);
          varFold := var::varFold;
        end for;

        aliasFold := aliasFoldIn;
        for var in simAlias loop
          var := appendSubscriptsInVar(var);
          aliasFold := var::aliasFold;
        end for;

          //print("its fine!\n");
      elseif listLength(simVars) == 1 and intLe(listLength(simAlias),dim-1) then
        // add new alias vars, if the array is mixed simulation and alias var, put everything in the simvar part
        cref := BackendVariable.varCref(listHead(simAlias));
        {sub} := ComponentReference.crefSubs(name);
        subs := List.map(List.intRange(dim),Expression.intSubscript);
        subs := List.deleteMember(subs,sub);
        crefLst := List.map1(subs,replaceSubscriptAtEnd,name);
        varLst := List.map1Reverse(crefLst,BackendVariable.copyVarNewName,listHead(simAlias));
        varLst := List.map(varLst,appendSubscriptsInVar);
        // put subscript at end for the var
          var := appendSubscriptsInVar(listHead(varLstIn));
        varFold := var::varLstFoldIn;
        aliasFold := listAppend(varLst,aliasFoldIn);
          //print("add new aliase\n");
      else
        // expand the simVars
        subs := List.map(List.intRange(dim),Expression.intSubscript);
        //crefLst := List.map1r(subs,replaceFirstSubInCref,name);
        crefLst := List.map1(subs,replaceSubscriptAtEnd,name);
        varLst := List.map1Reverse(crefLst,BackendVariable.copyVarNewName,listHead(varLstIn));
        varLst := List.map(varLst,appendSubscriptsInVar);
        varFold := listAppend(varLst, varLstFoldIn);
        aliasFold := aliasFoldIn;
          //print("increase!\n");
      end if;
      (varFold,aliasFold) := enlargeIteratedArrayVars1(rest,restAlias,varFold,aliasFold);
    then (varFold,aliasFold);

  case({},BackendDAE.VAR(varName = name, arryDim=({DAE.DIM_INTEGER(integer=dim)}), bindExp=SOME(bindExp))::rest,_,_)
    algorithm
      // handle the remaining alias vars
        //print("check alias: "+BackendDump.varString(listHead(aliasLstIn))+"\n");
      (simAlias,restAlias) := List.separate1OnTrue(aliasLstIn,isSimilarVarNoBind,listHead(aliasLstIn));
          //BackendDump.dumpVarList(simAlias,"similarAlias");
      if listLength(simAlias) == dim then
        // everything is correct
        varFold := varLstFoldIn;
        simAlias := List.map(simAlias,appendSubscriptsInVar);
        aliasFold := listAppend(simAlias,aliasFoldIn);
          //print("its fine alias!\n");
      else
        // expand the aliasVars
        subs := List.map(List.intRange(dim),Expression.intSubscript);
        //crefLst := List.map1r(subs,replaceFirstSubInCref,name);
        crefLst := List.map1(subs,replaceSubscriptAtEnd,name);
        varLst := List.map1Reverse(crefLst,BackendVariable.copyVarNewName,listHead(aliasLstIn));
        varLst := List.map(varLst,appendSubscriptsInVar);
        aliasFold := listAppend(varLst, aliasFoldIn);
        varFold := varLstFoldIn;
          //print("increase alias!\n");
      end if;
      (varFold,aliasFold) := enlargeIteratedArrayVars1({},restAlias,varFold,aliasFold);
    then (varFold,aliasFold);

  case(_::rest,_,_,_)
    algorithm
      // add this non-array var
      //print("add non arry var: "+BackendDump.varString(listHead(varLstIn))+"\n");
      var := appendSubscriptsInVar(listHead(varLstIn));
      (varFold,aliasFold) := enlargeIteratedArrayVars1(rest,aliasLstIn,var::varLstFoldIn,aliasFoldIn);
    then (varFold,aliasFold);

  case({},_::restAlias,_,_)
    algorithm
      // add this non-array alias
       //print("add non array alias var: "+BackendDump.varString(listHead(aliasLstIn))+"\n");
       var := appendSubscriptsInVar(listHead(aliasLstIn));
      (varFold,aliasFold) := enlargeIteratedArrayVars1({},restAlias,varLstFoldIn,var::aliasFoldIn);
    then (varFold,aliasFold);

  end matchcontinue;
end enlargeIteratedArrayVars1;

protected function appendSubscriptsInVar
  input BackendDAE.Var varIn;
  output BackendDAE.Var varOut;
algorithm
  varOut := matchcontinue(varIn)
    local
      DAE.Exp bindExp;
      DAE.ComponentRef name;
      BackendDAE.Var var;
      DAE.Subscript sub;
  case(BackendDAE.VAR(varName=name,bindExp=SOME(bindExp)))
    equation
      if ComponentReference.crefHaveSubs(name) then
        {sub} = ComponentReference.crefSubs(name);
        name = replaceSubscriptAtEnd(sub,name);
      end if;
      bindExp = Expression.traverseExpBottomUp(bindExp,appendSubscriptsInExp,"bla");
      var = BackendVariable.setBindExp(varIn,SOME(bindExp));
      var = BackendVariable.copyVarNewName(name,var);
  then var;
  case(BackendDAE.VAR(varName=name))
    equation
      {sub} = ComponentReference.crefSubs(name);
      name = replaceSubscriptAtEnd(sub,name);
      var = BackendVariable.copyVarNewName(name,varIn);
  then var;
    else
    then varIn;
  end matchcontinue;
end appendSubscriptsInVar;

protected function appendSubscriptsInExp
  input DAE.Exp expIn;
  input String blaIn;
  output DAE.Exp expOut;
  output String blaOut;
algorithm
 (expOut, blaOut) := matchcontinue(expIn,blaIn)
  local
    DAE.ComponentRef cref;
    DAE.Subscript sub;
    DAE.Type ty;
  case(DAE.CREF(componentRef=cref,ty=ty),_)
    equation
      {sub} = ComponentReference.crefSubs(cref);
      cref = replaceSubscriptAtEnd(sub,cref);
     then (DAE.CREF(cref,ty),blaIn);
    else
      then(expIn,blaIn);
  end matchcontinue;
end appendSubscriptsInExp;

protected function replaceSubscriptAtEnd
  input DAE.Subscript sub;
  input DAE.ComponentRef crefIn;
  output DAE.ComponentRef crefOut;
protected
  DAE.ComponentRef cref;
algorithm
  cref := ComponentReference.crefStripSubs(crefIn);
  crefOut := ComponentReference.crefSetLastSubs(cref,{sub});
end replaceSubscriptAtEnd;

public function updateSimCode"updates some things in the simCode"
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut;
protected
  list<SimCode.SimEqSystem> initialEquations;
  list<SimCodeVar.SimVar> aliasVars;
algorithm
  SimCode.SIMCODE(modelInfo=SimCode.MODELINFO(vars=SimCodeVar.SIMVARS(aliasVars=aliasVars)),initialEquations=initialEquations) := simCodeIn;
  initialEquations := List.map1(initialEquations,updateAliasInSimEqSystem, aliasVars);
  simCodeOut := setSimCodeInitialEquations(simCodeIn,initialEquations);
end updateSimCode;

protected function updateAliasInSimEqSystem
  input SimCode.SimEqSystem eqIn;
  input list<SimCodeVar.SimVar> aliasVars;
  output SimCode.SimEqSystem eqOut;
algorithm
  eqOut := matchcontinue(eqIn,aliasVars)
    local
      Integer idx;
      DAE.ComponentRef cref;
      DAE.Exp exp;
      DAE.ElementSource source;
  case(SimCode.SES_SIMPLE_ASSIGN(index=idx,cref=cref,exp=exp,source=source),_)
    equation
      (exp,_) = Expression.traverseExpBottomUp(exp,updateAliasInSimEqSystem1,aliasVars);
    then SimCode.SES_SIMPLE_ASSIGN(idx,cref,exp,source);
  else
    then eqIn;
  end matchcontinue;
end updateAliasInSimEqSystem;

protected function updateAliasInSimEqSystem1"replaces crefs with its alias"
  input DAE.Exp expIn;
  input list<SimCodeVar.SimVar> aliasVarsIn;
  output DAE.Exp expOut;
  output list<SimCodeVar.SimVar> aliasVarsOut;
algorithm
  (expOut,aliasVarsOut) := matchcontinue(expIn,aliasVarsIn)
    local
      Boolean isNegated;
      DAE.ComponentRef cref;
      DAE.Exp exp;
      DAE.Type ty;
  case(DAE.CREF(componentRef=cref,ty=ty),_)
    equation
      (cref,isNegated) = getSimCodeVarAlias(aliasVarsIn,cref);
      if isNegated then
        exp = DAE.UNARY(DAE.UMINUS(ty),DAE.CREF(cref,ty));
      else
        exp = DAE.CREF(cref,ty);
      end if;
  then (exp,aliasVarsIn);
  else
    then(expIn,aliasVarsIn);
  end matchcontinue;
end updateAliasInSimEqSystem1;

protected function getSimCodeVarAlias
  input list<SimCodeVar.SimVar> simVar;
  input DAE.ComponentRef crefIn;
  output DAE.ComponentRef crefOut;
  output Boolean isNegated;
algorithm
  (crefOut,isNegated) := matchcontinue(simVar,crefIn)
    local
      DAE.ComponentRef name, varName;
      list<SimCodeVar.SimVar> rest;
  case({},_)
    then (crefIn,false);
  case(SimCodeVar.SIMVAR(name=name,aliasvar=SimCodeVar.ALIAS(varName=varName))::_,_)
    equation
      true = ComponentReference.crefEqual(crefIn,name);
  then (varName,false);
  case(SimCodeVar.SIMVAR(name=name,aliasvar=SimCodeVar.NEGATEDALIAS(varName=varName))::_,_)
    equation
      true = ComponentReference.crefEqual(crefIn,name);
  then (varName,true);
  case(_::rest,_)
    then getSimCodeVarAlias(rest,crefIn);
  end matchcontinue;
end getSimCodeVarAlias;

protected function setSimCodeInitialEquations
  input SimCode.SimCode simCode;
  input list<SimCode.SimEqSystem> initEqs;
  output SimCode.SimCode outSimCode;
algorithm
  outSimCode := match (simCode, initEqs)
    local
      SimCode.ModelInfo modelInfo;
      list<DAE.Exp> literals;
      list<SimCode.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;
      list<list<SimCode.SimEqSystem>> algebraicEquations;
      Boolean useHomotopy;
      list<SimCode.SimEqSystem> initialEquations, removedInitialEquations;
      list<SimCode.SimEqSystem> startValueEquations;
      list<SimCode.SimEqSystem> nominalValueEquations;
      list<SimCode.SimEqSystem> minValueEquations;
      list<SimCode.SimEqSystem> maxValueEquations;
      list<SimCode.SimEqSystem> parameterEquations;
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      list<SimCode.SimEqSystem> jacobianEquations;
      list<SimCode.SimEqSystem> equationsForZeroCrossings;
      list<SimCode.StateSet> stateSets;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings, relations;
      list<BackendDAE.TimeEvent> timeEvents;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      SimCode.DelayedExpression delayedExps;
      list<SimCode.JacobianMatrix> jacobianMatrixes;
      Option<SimCode.SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix;
      // *** a protected section *** not exported to SimCodeTV
      SimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HpcOmSimCode.HpcOmData hpcomData;
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      HashTableCrILst.HashTable varToIndexMapping;
      Option<SimCode.FmiModelStructure> modelStruct;
      Option<SimCode.BackendMapping> backendMapping;
      list<BackendDAE.BaseClockPartitionKind> partitionsKind;
      list<DAE.ClockKind> baseClocks;

    case (SimCode.SIMCODE( modelInfo, literals, recordDecls, externalFunctionIncludes,
                           allEquations, odeEquations, algebraicEquations, partitionsKind, baseClocks,
                           useHomotopy, initialEquations, removedInitialEquations, startValueEquations,
                           nominalValueEquations, minValueEquations, maxValueEquations,
                           parameterEquations, removedEquations, algorithmAndEquationAsserts, equationsForZeroCrossings,
                           jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings,
                           relations, timeEvents, whenClauses, discreteModelVars, extObjInfo, makefileParams,
                           delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, hpcomData, varToArrayIndexMapping,
                           varToIndexMapping, crefToSimVarHT, backendMapping, modelStruct ), _)
      then SimCode.SIMCODE( modelInfo, literals, recordDecls, externalFunctionIncludes,
                            allEquations, odeEquations, algebraicEquations, partitionsKind, baseClocks,
                            useHomotopy, initEqs, removedInitialEquations, startValueEquations,
                            nominalValueEquations, minValueEquations, maxValueEquations,
                            parameterEquations, removedEquations, algorithmAndEquationAsserts,equationsForZeroCrossings,
                            jacobianEquations, stateSets, constraints, classAttributes, zeroCrossings,
                            relations, timeEvents, whenClauses, discreteModelVars, extObjInfo, makefileParams,
                            delayedExps, jacobianMatrixes, simulationSettingsOpt, fileNamePrefix, hpcomData,
                            varToArrayIndexMapping, varToIndexMapping, crefToSimVarHT, backendMapping, modelStruct );
  end match;
end setSimCodeInitialEquations;

/*
public function prepareVectorizedDAE1
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
protected
  BackendDAE.Variables vars, aliasVars;
  list<BackendDAE.Var> varLst, addAlias, addAliasLst1, aliasVars0;
  list<BackendDAE.Equation> eqLst;
  BackendDAE.EquationArray eqs;
  Option<BackendDAE.IncidenceMatrix> m;
  Option<BackendDAE.IncidenceMatrixT> mT;
  BackendDAE.Matching matching;
  BackendDAE.StateSets stateSets "the statesets of the system";
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs, m=m, mT=mT, matching=matching, stateSets=stateSets, partitionKind=partitionKind) := sysIn;
  BackendDAE.SHARED(aliasVars=aliasVars) := sharedIn;

  //unroll variables
  varLst := BackendVariable.varList(vars);
  aliasVars0 := BackendVariable.varList(aliasVars);
    BackendDump.dumpVarList(varLst,"varLst1");
    BackendDump.dumpVarList(aliasVars0,"alias1");
  (varLst,addAlias) := List.fold1(varLst,rollOutArrays,aliasVars0,({},{}));
    BackendDump.dumpVarList(varLst,"the unrolled vars");
    BackendDump.dumpVarList(addAlias,"teh additional alias");
  aliasVars := BackendVariable.mergeVariables(aliasVars,BackendVariable.listVar1(addAlias));
    //BackendDump.dumpVariables(aliasVars,"final alias");
  vars := BackendVariable.listVar(varLst);
  // add missing aliase
  //there are still alias vars that need to be expanded
  addAliasLst1 := expandAliasVars(aliasVars0,vars,{});

  sysOut := BackendDAE.EQSYSTEM(vars,eqs,m,mT,matching,stateSets,partitionKind);
  sharedOut := BackendDAEUtil.setSharedAliasVars(sharedIn,aliasVars);
end prepareVectorizedDAE1;

protected function expandAliasVars
  input list<BackendDAE.Var> varsIn;
  input BackendDAE.Variables algVars;
  input list<BackendDAE.Var> foldIn;
  output list<BackendDAE.Var> foldOut;
algorithm
  foldOut := matchcontinue(varsIn,algVars,foldIn)
    local
      Integer dim;
      list<BackendDAE.Var> rest, similarVars,rest;
  case({},_,_)
    equation
  then foldIn;
  case(BackendDAE.VAR(arryDim=({DAE.DIM_INTEGER(integer=dim)}))::rest,_,_)
    equation
      (similarVars,rest) = List.separate1OnTrue(varsIn,isSimilarVar,listHead(varsIn));
      //there are less vars than dimensions
      true = intLt(listLength(similarVars),dim);
      BackendDump.dumpVarList(similarVars,"simVars");
  then expandAliasVars(rest,algVars,foldIn);
  case(_::rest,_,_)
    then expandAliasVars(rest,algVars,foldIn);
  end matchcontinue;
end expandAliasVars;



protected function markUnrolledForEqs"checks the loop ids for every for-equation. the loop ids have to be unique."
  input BackendDAE.Equation eqIn;
  input tuple<list<BackendDAE.Equation>,list<Integer>> tplIn; //foldEqs, loopIds
  output tuple<list<BackendDAE.Equation>,list<Integer>> tplOut;
algorithm
  tplOut := matchcontinue(eqIn,tplIn)
    local
      Integer id;
      list<Integer> ids0, ids;
      list<BackendDAE.Equation> eqLst0, eqLst;
    case(BackendDAE.EQUATION(attr=BackendDAE.EQUATION_ATTRIBUTES(loopInfo=BackendDAE.LOOP(loopId=id))),(eqLst0,ids0))
      equation
        if List.exist1(ids0,intEq,id) then
          ids = ids0;
          eqLst = setLoopId(eqIn,-1)::eqLst0;
        else
          ids = id::ids0;
          eqLst = eqIn::eqLst0;
        end if;
    then (eqLst,ids);
    case(_,(eqLst0,ids0))
      then (eqIn::eqLst0,ids0);
  end matchcontinue;
end markUnrolledForEqs;


protected function setLoopId
  input BackendDAE.Equation eqIn;
  input Integer id;
  output BackendDAE.Equation eqOut;
protected
  DAE.Exp exp,scalar,startIt,endIt;
  list<BackendDAE.IterCref> iterCrefs;
  DAE.ElementSource source;
  BackendDAE.EquationAttributes attr;
  Boolean differentiated;
  BackendDAE.EquationKind kind;
  BackendDAE.LoopInfo loopInfo;
algorithm
  try
    BackendDAE.EQUATION(exp=exp,scalar=scalar,source=source,attr=BackendDAE.EQUATION_ATTRIBUTES(differentiated=differentiated,kind=kind,loopInfo=BackendDAE.LOOP(startIt=startIt,endIt=endIt,crefs=iterCrefs))) := eqIn;
    eqOut := BackendDAE.EQUATION(exp,scalar,source,BackendDAE.EQUATION_ATTRIBUTES(differentiated,kind,BackendDAE.LOOP(id,startIt,endIt,iterCrefs)));
  else
    eqOut := eqIn;
  end try;
end setLoopId;

protected function rollOutArrays"expands the array vars. dispatch the unrolled vars to the algebraic and to the alias vars."
  input BackendDAE.Var inVar;
  input list<BackendDAE.Var> aliasVars;
  input tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> foldIn;
  output tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> foldOut;
algorithm
  foldOut := matchcontinue(inVar, foldIn)
    local
      Integer i,dim;
      DAE.ComponentRef cref;
      DAE.Subscript sub;
      BackendDAE.Var var;
      list<BackendDAE.Var> varLst0, aliasLst0, varLst, aliasLst, equalCrefLst, otherArrayVarLst, addAliasLst, addAliasLst1;
      list<DAE.ComponentRef> crefLst;
      list<DAE.Subscript> subs;
  case(BackendDAE.VAR(varName=cref, arryDim={DAE.DIM_INTEGER(integer=dim)}),(varLst0,aliasLst0))
   algorithm
     // its an array var with one subscript
       //print("analyse Var "+BackendDump.varString(inVar)+"\n");
     if List.exist1(varLst0,BackendVariable.varEqual,inVar) then
       // this var is already in the list, add nothing
       varLst := {};
       addAliasLst := {};
     else
       // add all rolled out vars, and aliase for the rolled outs
      {DAE.INDEX(DAE.ICONST(integer = i))} := ComponentReference.crefSubs(cref);
      (aliasLst, _) := List.separate1OnTrue(aliasVars,isAliasVarOf,inVar);
        //BackendDump.dumpVarList(aliasLst,"all aliase");
        //BackendDump.dumpVarList(varLst,"no aliase");
      (equalCrefLst, otherArrayVarLst) := List.fold1(aliasLst,dispatchAliasVars,inVar,({},{}));
        //BackendDump.dumpVarList(equalCrefLst,"aliase with equal crefs");
        //BackendDump.dumpVarList(otherArrayVarLst,"other aliase");
      addAliasLst := {};
      if listEmpty(equalCrefLst) then
        // there are no aliase equations for the iterated crefs, therefore we need algebraic vars for them
        subs := List.map(List.intRange(dim),Expression.intSubscript);
        crefLst := List.map1r(subs,replaceFirstSubInCref,cref);
        varLst := List.map1(crefLst,BackendVariable.copyVarNewName,inVar);
      else
        // there are alias variables for the iterated crefs
        for var in equalCrefLst loop
          addAliasLst := listAppend(additionalAlias(var),addAliasLst);
        end for;
        varLst := {inVar};
      end if;
    end if;
       //BackendDump.dumpVarList(addAliasLst,"addAliasLst");
       //BackendDump.dumpVarList(varLst,"varLst");
   then (listAppend(varLst,varLst0),listAppend(addAliasLst,aliasLst0));
  case(_,(varLst0,aliasLst0))
    then (inVar::varLst0,aliasLst0);
  end matchcontinue;
end rollOutArrays;
*/


protected function isSimilarVar
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(var1,var2)
    local
      Boolean b;
      DAE.ComponentRef cref1, cref2;
      DAE.Exp bindExp1, bindExp2;
  case(BackendDAE.VAR(varName=cref1, bindExp=SOME(bindExp1)),BackendDAE.VAR(varName=cref2, bindExp=SOME(bindExp2)))
    equation
      then crefPartlyEqual(cref1,cref2) and expEqualNoCrefSubs(bindExp1,bindExp2);
  else
    then false;
  end matchcontinue;
end isSimilarVar;

protected function isSimilarVarNoBind
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  output Boolean bOut;
algorithm
  bOut := matchcontinue(var1,var2)
    local
      Boolean b;
      DAE.ComponentRef cref1, cref2;
  case(BackendDAE.VAR(varName=cref1),BackendDAE.VAR(varName=cref2))
    equation
      then crefPartlyEqual(cref1,cref2);
  else
    then false;
  end matchcontinue;
end isSimilarVarNoBind;

protected function additionalAlias"adds additional alias vars"
  input BackendDAE.Var var;
  output list<BackendDAE.Var> varLstOut;
algorithm
  varLstOut := matchcontinue(var)
    local
      Integer i, dim;
      DAE.Exp bindExp;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefLst;
      list<BackendDAE.Var> varLst;
   case(BackendDAE.VAR(bindExp = SOME(bindExp), arryDim={DAE.DIM_INTEGER(integer=dim)}))
     algorithm
       {cref} := Expression.extractCrefsFromExp(bindExp);
       crefLst := {};
       for i in List.intRange(dim) loop
         crefLst := replaceFirstSubInCref(cref,DAE.INDEX(DAE.ICONST(i)))::crefLst;
       end for;
       (crefLst,_) := List.deleteMemberOnTrue(cref,crefLst,ComponentReference.crefEqual);
       varLst := List.map1(crefLst,BackendVariable.copyVarNewName,var);
   then varLst;
   else
     then {};
  end matchcontinue;
end additionalAlias;

protected function dispatchAliasVars"dispatches the aliasvars in a list of alias that have the same cref except the subscript and aliasvars that are array vars with other crefs.
non array vars are dismissed"
  input BackendDAE.Var aliasVar;
  input BackendDAE.Var refVar;
  input tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplIn;
  output tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplOut;
algorithm
  tplOut := matchcontinue(aliasVar,refVar,tplIn)
    local
      Integer dim;
      list<BackendDAE.Var> equalCrefLst, otherArrayVarLst;
      DAE.ComponentRef cref1, cref2;
  case(BackendDAE.VAR(varName = cref1, arryDim={DAE.DIM_INTEGER(integer=dim)}),BackendDAE.VAR(varName = cref2),(equalCrefLst, otherArrayVarLst))
    equation
      true = crefPartlyEqual(cref1,cref2);
      then (aliasVar::equalCrefLst, otherArrayVarLst);
  case(BackendDAE.VAR(varName = cref1, arryDim={DAE.DIM_INTEGER(integer=dim)}),BackendDAE.VAR(varName = cref2),(equalCrefLst, otherArrayVarLst))
    equation
      false = crefPartlyEqual(cref1,cref2);
      then (equalCrefLst, aliasVar::otherArrayVarLst);
  else
  equation
    then tplIn;
  end matchcontinue;
end dispatchAliasVars;

protected function isAliasVarOf"checks if the var is the aliasVar of varWithAlias"
  input BackendDAE.Var varWithAlias;
  input BackendDAE.Var var;
  output Boolean b;
algorithm
  b := matchcontinue(varWithAlias,var)
    local
      DAE.ComponentRef cref0, cref1;
      DAE.Exp bindExp;
  case(BackendDAE.VAR(bindExp=SOME(bindExp)),BackendDAE.VAR(varName=cref0))
    equation
      {cref1} = Expression.extractCrefsFromExp(bindExp);
    then ComponentReference.crefEqual(cref0,cref1);
  else
  then false;
  end matchcontinue;
end isAliasVarOf;

annotation(__OpenModelica_Interface="backend");
end Vectorization;
