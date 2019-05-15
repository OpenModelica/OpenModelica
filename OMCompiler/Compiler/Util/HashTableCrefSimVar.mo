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

encapsulated package HashTableCrefSimVar

/* Below is the instance specific code. For each hashtable the user must define:

Key       - The key used to uniquely define elements in a hashtable
Value     - The data to associate with each key
hashFunc   - A function that maps a key to a positive integer.
keyEqual   - A comparison function between two keys, returns true if equal.
*/

/* HashTable instance specific code */

import BaseHashTable;
import DAE;
import SimCodeVar;
import Error.addInternalError;

type Key = DAE.ComponentRef;
type Value = SimCodeVar.SimVar;

protected

import ComponentReference;

public

type HashTableCrefFunctionsType = tuple<FuncHashCref,FuncCrefEqual,FuncCrefStr,FuncExpStr>;
type HashTable = tuple<
  array<list<tuple<Key,Integer>>>,
  tuple<Integer,Integer,array<Option<tuple<Key,Value>>>>,
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

function emptyHashTable
"
  Returns an empty HashTable.
  Using the default bucketsize..
"
  output HashTable hashTable;
algorithm
  hashTable := emptyHashTableSized(BaseHashTable.defaultBucketSize);
end emptyHashTable;

function emptyHashTableSized
"Returns an empty HashTable.
 Using the bucketsize size."
  input Integer size;
  output HashTable hashTable;
algorithm
  hashTable := BaseHashTable.emptyHashTableWork(size,(ComponentReference.hashComponentRefMod,ComponentReference.crefEqual,ComponentReference.printComponentRefStr,opaqueStr));
end emptyHashTableSized;

protected
function opaqueStr
  input SimCodeVar.SimVar var;
  output String str;
algorithm
  str := "#SimVar(index="+String(var.index)+",name="+ComponentReference.printComponentRefStr(var.name)+")#";
end opaqueStr;


public function addSimVarToHashTable
"adds SimVar to hash table inHT and returns extended hash table"
  input  SimCodeVar.SimVar simvarIn;
  input  HashTable inHT;
  output HashTable outHT;
algorithm
  outHT :=
  matchcontinue (simvarIn, inHT)
    local
      DAE.ComponentRef cr, acr;
      SimCodeVar.SimVar sv;

    case (sv as SimCodeVar.SIMVAR(name = cr, arrayCref = NONE()), _)
      equation
        //print("addSimVarToHashTable: handling variable '" + ComponentReference.printComponentRefStr(cr) + "'\n");
        outHT = BaseHashTable.add((cr, sv), inHT);
      then outHT;
        // add the whole array crefs to the hashtable, too
    case (sv as SimCodeVar.SIMVAR(name = cr, arrayCref = SOME(acr)), _)
      equation
        //print("addSimVarToHashTable: handling array variable '" + ComponentReference.printComponentRefStr(cr) + "'\n");
        outHT = BaseHashTable.add((acr, sv), inHT);
        outHT = BaseHashTable.add((cr, sv), outHT);
      then outHT;
    else
      equation
        Error.addInternalError("function addSimVarToHashTable failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end addSimVarToHashTable;

annotation(__OpenModelica_Interface="backend");
end HashTableCrefSimVar;
