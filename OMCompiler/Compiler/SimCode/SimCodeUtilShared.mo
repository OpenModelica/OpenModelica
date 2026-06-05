/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package SimCodeUtilShared "Simulation-related SimCode generator helpers shared by the old and new backends.

  This package holds the SimCode generator functions that both SimCodeUtil (old
  backend) and NSimCode (new backend) need but that are *not* bootstrap-safe: they
  pull in the full simulation datatypes (SimCode.ModelInfo) and the inliner, so they
  must stay out of SimCodeFunctionUtil. SimCodeFunctionUtil is part of the bootstrap
  set, where SimCode is only a stub and nothing simulation-related is available.

  Keeping these here lets the new backend reuse them without depending on the entire
  16k-line SimCodeUtil (interface 'backend'); this module is tagged 'simcode_util'
  like SimCodeFunctionUtil, so both backends already depend on it."

import Absyn;
import AvlTreePathFunction;
import DAE;
import HashTableCrIListArray;
import HashTableCrILst;
import HashTableExpToIndex;
import Inline;
import SimCode;
import SimCodeFunction;
import SimCodeFunctionUtil;
import SimCodeVar;
import Util;

protected

import BaseHashTable;
import ComponentReference;
import ComponentReferenceBasics;
import DAEUtil;
import Error;
import List;

public

protected function simulationFindLiterals
  "Finds all literal expressions in functionsa"
  input list<DAE.Function> fns;
  output list<DAE.Function> ofns;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
algorithm
  (ofns, literals) := DAEUtil.traverseDAEFunctions(
    fns, SimCodeFunctionUtil.findLiteralsHelper,
    (0, HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize), {}));
  // Broke things :(
  // ((i, ht, literals)) := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dae, findLiteralsHelper, (i, ht, literals));
end simulationFindLiterals;

public function createFunctions
  input Absyn.Program inProgram;
  input AvlTreePathFunction.Tree functionTree;
  output list<String> outLibs;
  output list<String> outLibPaths;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<SimCodeFunction.Function> outFunctions;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> outLiterals;
protected
  list<DAE.Function> funcelems;
  list<DAE.Exp> lits;
algorithm
  try
    // get all the used functions from the function tree
    funcelems := DAEUtil.getFunctionList(functionTree);
    funcelems := Inline.inlineCallsInFunctions(funcelems, (NONE(), {DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}));
    (funcelems, outLiterals as (_, _, lits)) := simulationFindLiterals(funcelems);
    (outFunctions, outRecordDecls, outIncludes, outIncludeDirs, outLibs, outLibPaths) := SimCodeFunctionUtil.elaborateFunctions(inProgram, funcelems, {}, lits, {}); // Do we need metarecords here as well?
  else
    Error.addInternalError("Creation of Modelica functions failed.", sourceInfo());
    fail();
  end try;
end createFunctions;

public function createVarToArrayIndexMapping
  "Creates a mapping for each array-cref to the array dimensions (int list) and to the indices (for the code generation) used to store the array content."
  input SimCode.ModelInfo iModelInfo;
  output HashTableCrIListArray.HashTable oVarToArrayIndexMapping;
  output HashTableCrILst.HashTable oVarToIndexMapping; //same as oVarToArrayIndexMapping, but does not merge array variables into one list
protected
  SimCodeVar.SimVars sim_vars;
  list<tuple<list<SimCodeVar.SimVar>, Integer>> vars;
  Integer table_size = 0;
  list<SimCodeVar.SimVar> var_lst;
  Integer var_type;
  array<Integer> currentVarIndices; //current variable index real,int,bool,string
algorithm
  // Collect the variable lists into a list for easier handling.
  sim_vars := iModelInfo.vars;
  vars := {
    (sim_vars.stateVars, 1),
    (sim_vars.derivativeVars, 1),
    (sim_vars.algVars, 1),
    (sim_vars.discreteAlgVars, 1),
    (sim_vars.intAlgVars, 2),
    (sim_vars.boolAlgVars, 3),
    (sim_vars.stringAlgVars, 4),
    (sim_vars.paramVars, 1),
    (sim_vars.intParamVars, 2),
    (sim_vars.boolParamVars, 3),
    (sim_vars.stringParamVars, 4),
    //(sim_vars.inputVars, 1),
    //(sim_vars.utputVars, 1),
    (sim_vars.constVars, 1),
    (sim_vars.intConstVars, 2),
    (sim_vars.boolConstVars, 3),
    (sim_vars.stringConstVars, 4),
    (sim_vars.realOptimizeConstraintsVars, 1),
    (sim_vars.realOptimizeFinalConstraintsVars, 1),
    (sim_vars.aliasVars, 1),
    (sim_vars.intAliasVars, 2),
    (sim_vars.boolAliasVars, 3),
    (sim_vars.stringAliasVars, 4)
  };

  // Count the number of variables to determine an appropriate size for the hash tables.
  for vl in vars loop
    (var_lst, _) := vl;
    table_size := table_size + listLength(var_lst);
  end for;
  table_size := Util.nextPrime(realInt(table_size * 1.4));

  oVarToArrayIndexMapping := HashTableCrIListArray.emptyHashTableSized(table_size);
  oVarToIndexMapping := HashTableCrILst.emptyHashTableSized(table_size);
  currentVarIndices := arrayCreate(4, 1); //0 is reserved for unused variables

  // Add the variables to the tables.
  for vl in vars loop
    (var_lst, var_type) := vl;
    (currentVarIndices, oVarToArrayIndexMapping, oVarToIndexMapping) :=
      addVarToArrayIndexMappings(var_lst, var_type, currentVarIndices, oVarToArrayIndexMapping, oVarToIndexMapping);
  end for;
end createVarToArrayIndexMapping;

public function addVarToArrayIndexMappings
  input list<SimCodeVar.SimVar> vars;
  input Integer iVarType; //1 = real ; 2 = int ; 3 = bool ; 4 = string
  input output array<Integer> currentVarIndices;
  input output HashTableCrIListArray.HashTable varToArrayIndexMapping;
  input output HashTableCrILst.HashTable varToIndexMapping;
algorithm
  for v in vars loop
    (currentVarIndices, varToArrayIndexMapping, varToIndexMapping) :=
      addVarToArrayIndexMapping(v, iVarType, currentVarIndices, varToArrayIndexMapping, varToIndexMapping);
  end for;
end addVarToArrayIndexMappings;

public function addVarToArrayIndexMapping "author: marcusw
  Adds the given variable to the array-mapping and to the var-mapping. If the variable is part of an array 'a' which is not already part of the
  given hash table, a new hash table element with size 'a.length' is allocated. The allocated arrays are row-major based."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType; //1 = real ; 2 = int ; 3 = bool ; 4 = string
  input output array<Integer> currentVarIndices;
  input output HashTableCrIListArray.HashTable varToArrayIndexMapping;
  input output HashTableCrILst.HashTable varToIndexMapping;
protected
  DAE.ComponentRef name, arrayName;
  Integer varIdx, arrayIndex;
  array<Integer> varIndices;
  list<Integer> arrayDimensions;
  list<String> numArrayElement;
  list<DAE.Subscript> arraySubscripts;
algorithm
  () := match iVar
    case SimCodeVar.SIMVAR(name=name, numArrayElement=numArrayElement)
      algorithm
        (currentVarIndices,varIdx) := getArrayIdxByVar(iVar, iVarType, varToIndexMapping, currentVarIndices);
        //print("Adding variable " + ComponentReferenceBasics.printComponentRefStr(name) + " with type " + intString(iVarType) + " to map with index " + intString(varIdx) + "\n");
        varToIndexMapping := BaseHashTable.add((name, {varIdx}), varToIndexMapping);
        arraySubscripts := ComponentReference.crefLastSubs(name);
        if listEmpty(numArrayElement) or checkIfSubscriptsContainsUnhandlableIndices(arraySubscripts) then
          arrayName := name;
        else
          arrayName := ComponentReferenceBasics.crefStripLastSubs(name);
        end if;

        if isArrayVar(iVar) then
          // store array dimensions and index of first element to indicate a contiguous array
          arrayDimensions := list(stringInt(e) for e in List.lastN(numArrayElement, listLength(numArrayElement)));
          varIndices := arrayCreate(1, varIdx);
          varToArrayIndexMapping := BaseHashTable.add((arrayName, (arrayDimensions, varIndices)), varToArrayIndexMapping);
        elseif ComponentReferenceBasics.crefEqual(arrayName, name) then
          // scalar variable
          varIndices := arrayCreate(1, varIdx);
          varToArrayIndexMapping := BaseHashTable.add((arrayName, ({1},varIndices)), varToArrayIndexMapping);
        else
          // store array dimensions and build up list of indices for elements
          if BaseHashTable.hasKey(arrayName, varToArrayIndexMapping)  then
            (arrayDimensions,varIndices) := BaseHashTable.get(arrayName, varToArrayIndexMapping);
          else
            //print("Try to calculate array dimensions out of " + intString(listLength(numArrayElement)) + " array elements " + "\n");
            arrayDimensions := list(stringInt(e) for e in List.lastN(numArrayElement, listLength(arraySubscripts)));
            //print("Allocating new array with " + intString(List.fold(arrayDimensions, intMul, 1)) + " elements.\n");
            varIndices := arrayCreate(List.fold(arrayDimensions, intMul, 1), 0);
          end if;
          //print("Num of array elements {" + stringDelimitList(List.map(arrayDimensions, intString), ",") + "} : " + intString(listLength(arraySubscripts)) + "  arraySubs "+ExpressionDump.printSubscriptLstStr(arraySubscripts) + "  arrayDimensions[ "+stringDelimitList(List.map(arrayDimensions,intString),",")+"]\n");
          arrayIndex := getScalarElementIndex(arraySubscripts, arrayDimensions);
          //print("VarIndices: " + intString(arrayLength(varIndices)) + " arrayIndex: " + intString(arrayIndex) + " varIndex: " + intString(varIdx) + "\n");
          varIndices := arrayUpdate(varIndices, arrayIndex, varIdx);
          varToArrayIndexMapping := BaseHashTable.add((arrayName, (arrayDimensions,varIndices)), varToArrayIndexMapping);
        end if;
      then
        ();

    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {"Unknown case for addVarToArrayIndexMapping.\n"});
      then
        ();
  end match;
end addVarToArrayIndexMapping;

protected function checkIfSubscriptsContainsUnhandlableIndices "author: marcusw
  Returns false if at least one subscript can not be handled as constant index."
  input list<DAE.Subscript> iSubscripts;
  output Boolean oContainsUnhandledSubscripts = false;
protected
  DAE.Subscript subscript;
algorithm
  for subscript in iSubscripts loop
    if DAEUtil.getSubscriptIndex(subscript) < 0 then
      oContainsUnhandledSubscripts := true;
      break;
    end if;
  end for;
end checkIfSubscriptsContainsUnhandlableIndices;

protected function getArrayIdxByVar "author: marcusw
  Get the storage-index of the given variable. If the variable is an alias, the storage position of the alias variable is returned.
  If the variable is a negated alias, then the negated storage position of the alias variable is returned."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType;
  input HashTableCrILst.HashTable iVarToIndexMapping;
  input output array<Integer> iCurrentVarIndices;
  output Integer oVarIndex;
protected
  DAE.ComponentRef varName, name;
  Integer varIdx;
  array<Integer> tmpCurrentVarIndices;
algorithm
  oVarIndex := match(iVar, iCurrentVarIndices)
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.NOALIAS()), tmpCurrentVarIndices)
      algorithm
        //print("getArrayIdxByVar: Handling common variable\n");
        (varIdx,tmpCurrentVarIndices) := getVarToArrayIndexByType(iVar, iVarType, tmpCurrentVarIndices);
      then varIdx;
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.NEGATEDALIAS(varName)), _)
      algorithm
        //print("getArrayIdxByVar: Handling negated alias variable pointing to " + ComponentReferenceBasics.printComponentRefStr(varName) + "\n");
        if(BaseHashTable.hasKey(varName, iVarToIndexMapping)) then
          varIdx::_ := BaseHashTable.get(varName, iVarToIndexMapping);
          varIdx := intMul(varIdx,-1);
        elseif ComponentReference.isTime(varName) then
          varIdx := 0;
        else
          Error.addMessage(Error.INTERNAL_ERROR, {"Negated alias to unknown variable given."});
          fail();
        end if;
      then varIdx;
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.ALIAS(varName)), _)
      algorithm
        //print("getArrayIdxByVar: Handling alias variable pointing to " + ComponentReferenceBasics.printComponentRefStr(varName) + "\n");
        if(BaseHashTable.hasKey(varName, iVarToIndexMapping)) then
          varIdx::_ := BaseHashTable.get(varName, iVarToIndexMapping);
        elseif ComponentReference.isTime(varName) then
          varIdx := 0;
        else
          Error.addMessage(Error.INTERNAL_ERROR, {"Alias to unknown variable given."});
          fail();
        end if;
      then varIdx;
  end match;
end getArrayIdxByVar;

protected function getVarToArrayIndexByType "author: marcusw
  Return the the current variable index of the given tuple, regarding the given type. The index-tuple is incremented and returned."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType; //1 = real ; 2 = int ; 3 = bool ; 4 = string
  output Integer oVarIdx;
  input output array<Integer> iCurrentVarIndices;
algorithm
  try
    oVarIdx := arrayGet(iCurrentVarIndices, iVarType);
    arrayUpdate(iCurrentVarIndices, iVarType, oVarIdx + getNumElems(iVar));
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"GetVarToArrayIndexByType with unknown type called."});
    oVarIdx := -1;
  end try;
end getVarToArrayIndexByType;

public function getScalarElementIndex
 "Calculate the one based memory offset for consecutive row major storage,
  author: rfranke"
  input list<DAE.Subscript> arraySubscripts;
  input list<Integer> arrayDimensions;
  output Integer arrayIndex;
protected
  Integer idx, fac;
algorithm
  arrayIndex := 1; // one based
  fac := 1;
  for i in listLength(arraySubscripts):-1:1 loop
    idx := DAEUtil.getSubscriptIndex(listGet(arraySubscripts, i));
    arrayIndex := arrayIndex + (idx - 1) * fac;
    fac := fac * listGet(arrayDimensions, i);
  end for;
end getScalarElementIndex;

public function getNumElems
  "Get number of scalar elements of a variable, rolling out arrays.
   author: rfranke"
  input SimCodeVar.SimVar var;
  output Integer numElems;
algorithm
  numElems := match var
    case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY()) algorithm
      numElems := 1;
      for d in var.numArrayElement loop
        numElems := numElems * stringInt(d);
      end for;
      then numElems;
    else 1;
  end match;
end getNumElems;

function isArrayVar
  input SimCodeVar.SimVar var;
  output Boolean isArray;
algorithm
  isArray := match var
    case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY()) then true;
    else false;
  end match;
end isArrayVar;

annotation(__OpenModelica_Interface="simcode_util");
end SimCodeUtilShared;
