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


encapsulated package SCodeHashTable 
" file:        SCodeHashTable.mo
  package:     SCodeHashTable
  description: SCodeHashTable deals with hashing the elements in SCode

  RCS: $Id: SCodeHashTable.mo 7705 2011-01-17 09:53:52Z sjoelund.se $

  SCodeHashTable deals with hashing the elements in SCode
  Absyn.ComponentRef -> SCode.Element
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
protected import System;
protected import BaseHashTable;
protected import SCodeLookup;

public 
uniontype HashValue
  record VALUE
    Integer seqNo "the element number inside the class";
    SCode.Element element "the element";
    list<SCode.Mod> outsideMods "the outside modifiers";
    Option<SCode.Element> replacedElement "the element replaced (extends/derived/class_extends)";   
    Option<HashTable> optChildren;
  end VALUE;
end HashValue; 

public type Key = Absyn.ComponentRef;
public type Value = HashValue;

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
  input HashValue inHashValue;
  output String outString;
algorithm
  outString := matchcontinue(inHashValue)
    local
      String str;
      Integer seqNo;
      SCode.Element element;
      list<SCode.Mod> outsideMods;
      HashTable hashTable;
      
    case (VALUE(seqNo = seqNo, element = element, outsideMods = outsideMods, optChildren = NONE()))
      equation
        str = intString(seqNo) +& 
              ", " +& SCode.shortElementStr(element) +&
              ", {" +& 
              Util.stringDelimitList(
                Util.listMap(outsideMods, SCode.printModStr),
                ", ") +& "}";
      then
        str;
    
    case (VALUE(seqNo = seqNo, element = element, outsideMods = outsideMods, optChildren = SOME(hashTable)))
      equation
        str = intString(seqNo) +& 
              ", " +& SCode.shortElementStr(element) +&
              ", {" +& 
              Util.stringDelimitList(
                Util.listMap(outsideMods, SCode.printModStr),
                ", ") +& "}" +&
              ", Kids: (" +& 
              Util.stringDelimitList(
                Util.listMap(BaseHashTable.hashTableList(hashTable), 
                hashItemString), ", ") +& ")";
      then
        str;
  end matchcontinue;
end hashValueString;

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

public function getHasValueElement
  input HashValue inValue;
  output SCode.Element el;
algorithm
  VALUE(element=el) := inValue;
end getHasValueElement;

public function compare
  input HashValue inValue1;
  input HashValue inValue2;
  output Boolean isGreater;
algorithm
  isGreater := matchcontinue(inValue1, inValue2)
    local
      Integer sq1, sq2;
    case (VALUE(seqNo=sq1), VALUE(seqNo=sq2))
      then intGt(sq1, sq2); 
  end matchcontinue;
end compare;

public function createSomeHash
  input Option<HashTable> inOptHashTable;
  output Option<HashTable> outOptHashTable;
algorithm
  outOptHashTable := matchcontinue(inOptHashTable)
    local 
      HashTable h;

    case (NONE())
      equation
        h = emptyHashTable(); 
      then SOME(h);

    case (SOME(_)) then inOptHashTable;

  end matchcontinue;
end createSomeHash;

public function add
  input tuple<Key,Value> inKeyValue;
  input Option<HashTable> inOptHashTable;
  output Option<HashTable> outOptHashTable;
algorithm
  outOptHashTable := matchcontinue(inKeyValue, inOptHashTable)
    local
      HashTable hashTable;
      Option<HashTable> optHashTable;
      HashValue hashValue;
      Key key;
    
    // not there, add it
    case (inKeyValue as (key, _), optHashTable)
      equation
        SOME(hashTable) = createSomeHash(optHashTable);
        failure((_) = BaseHashTable.get(key, hashTable));
        hashTable = BaseHashTable.addNoUpdCheck(inKeyValue, hashTable);
      then
        SOME(hashTable);

    // failed, we have a duplicate
    case (inKeyValue as (key, _), optHashTable)
      equation
        SOME(hashTable) = createSomeHash(optHashTable);
        hashValue = BaseHashTable.get(key, hashTable);
        print("Duplicate element found: " +& hashValueString(hashValue) +& "\n");
      then
        fail();

  end matchcontinue;
end add;

public function programFromHashTable
  input HashTable inHash;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inHash)
    local
      SCode.Program program;
      list<HashValue> els; 
      
    case (inHash)
      equation
        els = BaseHashTable.hashTableValueList(inHash);
        els = Util.sort(els, compare);
        program = Util.listMap(els, getHasValueElement);
      then
        program;
  end matchcontinue;
end programFromHashTable;

public function hashTableFromProgram
  "Flattens a program."
  input SCode.Program inProgram;
  input SCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNo;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inProgram, inEnv, inHashTable, seqNo)
    local
      SCodeEnv.Env env;
      SCode.Element cl, newCls;
      SCode.Program rest;
      Option<HashTable> hashTable;
      
    case ({}, env, hashTable, _) then hashTable;
    case (cl::rest, env, hashTable, seqNo)
      equation
        hashTable = hashTableFromClass(Absyn.CREF_IDENT("", {}), cl, env, hashTable, seqNo);
        hashTable = hashTableFromProgram(rest, env, hashTable, seqNo + 1);
      then 
        hashTable;
  end matchcontinue; 
end hashTableFromProgram;

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

protected function hashTableFromClass
  "Flattens a program."
  input Absyn.ComponentRef inParent;
  input SCode.Element inClass;
  input SCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNo;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inParent, inClass, inEnv, inHashTable, seqNo)
    local
      SCodeEnv.Env env;
      SCode.Element cl, newCls;
      SCode.Program rest;
      Option<HashTable> hashTable;
      SCode.Element element;
      SCode.Ident className;
      Absyn.ComponentRef fullCref;
      Option<HashTable> optHT;
      SCode.ClassDef cDef;
      Absyn.Info info;
      
    case (inParent, cl as SCode.CLASS(classDef = cDef, info = info), env, hashTable, seqNo)
      equation
        className = SCode.className(cl);        
        element = cl;
        fullCref = joinCrefs(inParent, Absyn.CREF_IDENT(className, {}));
        env = SCodeEnv.enterScope(env, className);
        optHT = hashTableFromClassDef(fullCref, cl, cDef, env, NONE(), 1, info);
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, element, {}, NONE(), optHT)),
            hashTable);
      then 
        hashTable;
  end matchcontinue; 
end hashTableFromClass;

protected function hashTableFromClassDef
  "Flattens a classdef."
  input Absyn.ComponentRef inParent;
  input SCode.Element inElementParent;  
  input SCode.ClassDef inClassDef;
  input SCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNo;
  input Absyn.Info info;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inParent, inElementParent, inClassDef, inEnv, inHashTable, seqNo, info)
    local
      SCodeEnv.Env env;
      SCode.Element cl, newCls, parentElement;
      SCode.Program rest;
      Option<HashTable> hashTable, optHT;
      SCode.Element el;
      SCode.Ident className, baseClassName, name;
      Absyn.ComponentRef fullCref;
      list<SCode.Element> els;
      Absyn.Path path;
      SCodeEnv.ClassType classType;
    
    // handle parts  
    case (inParent, parentElement, SCode.PARTS(elementLst = els), env, hashTable, seqNo, info)
      equation        
        hashTable = hashTableAddElements(inParent, els, env, hashTable, 1);
      then 
        hashTable;
    
    // handle class extends   
    case (inParent, parentElement, SCode.CLASS_EXTENDS(baseClassName = baseClassName, composition = SCode.PARTS(elementLst = els)), env, hashTable, seqNo, info)
      equation
        fullCref = joinCrefs(inParent, Absyn.CREF_QUAL("$cextends", {}, Absyn.CREF_IDENT(baseClassName, {})));
        hashTable = hashTableAddElements(fullCref, els, env, NONE(), 1);
      then 
        hashTable;
    
    // handle derived not builtin!
    case (inParent, parentElement, SCode.DERIVED(typeSpec = Absyn.TPATH(path = path)), env, hashTable, seqNo, info)
      equation
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = SCodeEnv.removeExtendsFromLocalScope(env);
        
        (SCodeEnv.CLASS(cls = el, classType = classType), path, env) = 
          SCodeLookup.lookupBaseClassName(path, env, info);
        
        // not builtin types
        false = valueEq(classType, SCodeEnv.BUILTIN());
        
        name = Absyn.pathString(path);
        fullCref = joinCrefs(inParent,
          Absyn.CREF_QUAL("$derived", {}, Absyn.CREF_IDENT(name, {})));
        
        optHT = hashTableAddElement(Absyn.crefStripLast(fullCref), el, env, NONE(), 1);
        
        hashTable =
          add(
            (fullCref, VALUE(seqNo, el, {}, SOME(parentElement), optHT)),
            hashTable);
      then 
        hashTable;
    
    // handle derived builtin!
    case (inParent, parentElement, SCode.DERIVED(typeSpec = Absyn.TPATH(path = path)), env, hashTable, seqNo, info)
      equation
        // Remove the extends from the local scope before flattening the derived
        // type, because the type should not be looked up via itself.
        env = SCodeEnv.removeExtendsFromLocalScope(env);
        
        (SCodeEnv.CLASS(cls = el, classType = classType), path, env) = 
          SCodeLookup.lookupBaseClassName(path, env, info);
        
        // builtin types
        true = valueEq(classType, SCodeEnv.BUILTIN());
        
        name = Absyn.pathString(path);
        fullCref = joinCrefs(inParent,
          Absyn.CREF_QUAL("$derived", {}, Absyn.CREF_IDENT(name, {})));
        
        hashTable =
          add(
            (fullCref, VALUE(seqNo, el, {}, SOME(parentElement), NONE())),
            hashTable);
      then 
        hashTable;
    
    // handle enumeration
    case (inParent, parentElement, SCode.ENUMERATION(enumLst = _), env, hashTable, seqNo, info)
      then 
        hashTable;
    
    // handle overload
    case (inParent, parentElement, SCode.OVERLOAD(pathLst = _), env, hashTable, seqNo, info)
      then 
        hashTable;
    
    // handle pder
    case (inParent, parentElement, SCode.PDER(functionPath = _), env, hashTable, seqNo, info)
      then 
        hashTable;
  end matchcontinue; 
end hashTableFromClassDef;

protected function hashTableAddElements
  "adds elements to hashtable"
  input Absyn.ComponentRef inParent;
  input list<SCode.Element> inElements;
  input SCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNo;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inParent, inElements, inEnv, inHashTable, seqNo)
    local
      SCodeEnv.Env env;
      Option<HashTable> hashTable;
      SCode.Element el;
      list<SCode.Element> rest;
    
    // handle empty  
    case (inParent, {}, env, hashTable, seqNo) then hashTable;
    
    // handle rest
    case (inParent, el::rest, env, hashTable, seqNo)
      equation
        hashTable = hashTableAddElement(inParent, el, env, hashTable, seqNo);
        hashTable = hashTableAddElements(inParent, rest, env, hashTable, seqNo + 1);
      then 
        hashTable;
    
  end matchcontinue; 
end hashTableAddElements;

protected function hashTableAddElement
  "adds elements to hashtable"
  input Absyn.ComponentRef inParent;
  input SCode.Element inElement;
  input SCodeEnv.Env inEnv;
  input Option<HashTable> inHashTable;
  input Integer seqNo;
  output Option<HashTable> outHashTable;
algorithm
  outHashTable := matchcontinue(inParent, inElement, inEnv, inHashTable, seqNo)
    local
      SCodeEnv.Env env;
      Option<HashTable> hashTable;
      SCode.Element el;
      Absyn.ComponentRef fullCref;
      Option<HashTable> optHT;
      SCode.Ident name;
      Absyn.Path path;
      SCode.Element cl;
      Absyn.Import imp;
      Absyn.Info info;
      SCodeEnv.Item item;
      SCode.ClassDef cDef;
      SCode.Mod mod;
      SCode.Visibility vis;
    
    // handle extends
    case (inParent, el as SCode.EXTENDS(baseClassPath = path, modifications = mod, visibility = vis, info = info), env, hashTable, seqNo)
      equation
        // Remove the extends from the local scope before flattening the extends
        // type, because the type should not be looked up via itself.
        env = SCodeEnv.removeExtendsFromLocalScope(env);
        (SCodeEnv.CLASS(cls = cl), path, env) = SCodeLookup.lookupBaseClassName(path, env, info);
        name = Absyn.pathString(path);
        fullCref = joinCrefs(inParent, 
          Absyn.CREF_QUAL("$extends", {}, Absyn.CREF_IDENT(name, {})));
        optHT = hashTableAddElement(Absyn.crefStripLast(fullCref), cl, env, NONE(), 1);
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, cl, {mod}, SOME(el), optHT)),
            hashTable);
      then 
        hashTable;

    // handle classdef
    case (inParent, el as SCode.CLASS(name = name, classDef = cDef, info = info), env, hashTable, seqNo)
      equation
        fullCref = joinCrefs(inParent, Absyn.CREF_IDENT(name, {}));
        env = SCodeEnv.enterScope(env, name);
        optHT = hashTableFromClassDef(fullCref, el, cDef, env, NONE(), 1, info);
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, el, {}, NONE(), optHT)),
            hashTable);
      then 
        hashTable;
    
    // handle import, WE SHOULD NOT HAVE ANY!
    case (inParent, el as SCode.IMPORT(imp = imp), env, hashTable, seqNo)
      equation
        name = Dump.unparseImportStr(imp);
        fullCref = joinCrefs(inParent, 
           Absyn.CREF_QUAL("$import", {}, Absyn.CREF_IDENT(name, {})));
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, el, {}, NONE(), NONE())),
            hashTable);
      then 
        hashTable;

    // handle component
    case (inParent, el as SCode.COMPONENT(name = name), env, hashTable, seqNo)
      equation
        fullCref = joinCrefs(inParent, Absyn.CREF_IDENT(name, {}));
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, el, {}, NONE(), NONE())),
            hashTable);
      then 
        hashTable;
    
    // handle defineunit
    case (inParent, el as SCode.DEFINEUNIT(name = name), env, hashTable, seqNo)
      equation
        fullCref = joinCrefs(inParent, Absyn.CREF_IDENT(name, {}));
        hashTable = 
          add(
            (fullCref, VALUE(seqNo, el, {}, NONE(), NONE())),
            hashTable);
      then 
        hashTable;
  end matchcontinue; 
end hashTableAddElement;

public function lookup
  input Option<HashTable> inHashTable;
  input Key key;
  output HashValue outHashValue;
algorithm  
  outHashValue := matchcontinue(inHashTable, key)
    local
      HashTable hashTable;
      HashValue hashValue;
    
    // found something  
    case (SOME(hashTable), key)
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

end SCodeHashTable;
