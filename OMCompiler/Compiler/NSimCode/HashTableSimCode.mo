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

encapsulated package HashTableSimCode

/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTableSimCode instance specific code */

public import BaseHashTable;
import ComponentRef = NFComponentRef;
import NSimVar.SimVar;
import NSimVar.SimVars;

public type Key = ComponentRef;
public type Value = SimVar;

public type HashTableCrefFunctionsType = tuple<FuncHashCref, FuncCrefEqual, FuncCrefStr, FuncSimVarStr>;
public type HashTable = tuple<array<list<tuple<Key, Integer>>>,
                              tuple<Integer, Integer, array<Option<tuple<Key, Value>>>>,
                              Integer,
                              HashTableCrefFunctionsType>;

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

partial function FuncSimVarStr
  input Value var;
  output String res;
end FuncSimVarStr;

public
  function empty
  "
    Returns an empty HashTable.
    Using the default bucketsize, if nothing else is provided.
  "
    input Integer size = BaseHashTable.defaultBucketSize;
    output HashTable hashTable;
  algorithm
    hashTable := BaseHashTable.emptyHashTableWork(size,(ComponentRef.hash,ComponentRef.isEqual,ComponentRef.toString, function SimVar.toString(str = "")));
  end empty;

  function create
    input SimVars simVars;
    output HashTable ht = empty(intMax(SimVars.size(simVars), 1));
  algorithm
    ht := addList(simVars.stateVars, ht);
    ht := addList(simVars.derivativeVars, ht);
    ht := addList(simVars.algVars, ht);
    ht := addList(simVars.discreteAlgVars, ht);
    ht := addList(simVars.intAlgVars, ht);
    ht := addList(simVars.boolAlgVars, ht);
    ht := addList(simVars.inputVars, ht);
    ht := addList(simVars.outputVars, ht);
    ht := addList(simVars.aliasVars, ht);
    ht := addList(simVars.intAliasVars, ht);
    ht := addList(simVars.boolAliasVars, ht);
    ht := addList(simVars.paramVars, ht);
    ht := addList(simVars.intParamVars, ht);
    ht := addList(simVars.boolParamVars, ht);
    ht := addList(simVars.stringAlgVars, ht);
    ht := addList(simVars.stringParamVars, ht);
    ht := addList(simVars.stringAliasVars, ht);
    ht := addList(simVars.extObjVars, ht);
    ht := addList(simVars.constVars, ht);
    ht := addList(simVars.intConstVars, ht);
    ht := addList(simVars.boolConstVars, ht);
    ht := addList(simVars.stringConstVars, ht);
    ht := addList(simVars.jacobianVars, ht);
    ht := addList(simVars.seedVars, ht);
    ht := addList(simVars.realOptimizeConstraintsVars, ht);
    ht := addList(simVars.realOptimizeFinalConstraintsVars, ht);
    ht := addList(simVars.sensitivityVars, ht);
    ht := addList(simVars.dataReconSetcVars, ht);
    ht := addList(simVars.dataReconinputVars, ht);
  end create;

  function addList
    input list<SimVar> simVars;
    input output HashTable ht;
  algorithm
    for var in simVars loop
      ht := BaseHashTable.add((SimVar.getName(var), var), ht);
    end for;
  end addList;

annotation(__OpenModelica_Interface="backend");
end HashTableSimCode;
