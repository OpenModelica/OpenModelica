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

encapsulated package HashSetString "HashSet of strings."

/* Below is the instance specific code. For each hashset the user must define:

Key       - The key used to uniquely define elements in a hashset
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashSet instance specific code */

public import BaseHashSet;
protected import System;
protected import Util;

public type Key = String;

public type HashSetCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr>;
public type HashSet = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<Key>>>,
  Integer,
  Integer,
  HashSetCrefFunctionsType
>;

partial function FuncHashCref
  input Key cr;
  input Integer mod;
  output Integer res;
end FuncHashCref;

partial function FuncCrefEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncCrefEqual;

partial function FuncCrefStr
  input Key cr;
  output String res;
end FuncCrefStr;

public function emptyHashSet
"
  Returns an empty HashSet.
  Using the default bucketsize..
"
  output HashSet hashSet;
algorithm
  hashSet := emptyHashSetSized(BaseHashSet.defaultBucketSize);
end emptyHashSet;

public function emptyHashSetSized
"Returns an empty HashSet.
 Using the bucketsize size"
  input Integer size;
  output HashSet hashSet;
algorithm
  hashSet := BaseHashSet.emptyHashSetWork(size,(stringHashDjb2Mod,stringEq,Util.id));
end emptyHashSetSized;

annotation(__OpenModelica_Interface="util");
end HashSetString;
