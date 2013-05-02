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
" file:  Name.mo
  package:     Name
  description: Name is name in a pool.

  RCS: $Id: Name.mo 8980 2011-05-13 09:12:21Z adrpo $

  The Name in a pool.

  TODO! USE AN AVLTREE to handle unique instead of a pool!

  "

public import Pool;

type Name  = String;
type Names = Pool.Pool<Name> "an array of shared names";

constant Integer defaultPoolSizeNames = 100000;

protected
import Util;
import System;

public function new
  input Names inNames;
  input Name inName;
  output Names outNames;
  output Integer outID;
algorithm
  (outNames, outID) := Pool.addUnique(inNames, inName, NONE());
end new;

public function pool
  output Names outNames;
algorithm
  outNames := Pool.create("Names", defaultPoolSizeNames);
end pool;

public function get
  input Names inNames;
  input Integer inID;
  output Name outName;
algorithm
  outName := Pool.get(inNames, inID);
end get;

public function add
  input Names inNames;
  input Name inName;
  output Names outNames;
  output Integer outID;
algorithm
  (outNames, outID) := Pool.add(inNames, inName, NONE());
end add;

public function set
  input Names inNames;
  input Integer inID;
  input Name inName;
  output Names outNames;
algorithm
  outNames := Pool.set(inNames, inID, inName);
end set;

public function dump
  input Integer ignored;
  input Option<Name> inStrOpt;
algorithm
  _ := match(ignored, inStrOpt)
    local Name s;
    case (_, SOME(s))
      equation
  print(s +& "\n");
      then
  ();

    case (_, _)
      equation
  print("\n");
      then ();
  end match;
end dump;

public function dumpPool
  input Names inNames;
algorithm
  _ := Util.arrayApplyR(Pool.members(inNames), Pool.next(inNames), dump, 0);
end dumpPool;

end Name;

