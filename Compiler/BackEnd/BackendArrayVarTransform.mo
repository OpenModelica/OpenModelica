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

encapsulated package BackendArrayVarTransform
" file:        BackendArrayVarTransform.mo
  package:     BackendArrayVarTransform
  description: BackendArrayVarTransform contains a Binary Tree representation of variable replacements.

  RCS: $Id: BackendVarTransform.mo 25836 2015-04-30 07:08:15Z vwaurich $

  This module contain a Binary tree representation of variable replacements
  along with some functions for performing replacements of variables in equations"

public import BackendDAE;
public import DAE;
public import HashTable2;
public import HashTable3;

protected import Absyn;
protected import BaseHashTable;
protected import BaseHashSet;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import ClassInf;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Flags;
protected import HashSet;
protected import List;
protected import Util;
protected import Vectorization;

public uniontype ArrayVarRepl
"VariableReplacements consists of a mapping between variables and expressions, the first binary tree of this type.
 To eliminate a variable from an equation system a replacement rule varname->expression is added to this
 datatype.
 To be able to update these replacement rules incrementally a backward lookup mechanism is also required.
 For instance, having a rule a->b and adding a rule b->c requires to find the first rule a->b and update it to
 a->c. This is what the second binary tree is used for."
  record REPLACEMENTS
    HashTable2.HashTable nonArrayHT "cref --> exp";
    HashTable.HashTable arrayHT "cref --> idx, idx is used to find concrete arrayCrefs";
    HashTable3.HashTable invHashTable "cref-->cref, to loop backwars";
    array<list<tuple<DAE.Subscript,DAE.Exp>>> arrayExps "for each arraycref, a list of corresponding subscripts and their replaced expressions";
    Integer nextFreeIdx;
  end REPLACEMENTS;
end ArrayVarRepl;


//-------------
//BASIC FUNCTIONS
//-------------

public function emptyReplacementsSized "
  Returns an empty set of replacement rules
"
  input Integer size;
  input Integer arrSize;
  output ArrayVarRepl outRepl;
algorithm
  outRepl:=  match (size,arrSize)
    local
      array<list<tuple<DAE.Subscript,DAE.Exp>>> arrayExps;
      HashTable2.HashTable nonArrayHT;
      HashTable.HashTable arrayHT;
      HashTable3.HashTable invHashTable;
    case (_,_)
      equation
        arrayHT = HashTable.emptyHashTableSized(size);
        nonArrayHT = HashTable2.emptyHashTableSized(size);
        invHashTable = HashTable3.emptyHashTableSized(size);
        arrayExps  = arrayCreate(arrSize,{});
      then
        REPLACEMENTS(nonArrayHT,arrayHT,invHashTable,arrayExps,1);
  end match;
end emptyReplacementsSized;


public function addArrReplacement "adds a replacement for an array cref and saves the replacements for the scalars in a compact way"
  input ArrayVarRepl repl;
  input DAE.ComponentRef inSrc;
  input DAE.Exp inDst;
  input DAE.Subscript subIn; // the range
  output ArrayVarRepl outRepl;
algorithm
  outRepl:=
  matchcontinue (repl,inSrc,inDst,subIn)
    local
      Integer idx;
      DAE.ComponentRef src;
      DAE.Subscript sub;
      HashTable.HashTable arrayHT;
      HashTable2.HashTable nonArrayHT;
      HashTable3.HashTable invHashTable;
      list<tuple<DAE.Subscript,DAE.Exp>> crefEntries;
      array<list<tuple<DAE.Subscript,DAE.Exp>>> arrayExps;
    case (REPLACEMENTS(nonArrayHT=nonArrayHT, arrayHT=arrayHT, invHashTable=invHashTable, arrayExps=arrayExps, nextFreeIdx=idx),_,_,_)
      equation
        // an array cref
        true = ComponentReference.crefHaveSubs(inSrc);
        src = ComponentReference.crefStripSubs(inSrc);
        print("source: "+ComponentReference.printComponentRefStr(src)+"\n");
        if BaseHashTable.hasKey(src,arrayHT) then
          print("exists!\n");
          //crefEntries = arrayGet(arrayExps,BaseHashTable.get(src,arrayHT));
          //crefEntries = insertSubInCrefEntries(subIn,inDst,crefEntries,{});
          //arrayUpdate(arrayExps,BaseHashTable.get(src,arrayHT),crefEntries);
        else
          arrayHT = BaseHashTable.add((src, idx),arrayHT);
          crefEntries = {(subIn,inDst)};
          arrayUpdate(arrayExps,idx,crefEntries);
          idx = idx+1;
        end if;
      then
        REPLACEMENTS(nonArrayHT,arrayHT,invHashTable,arrayExps,idx);
    case (_,_,_,_)
      equation
        print("-BackendArrayVarTransform.addReplacement failed for " + ComponentReference.printComponentRefStr(inSrc)+"\n");
      then
        fail();
  end matchcontinue;
end addArrReplacement;

protected function insertSubInCrefEntries"inserts a subentry in the list of subentries"
  input DAE.Subscript sub;
  input DAE.Exp exp;
  input list<tuple<DAE.Subscript,DAE.Exp>> crefEntriesIn;
  input list<tuple<DAE.Subscript,DAE.Exp>> foldIn;
  output list<tuple<DAE.Subscript,DAE.Exp>> foldOut;
protected
  Boolean merged;
  tuple<DAE.Subscript,DAE.Exp> entry;
  list<tuple<DAE.Subscript,DAE.Exp>> lst, rest;
algorithm
  foldOut := matchcontinue(sub,exp,crefEntriesIn,foldIn)
    local
  case(_,_,{},{})
    //no entry yet
    then({(sub,exp)});
  case(_,_,entry::rest,_)
    equation
    //merge subscripts if necessary
      (lst,merged) = mergeSubscripts((sub,exp),entry);
      if merged then
        lst = listAppend(foldIn,lst);
      else
        lst = insertSubInCrefEntries(sub,exp,rest,entry::foldIn);
      end if;
    then lst;
  case(_,_,{},_)
    equation
    //append entry
      lst = (sub,exp)::foldIn;
    then lst;
  end matchcontinue;
end insertSubInCrefEntries;

protected function mergeSubscripts"compares 2 subscripts and merges both entries."
  input tuple<DAE.Subscript,DAE.Exp> sub1; // to be inserted
  input tuple<DAE.Subscript,DAE.Exp> sub2;
  output list<tuple<DAE.Subscript,DAE.Exp>> mergeLst;
  output Boolean merged;
algorithm
  (mergeLst,merged) := matchcontinue(sub1,sub2)
    local
      Integer i1,i2,start1, start2, stop1 ,stop2;
      DAE.Exp exp1,exp2;
      DAE.Type ty;

  case((DAE.INDEX(DAE.ICONST(i1)),_),(DAE.INDEX(DAE.ICONST(i2)),_))
    equation
      if intEq(i1,i2) then
        mergeLst = {sub2};//equal
        merged = true;
      elseif intLt(i1,i2) then
        mergeLst = {sub2};//less
        merged = false;
      elseif intGt(i1,i2) then
        mergeLst = {sub2,sub1};//bigger
        merged = true;
      else
        print("check this1!");
      end if;
    then (mergeLst,merged);

  case((DAE.INDEX(DAE.ICONST(i1)),exp1), (DAE.SLICE(DAE.RANGE(ty=ty,start=DAE.ICONST(start2),step=NONE(),stop=DAE.ICONST(stop2))),exp2))
    equation
      if intLt(i1,start2) then
        mergeLst={sub2}; //less
        merged = false;
      elseif intEq(i1,start2) then
        mergeLst={sub1,(DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(i1+1),NONE(),DAE.ICONST(stop2))),exp2)}; //beginning of range
        merged = true;
      elseif intEq(i1,stop2) then
        mergeLst={(DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(start2),NONE(),DAE.ICONST(i1-1))),exp2),sub1}; //end of range
        merged = true;
      elseif intGt(i1,start2) and intLt(i1,stop2) then
        mergeLst={(DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(start2),NONE(),DAE.ICONST(i1-1))),exp2),
                  sub1,
                  (DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(i1+1),NONE(),DAE.ICONST(stop2))),exp2) }; //included
        merged = true;
      elseif intGt(i1,stop2) then
        mergeLst={sub2,sub1}; //bigger
        merged = true;
      else
        print("check this2!");
      end if;
    then (mergeLst,merged);

  case((DAE.SLICE(DAE.RANGE(start=DAE.ICONST(start1),stop=DAE.ICONST(stop1))),exp1),(DAE.SLICE(DAE.RANGE(ty=ty,start=DAE.ICONST(start2),step=NONE(),stop=DAE.ICONST(stop2))),exp2))
    equation
      print("start1"+intString(start1)+" stop1"+intString(stop1)+" start2"+intString(start2)+" stop2"+intString(stop2)+"\n");
      if intLt(stop1,start2) then
        mergeLst={sub2}; //less
        merged = false;
      elseif intGt(start1,start2) and intLt(stop1,stop2) then
        mergeLst={(DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(start2),NONE(),DAE.ICONST(start1-1))),exp2),
                  sub1,
                  (DAE.SLICE(DAE.RANGE(ty,DAE.ICONST(stop1+1),NONE(),DAE.ICONST(stop2))),exp2)}; //included
        merged = true;
      elseif intGt(start1,stop2) then
        mergeLst={sub2,sub1}; //bigger
        merged = true;
      else
        print("check this3!");
      end if;
    then (mergeLst,merged);

  case((DAE.INDEX(DAE.ICONST(i1)),exp1),(DAE.WHOLEDIM(),exp2))
    equation
      mergeLst={sub1, sub2}; //included;
      merged = true;
    then (mergeLst,merged);
  end matchcontinue;
end mergeSubscripts;

public function getReplacement "Retrives a replacement variable given a set of replacement rules and a
  source variable."
  input DAE.ComponentRef iCref;
  input ArrayVarRepl iRepl;
  output list<DAE.Exp> outCrefs;
  output list<DAE.ComponentRef> notFoundCref;
algorithm
  (outCref,notFoundCref) := match (iCref,iRepl)
    local
      DAE.ComponentRef src;
      list<DAE.Exp> dst;
      HashTable2.HashTable nonArrayHT;
      HashTable.HashTable arrayHT;
      array<list<tuple<DAE.Subscript,DAE.Exp>>> arrayExps;
      list<tuple<DAE.Subscript,DAE.Exp>> subExps;
      DAE.Subscript sub;
      list<DAE.Subscript> subs;
    case(_, REPLACEMENTS(nonArrayHT=nonArrayHT,arrayHT=arrayHT))
      equation
        if ComponentReference.crefHaveSubs(iCref) then
        // its an array cref
          {sub} = ComponentReference.crefSubs(iCref);
          src = ComponentReference.crefStripSubs(iCref);
          subExps = arrayGet(arrayExps,BaseHashTable.get(src,arrayHT));
          (dst,subs) = getReplSubExps(sub,subExps);
        else
          dst = {BaseHashTable.get(iCref,nonArrayHT)};
        end if;
      then (dst,{});
  end match;
end getReplacement;


protected function getReplSubExps"gets the corresponding expressions for the givens ubscripts"
  input DAE.Subscript subIn;
  input list<DAE.Subscript,DAE.Exp> subExps;
  output list<DAE.Exp> expsOut;
  output list<DAE.Subscript> notFoundSubs;
algorithm
  (expsOut,notFoundSubs) := matchcontinue(subIn,subExps)
    local
      Integer start, stop, i1;
      list<DAE.Subscript,DAE.Exp> rest;
      DAE.Exp exp;
      list<DAE.Exp> exps;
      list<DAE.Subscript> restSubs;
  case(DAE.INDEX(DAE.ICONST(i1)),(DAE.SLICE(RANGE(start=DAE.ICONST(start), stop=DAE.ICONST(stop))),exp)::rest)
    equation
      // an index subscript
      if intGe(i1,start) and intLe(i1,stop) then
        exps = {replaceSubExp(exp,subIn)};
        restSubs = {};
      else
        (exps,restSubs) = getReplSubExps(subIn,rest);
      end if;
    then (exps,restSubs);
      
  case(_,{})
    then ({},subIn);
  end matchcontinue;
end getReplSubExps;


protected function replaceSubExp"replaces a subscript in a cref exp"
  input DAE.Exp expIn;
  input DAE.Subscript subIn;
  output DAE.Exp expOut;
algorithm
  expOut := matchcontinue(expIn,subIn)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
  case(DAE.CREF(componentRef=cref, ty=ty),_)
    equation
      cref = Vectorization.replaceFirstSubsInCref(cref,subIn);
    then (DAE.CREF(cref,ty));
  else
    then expIn;
  end matchcontinue;      
end replaceSubExp;

//-------------
//REPLACING FUNCTIONS
//-------------

public function replaceExp
  input DAE.Exp inExp;
  input ArrayVarRepl repl;
  output DAE.Exp outExp;
  output Boolean replacementPerformed;
algorithm
  (outExp,replacementPerformed) := matchcontinue(inExp,repl)
    local
      DAE.ComponentRef cref;
      DAE.Exp e;
  case(DAE.CREF(componentRef=cref),_)
    equation
      (cref,_) = getReplacement(cref,repl);
    then 
end replaceExp;

*/
//-------------
//DUMPING STUFF
//-------------

public function dumpReplacements "Prints the variable replacements on form var1 -> var2"
  input ArrayVarRepl replIn;
algorithm
  _ := match (replIn)
    local
      String str, len_str;
      Integer len;
      HashTable2.HashTable naHT;
      HashTable.HashTable arrHT;
      list<tuple<DAE.ComponentRef,DAE.Exp>> tplLst;
      list<tuple<DAE.ComponentRef,Integer>> tplLst2;
      array<list<tuple<DAE.Subscript, DAE.Exp>>> arrayExps;

    case (REPLACEMENTS(nonArrayHT=naHT, arrayHT=arrHT, arrayExps=arrayExps)) equation
      (tplLst) = BaseHashTable.hashTableList(naHT);
      (tplLst2) = BaseHashTable.hashTableList(arrHT);
      print("\nReplacements: (");
      len = listLength(tplLst)+listLength(tplLst2);
      len_str = intString(len);
      print(len_str);
      print(")\n");
      print("NON-ARRAY-REPLACEMENTS========================================\n");
      str = stringDelimitList(List.map(tplLst,printReplacementTupleStr), "\n");
      print(str);
      print("\n");
      print("ARRAY-REPLACEMENTS========================================\n");
      str = stringDelimitList(List.map1(tplLst2,printReplacementTupleStr1,arrayExps), "\n");
      print(str);
      print("\n");
    then ();
  end match;
end dumpReplacements;

protected function printReplacementTupleStr "help function to dumpReplacements"
  input tuple<DAE.ComponentRef,DAE.Exp> tpl;
  output String str;
algorithm
  str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) + " -> " + ExpressionDump.printExpStr(Util.tuple22(tpl));
end printReplacementTupleStr;

protected function printReplacementTupleStr1 "help function to dumpReplacements"
  input tuple<DAE.ComponentRef,Integer> tpl;
  input array<list<tuple<DAE.Subscript,DAE.Exp>>> arrayExps;
  output String str;
algorithm
  str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) + " -> " + stringDelimitList(List.map(arrayGet(arrayExps,(Util.tuple22(tpl))),printReplacementTupleStr2),"");
end printReplacementTupleStr1;

protected function printReplacementTupleStr2 "help function to dumpReplacements"
  input tuple<DAE.Subscript,DAE.Exp> tpl;
  output String str;
algorithm
  str := "["+ExpressionDump.printSubscriptStr(Util.tuple21(tpl)) + "] : " + ExpressionDump.printExpStr(Util.tuple22(tpl))+" ";
end printReplacementTupleStr2;

annotation(__OpenModelica_Interface="backend");
end BackendArrayVarTransform;
