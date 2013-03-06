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

encapsulated package Relation
" file:        Relation.mo
  package:     Relation
  description: Relation is a representation of a relation between two objects.
  @author:     adrpo

  RCS: $Id: Relation.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Relation can be unidirectional source->target or bidirectional source<->target.
  The relation is implemented using generic Avl trees."

public
import AvlTree;

replaceable type Source subtypeof Any;
replaceable type Target subtypeof Any;

type Tree = AvlTree.Tree<Source, Target>;
type FuncTypeKeyCompareSource = AvlTree.FuncTypeKeyCompare<Source>;
type FuncTypeKeyCompareTarget = AvlTree.FuncTypeKeyCompare<Target>;

type FuncTypeStrSourceOpt = Option<AvlTree.FuncTypeKeyToStr<Source>> "for transforming source to string";
type FuncTypeStrTargetOpt = Option<AvlTree.FuncTypeValToStr<Target>> "for transforming target to string";

type FuncTypeItemUpdateCheckSourceTargetOpt = Option<AvlTree.FuncTypeItemUpdateCheck<Source,Target>> "for checking the update of the relation source->target";
type FuncTypeItemUpdateCheckTargetSourceOpt = Option<AvlTree.FuncTypeItemUpdateCheck<Target,Source>> "for checking the update of the relation target->source";

uniontype Relation "a relation is either simple Source->Target or double Source<->Target"
  record UNIDIRECTIONAL "a unidirectional relation, from Source to Target and not vice-versa"
    Tree<Source, Target> relation;
    String name "a name for the relation so you know which one it is if you have more";
  end UNIDIRECTIONAL;

  record BIDIRECTIONAL "a bidirectional relation, both from Source to Target and back"
    Tree<Source, Target> relationSourceTarget;
    Tree<Target, Source> relationTargetSource;
    String name "a name for the relation so you know which one it is if you have more";
  end BIDIRECTIONAL;
end Relation;

// add more here as you please
type IntIntRelation    = Relation<Integer, Integer> "Integer - Integer relation type";
type StrIntRelation    = Relation<String, Integer> "String - Integer relation type";
type IntStrRelation    = Relation<Integer, String> "Integer - String relation type";
type IntLstIntRelation = Relation<Integer, list<Integer>> "Integer - list<Integer> relation type (one to many)";

protected
import Util;
protected import List;

public
function unidirectional
"an unidirectional relation gets:
 - a comparison function for source
 - two optional toString functions for source and target
 - one optional function to check the update of a relation, returns:
   + true if the update should be done,
   + false if the update should not be done
   + fail (with a message) if the update is wrong"
  input String name "a name for the relation so you know which one it is if you have more";
  input FuncTypeKeyCompareSource inCompareFuncSource;
  input FuncTypeStrSourceOpt inSourceStrFunctOpt;
  input FuncTypeStrTargetOpt inTargetStrFunctOpt;
  input FuncTypeItemUpdateCheckSourceTargetOpt inCheckUpdateFuncOpt;
  output Relation<Source, Target> outRelation;
protected
  Tree<Source, Target> t;
algorithm
  t := AvlTree.create(name +& "SourceTarget", inCompareFuncSource, inSourceStrFunctOpt, inTargetStrFunctOpt, inCheckUpdateFuncOpt);
  outRelation := UNIDIRECTIONAL(t,name);
end unidirectional;

function bidirectional
"an bidirectional relation gets:
 - a comparison function for source and one for target and two optional toString functions for source and target"
  input String name "a name for the relation so you know which one it is if you have more";
  input FuncTypeKeyCompareSource inCompareFuncKeySource;
  input FuncTypeKeyCompareTarget inCompareFuncKeyTarget;
  input FuncTypeStrSourceOpt inSourceStrFunctOpt;
  input FuncTypeStrTargetOpt inTargetStrFunctOpt;
  input FuncTypeItemUpdateCheckSourceTargetOpt inSourceTargetCheckUpdateFuncOpt;
  input FuncTypeItemUpdateCheckTargetSourceOpt inTargetSourceCheckUpdateFuncOpt;
  output Relation<Source, Target> outRelation;
protected
  Tree<Source, Target> tTo;
  Tree<Source, Target> tFrom;
algorithm
  tTo := AvlTree.create(name +& "SourceTarget", inCompareFuncKeySource, inSourceStrFunctOpt, inTargetStrFunctOpt, inSourceTargetCheckUpdateFuncOpt);
  tFrom := AvlTree.create(name +& "TargetSource", inCompareFuncKeyTarget, inTargetStrFunctOpt, inSourceStrFunctOpt, inTargetSourceCheckUpdateFuncOpt);
  outRelation := BIDIRECTIONAL(tTo, tFrom, name);
end bidirectional;

function add
  input Relation<Source, Target> inRelation;
  input Source inSource;
  input Target inTarget;
  output Relation<Source, Target> outRelation;
algorithm
  outRelation := matchcontinue(inRelation, inSource, inTarget)
    local
      Tree<Source, Target> tTo;
      Tree<Source, Target> tFrom;
      String n;

    // add in single
    case (UNIDIRECTIONAL(tTo, n), inSource, inTarget)
      equation
        tTo = AvlTree.add(tTo, inSource, inTarget);
      then
        UNIDIRECTIONAL(tTo, n);

    // add in double
    case (BIDIRECTIONAL(tTo, tFrom, n), inSource, inTarget)
      equation
        tTo = AvlTree.add(tTo, inSource, inTarget);
        tFrom = AvlTree.add(tFrom, inTarget, inSource);
      then
        BIDIRECTIONAL(tTo, tFrom, n);

  end matchcontinue;
end add;

function getTargetFromSource
"gets a Target from a Source"
  input Relation<Source, Target> inRelation;
  input Source inSource;
  output Target outTarget;
algorithm
  outTarget := matchcontinue(inRelation, inSource)
    local
      Tree<Source, Target> tTo;
      Target target;

    // search in single
    case (UNIDIRECTIONAL(relation = tTo), inSource)
      equation
        target = AvlTree.get(tTo, inSource);
      then
        target;

    // search in double
    case (BIDIRECTIONAL(relationSourceTarget = tTo), inSource)
      equation
        target = AvlTree.get(tTo, inSource);
      then
        target;

  end matchcontinue;
end getTargetFromSource;

function getSourceFromTarget
"gets a Source from a Target"
  input Relation<Source, Target> inRelation;
  input Target inTarget;
  output Source outSource;
algorithm
  outSource := matchcontinue(inRelation, inTarget)
    local
      Tree<Source, Target> tTo;
      Tree<Source, Target> tFrom;
      Source source;

    // get in single
    case (UNIDIRECTIONAL(relation = tTo), inTarget)
      equation
        source = AvlTree.getKeyOfVal(tTo, inTarget);
      then
        source;

    // get in double
    case (BIDIRECTIONAL(relationTargetSource = tFrom), inTarget)
      equation
        source = AvlTree.get(tFrom, inTarget);
      then
        source;

  end matchcontinue;
end getSourceFromTarget;

function name
  input Relation<Source, Target> inRelation;
  output String name;
algorithm
  name := matchcontinue(inRelation)
    local String n;
    case (UNIDIRECTIONAL(name = n)) then n;
    case (BIDIRECTIONAL(name = n)) then n;
  end matchcontinue;
end name;

function printRelationStr
  input Relation<Source, Target> inRelation;
  output String outString;
algorithm
  outString := matchcontinue(inRelation)
    local
      Tree<Source, Target> tTo;
      Tree<Source, Target> tFrom;
      String str1, str2, str, n;

    case (UNIDIRECTIONAL(tTo,n))
      equation
        str = "to[" +& n +& "]:" +& AvlTree.prettyPrintTreeStr(tTo) +& "\n";
      then
        str;
    case (BIDIRECTIONAL(tTo,tFrom,n))
      equation
        str1 = AvlTree.prettyPrintTreeStr(tTo);
        str2 = AvlTree.prettyPrintTreeStr(tFrom);
        str = stringAppendList({"to[", n, "]:", str1, "\nfrom[", n, "]:" , str2, "\n"});
      then
        str;
  end matchcontinue;
end printRelationStr;

public function intCompare
  input Integer i1;
  input Integer i2;
  output Integer out "-1,0,1";
algorithm
  out := Util.if_(intEq(i1, i2), 0, Util.if_(intLt(i1,i2), -1, 1));
end intCompare;

public function intPairCompare
  input tuple<Integer, Integer> i1;
  input tuple<Integer, Integer> i2;
  output Integer out "-1,0,1";
algorithm
  out := match(i1, i2)
    local
      Integer l1, r1, l2, r2, o;
      Boolean bEQ, bLT;

    case ((l1,r1),(l2,r2))
      equation
        //print("comparing: " +& intPairStr(i1) +& "=<" +& intPairStr(i2));
        bEQ = boolAnd(intEq(l1, l2), intEq(r1, r2));
        bLT = boolOr(intLt(l1, l2), boolAnd(intEq(l1, l2), intLt(r1, r2)));
        o = Util.if_(bEQ, 0, Util.if_(bLT, -1, 1));
        //print(" got: " +& intString(o) +& "\n");
      then
        o;
  end match;
end intPairCompare;

public function intPairStr
  input tuple<Integer, Integer> i;
  output String str;
protected
  Integer i1,i2;
algorithm
  str := "("+& intString(Util.tuple21(i)) +& "," +& intString(Util.tuple22(i)) +& ")";
end intPairStr;

public function intListStr
  input list<Integer> l;
  output String str;
algorithm
  str := "{"+& stringDelimitList(List.map(l, intString), ",") +& "}";
end intListStr;

end Relation;

