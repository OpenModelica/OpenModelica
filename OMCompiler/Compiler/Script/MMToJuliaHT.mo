/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

encapsulated package MMToJuliaHT
"
Description:
  Hash table used for Julia translation
  Maps an identifier to it's class.
  Operates on a global varible indexed with MM_TO_JL_HT_INDEX.

  This cache is used both when generating Julia code and when transformering Meta Modelica into Julia.

  During the transformation phase certain components are saved, wheras in the code generation phase lookup is rerouted
  to account for structural changes to the code.
"
protected
import Absyn;
import AbsynUtil;
import Dump;
import Error;
import Global;
import List;
import Util.println;
import Util;
public
import BaseHashTable;

public uniontype ClassInfo
  record CLASS_INFO
    Absyn.Class originalClass "Uniontype usually";
    Absyn.Class wrapperClass "The class in which the old top class is wrapped. E.g a package around a uniontype";
  end CLASS_INFO;
end ClassInfo;

public type Key = String;
public type Value = Option<ClassInfo>;

public
constant Integer MM_JL_HT_BUCKETSIZE = BaseHashTable.avgBucketSize;

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

partial function FuncExpStr
  input Value exp;
  output String res;
end FuncExpStr;

public type HashTableCrefFunctionsType = tuple<FuncHashCref, FuncCrefEqual, FuncCrefStr, FuncExpStr>;
public type HashTable = tuple<array<list<tuple<Key, Integer>>>,
                              tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
                              Integer,
                              HashTableCrefFunctionsType>;
protected type HashNode = list<tuple<Key, Integer>>;
protected type HashVector = array<HashNode>;

public function dumpHashTableStatistics "
author: PA.
dump statistics on how many entries per hash value. Useful to see how hash function behaves"
  input HashTable hashTable;
algorithm
 _ := match(hashTable)
 local HashVector hvec;
   case((hvec,_,_,_)) equation
      print("index list lengths:\n");
      print(stringDelimitList(list(intString(listLength(l)) for l in hvec),","));
      print("\n");
      print("non-zero: " + String(sum(1 for l guard not listEmpty(l) in hvec)) + "/" + String(arrayLength(hvec)) +"\n");
      print("max element: " + String(max(listLength(l) for l in hvec)) + "\n");
      print("total entries: " + String(sum(listLength(l) for l in hvec)) + "\n");
   then ();
 end match;
end dumpHashTableStatistics;

function dumpClassInfo
  input Value exp;
  output String res;
algorithm
  res := match exp
    local
      ClassInfo info;
    case SOME(info as CLASS_INFO(__)) then
      Dump.unparseClassStr(info.originalClass) + "\n"
      + Dump.unparseClassStr(info.wrapperClass);
    else "";
  end match;
end dumpClassInfo;

function valueEq
  input Key key1;
  input Key key2;
  output Boolean res;
algorithm
  res := stringEqual(key1, key2);
end valueEq;

function keyToString
  input Key key1;
  output String keyStr;
algorithm
  keyStr := key1;
end keyToString;

function hashKey
  input Key inKey;
  input Integer modulo;
  output Integer outHash;
algorithm
  outHash := stringHashDjb2Mod(inKey, modulo);
end hashKey;

function get
  input Key k;
  output Value v;
protected
  HashTable ht;
algorithm
  try
    ht := getGlobalRoot(Global.MM_TO_JL_HT_INDEX);
    v := BaseHashTable.get(k, ht);
  else
    v := NONE();
  end try;
end get;

function add
  input Key k;
  input Value v;
protected
  HashTable ht;
algorithm
  try
    ht := getGlobalRoot(Global.MM_TO_JL_HT_INDEX);
    ht := BaseHashTable.add((k, v),ht);
    setGlobalRoot(Global.MM_TO_JL_HT_INDEX, ht);
  else
    Error.addInternalError("Error adding to HT", sourceInfo());
  end try;
end add;

function componentInPathIsInHT
  "This function returns true if a part of a path is in the HT.
   For instance for the path A.B.C we will return true if either A, B or C is in the HT."
  input Absyn.Path inPath;
  output Boolean pathIsInHT;
protected
  list<String> pathStrings = {};
algorithm
//  println(anyString(inPath));
  pathStrings := Util.stringSplitAtChar(AbsynUtil.pathStringDefault(inPath), ".");
//  println(anyString(pathStrings));
  for ps in pathStrings loop
    pathIsInHT := match get(ps)
      case SOME(CLASS_INFO(__)) algorithm then true;
      case _ then false;
    end match;
    if pathIsInHT then
      break;
    end if;
  end for;
end componentInPathIsInHT;

function returnThePathOfTheWrapperPackageInHT
  " This function returns the path as a string of the component in a path that is in the HT.
    Otherwise returns the old path"
  input Absyn.Path inPath;
  output String newPath  = "";
protected
  list<ClassInfo> fetchedInfos = {};
  list<String> pathStrings = {};
  list<String> newPathStrs = {};
  Integer indexCounter = 0;
algorithm
  if not componentInPathIsInHT(inPath) then
//  println("returnThePathOfTheWrapperPackageInHT: 1");
    newPath := AbsynUtil.pathStringDefault(inPath);
    return;
  end if;
//  println("returnThePathOfTheWrapperPackageInHT: 2");
  pathStrings := Util.stringSplitAtChar(AbsynUtil.pathStringDefault(inPath), ".");
  newPathStrs := pathStrings;
  for ps in pathStrings loop
    indexCounter := indexCounter + 1;
    () := match get(ps)
     local
       ClassInfo cInfo;
       Absyn.Class oldClass_;
       Absyn.Class newPackage_;
     case SOME(CLASS_INFO(originalClass = oldClass_, wrapperClass = newPackage_))
       algorithm /* Insert the wrapper in the path before the path that was in the HT. */
         newPathStrs := List.insert(newPathStrs, indexCounter, newPackage_.name);
         newPathStrs := List.deleteMember(newPathStrs, oldClass_.name);
       then ();
     else ();
   end match;
  end for;
//println("returnThePathOfTheWrapperPackageInHT: 3" + anyString(newPathStrs));
  for ps in newPathStrs loop
    if stringEqual(newPath, "") then
      newPath := ps;
    else
        newPath := newPath + "." + ps;
    end if;
  end for;
//  println("The new path:" + newPath);
end returnThePathOfTheWrapperPackageInHT;

function exists
"Returns true if key exists in HT"
  input Key k;
  output Boolean b;
protected
  list<String> pathStrings = {};
algorithm
  b := match get(k)
    case SOME(CLASS_INFO(__)) then true;
    else false;
  end match;
end exists;

function init
  "Init the HT. If not empty reuse the one that is in use."
protected
  HashTable ht;
algorithm
  try
    ht := getGlobalRoot(Global.MM_TO_JL_HT_INDEX);
  else /* If we do not have a HT */
    setGlobalRoot(Global.MM_TO_JL_HT_INDEX, createHT());
  end try;
end init;

function createHT
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(MM_JL_HT_BUCKETSIZE,
                                                (hashKey,
                                                valueEq,
                                                keyToString,
                                                dumpClassInfo));
end createHT;

annotation(__OpenModelica_Interface="backend");
end MMToJuliaHT;
