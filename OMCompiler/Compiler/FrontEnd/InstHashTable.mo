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

encapsulated package InstHashTable "hash table implementation for cashing instantiation results"

import DAE.Connect;
import ConnectionGraph;
import ClassInf;
import DAE;
import FCore;
import InstTypes;
import SCode;

protected

import Flags;
import Global;
import OperatorOverloading;

public

type Key = Absyn.Path;
type Value = CachedInstItems;

type CachedInstItemInputs = tuple<DAE.Mod, DAE.Prefix,
    Connect.Sets, ClassInf.State, SCode.Element, InstTypes.InstDims, Boolean,
    Option<DAE.ComponentRef>, InstTypes.CallingScope>;

type CachedInstItemOutputs = tuple<FCore.Graph, DAE.DAElist, Connect.Sets,
    ClassInf.State, list<DAE.Var>, Option<DAE.Type>, Option<SCode.Attributes>,
    DAE.EqualityConstraint, ConnectionGraph.ConnectionGraph>;

type CachedPartialInstItemInputs = tuple<DAE.Mod, DAE.Prefix,
    ClassInf.State, SCode.Element, InstTypes.InstDims>;

type CachedPartialInstItemOutputs = tuple<FCore.Graph, ClassInf.State, list<DAE.Var>>;

type CachedInstItems = list<Option<CachedInstItem>>;

function init
protected
  HashTable ht;
algorithm
  /* adrpo: reuse it if is already there! */
  try
    ht := getGlobalRoot(Global.instHashIndex);
    ht := BaseHashTable.clear(ht);
    setGlobalRoot(Global.instHashIndex, ht);
  else
    setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
  end try;
end init;

function release
algorithm
  setGlobalRoot(Global.instHashIndex, emptyInstHashTable());
  OperatorOverloading.initCache();
end release;

function get
  input Key k;
  output Value v;
protected
  HashTable ht;
algorithm
  ht := getGlobalRoot(Global.instHashIndex);
  v := BaseHashTable.get(k, ht);
end get;

uniontype CachedInstItem
  // *important* inputs/outputs for instClassIn
  record FUNC_instClassIn
    CachedInstItemInputs inputs;
    CachedInstItemOutputs outputs;
  end FUNC_instClassIn;

  // *important* inputs/outputs for partialInstClassIn
  record FUNC_partialInstClassIn
    CachedPartialInstItemInputs inputs;
    CachedPartialInstItemOutputs outputs;
  end FUNC_partialInstClassIn;

end CachedInstItem;

function addToInstCache
  input Absyn.Path fullEnvPathPlusClass;
  input Option<CachedInstItem> fullInstOpt;
  input Option<CachedInstItem> partialInstOpt;
algorithm
  _ := matchcontinue(fullEnvPathPlusClass,fullInstOpt, partialInstOpt)
    local
      CachedInstItem fullInst, partialInst;
      HashTable instHash;
      Option<CachedInstItem> opt;
      list<Option<CachedInstItem>> lst;

    // nothing is we have -d=noCache
    case (_, _, _)
      equation
        false = Flags.isSet(Flags.CACHE);
       then
         ();

    // we have them both
    case (_, SOME(_), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{fullInstOpt,partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a partial inst result and the full in the cache
    case (_, NONE(), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a full inst here
        {opt,_} = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{opt,partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a partial inst result and the full is NOT in the cache
    case (_, NONE(), SOME(_))
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a full inst here
        // failed above {SOME(fullInst),_} = get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{NONE(),partialInstOpt}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a full inst result and the partial in the cache
    case (_, SOME(_), NONE())
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a partial inst here
        (_::(lst as {SOME(_)})) = BaseHashTable.get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,fullInstOpt::lst),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we have a full inst result and the partial is NOT in the cache
    case (_, SOME(_), NONE())
      equation
        instHash = getGlobalRoot(Global.instHashIndex);
        // see if we have a partial inst here
        // failed above {_,SOME(partialInst)} = get(fullEnvPathPlusClass, instHash);
        instHash = BaseHashTable.add((fullEnvPathPlusClass,{fullInstOpt,NONE()}),instHash);
        setGlobalRoot(Global.instHashIndex, instHash);
      then
        ();

    // we failed above??!!
    else ();
  end matchcontinue;
end addToInstCache;

protected type HashTableKeyFunctionsType = tuple<FuncHashKey,FuncKeyEqual,FuncKeyStr,FuncValueStr>;
protected type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
  Integer,
  HashTableKeyFunctionsType
>;

protected partial function FuncHashKey
  input Key cr;
  output Integer res;
end FuncHashKey;

protected partial function FuncKeyEqual
  input Key cr1;
  input Key cr2;
  output Boolean res;
end FuncKeyEqual;

protected partial function FuncKeyStr
  input Key cr;
  output String res;
end FuncKeyStr;

protected partial function FuncValueStr
  input Value exp;
  output String res;
end FuncValueStr;

protected function opaqVal
"Don't actually print what is stored in the value... It's too damn long."
  input Value v;
  output String str;
algorithm
  str := "OPAQUE_VALUE";
end opaqVal;

protected function emptyInstHashTable
  "Returns an empty HashTable."
  output HashTable hashTable;
algorithm
  hashTable := emptyInstHashTableSized(Flags.getConfigInt(Flags.INST_CACHE_SIZE));
  OperatorOverloading.initCache();
end emptyInstHashTable;

protected function emptyInstHashTableSized
  "Returns an empty HashTable, using the given bucket size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(AbsynUtil.pathHash,AbsynUtil.pathEqual,AbsynUtil.pathStringDefault,opaqVal));
end emptyInstHashTableSized;

annotation(__OpenModelica_Interface="frontend");
end InstHashTable;
