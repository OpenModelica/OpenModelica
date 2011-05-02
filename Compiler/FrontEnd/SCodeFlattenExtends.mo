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

encapsulated package SCodeFlattenExtends
" file:        SCodeFlattenExtends.mo
  package:     SCodeFlattenExtends
  description: Flattening of extends (and class extends) clauses by copying all components 
               from base classes in the current class, fully qualifying all paths and 
               applying the outer modifications.

  RCS: $Id$

  This module is responsible for flattening of extends (and class extends) 
  clauses by copying all components from base classes in the current class, 
  fully qualifying all paths and applying the outer modifications."

// public imports
public import SCode;
public import SCodeEnv;
public import SCodeHashTable;

protected import BaseHashTable;
protected import Debug;
protected import RTOpts;

public function flattenProgram
  "Flattens the last class in a program."
  input SCode.Program inProgram;
  input SCodeEnv.Env inEnv;
  output SCode.Program outProgram;
algorithm
  outProgram := matchcontinue(inProgram, inEnv)
    local
      SCodeHashTable.HashTable hashTable;

    case (_, _)
      equation
        false = RTOpts.debugFlag("scodeFlatten");
      then
        inProgram;

    else
      equation
        SOME(hashTable) = SCodeHashTable.hashTableFromProgram(inProgram, inEnv, NONE(), 1);
        SOME(hashTable) = handleExtends(SOME(hashTable), inEnv);
        Debug.fcall("scodeHash", BaseHashTable.dumpHashTable, hashTable);
        outProgram = SCodeHashTable.programFromHashTable(hashTable);
      then
        outProgram;

  end matchcontinue;
end flattenProgram;

protected function handleExtends
  "this will flatten extends"
  input Option<SCodeHashTable.HashTable> inOptHashTable;
  input SCodeEnv.Env inEnv;
  output Option<SCodeHashTable.HashTable> outOptHashTable;
algorithm
  outOptHashTable := matchcontinue(inOptHashTable, inEnv)
    local
      SCodeHashTable.HashTable hashTable;
      
    case (SOME(hashTable), inEnv)
      equation
        hashTable = resolveExtends(hashTable, inEnv);
        hashTable = populateModifications(hashTable, inEnv);
        hashTable = mergeExtendsElements(hashTable, inEnv);
      then 
        SOME(hashTable);
    
  end matchcontinue;
end handleExtends;

protected function resolveExtends
  "this will lookup extends classes and replace them with actual elements"
  input SCodeHashTable.HashTable inHashTable;
  input SCodeEnv.Env inEnv;
  output SCodeHashTable.HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(inHashTable, inEnv)
    local
      SCodeHashTable.HashTable hashTable;
      
    case (hashTable, inEnv)
      equation
      then 
        hashTable;
    
  end matchcontinue;
end resolveExtends;

protected function populateModifications
  "this will populate the modifications"
  input SCodeHashTable.HashTable inHashTable;
  input SCodeEnv.Env inEnv;
  output SCodeHashTable.HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(inHashTable, inEnv)
    local
      SCodeHashTable.HashTable hashTable;
      
    case (hashTable, inEnv)
      equation
      then 
        hashTable;
    
  end matchcontinue;
end populateModifications;

protected function mergeExtendsElements
  "this will merge the extends elements into the local classes"
  input SCodeHashTable.HashTable inHashTable;
  input SCodeEnv.Env inEnv;
  output SCodeHashTable.HashTable outHashTable;
algorithm
  outHashTable := matchcontinue(inHashTable, inEnv)
    local
      SCodeHashTable.HashTable hashTable;
      
    case (hashTable, inEnv)
      equation
      then 
        hashTable;
    
  end matchcontinue;
end mergeExtendsElements;

end SCodeFlattenExtends;
