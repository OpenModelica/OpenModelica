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

encapsulated package Name
" file:        Name.mo
  package:     Name
  description: Name is name in a pool.
  @author:     adrpo

  RCS: $Id: Name.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Name is a string in an unique relation to an integer. "

public
import AvlTree;

type Name  = String;

type NameInteger = AvlTree.Tree<Name, Integer>;
type IntegerName = AvlTree.Tree<Integer, Name>;

uniontype Names "an dictionary of shared names"
  record NAMES
     NameInteger name2integer;
     IntegerName integer2name;
     Integer sequenceNo "starts at 0 and increments before each addUnique.
                         if the returned value from addUnique is the same
                         smaller than before the increment then the name
                         is already in there!";
  end NAMES;
end Names;

protected
import Relation; // for intCompare!

public function new
  input Names inNames;
  input Name inName;
  output Names outNames;
  output Integer outID;
algorithm
  (outNames, outID) := matchcontinue(inNames, inName)
    local
      NameInteger n2i;
      IntegerName i2n;
      Integer seqOld, seqNew, id;
      Names names;

    // was not there, add it to both
    case (NAMES(n2i, i2n, seqOld), inName)
      equation
        seqNew = seqOld + 1;
        // try to insert it into name2integer
        (n2i, AvlTree.ITEM(val = id)) = AvlTree.addUnique(n2i, inName, seqNew);
        // succesfull add!
        true = intEq(id, seqNew);
        // add to the i2n too!
        i2n = AvlTree.add(i2n, seqNew, inName);
      then
        (NAMES(n2i, i2n, seqNew), id);

    // was there already, do no changes and return the old id!
    case (NAMES(n2i, i2n, seqOld), inName)
      equation
        seqNew = seqOld + 1;
        // try to insert it into name2integer
        (n2i, AvlTree.ITEM(val = id)) = AvlTree.addUnique(n2i, inName, seqNew);
        // already there
        false = intEq(id, seqNew);
      then
        (inNames, id);
  end matchcontinue;
end new;

public function pool
  output Names outNames;
protected
  NameInteger n2i;
  IntegerName i2n;
algorithm
  n2i := AvlTree.create("name2integer", stringCompare, SOME(strIdentity), SOME(intString), NONE());
  i2n := AvlTree.create("integer2name", Relation.intCompare, SOME(intString), SOME(strIdentity), NONE());
  outNames := NAMES(n2i, i2n, 0);
end pool;

public function next
  input Names inNames;
  output Integer nextOne;
algorithm
  NAMES(sequenceNo = nextOne) := inNames;
  nextOne := nextOne + 1;
end next;

function strIdentity
  input String inStr;
  output String outStr;
algorithm
  outStr := inStr;
end strIdentity;

public function get
  input Names inNames;
  input Integer inID;
  output Name outName;
protected
  IntegerName i2n;
algorithm
  // use integer2name relation
  NAMES(integer2name = i2n) := inNames;
  outName := AvlTree.get(i2n, inID);
end get;

public function toString
  input Names inNames;
  output String str;
protected
  NameInteger n2i;
  IntegerName i2n;
  Integer seqNo;
  String str1, str2;
algorithm
  NAMES(n2i, i2n, seqNo) := inNames;
  str1 := AvlTree.prettyPrintTreeStr(n2i);
  str2 := AvlTree.prettyPrintTreeStr(i2n);
  str  := stringAppendList({"to[name2integer]:", str1, "\nfrom[intgeger2name]:" , str2, "\n"});
end toString;

end Name;

