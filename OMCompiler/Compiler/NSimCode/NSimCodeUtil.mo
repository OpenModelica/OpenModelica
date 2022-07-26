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

encapsulated package NSimCodeUtil
"file:        NSimCodeUtil.mo
 package:     NSimCodeUtil
 description: This file contains utility functions for simcode creation.
              Mainly cref to simvar mapping utilities.
"
// Frontend imports
import ComponentRef = NFComponentRef;

// SimCode imports
import NSimVar.SimVar;
import NSimVar.SimVars;

// Old SimCode imports
import HashTableCrefSimVar;

// Util imports
import List;
import UnorderedMap;

public
  function createSimCodeMap
    input SimVars simVars;
    output UnorderedMap<ComponentRef, SimVar> simcode_map = UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    addListSimCodeMap(simVars.stateVars, simcode_map);
    addListSimCodeMap(simVars.derivativeVars, simcode_map);
    addListSimCodeMap(simVars.algVars, simcode_map);
    addListSimCodeMap(simVars.discreteAlgVars, simcode_map);
    addListSimCodeMap(simVars.intAlgVars, simcode_map);
    addListSimCodeMap(simVars.boolAlgVars, simcode_map);
    addListSimCodeMap(simVars.inputVars, simcode_map);
    addListSimCodeMap(simVars.outputVars, simcode_map);
    addListSimCodeMap(simVars.aliasVars, simcode_map);
    addListSimCodeMap(simVars.intAliasVars, simcode_map);
    addListSimCodeMap(simVars.boolAliasVars, simcode_map);
    addListSimCodeMap(simVars.paramVars, simcode_map);
    addListSimCodeMap(simVars.intParamVars, simcode_map);
    addListSimCodeMap(simVars.boolParamVars, simcode_map);
    addListSimCodeMap(simVars.stringAlgVars, simcode_map);
    addListSimCodeMap(simVars.stringParamVars, simcode_map);
    addListSimCodeMap(simVars.stringAliasVars, simcode_map);
    addListSimCodeMap(simVars.extObjVars, simcode_map);
    addListSimCodeMap(simVars.constVars, simcode_map);
    addListSimCodeMap(simVars.intConstVars, simcode_map);
    addListSimCodeMap(simVars.boolConstVars, simcode_map);
    addListSimCodeMap(simVars.stringConstVars, simcode_map);
    addListSimCodeMap(simVars.residualVars, simcode_map);
    addListSimCodeMap(simVars.jacobianVars, simcode_map);
    addListSimCodeMap(simVars.seedVars, simcode_map);
    addListSimCodeMap(simVars.realOptimizeConstraintsVars, simcode_map);
    addListSimCodeMap(simVars.realOptimizeFinalConstraintsVars, simcode_map);
    addListSimCodeMap(simVars.sensitivityVars, simcode_map);
    addListSimCodeMap(simVars.dataReconSetcVars, simcode_map);
    addListSimCodeMap(simVars.dataReconinputVars, simcode_map);
  end createSimCodeMap;

  function addListSimCodeMap
    input list<SimVar> simVars;
    input output UnorderedMap<ComponentRef, SimVar> simcode_map;
  algorithm
    for var in simVars loop
      UnorderedMap.add(SimVar.getName(var), var, simcode_map);
    end for;
  end addListSimCodeMap;

  function convertSimCodeMap
    input UnorderedMap<ComponentRef, SimVar> simcode_map;
    output HashTableCrefSimVar.HashTable old_ht;
  protected
    list<SimVar> vars = UnorderedMap.valueList(simcode_map);
  algorithm
    old_ht := HashTableCrefSimVar.emptyHashTableSized(listLength(vars));
    old_ht := List.fold(SimVar.convertList(vars), HashTableCrefSimVar.addSimVarToHashTable, old_ht);
  end convertSimCodeMap;

annotation(__OpenModelica_Interface="backend");
end NSimCodeUtil;
