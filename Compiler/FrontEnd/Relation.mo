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

  RCS: $Id: Relation.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Relation can be single source->target or double source<->target.
  The relation is implemented using generic Avl trees."

public 
import AvlTree;

replaceable type Source subtypeof Any;
replaceable type Target subtypeof Any;

type Tree = AvlTree.Tree<Source, Target>;
type FuncTypeKeyCompareSource = AvlTree.FuncTypeKeyCompare<Source>; 
type FuncTypeKeyCompareTarget = AvlTree.FuncTypeKeyCompare<Target>;

uniontype Relation "a relation is either simple Source->Target or double Source<->Target"
  record SINGLE "a single relation, from Source to Target and not vice-versa"
    Tree<Source, Target> relation; 
  end SINGLE;
  
  record DOUBLE "a double relation, both from Source to Target and back"
    Tree<Source, Target> relationSourceTarget;
    Tree<Target, Source> relationTargetSource;
  end DOUBLE;
end Relation;

// add more here as you please
type IntRelation = Relation<Integer, Integer> "Integer - Integer relation type";
type IntRelation = Relation<String, Integer> "String - Integer relation type";
type IntRelation = Relation<Integer, String> "String - Integer relation type";

function createSingle
  input FuncTypeKeyCompareSource inCompareFuncSource;
  output Relation<Source, Target> outRelation;
protected 
  Tree<Source, Target> t;
algorithm
  t := AvlTree.create(inCompareFuncSource, NONE(), NONE(), NONE());
  outRelation := SINGLE(t);
end createSingle;

function createDouble
  input FuncTypeKeyCompareSource inCompareFuncKeySource;
  input FuncTypeKeyCompareTarget inCompareFuncKeyTarget;
  output Relation<Source, Target> outRelation;
protected
  Tree<Source, Target> tTo;
  Tree<Source, Target> tFrom;
algorithm
  tTo := AvlTree.create(inCompareFuncKeySource, NONE(), NONE(), NONE());
  tFrom := AvlTree.create(inCompareFuncKeyTarget, NONE(), NONE(), NONE());
  outRelation := DOUBLE(tTo, tFrom);
end createDouble;

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
    
    // add in single
    case (SINGLE(tTo), inSource, inTarget)
      equation
        tTo = AvlTree.add(tTo, inSource, inTarget);
      then
        SINGLE(tTo);
    
    // add in double
    case (DOUBLE(tTo, tFrom), inSource, inTarget)
      equation
        tTo = AvlTree.add(tTo, inSource, inTarget);
        tFrom = AvlTree.add(tFrom, inTarget, inSource);
      then
        DOUBLE(tTo, tFrom);
   
  end matchcontinue;
end add;

function getTarget
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
    case (SINGLE(tTo), inSource)
      equation
        target = AvlTree.get(tTo, inSource);
      then
        target;
    
    // search in double
    case (DOUBLE(tTo, _), inSource)
      equation
        target = AvlTree.get(tTo, inSource);
      then
        target;
   
  end matchcontinue;
end getTarget;

function getSource 
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
    case (SINGLE(tTo), inTarget)
      equation
        source = AvlTree.getKeyOfVal(tTo, inTarget);
      then
        source;
    
    // get in double
    case (DOUBLE(_, tFrom), inTarget)
      equation
        source = AvlTree.get(tFrom, inTarget);
      then
        source;
   
  end matchcontinue;
end getSource;

end Relation;

