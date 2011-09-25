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


encapsulated package SCodeMod 
" file:        SCodeMod.mo
  package:     SCodeMod
  description: SCodeMod deals with hashing the modifications in SCode

  RCS: $Id: SCodeMod.mo 7705 2011-01-17 09:53:52Z sjoelund.se $

  SCodeMod deals with hashing the modifications in SCode
  Absyn.ComponentRef -> SCode.Mod
  "
  
/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

public import Absyn;
public import SCode;
public import SCodeEnv;

protected import Dump;
protected import Util;
protected import List;
protected import System;
protected import BaseHashTable;
protected import SCodeLookup;
protected import SCodeDump;

public
uniontype ModType
  record INNER_MOD end INNER_MOD;
  record OUTER_MOD end OUTER_MOD; 
end ModType;

public 
uniontype Mod
  record MOD
    Absyn.ComponentRef fullCref "the component reference of this modifier";
    SCode.Mod          mod "the modifier";
    Absyn.Path         scope "the scope of the modifier, i.e. the fully qualified class where it originates";
    SCode.Element      origin "the element where the modification appeared (extends, derived, component, constraint class)";
    ModType            modType "the type of modifer, local vs. outside"; 
  end MOD;
end Mod; 

type Modifications = list<Mod> "a list of modifications with the same name";

public type Key = Absyn.ComponentRef;
public type Value = Modifications;

public type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
public type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  Integer,
  HashTableCrefFunctionsType
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

partial function FuncExpStr
  input Value exp;
  output String res;
end FuncExpStr;

protected function hashFunc
"Calculates a hash value for Key"
  input Key cr;
  input Integer mod;
  output Integer res;
protected
  String crstr;
algorithm
  crstr := Dump.printComponentRefStr(cr);
  res := System.stringHashDjb2Mod(crstr,mod);
end hashFunc;

protected function hashValueString
  input Value inHashValue;
  output String outString;
algorithm
  outString := matchcontinue(inHashValue)
    local
      String str;
    
    case (inHashValue)
      equation
        str = "(" +& stringDelimitList(
                List.map(inHashValue, modString),
                ", ") +& ")";
      then
        str;    
  end matchcontinue;
end hashValueString;

public function modString
  input Mod inMod;
  output String str;
algorithm
  str := matchcontinue(inMod)
    local
      Absyn.ComponentRef fullCref "the component reference of this modifier";
      SCode.Mod mod "the modifier";
      Absyn.Path scope "the scope of the modifier, i.e. the fully qualified class where it originates";
      SCode.Element origin "the element where the modification appeared (extends, derived, component, constraint class)";
      ModType modType "the type of modifer, local vs. outside";      
    
    case (MOD(fullCref, mod, scope, origin, modType))
      equation
        str = Dump.printComponentRefStr(fullCref) +& "[" +& 
          "mod: " +& SCodeDump.printModStr(mod) +& ", " +&
          "scope: " +& Absyn.pathString(scope) +& ", " +&
          "origin:" +& SCodeDump.shortElementStr(origin) +& ", " +&
          "type:" +& modTypeString(modType) +& "]";
      then
        str;
  end matchcontinue;
end modString;

public function modTypeString
  input ModType inModType;
  output String str;
algorithm
  str := matchcontinue(inModType)    
    case (INNER_MOD()) then "inner";
    case (OUTER_MOD()) then "outer";      
  end matchcontinue;
end modTypeString;

public function hashItemString
  input tuple<Key,Value> tpl;
  output String str;
protected
  Key k;
  Value v;
algorithm
  (k, v) := tpl;
  str := "{" +& Dump.printComponentRefStr(k) +& ",{" +& hashValueString(v) +& "}}";  
end hashItemString;

public function emptyHashTable
"Returns an empty HashTable.
 Using the default bucketsize.."
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

public function emptyHashTableSized
"Returns an empty HashTable.
 Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(hashFunc,Absyn.crefEqual,Dump.printComponentRefStr,hashValueString));
end emptyHashTableSized;

public function add
  input tuple<Key,Value> inKeyValue;
  input HashTable inHashTable;
  output HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(inKeyValue, inHashTable)
    local
      HashTable hashTable;
      Value hashValue;
      Key key;
    
    // not there, add it
    case (inKeyValue as (key, _), hashTable)
      equation
        failure((_) = BaseHashTable.get(key, hashTable));
        hashTable = BaseHashTable.addNoUpdCheck(inKeyValue, hashTable);
      then
        hashTable;

    // failed, we have a duplicate
    case (inKeyValue as (key, _), hashTable)
      equation
        hashValue = BaseHashTable.get(key, hashTable);
        print("Duplicate modifier found: " +& hashValueString(hashValue) +& "\n");
      then
        fail();
  end matchcontinue;
end add;

public function hashTableFromMod
  "Creates a hashtable from a modifier"
  input Absyn.ComponentRef inName;
  input SCode.Mod inMod;
  input SCodeEnv.Env inEnv;
  input Absyn.Path inPathScope;
  input SCode.Element inElementOrigin;
  input ModType inModType;
  output HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(inName, inMod, inEnv, inPathScope, inElementOrigin, inModType)
    local
      SCodeEnv.Env env;
      HashTable hashTable;
      SCode.Final finalPrefix "final prefix";
      SCode.Each eachPrefix "each prefix";
      list<SCode.SubMod> subModLst;
      Option<tuple<Absyn.Exp, Boolean>> binding;      
      
    case (inName, SCode.MOD(finalPrefix, eachPrefix, subModLst, binding), inEnv, inPathScope, inElementOrigin, inModType)
      equation
        // TODO! add mod to hashtable
        hashTable = emptyHashTable();
      then 
        hashTable;
  end matchcontinue; 
end hashTableFromMod;

protected function joinCrefs
  "do not join if ident is empty"
  input Absyn.ComponentRef inCrefPrefix;
  input Absyn.ComponentRef inCrefSuffix;
  output Absyn.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCrefPrefix, inCrefSuffix)
    local
      Absyn.ComponentRef cref;

    // handle "", return the suffix
    case (Absyn.CREF_IDENT(name = ""), inCrefSuffix) 
      then inCrefSuffix;

    // handle != "", return the joined prefix.suffix
    case (inCrefPrefix, inCrefSuffix)
      equation
        cref = Absyn.joinCrefs(inCrefPrefix, inCrefSuffix);
      then 
        cref;
  end matchcontinue;
end joinCrefs;

public function lookup
  input HashTable inHashTable;
  input Key key;
  output Value outValue;
algorithm  
  outValue := matchcontinue(inHashTable, key)
    local
      HashTable hashTable;
      Value hashValue;
    
    // found something  
    case (hashTable, key)
      equation
        hashValue = BaseHashTable.get(key, hashTable);
      then
        hashValue;
    
    // found nothing!
    case (_, key)
      equation
        print("Lookup failed for: " +&  Dump.printComponentRefStr(key) +& "\n");
      then
        fail();
  end matchcontinue;
end lookup;

end SCodeMod;
