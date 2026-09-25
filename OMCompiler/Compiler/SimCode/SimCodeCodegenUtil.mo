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

encapsulated package SimCodeCodegenUtil
"SimCode queries the code generators need: the variable, value-reference and
  equation lookups they call while emitting code."

import Absyn;
import BackendDAE;
import DAE;
import DoubleEnded;
import ExpressionBasics;
import HashTable;
import HashTableCrIListArray;
import HashTableCrILst;
import SimCode;
import SimCodeFunction;
import SimCodeVar;
import Types;
import Util;

protected
import AbsynUtil;
import Array;
import AvlTreeCRToInt;
import BaseHashTable;
import ClassInf;
import ComponentReference;
import ComponentReferenceBasics;
import Config;
import DAEDump;
import MetaModelica.Dangerous;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import Global;
import HashTableCrefSimVar;
import List;
import SimCodeFunctionUtil;
import SimCodeUtilShared;
import StringUtil;
import System;
import UnitAbsyn;
import UnitAbsynBuilder;
import UnitParserExt;
import UnorderedMap;

public

protected function compareEqSystems
  input SimCode.SimEqSystem eq1;
  input SimCode.SimEqSystem eq2;
  output Boolean b;
algorithm
  b := simEqSystemIndex(eq1) > simEqSystemIndex(eq2);
end compareEqSystems;

public function sortEqSystems
  input list<SimCode.SimEqSystem> eqs;
  output list<SimCode.SimEqSystem> outEqs;
algorithm
  outEqs := List.flatten(list(expandEntwined(eq) for eq in eqs));
  outEqs := List.sort(outEqs, compareEqSystems);
end sortEqSystems;

protected function expandEntwined
  "expands entwined equations to their body equation systems
  used for serializing"
  input SimCode.SimEqSystem eq;
  output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := match eq
    case SimCode.SES_ENTWINED_ASSIGN() then eq :: eq.single_calls;
    else {eq};
  end match;
end expandEntwined;

public function getClockIndex "author: rfranke
  Returns the index of the clock of a variable or zero non-clocked variables"
  input SimCodeVar.SimVar simVar;
  input SimCode.SimCode simCode;
  output Option<Integer> clockIndex;
protected
  DAE.ComponentRef cref;
  HashTable.HashTable clkHT;
algorithm
  cref := getSimVarCompRef(simVar);
  clockIndex := match simCode
    case SimCode.SIMCODE(crefToClockIndexHT=clkHT) then
      if BaseHashTable.hasKey(cref, clkHT)
      then SOME(BaseHashTable.get(cref, clkHT))
      else NONE();
  end match;
end getClockIndex;

public function getSimVarCompRef
  input SimCodeVar.SimVar inVar;
  output DAE.ComponentRef outComp;
algorithm
  outComp := inVar.name;
end getSimVarCompRef;

public function getSubPartitions
  input list<SimCode.ClockedPartition> inPartitions;
  output list<SimCode.SubPartition> outSubPartitions;
algorithm
  outSubPartitions := List.flatten(List.map(inPartitions, getSubPartition));
end getSubPartitions;

public function getSubPartition
  input SimCode.ClockedPartition inPartition;
  output list<SimCode.SubPartition> outSubPartitions;
algorithm
  outSubPartitions := inPartition.subPartitions;
end getSubPartition;

public function getClockedEquations
  input list<SimCode.SubPartition> inSubPartitions;
  output list<SimCode.SimEqSystem> outEqs = {};
algorithm
  for part in inSubPartitions loop
    outEqs := listAppend(part.equations, outEqs);
    outEqs := listAppend(part.removedEquations, outEqs);
  end for;
end getClockedEquations;

public function jacobianColumnsAreEmpty
  input list<SimCode.JacobianColumn> columns;
  output Boolean b = true;
algorithm
  for col in columns loop
    if not (listEmpty(col.columnEqns) and listEmpty(col.constantEqns)) then
      b := false;
      return;
    end if;
  end for;
end jacobianColumnsAreEmpty;

public function stripAsubIfNoIter
  "Strips a RELATION's optionExpisASUB (see the comment on DAE.RELATION, and
  NBEvents.mo's asubTuple) whenever the caller has no regenerated for-loop of its
  own around this expression (hasIter = false). optionExpisASUB names the iterator
  cref a state-event condition was originally wrapped in, so CodegenCFunctions.tpl's
  zero-crossing template can offset storedRelations[] per iteration -- but that only
  compiles when the SAME for-loop is regenerated at the call site, giving the
  iterator an actual in-scope C variable. When the caller has already fully unrolled
  this expression into an independent scalar occurrence (hasIter = false), the
  RELATION's own index is already correct standalone, and the stored iterator cref
  has no corresponding loop variable to reference: codegen falls back to emitting
  its bare (often source-level, e.g. \"i\") name, which doesn't compile (see
  PNlib.Test2.mos and the other tests this fixes in CodegenC.tpl's zeroCrossingTpl/
  relationTpl, the only current callers)."
  input DAE.Exp exp;
  input Boolean hasIter;
  output DAE.Exp outExp;
algorithm
  outExp := if hasIter then exp else match exp
    case DAE.RELATION(optionExpisASUB = SOME(_))
      then DAE.RELATION(exp.exp1, exp.operator, exp.exp2, exp.index, NONE());
    case DAE.LBINARY()
      then DAE.LBINARY(stripAsubIfNoIter(exp.exp1, hasIter), exp.operator, stripAsubIfNoIter(exp.exp2, hasIter));
    case DAE.LUNARY()
      then DAE.LUNARY(exp.operator, stripAsubIfNoIter(exp.exp, hasIter));
    else exp;
  end match;
end stripAsubIfNoIter;

public function dimsToAllIndexes
  input DAE.Dimensions inDims;
  output list<list<Integer>> outIndexes;
protected
  list<Integer> ilst;
  list<list<Integer>> lstlst;
algorithm
  ilst := Expression.dimensionsSizes(inDims);
  lstlst := List.map(ilst, List.intRange);
  outIndexes := dimsToAllIndexes1(lstlst);
end dimsToAllIndexes;

protected function dimsToAllIndexes1
  input list<list<Integer>> inDims;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := match inDims
    local
      list<Integer> dims;
      list<list<Integer>> rest, indxes;
    case dims::{}
      algorithm
        indxes := List.map(dims, List.create);
      then
        indxes;
    case dims::rest
      algorithm
        indxes := dimsToAllIndexes1(rest);
        // cons for each element in dims
        indxes := List.fold1(dims, dimsToAllIndexes2, indxes, {});
      then
        indxes;
  end match;
end dimsToAllIndexes1;

protected function dimsToAllIndexes2
  input Integer i;
  input list<list<Integer>> iIndex;
  input list<list<Integer>> iAllIndex;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := List.map1(iIndex, List.consr, i);
  oAllIndex := listAppend(iAllIndex, oAllIndex);
end dimsToAllIndexes2;

public function getDefaultFmiInitialAttribute
 "Get the defualt fmi 2.0 initial attribute."
  input SimCodeVar.Variability variability;
  input SimCodeVar.Causality causality;
  output SimCodeVar.Initial initial_;
algorithm
  initial_ := match(variability, causality)
    // CONSTANT
    case (SimCodeVar.CONSTANT(), SimCodeVar.OUTPUT()) then SimCodeVar.EXACT();
    case (SimCodeVar.CONSTANT(), SimCodeVar.LOCAL()) then SimCodeVar.EXACT();

    // FIXED
    case (SimCodeVar.FIXED(), SimCodeVar.PARAMETER()) then SimCodeVar.EXACT();
    case (SimCodeVar.FIXED(), SimCodeVar.CALCULATED_PARAMETER()) then SimCodeVar.CALCULATED();
    case (SimCodeVar.FIXED(), SimCodeVar.LOCAL()) then SimCodeVar.CALCULATED();

    // TUNABLE
    case (SimCodeVar.TUNABLE(), SimCodeVar.PARAMETER()) then SimCodeVar.EXACT();
    case (SimCodeVar.TUNABLE(), SimCodeVar.CALCULATED_PARAMETER()) then SimCodeVar.CALCULATED();
    case (SimCodeVar.TUNABLE(), SimCodeVar.LOCAL()) then SimCodeVar.CALCULATED();

    // DISCRETE
    case (SimCodeVar.DISCRETE(), SimCodeVar.OUTPUT()) then SimCodeVar.CALCULATED();
    case (SimCodeVar.DISCRETE(), SimCodeVar.LOCAL()) then SimCodeVar.CALCULATED();

    // CONTINUOUS
    case (SimCodeVar.CONTINUOUS(), SimCodeVar.OUTPUT()) then SimCodeVar.CALCULATED();
    case (SimCodeVar.CONTINUOUS(), SimCodeVar.LOCAL()) then SimCodeVar.CALCULATED();

    else SimCodeVar.NONE_INITIAL();
  end match;
end getDefaultFmiInitialAttribute;

public function getFmiInitialAttributeStr
  "This function is called from CodegenFMUCommon.tpl. It compares a variable's initial_ fmi attriute
  with the default expected (based on teh variability and causality of the variable). If it turns out
  to be the same as the default then it will return an empty string so that the value is not
  printed to the modelDescription.xml file. However, if the flag DUMP_FORCE_FMI_ATTRIBUTES is set,
  it will always print the attrbute whether it is equal to the defaul or not."
  input SimCodeVar.SimVar simVar;
  output String out_string = "";
protected
  SimCodeVar.Initial var_initial, default_initial;
algorithm
  if isNone(simVar.initial_) then
    return;
  end if;

  SOME(var_initial) := simVar.initial_;
  default_initial := getDefaultFmiInitialAttribute(Util.getOptionOrDefault(simVar.variability, SimCodeVar.CONTINUOUS())
                                                  , Util.getOptionOrDefault(simVar.causality, SimCodeVar.LOCAL()));

  if valueEq(var_initial, default_initial) and not Flags.isSet(Flags.DUMP_FORCE_FMI_ATTRIBUTES) then
    var_initial := SimCodeVar.NONE_INITIAL(); // Set it to NONE_INITIAL here so the case below turns it to ""
  end if;

  out_string := match var_initial
    case SimCodeVar.EXACT(__) then "exact";
    case SimCodeVar.APPROX(__) then "approx";
    case SimCodeVar.CALCULATED(__) then "calculated";
    case SimCodeVar.NONE_INITIAL(__) then "";
  end match;
end getFmiInitialAttributeStr;

public function simGenericCallString
  input SimCode.SimGenericCall call;
  output String str;
algorithm
  str := match call
    case SimCode.SINGLE_GENERIC_CALL() algorithm
      str := "single generic call " + intString(call.index) + " " + List.toString(call.iters, simIteratorString);
      str := str + "\n  " + ExpressionBasics.printExpStr(call.lhs) + " = " + ExpressionBasics.printExpStr(call.rhs) + ";";
    then str;

    case SimCode.IF_GENERIC_CALL() algorithm
      str := "if generic call " + intString(call.index) + " " + List.toString(call.iters, simIteratorString);
      str := str + List.toString(call.branches, simBranchString, List.Style.NEWLINE);
    then str;

    case SimCode.WHEN_GENERIC_CALL() algorithm
      str := "when generic call " + intString(call.index) + " " + List.toString(call.iters, simIteratorString);
      str := str + List.toString(call.branches, simBranchString, List.Style.NEWLINE);
    then str;

    else "";
  end match;
end simGenericCallString;

public function simBranchString
  input SimCode.SimBranch branch;
  output String str;
protected
  function simBranchBodyString
    input tuple<DAE.Exp, DAE.Exp> tpl;
    output String str = ExpressionBasics.printExpStr(Util.tuple21(tpl)) + " = " + ExpressionBasics.printExpStr(Util.tuple22(tpl)) + ";";
  end simBranchBodyString;
algorithm
  str := match branch
    local
      Boolean b;

    case SimCode.SIM_BRANCH() algorithm
      b := isSome(branch.condition);
      str := if b then "if " + ExpressionBasics.printExpStr(Util.getOption(branch.condition)) + " then\n" else "else\n";
      str := str + List.toString(branch.body, simBranchBodyString, List.Style.NEWLINE_INDENT);
      str := if b then str + "end if;" else str;
    then str;

    case SimCode.SIM_BRANCH_STMT() algorithm
      b := isSome(branch.condition);
      str := if b then "if " + ExpressionBasics.printExpStr(Util.getOption(branch.condition)) + " then\n" else "else\n";
      str := str + List.toString(branch.body, DAEDump.ppStatementStr, List.Style.NEWLINE_INDENT);
      str := if b then str + "\nend if;" else str;
    then str;

    else "";
  end match;
end simBranchString;

public function simVarString
  "returns the string representation of a SimVar in the following form
  index: <index>: <name> (alias <aliasvar>) [ protected ][ hideResult ] initial: <initialValue>\tarrCref:<arrayCref> index:(<variable_index>) [<numArrayElement>]"
  input SimCodeVar.SimVar inVar;
  output String s;
algorithm
  s := "index:" + intString(inVar.index) + ": " + ComponentReferenceBasics.printComponentRefStr(inVar.name);
  s := s + (match inVar.aliasvar
    local DAE.ComponentRef cr;
    case SimCodeVar.NOALIAS() then " (no alias) ";
    case SimCodeVar.ALIAS(varName = cr) then " (alias: " + ComponentReferenceBasics.printComponentRefStr(cr) + ") ";
    case SimCodeVar.NEGATEDALIAS(varName = cr) then " (negated alias: " + ComponentReferenceBasics.printComponentRefStr(cr) + ") ";
  end match);
  s := s + (if inVar.isProtected then " protected " else "");
  s := s + (if Util.getOptionOrDefault(inVar.hideResult, false) then " hideResult " else "");
  s := s + " initial: " + (if isSome(inVar.initialValue) then ExpressionDump.printOptExpStr(inVar.initialValue) else "");
  s := s + (if isSome(inVar.arrayCref) then "\tarrCref:" + ComponentReferenceBasics.printComponentRefStr(Util.getOption(inVar.arrayCref)) else "\tno arrCref");
  s := s + " index:(" + (if isSome(inVar.variable_index) then intString(Util.getOption(inVar.variable_index)) else "") + ")";
  s := s + " [" + stringDelimitList(inVar.numArrayElement, ",") + "]";
end simVarString;

public function setVariableIndexHelper
  input list<SimCodeVar.SimVar> inVars;
  input Integer inIndex;
  input Integer inFMIIndex;
  output list<SimCodeVar.SimVar> outVars;
  output Integer outIndex;
  output Integer outFMIIndex;
algorithm
  (outVars, (outIndex, outFMIIndex)) := List.mapFold(inVars, setVariableIndexHelper2, (inIndex, inFMIIndex));
end setVariableIndexHelper;

protected function setVariableIndexHelper2
  input output SimCodeVar.SimVar var;
  input output tuple<Integer, Integer> tpl;
protected
  Integer index, fmi_index;
algorithm
  (index, fmi_index) := tpl;

  var.variable_index := SOME(index);
  index := index + SimCodeUtilShared.getNumElems(var);

  if isSome(var.exportVar) then
    var.fmi_index := SOME(fmi_index);
    fmi_index := fmi_index + SimCodeUtilShared.getNumElems(var);
  else
    var.fmi_index := NONE();
  end if;

  tpl := (index, fmi_index);
end setVariableIndexHelper2;

public function unitConversion
  "CevalScriptBackend's convertUnits: value_to = factor*value_from + offset, and
   false where the two are of different dimensions."
  input String to;
  input String from;
  output Boolean converts = false;
  output Real factor = 1.0;
  output Real offset = 0.0;
protected
  UnitAbsyn.Unit u1, u2;
  Real factor1, factor2, offset1, offset2;
algorithm
  try
    UnitParserExt.initSIUnits();
    (u1, factor1, offset1) := UnitAbsynBuilder.str2unitWithScaleFactor(to, NONE());
    (u2, factor2, offset2) := UnitAbsynBuilder.str2unitWithScaleFactor(from, NONE());
    true := valueEq(u1, u2);
    factor := factor2/factor1;
    offset := (offset2 - offset1)/factor1;
    converts := true;
  else
  end try;
end unitConversion;

public function createCrefToSimVarHT "author: unknown and marcusw
 Create a hash table that maps all variable names (crefs) to the simVar objects."
  input SimCode.ModelInfo modelInfo;
  output SimCode.HashTableCrefToSimVar outHT;
protected
  Integer size;
  SimCode.VarInfo varInfo;
  HashTableCrILst.HashTable arraySimVars;
  SimCodeVar.SimVars vars;
algorithm
  try
    varInfo := modelInfo.varInfo;
    vars := modelInfo.vars;
    size := varInfo.numStateVars + varInfo.numAlgVars + varInfo.numIntAlgVars + varInfo.numBoolAlgVars + varInfo.numAlgAliasVars +
            varInfo.numIntAliasVars + varInfo.numBoolAliasVars + varInfo.numParams + varInfo.numIntParams + varInfo.numBoolParams +
            varInfo.numOutVars + varInfo.numInVars + varInfo.numOptimizeConstraints + varInfo.numOptimizeFinalConstraints;
    size := intMax(size, 1023);
    outHT := HashTableCrefSimVar.emptyHashTableSized(size);
    arraySimVars := HashTableCrILst.emptyHashTableSized(size);

    outHT := List.fold(vars.stateVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    //true := intLt(size, -1);
    outHT := List.fold(vars.derivativeVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.algVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.algVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.discreteAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.intAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.paramVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.paramVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.intParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.aliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.aliasVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.intAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.extObjVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.constVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.intConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.sensitivityVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.jacobianVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.seedVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.realOptimizeConstraintsVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.realOptimizeFinalConstraintsVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
  else
    Error.addInternalError("function createCrefToSimVarHT failed", sourceInfo());
    fail();
  end try;
end createCrefToSimVarHT;

protected function getArraySimVars "author: marcusw
  store the array-cref of the variable in the hash table and add the variable-index as value. The variable is handled as array-variable,
  if it has more than one element as numArrayElement."
  input SimCodeVar.SimVar iSimVar;
  input HashTableCrILst.HashTable iArrayMapping;
  output HashTableCrILst.HashTable oArrayMapping;
protected
  DAE.ComponentRef name;
  DAE.ComponentRef arrayCref;
  HashTableCrILst.HashTable tmpArrayMapping = iArrayMapping;
  list<Integer> arrayVars;
  Integer index;
algorithm
  oArrayMapping := match iSimVar
    case SimCodeVar.SIMVAR(name=name, index=index, numArrayElement=_::_)
      algorithm
        arrayCref := ComponentReferenceBasics.crefStripLastSubs(name);
        if(BaseHashTable.hasKey(arrayCref, iArrayMapping)) then
          arrayVars := BaseHashTable.get(arrayCref, iArrayMapping);
          tmpArrayMapping := BaseHashTable.add((arrayCref, index::arrayVars), tmpArrayMapping);
        else
          tmpArrayMapping := BaseHashTable.add((arrayCref, {index}), tmpArrayMapping);
        end if;
        //print("markSimVarArrays: " + ComponentReferenceBasics.printComponentRefStr(name) + " for " + ComponentReferenceBasics.printComponentRefStr(ComponentReferenceBasics.crefStripLastSubs(name)) + "\n");
      then tmpArrayMapping;
    else
      then iArrayMapping;
  end match;
end getArraySimVars;

public function functionInfo
  input SimCodeFunction.Function fn;
  output SourceInfo info;
algorithm
  info := match fn
    case SimCodeFunction.FUNCTION(info = info) then info;
    case SimCodeFunction.EXTERNAL_FUNCTION(info = info) then info;
    case SimCodeFunction.RECORD_CONSTRUCTOR(info = info) then info;
  end match;
end functionInfo;

public function eqInfo
  input SimCode.SimEqSystem eq;
  output SourceInfo info;
algorithm
  info := match eq
    case SimCode.SES_RESIDUAL(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_FOR_RESIDUAL(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_GENERIC_RESIDUAL(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_SIMPLE_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_ARRAY_CALL_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_RESIZABLE_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_GENERIC_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_ENTWINED_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_WHEN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_FOR_LOOP(source=DAE.SOURCE(info=info)) then info;
  end match;
end eqInfo;

public function simEqSystemIndex
  input SimCode.SimEqSystem eq;
  output Integer index;
algorithm
  index := match eq
    case SimCode.SES_RESIDUAL(index=index) then index;
    case SimCode.SES_FOR_RESIDUAL(index=index) then index;
    case SimCode.SES_GENERIC_RESIDUAL(index=index) then index;
    case SimCode.SES_SIMPLE_ASSIGN(index=index) then index;
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index=index) then index;
    case SimCode.SES_ARRAY_CALL_ASSIGN(index=index) then index;
    case SimCode.SES_RESIZABLE_ASSIGN(index=index) then index;
    case SimCode.SES_GENERIC_ASSIGN(index=index) then index;
    case SimCode.SES_ENTWINED_ASSIGN(index=index) then index;
    case SimCode.SES_IFEQUATION(index=index) then index;
    case SimCode.SES_ALGORITHM(index=index) then index;
    case SimCode.SES_INVERSE_ALGORITHM(index=index) then index;
    case SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index)) then index;
    case SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index)) then index;
    case SimCode.SES_MIXED(index=index) then index;
    case SimCode.SES_WHEN(index=index) then index;
    case SimCode.SES_FOR_LOOP(index=index) then index;
    case SimCode.SES_ALIAS(index=index) then index;
    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCodeUtil.simEqSystemIndex failed"});
      then fail();
  end match;
end simEqSystemIndex;

public function countDynamicExternalFunctions
  input list<SimCodeFunction.Function> inFncLst;
  output Integer outDynLoadFuncs;
algorithm
  outDynLoadFuncs:= match inFncLst
  local
     list<SimCodeFunction.Function> rest;
     Integer i;
  case {}
     then
       0;
  case SimCodeFunction.EXTERNAL_FUNCTION(dynamicLoad=true)::rest
     algorithm
      i := countDynamicExternalFunctions(rest);
    then
      intAdd(i, 1);
  case _::rest
    algorithm
      i := countDynamicExternalFunctions(rest);
    then
      i;
end match;
end countDynamicExternalFunctions;

public function getVarIndexListByMapping "author: marcusw
  Return the variable indices stored for the given variable in the mapping-table. If the variable is part of an array, all array indices are returned. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor;
  input String iIndexForUndefinedReferences;
  output list<String> oVarIndexList; //if the variable is part of an array, all array indices are returned in this list (the list contains one element if the variable is a scalar)
algorithm
  (oVarIndexList,_) := getVarIndexInfosByMapping(iVarToArrayIndexMapping, iVarName, iColumnMajor, iIndexForUndefinedReferences);
end getVarIndexListByMapping;

public function getVarIndexHeadByMapping "author: phannebohm
  Return the head of variable indices stored for the given variable in the mapping-table, similar to getVarIndexListByMapping. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor;
  input String iIndexForUndefinedReferences;
  output String oVarIndex;
protected
  list<String> varIndexList;
algorithm
  // TODO make this more efficient by not generating the whole varIndexList
  (varIndexList,_) := getVarIndexInfosByMapping(iVarToArrayIndexMapping, iVarName, iColumnMajor, iIndexForUndefinedReferences);
  oVarIndex := listHead(varIndexList);
end getVarIndexHeadByMapping;

public function getVarIndexByMapping "author: marcusw
  Return the variable index stored for the given variable in the mapping-table. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor;
  input String iIndexForUndefinedReferences;
  output String oConcreteVarIndex; //the scalar index of the variable (this value is always part of oVarIndexList)
algorithm
  (_,oConcreteVarIndex) := getVarIndexInfosByMapping(iVarToArrayIndexMapping, iVarName, iColumnMajor, iIndexForUndefinedReferences);
end getVarIndexByMapping;

public function providesDirectionalDerivative
  input SimCode.SimCode inSimCode;
  output Boolean b;
algorithm
  b := match inSimCode
    case SimCode.SIMCODE(modelStructure=SOME(SimCode.FMIMODELSTRUCTURE(continuousPartialDerivatives=SOME(_))))
    then true;
    else false;
  end match;
end providesDirectionalDerivative;

protected function getVarIndexInfosByMapping "author: marcusw
  Return the variable indices stored for the given variable in the mapping-table. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor; //true if the subscripts should be evaluated in column major
  input String iIndexForUndefinedReferences;
  output list<String> oVarIndexList; //if the variable is part of an array, all array indices are returned in this list (the list contains one element if the variable is a scalar)
  output String oConcreteVarIndex = ""; //the scalar index of the variable (this value is always part of oVarIndexList)
protected
  DAE.ComponentRef varName = iVarName;
  Integer arrayIdx, idx, arraySize, concreteVarIndex;
  array<Integer> varIndices;
  list<String> tmpVarIndexListNew = {};
  list<DAE.Subscript> arraySubscripts;
  list<Integer> arrayDimensions, arrayDimensionsReverse = {};
  Boolean toColumnMajor;
  Boolean isContiguous;
algorithm
  arraySubscripts := ComponentReference.crefLastSubs(varName);
  varName := ComponentReferenceBasics.crefStripLastSubs(varName);//removeSubscripts(varName);
  if(BaseHashTable.hasKey(varName, iVarToArrayIndexMapping)) then
    (arrayDimensions,varIndices) := BaseHashTable.get(varName, iVarToArrayIndexMapping); //varIndices are rowMajorOrder!
    isContiguous := arrayLength(varIndices) == 1;
    if isContiguous then
      arraySize := List.fold(arrayDimensions, intMul, 1);
    else
      arraySize := arrayLength(varIndices);
    end if;
    concreteVarIndex := SimCodeUtilShared.getScalarElementIndex(arraySubscripts, arrayDimensions);
    toColumnMajor := iColumnMajor and listLength(arrayDimensions) > 1;
    if toColumnMajor then
      concreteVarIndex := convertIndexToColumnMajor(concreteVarIndex, arrayDimensions);
      arrayDimensionsReverse := listReverse(arrayDimensions);
    end if;
    //print("SimCodeUtil.getVarIndexInfosByMapping: Found variable index for '" + ComponentReferenceBasics.printComponentRefStr(iVarName) + "'. The value is " + intString(concreteVarIndex) + "\n");
    for arrayIdx in 0:(arraySize-1) loop
      idx := arraySize-arrayIdx;
      if toColumnMajor then
        // convert to row major so that column major access will give this idx
        idx := convertIndexToColumnMajor(idx, arrayDimensionsReverse);
      end if;
      if isContiguous then
        idx := arrayGet(varIndices, 1) + idx - 1;
      else
        idx := arrayGet(varIndices, idx);
      end if;
      if(intLt(idx, 0)) then
        tmpVarIndexListNew := intString((intMul(idx, -1) - 1))::tmpVarIndexListNew;
        //print("SimCodeUtil.tmpVarIndexListNew: Warning, negativ aliases (" + ComponentReferenceBasics.printComponentRefStr(iVarName) + ") are not supported at the moment!\n");
      else
        if(intEq(idx, 0)) then
          tmpVarIndexListNew := iIndexForUndefinedReferences::tmpVarIndexListNew;
        else
          tmpVarIndexListNew := intString(idx - 1)::tmpVarIndexListNew;
        end if;
      end if;
    end for;
    if isVarIndexListConsecutive(iVarToArrayIndexMapping,iVarName) and toColumnMajor then
      //if the array is not completely stuffed (e.g. some array variables have been derived and became dummy-derivatives), the array will not be initialized as a consecutive array, therefore we cannot take the colMajor-indexes
      // otherwise convert to column major for consecutive array
      concreteVarIndex := convertIndexToColumnMajor(concreteVarIndex, arrayDimensions);
    end if;
    oConcreteVarIndex := listGet(tmpVarIndexListNew, concreteVarIndex);
  end if;
  if(listEmpty(tmpVarIndexListNew)) then
    Error.addMessage(Error.INTERNAL_ERROR, {"GetVarIndexListByMapping: No Element for " + ComponentReferenceBasics.printComponentRefStr(varName) + " found!"});
    tmpVarIndexListNew := {iIndexForUndefinedReferences};
    oConcreteVarIndex := iIndexForUndefinedReferences;
  end if;
  //print("SimCodeUtil.getVarIndexInfosByMapping: Variable " + ComponentReferenceBasics.printComponentRefStr(iVarName) + " has variable indices {" + stringDelimitList(tmpVarIndexListNew, ",") + "} and concrete index " + oConcreteVarIndex + "\n");
  oVarIndexList := tmpVarIndexListNew;
end getVarIndexInfosByMapping;

public function convertIndexToColumnMajor
 "Converts row-major unrolled idx to column-major, author: rfranke"
  input Integer idx; // one based, row-major ordered
  input list<Integer> arrayDimensions;
  output Integer idxOut; // one based, column-major ordered
protected
  Integer idx0, ndim, length, idxi, fac;
algorithm
  ndim := listLength(arrayDimensions);
  length := List.fold(arrayDimensions, intMul, 1);
  idx0 := idx - 1; // zero based
  idxOut := 1; // one based
  fac := 1;
  for dimi in arrayDimensions loop
    length := intDiv(length, dimi);
    idxi := intDiv(idx0, length);
    idx0 := idx0 - idxi*length;
    idxOut := idxOut + idxi*fac;
    fac := fac * dimi;
  end for;
end convertIndexToColumnMajor;

public function isVarIndexListConsecutive "author: marcusw
  Check if all variable indices of the given variables, stored in the hash table, are consecutive."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  output Boolean oIsConsecutive;
protected
  DAE.ComponentRef varName = iVarName;
  Integer arrayIdx, idx, arraySize;
  Integer currentIndex = -1;
  array<Integer> varIndices;
  Boolean consecutive = true;
algorithm
  varName := ComponentReferenceBasics.crefStripLastSubs(varName);//removeSubscripts(varName);
  if(BaseHashTable.hasKey(varName, iVarToArrayIndexMapping)) then
    (_,varIndices) := BaseHashTable.get(varName, iVarToArrayIndexMapping);
    arraySize := arrayLength(varIndices);
    for arrayIdx in 0:(arraySize-1) loop
      idx := arrayGet(varIndices, arraySize-arrayIdx);
      if(intLt(idx, 0)) then
        if(intEq(currentIndex, -1)) then
          currentIndex := intMul(idx, -1) - 1;
        else
          consecutive := boolAnd(consecutive, intEq(currentIndex, intMul(idx, -1)));
          currentIndex := intMul(idx, -1) - 1;
        end if;
        //print("SimCodeUtil.isVarIndexListConsecutive: Warning, negativ aliases (" + ComponentReferenceBasics.printComponentRefStr(iVarName) + ") are not supported at the moment!\n");
      else
        if(intEq(idx, 0)) then
          currentIndex := -2;
          consecutive := false;
        else
          if(intEq(currentIndex, -1)) then
            currentIndex := idx - 1;
          else
            //print("SimCodeUtil.isVarIndexListConsecutive: Checking if " + intString(currentIndex) + " is consecutive with " + intString(idx) + "\n");
            consecutive := boolAnd(consecutive, intEq(currentIndex, idx));
            //print("SimCodeUtil.isVarIndexListConsecutive: " + boolString(consecutive) + "\n");
            currentIndex := idx - 1;
          end if;
        end if;
      end if;
    end for;
  end if;
  oIsConsecutive := consecutive;
end isVarIndexListConsecutive;

public function getEnumerationTypes
  input SimCodeVar.SimVars inVars;
  output list<SimCodeVar.SimVar> outVars;
algorithm
  outVars := match inVars
    case SimCodeVar.SIMVARS()
      algorithm
        outVars := getEnumerationTypesHelper(inVars.stateVars, {});
        outVars := getEnumerationTypesHelper(inVars.derivativeVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.algVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.discreteAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.inputVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.outputVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.aliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.paramVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.extObjVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.constVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.sensitivityVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.jacobianVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.seedVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.realOptimizeConstraintsVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.realOptimizeFinalConstraintsVars, outVars);
      then
        listReverse(outVars); // TODO: Is the order actually important?

    else {};
  end match;
end getEnumerationTypes;

protected function getEnumerationTypesHelper
  input list<SimCodeVar.SimVar> inVars;
  input list<SimCodeVar.SimVar> inAccumVars;
  output list<SimCodeVar.SimVar> outVars = inAccumVars;
algorithm
  for var in inVars loop
    () := match var
      case SimCodeVar.SIMVAR()
        algorithm
          // Add the variable to the list if it's an enumeration variable which
          // doesn't already exist in the list.
          if Types.isEnumeration(var.type_) and not
             List.exist1(outVars, enumerationTypeExists, var.type_) then
            outVars := var :: outVars;
          end if;
        then
          ();

      else ();
    end match;
  end for;
end getEnumerationTypesHelper;

protected function enumerationTypeExists
  input SimCodeVar.SimVar var;
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match (var, inType)
    local
      DAE.Type ty;

    case (SimCodeVar.SIMVAR(type_ = ty as DAE.T_ENUMERATION()), DAE.T_ENUMERATION())
      then AbsynUtil.pathEqual(ty.path, inType.path);
    else false;
  end match;
end enumerationTypeExists;

public function getSimEqSysForIndex
  input Integer idx;
  input list<SimCode.SimEqSystem> allSimEqs;
  output SimCode.SimEqSystem outSimEq;
algorithm
  try
    outSimEq := List.getMemberOnTrue(idx,allSimEqs,indexIsEqual);
  else
    print("getSimEqSysForIndex failed!\n");
    fail();
  end try;
end getSimEqSysForIndex;

public function indexIsEqual
  input Integer idx;
  input SimCode.SimEqSystem ses;
  output Boolean b;
protected
  Integer idx2;
algorithm
  idx2 := simEqSystemIndex(ses);
  b := intEq(idx,idx2);
end indexIsEqual;

public function getSimEqSystemCrefsLHS "gets the crefs of the vars that are assigned (the lhs) for a simEqSystem
author:Waurich TUD 2014-05"
  input SimCode.SimEqSystem simEqSys;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := match simEqSys
    local
      DAE.Exp lhs;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs, crefs2;
      list<SimCodeVar.SimVar> simVars;
      list<SimCode.SimEqSystem> residual;
    case SimCode.SES_RESIDUAL()
      algorithm
        print("implement SES_RESIDUAL in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
      then {};
    case SimCode.SES_SIMPLE_ASSIGN(cref=cref)
      then {cref};
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(cref=cref)
      then {cref};
    case SimCode.SES_ARRAY_CALL_ASSIGN(lhs=lhs)
      then {Expression.expCref(lhs)};
    case SimCode.SES_IFEQUATION()
      algorithm
        print("implement SES_IFEQUATION in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
      then {};
    case SimCode.SES_ALGORITHM() algorithm
      print("implement SES_ALGORITHM in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
    then {};
    case SimCode.SES_INVERSE_ALGORITHM() algorithm
      print("implement SES_INVERSE_ALGORITHM in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
    then {};
    case SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(vars=simVars,residual=residual))
      algorithm
        crefs2 := list(v.name for v in simVars);
      then listAppend(crefs2,crefs2);
    case SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(crefs=crefs))
      then crefs;
    case SimCode.SES_MIXED(discVars=simVars)
      then list(v.name for v in simVars);
    case SimCode.SES_WHEN(whenStmtLst={BackendDAE.ASSIGN(left=lhs)})
      algorithm
        crefs := Expression.getAllCrefs(lhs);
      then crefs;
  end match;
end getSimEqSystemCrefsLHS;

public function getMaxSimEqSystemIndex"gets the maximal index of all simEqSystems in the SimCode.
author:Waurich TUD 2014-06"
  input SimCode.SimCode simCode;
  output Integer idxOut = 0;
protected
  list<SimCode.SimEqSystem> allEquations,jacobianEquations,equationsForZeroCrossings,algorithmAndEquationAsserts,removedEquations,parameterEquations,maxValueEquations,minValueEquations,nominalValueEquations,startValueEquations,initialEquations;
  list<list<SimCode.SimEqSystem>> odeEquations, algebraicEquations;
algorithm
  SimCode.SIMCODE(allEquations = allEquations, odeEquations=odeEquations, algebraicEquations=algebraicEquations, initialEquations=initialEquations,
                  startValueEquations=startValueEquations, nominalValueEquations=nominalValueEquations, minValueEquations=minValueEquations, maxValueEquations=maxValueEquations,
                    parameterEquations=parameterEquations, removedEquations=removedEquations, algorithmAndEquationAsserts=algorithmAndEquationAsserts,
                   equationsForZeroCrossings=equationsForZeroCrossings, jacobianEquations=jacobianEquations) := simCode;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in equationsForZeroCrossings loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in algorithmAndEquationAsserts loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in removedEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in parameterEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in maxValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in minValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in nominalValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in nominalValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in startValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in initialEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in allEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
end getMaxSimEqSystemIndex;

public function getDaeEqsNotPartOfOdeSystem "Get a list of eqSystem-objects that are solved in DAE, but not in the ODE-system.
author: marcusw"
  input SimCode.SimCode iSimCode;
  output list<SimCode.SimEqSystem> oEqs;
protected
  array<Option<SimCode.SimEqSystem>> allEqs;
  list<tuple<Integer, SimCode.SimEqSystem>> allEqIdxMapping; //mapping SimEqIdx -> SimEqSystem
  list<SimCode.SimEqSystem> allEquations;
  list<list<SimCode.SimEqSystem>> odeEquations;
  Integer highestIdx;
  list<SimCode.SimEqSystem> tmpEqs;
algorithm
  SimCode.SIMCODE(allEquations=allEquations,odeEquations=odeEquations) := iSimCode;
  (allEqIdxMapping, highestIdx) := List.fold(allEquations, getDaeEqsNotPartOfOdeSystem0, ({}, 0));
  allEqs := arrayCreate(highestIdx, NONE());
  allEqs := List.fold(allEqIdxMapping, getDaeEqsNotPartOfOdeSystem1, allEqs);
  allEqs := List.fold(odeEquations, getDaeEqsNotPartOfOdeSystem2, allEqs);
  tmpEqs := {};
  tmpEqs := Array.fold(allEqs, getDaeEqsNotPartOfOdeSystem4, tmpEqs);
  oEqs := Dangerous.listReverseInPlace(tmpEqs);
end getDaeEqsNotPartOfOdeSystem;

protected function getDaeEqsNotPartOfOdeSystem0 "Add the given equation system object to the mapping list (simEqIdx -> SimEqSystem).
author: marcusw"
  input SimCode.SimEqSystem iEqSystem;
  input tuple<list<tuple<Integer, SimCode.SimEqSystem>>, Integer> iMappingWithHighestIdx; //<mapping simEqIdx -> SimEqSystem, highestIdx>
  output tuple<list<tuple<Integer, SimCode.SimEqSystem>>, Integer> outMappingWithHighestIdx;
protected
  Integer index, highestIdx;
  list<tuple<Integer, SimCode.SimEqSystem>> allEqIdxMapping;
algorithm
  index := simEqSystemIndex(iEqSystem);
  (allEqIdxMapping, highestIdx) := iMappingWithHighestIdx;
  allEqIdxMapping := (index, iEqSystem)::allEqIdxMapping;
  highestIdx := intMax(highestIdx, index);
  outMappingWithHighestIdx := (allEqIdxMapping, highestIdx);
end getDaeEqsNotPartOfOdeSystem0;

protected function getDaeEqsNotPartOfOdeSystem1 "Set the array at position simEqIdx to the simEqSystem-object.
author: marcusw"
  input tuple<Integer, SimCode.SimEqSystem> iEqSystem; //<simEqIdx, simEqSystem>
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
protected
  Integer eqSysIdx;
  SimCode.SimEqSystem eqSys;
algorithm
  (eqSysIdx, eqSys) := iEqSystem;
  oEqArray := arrayUpdate(iEqArray, eqSysIdx, SOME(eqSys));
end getDaeEqsNotPartOfOdeSystem1;

protected function getDaeEqsNotPartOfOdeSystem2 "Set the array at position simEqIdx to NONE().
author: marcusw"
  input list<SimCode.SimEqSystem> iEqSystem;
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
algorithm
  oEqArray := List.fold(iEqSystem, getDaeEqsNotPartOfOdeSystem3, iEqArray);
end getDaeEqsNotPartOfOdeSystem2;

protected function getDaeEqsNotPartOfOdeSystem3 "Set the array at position simEqIdx to NONE().
author: marcusw"
  input SimCode.SimEqSystem iEqSystem;
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
protected
  Integer eqSysIdx;
algorithm
  eqSysIdx := simEqSystemIndex(iEqSystem);
  oEqArray := arrayUpdate(iEqArray, eqSysIdx, NONE());
end getDaeEqsNotPartOfOdeSystem3;

protected function getDaeEqsNotPartOfOdeSystem4 "Append the element to the list if it is not NONE().
author: marcusw"
  input Option<SimCode.SimEqSystem> iEqSystemOpt;
  input list<SimCode.SimEqSystem> iResList;
  output list<SimCode.SimEqSystem> oResList;
protected
  SimCode.SimEqSystem eqSys;
algorithm
  oResList := match iEqSystemOpt
    case SOME(eqSys)
      then eqSys::iResList;
    else
      then iResList;
  end match;
end getDaeEqsNotPartOfOdeSystem4;

public function getStateSimVarIndexFromIndex
  input list<SimCodeVar.SimVar> inStateVars;
  input Integer inIndex;
  output Integer outVariableIndex;
protected
  SimCodeVar.SimVar stateVar;
algorithm
  stateVar := listGet(inStateVars, inIndex + 1 - (if (Config.simCodeTarget()=="Cpp" ) then 0 else listLength(inStateVars)) /* SimVar indexes start from zero */);
  outVariableIndex := getVariableIndex(stateVar);
end getStateSimVarIndexFromIndex;

public function getNumScalars
  "Get number of elements when rolling out all arrays of a variable list.
   author: rfranke"
  input list<SimCodeVar.SimVar> vars;
  output Integer numScalars;
algorithm
  numScalars := List.applyAndFold(vars, intAdd, SimCodeUtilShared.getNumElems, 0);
end getNumScalars;

public function numScalarElems
  "Total number of scalar elements over a list of SimVars (rolling out arrays).
   Equals listLength for scalarized variables. Public wrapper around getNumScalars
   used by the FMU templates to compute per-scalar NUMBER_OF_* sizes for
   non-scalarized arrays."
  input list<SimCodeVar.SimVar> vars;
  output Integer n;
algorithm
  n := getNumScalars(vars);
end numScalarElems;

public function getFMI3ArrayStart
  "Space separated list of scalar start values for an FMI 3.0 array variable
   (length = number of scalar elements). Element-wise start values (e.g.
   start = {1,2,3}) are listed per element; a single (broadcast) value, as
   produced by 'each start = ...', is repeated for every element. Returns the
   empty string when there is no start value."
  input SimCodeVar.SimVar var;
  output String out = "";
protected
  list<String> svals;
  Integer n;
algorithm
  out := match var.initialValue
    local DAE.Exp e;
    case SOME(e) algorithm
        svals := getFMIArrayStartValues(e);
        n := SimCodeUtilShared.getNumElems(var);
      then
        if listEmpty(svals) then ""
        // a single (broadcast) start value is repeated for all elements
        else if intEq(listLength(svals), 1) then stringDelimitList(List.fill(listHead(svals), n), " ")
        else stringDelimitList(svals, " ");
    else "";
  end match;
end getFMI3ArrayStart;

public function getFMIArrayStartValues
  "Flattened list of the scalar start values of a (possibly array) start
   expression, in row major order. A scalar start expression yields a single
   value (broadcast by the caller)."
  input DAE.Exp e;
  output list<String> vals;
algorithm
  vals := match e
    local DAE.Exp first; list<DAE.Exp> arr; Real r; Integer i; Boolean b; String s;
    case DAE.RCONST(r) then {realString(r)};
    case DAE.ICONST(i) then {intString(i)};
    case DAE.BCONST(b) then {if b then "true" else "false"};
    case DAE.SCONST(s) then {s};
    case DAE.ARRAY(array = arr) then List.flatten(list(getFMIArrayStartValues(el) for el in arr));
    case DAE.REDUCTION(expr = first) then getFMIArrayStartValues(first);
    else {};
  end match;
end getFMIArrayStartValues;

public function getFMIScalarVRs
  "Comma separated list of the scalar value references occupied by a (possibly
   array) FMI variable: base, base+1, ..., base+getNumElems-1. For a scalar this
   is just its value reference. Used for the STATES/STATESDERIVATIVES macros."
  input SimCodeVar.SimVar var;
  input SimCode.SimCode simCode;
  output String out;
protected
  Integer base, n;
  list<String> refs = {};
algorithm
  base := lookupVR(var.name, simCode);
  n := SimCodeUtilShared.getNumElems(var);
  for i in 0:n-1 loop
    refs := String(base + i) :: refs;
  end for;
  out := stringDelimitList(listReverse(refs), ", ");
end getFMIScalarVRs;

public function getScalarElements
  "Get scalar elements of an array in row major order. This is
   needed by templates for XML files that only support scalar variables.
   author: rfranke"
  input SimCodeVar.SimVar var;
  output list<SimCodeVar.SimVar> elts;
protected
  list<Integer> dims;
  SimCodeVar.SimVar elt;
  Integer index;
  Integer fmi_index;
algorithm
  // create list of elements
  elts := match var
  // check for exportVar = NONE() in type_ = T_ARRAY() which is filtered by default and should not be exported to modeldescription.xml in fmus
  case SimCodeVar.SIMVAR(type_=DAE.T_ARRAY(), exportVar = NONE()) then {};

  case SimCodeVar.SIMVAR(type_=DAE.T_ARRAY(), variable_index=SOME(index), fmi_index=SOME(fmi_index)) algorithm
    dims := List.map(List.lastN(var.numArrayElement, listLength(var.numArrayElement)), stringInt);
    elt := var;
    elt.type_ := Types.arrayElementType(var.type_);
    elts := fillScalarElements(elt, dims, 1, {}, {});
    elts := setVariableIndexHelper(elts, index, fmi_index);
  then elts;
  else {var};
  end match;
end getScalarElements;

protected function fillScalarElements
  "Helper for getScalarElements, called recursively for each dimension.
   author: rfranke"
  input SimCodeVar.SimVar eltIn;
  input list<Integer> dims;
  input Integer dimIdx;
  input list<DAE.Subscript> subsIn;
  input output list<SimCodeVar.SimVar> elts;
protected
  SimCodeVar.SimVar elt = eltIn;
  list<DAE.Subscript> subs;
algorithm
  for i in listGet(dims, dimIdx):-1:1 loop
    subs := DAE.INDEX(DAE.ICONST(i)) :: subsIn;
    if dimIdx < listLength(dims) then
      elts := fillScalarElements(eltIn, dims, dimIdx + 1, subs, elts);
    else
      // add subscripts to array element
      subs := listReverse(subs);
      elt.name := ComponentReference.crefSetLastSubs(elt.name, subs);
      // copy the array subscripts to exportVar as it is used export vars in modeldescription.xml in CodegenFMUCommon.tpl
      elt.exportVar := SOME(ComponentReference.crefSetLastSubs(Util.getOption(elt.exportVar), subs));
      // add subscripts to previousName
      () := match elt
        local
          DAE.ComponentRef cref;
          Boolean fixed;
        case SimCodeVar.SIMVAR(varKind = BackendDAE.CLOCKED_STATE(previousName = cref, isStartFixed = fixed))
        algorithm
          elt.varKind := BackendDAE.CLOCKED_STATE(ComponentReference.crefSetLastSubs(cref, subs), fixed);
        then ();
        else ();
      end match;
      elts := elt :: elts;
    end if;
  end for;
end fillScalarElements;

public function getVariableIndex
  input SimCodeVar.SimVar inVar;
  output Integer outVariableIndex;
algorithm
  outVariableIndex := match inVar
    local
      Integer variableIndex;
    case SimCodeVar.SIMVAR(variable_index = SOME(variableIndex))
    then variableIndex;
    else 0;
  end match;
end getVariableIndex;

public function getVariableFMIIndex
  input SimCodeVar.SimVar inVar;
  output Integer outVariableIndex;
algorithm
  outVariableIndex := match inVar
    local
      Integer variableIndex;
    case SimCodeVar.SIMVAR(fmi_index = SOME(variableIndex))
    then variableIndex;
    else 0;
  end match;
end getVariableFMIIndex;

public function getValueReference
  "returns the value reference of a variable for direct memory access
   considering aliases and array storage order
   author: rfranke and mwalther and vwaurich and sjoelund"
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  outValueReference := match (inSimVar, inElimNegAliases, Config.simCodeTarget())
    local
      SimCodeVar.SimVar simVar;
      DAE.ComponentRef cref;
      String valueReference;
    case (SimCodeVar.SIMVAR(aliasvar = SimCodeVar.NEGATEDALIAS(_)), false, _) then
      getDefaultValueReference(inSimVar, inSimCode.modelInfo.varInfo);
    case (_, _, _) guard(stringEqual(Config.simCodeTarget(), "Cpp")
                        or stringEqual(Config.simCodeTarget(), "omsic")
            /*Temporary disabled omsicpp*/
            /*or stringEqual(Config.simCodeTarget(), "omsicpp")*/)
    algorithm
      // resolve aliases to get multi-dimensional arrays right
      // (this should possibly be done in getVarIndexByMapping?)
      simVar := match inSimVar
        local
          DAE.ComponentRef componentRef;
        case SimCodeVar.SIMVAR(aliasvar = SimCodeVar.ALIAS(varName = cref))
          then cref2simvar(cref, inSimCode);
        case SimCodeVar.SIMVAR(aliasvar = SimCodeVar.NEGATEDALIAS(varName = cref))
          then cref2simvar(cref, inSimCode);
        // resolve pre vars
        case SimCodeVar.SIMVAR(name = DAE.CREF_QUAL(ident=DAE.preNamePrefix, componentRef=componentRef))
          then cref2simvar(componentRef, inSimCode);
        else inSimVar;
      end match;

      valueReference := getVarIndexByMapping(inSimCode.varToArrayIndexMapping, simVar.name, true, "-1");
      if stringEqual(valueReference, "-1") then
        Error.addInternalError("invalid return value from getVarIndexByMapping for " + simVarString(simVar), sourceInfo());
      end if;
      then valueReference;
    case (SimCodeVar.SIMVAR(aliasvar = SimCodeVar.ALIAS(varName = cref)), _, _) then
      getDefaultValueReference(cref2simvar(cref, inSimCode), inSimCode.modelInfo.varInfo);
    else
      getDefaultValueReference(inSimVar, inSimCode.modelInfo.varInfo);
  end match;
end getValueReference;

protected function getDefaultValueReference
  "returns the value reference without consideration of aliases,
   starting from zero for each base type
   author: rfranke"
  input SimCodeVar.SimVar inSimVar;
  input SimCode.VarInfo inVarInfo;
  output String outDefaultValueReference;
protected
  Integer reference;
  Integer numReal = 2*inVarInfo.numStateVars + inVarInfo.numAlgVars + inVarInfo.numDiscreteReal + inVarInfo.numParams + inVarInfo.numAlgAliasVars;
  Integer numInteger = inVarInfo.numIntAlgVars + inVarInfo.numIntParams + inVarInfo.numIntAliasVars;
  Integer numBoolean = inVarInfo.numBoolAlgVars + inVarInfo.numBoolParams + inVarInfo.numBoolAliasVars;
algorithm
  reference := getVariableIndex(inSimVar);
  if reference > numReal + numInteger + numBoolean then
    // String variable
    reference := reference - numReal - numInteger - numBoolean;
  elseif reference > numReal + numInteger then
    // Boolean variable
    reference := reference - numReal - numInteger;
  elseif reference > numReal then
    // Integer variable
    reference := reference - numReal;
  elseif reference < 0 then
    Error.addInternalError("invalid return value from getVariableIndex", sourceInfo());
  end if;
  outDefaultValueReference := String(reference - 1);
end getDefaultValueReference;

public function getFMI3TypeOffset
  "Returns the offset that is added to the per-base-type value reference to make
   it globally unique, as required by the FMI 3.0 standard (in FMI 2.0 value
   references only need to be unique per base type). The offsets are chosen so
   that they match the per-base-type array layout used by getDefaultValueReference
   and the C runtime (fmu3_model_interface.c): reals first, then integers, then
   booleans, then strings. The very same offsets are emitted as #defines into the
   generated FMI 3.0 model code so the runtime can recover the per-type index by
   subtracting the offset.
   author: adrpo"
  input DAE.Type inType;
  input SimCode.ModelInfo inModelInfo;
  output Integer outOffset;
protected
  // Per-scalar counts from varInfo (O(1)). Re-counting the variable lists here on
  // every call is O(n) and this runs once per variable, i.e. O(n^2) overall.
  SimCode.VarInfo vi = inModelInfo.varInfo;
  Integer numReal = 2*vi.numStateVars + vi.numAlgVars + vi.numDiscreteReal + vi.numParams + vi.numAlgAliasVars;
  Integer numInteger = vi.numIntAlgVars + vi.numIntParams + vi.numIntAliasVars;
  Integer numBoolean = vi.numBoolAlgVars + vi.numBoolParams + vi.numBoolAliasVars;
  Integer numString = vi.numStringAlgVars + vi.numStringParamVars + vi.numStringAliasVars;
algorithm
  outOffset := match inType
    local DAE.Type aty;
    case DAE.T_REAL() then 0;
    // enumerations are stored in the integer arrays of the OM runtime
    case DAE.T_INTEGER() then numReal;
    case DAE.T_ENUMERATION() then numReal;
    case DAE.T_BOOL() then numReal + numInteger;
    case DAE.T_STRING() then numReal + numInteger + numBoolean;
    // external objects are exported as FMI 3.0 Binary, after the string block
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()) then numReal + numInteger + numBoolean + numString;
    // non-scalarized array variable: the offset is determined by the element type
    case DAE.T_ARRAY(ty = aty) then getFMI3TypeOffset(aty, inModelInfo);
    else 0;
  end match;
end getFMI3TypeOffset;

public function getFMI2ValueReferenceOffsets
  "The offsets that turn an FMI 2.0 value reference, which is unique only per base
   type, into the globally unique FMI 3.0 one, in the order Real, Integer, Boolean,
   String. The wasm FMU export ships them with the FMU so its loader can serve the
   FMI 2.0 API from a component that speaks FMI 3.0."
  input SimCode.ModelInfo modelInfo;
  output list<Integer> offsets;
algorithm
  offsets := {getFMI3TypeOffset(DAE.T_REAL_DEFAULT, modelInfo),
              getFMI3TypeOffset(DAE.T_INTEGER_DEFAULT, modelInfo),
              getFMI3TypeOffset(DAE.T_BOOL_DEFAULT, modelInfo),
              getFMI3TypeOffset(DAE.T_STRING_DEFAULT, modelInfo)};
end getFMI2ValueReferenceOffsets;

public function getFMI3ValueReference
  "Returns the globally unique value reference of a variable for the FMI 3.0
   export. It is the per-base-type value reference (see getValueReference) shifted
   by the per-base-type offset (see getFMI3TypeOffset).
   author: adrpo"
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  output String outValueReference;
protected
  Integer offset, localRef;
algorithm
  offset := getFMI3TypeOffset(inSimVar.type_, inSimCode.modelInfo);
  // Use the element-cumulative per-base-type value-reference map (same one the
  // C runtime macros use via lookupVR) so that array variables get the value
  // reference of their first scalar element and occupy a contiguous block.
  // For scalars this equals the former getValueReference result.
  localRef := lookupVR(inSimVar.name, inSimCode);
  outValueReference := String(offset + localRef);
end getFMI3ValueReference;

protected function fmi3ModelVariableLists
  "The variable lists in the order the FMI indices were handed out."
  input SimCodeVar.SimVars vars;
  output list<list<SimCodeVar.SimVar>> allLists;
algorithm
  allLists := {vars.stateVars, vars.derivativeVars, vars.algVars, vars.discreteAlgVars,
               vars.intAlgVars, vars.boolAlgVars, vars.stringAlgVars,
               vars.inputVars, vars.outputVars,
               vars.paramVars, vars.intParamVars, vars.boolParamVars, vars.stringParamVars,
               vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars};
end fmi3ModelVariableLists;

public function cacheFMI3ValueReferences
  "Build the FMI index -> value reference table the <ModelStructure> emitter reads,
   and keep it for as long as one is being written (see clearFMI3ValueReferences).

   Without it every unknown and every one of its dependencies searches all
   seventeen variable lists for its index, which on a model with thousands of
   variables is most of what exporting an FMI 3.0 FMU costs: FullRobot spent 15 of
   its 33 export seconds in that search."
  input SimCode.SimCode simCode;
  // Susan calls this for its effect; the empty string is what it interpolates.
  output String dummy = "";
protected
  list<list<SimCodeVar.SimVar>> allLists = fmi3ModelVariableLists(simCode.modelInfo.vars);
  array<String> table;
  Integer n = 0, i;
algorithm
  for lst in allLists loop
    for v in lst loop
      n := intMax(n, getVariableFMIIndex(v));
    end for;
  end for;
  // Index 0 is no variable's, so an unmapped entry keeps its own number as the
  // uncached lookup did.
  table := arrayCreate(n, "");
  for lst in allLists loop
    for v in lst loop
      i := getVariableFMIIndex(v);
      if i > 0 and i <= n and stringEmpty(arrayGet(table, i)) then
        arrayUpdate(table, i, getFMI3ValueReference(v, simCode));
      end if;
    end for;
  end for;
  setGlobalRoot(Global.fmi3ValueReferenceCache, SOME(table));
end cacheFMI3ValueReferences;

public function clearFMI3ValueReferences
  "Drop what cacheFMI3ValueReferences built, so the next model builds its own."
  output String dummy = "";
algorithm
  setGlobalRoot(Global.fmi3ValueReferenceCache, NONE());
end clearFMI3ValueReferences;

public function fmi3UnknownDependencyAttributes
  "The dependencies and dependenciesKind attributes of a <ModelStructure> entry,
   the dependencies mapped from FMI indices to value references."
  input SimCode.SimCode simCode;
  input SimCode.FmiUnknown unknown;
  output String attributes = "";
protected
  Option<array<String>> cache = getGlobalRoot(Global.fmi3ValueReferenceCache);
  list<String> vrs = {};
algorithm
  if not listEmpty(unknown.dependencies) then
    for d in unknown.dependencies loop
      vrs := match cache
        local array<String> table;
        case SOME(table) guard d > 0 and d <= arrayLength(table) and not stringEmpty(arrayGet(table, d))
          then arrayGet(table, d) :: vrs;
        else getFMI3ValueReferenceFromFMIIndex(simCode, d) :: vrs;
      end match;
    end for;
    attributes := " dependencies=\"" + stringDelimitList(listReverse(vrs), " ") + "\"";
  end if;
  if not listEmpty(unknown.dependenciesKind) then
    attributes := attributes + " dependenciesKind=\"" + stringDelimitList(unknown.dependenciesKind, " ") + "\"";
  end if;
end fmi3UnknownDependencyAttributes;

public function fmiDependenciesString
  "Space separated, as the FMI 2.0 ModelStructure dependencies attribute."
  input list<Integer> dependencies;
  output String str;
algorithm
  str := stringDelimitList(list(intString(d) for d in dependencies), " ");
end fmiDependenciesString;

public function fmiDependenciesKindString
  input list<String> kinds;
  output String str;
algorithm
  str := stringDelimitList(kinds, " ");
end fmiDependenciesKindString;

public function getFMI3ValueReferenceFromFMIIndex
  "Maps an FMI variable index (the 1-based position in the ModelVariables list as
   stored in the FmiModelStructure unknowns/dependencies) to the globally unique
   FMI 3.0 value reference of the corresponding variable. Used to emit the
   ModelStructure (Output/ContinuousStateDerivative/InitialUnknown) which, unlike
   FMI 2.0, references variables by valueReference instead of by index.
   Returns the input index as a string if no matching variable is found, so the
   generated XML is still well-formed.
   author: adrpo"
  input SimCode.SimCode inSimCode;
  input Integer inFMIIndex;
  output String outValueReference;
protected
  SimCodeVar.SimVars vars = inSimCode.modelInfo.vars;
  Option<array<String>> cache;
  array<String> table;
  Option<SimCodeVar.SimVar> found = NONE();
algorithm
  cache := getGlobalRoot(Global.fmi3ValueReferenceCache);
  if isSome(cache) then
    SOME(table) := cache;
    if inFMIIndex > 0 and inFMIIndex <= arrayLength(table) and not stringEmpty(arrayGet(table, inFMIIndex)) then
      outValueReference := arrayGet(table, inFMIIndex);
      return;
    end if;
  end if;
  for lst in fmi3ModelVariableLists(vars) loop
    for v in lst loop
      if intEq(getVariableFMIIndex(v), inFMIIndex) then
        found := SOME(v);
        break;
      end if;
    end for;
    if isSome(found) then
      break;
    end if;
  end for;
  outValueReference := match found
    case SOME(_) then getFMI3ValueReference(Util.getOption(found), inSimCode);
    else String(inFMIIndex);
  end match;
end getFMI3ValueReferenceFromFMIIndex;

public function getFMI3TimeValueReference
  "Returns a value reference for the independent variable (time) that does not
   collide with any model variable. It is the first free value reference past the
   real/integer/boolean/string/binary/clock blocks. The same value is emitted as a
   #define (FMI3_TIME_VR) into the generated FMI 3.0 model code.
   author: adrpo"
  input SimCode.SimCode inSimCode;
  output String outValueReference;
algorithm
  outValueReference := String(getFMI3ClockVROffset(inSimCode.modelInfo) + listLength(inSimCode.clockedPartitions));
end getFMI3TimeValueReference;

public constant String FMI_LS_DAE_VERSION = "1.0.0-alpha.1";

public function fmiLsDaeVersion
  "The version of fmi-ls-dae the manifest declares. FMI_LS_DAE_DRAFT_DATE and
   FMI_LS_DAE_DRAFT_COMMIT name the revision of github.com/modelica/fmi-ls-dae
   the export was written against, which the export reports since the layered
   standard is still a draft."
  output String version = FMI_LS_DAE_VERSION;
end fmiLsDaeVersion;

public function getFMI3DaeModeValueReference
  "fmi-ls-dae: the value reference of the structural parameter that switches a
   --daeMode FMU into DAE mode, the first one past the event indicators. The
   residuals follow it (fmi3DaeResiduals); the wasm emitter
   (CodegenWasmJit.build_fmi_vrs) assigns the same numbers."
  input SimCode.SimCode simCode;
  output String vr;
algorithm
  vr := String(stringInt(getFMI3TimeValueReference(simCode)) + simCode.modelInfo.varInfo.numZeroCrossings + 1);
end getFMI3DaeModeValueReference;

public function fmi3DaeResiduals
  "fmi-ls-dae: the residuals of a --daeMode model as (valueReference, dependency
   attributes): the value references follow the DAE-mode switch's, and the
   dependencies and dependenciesKind attributes of each <Residual> are read
   off the rows of the DAE-mode Jacobian's transposed sparsity. A state column
   stands for the state and its derivative both, since DAE-mode differentiation
   folds der(x) into x ($cj * x.Seed); the other columns are the algebraic
   variables. No attributes without a pattern, which the standard reads as a
   dependency on every known."
  input SimCode.SimCode simCode;
  output list<tuple<String, String>> residuals = {};
protected
  SimCode.DaeModeData dmd;
  Option<list<list<Integer>>> rows;
  list<list<Integer>> rest;
  list<Integer> cols;
  array<String> stateVRs, algebraicVRs;
  Integer numStates, daeModeVR;
  String vr, attributes;
  list<String> acc;
algorithm
  SOME(dmd) := simCode.daeModeData;
  daeModeVR := stringInt(getFMI3DaeModeValueReference(simCode));
  rows := match dmd.sparsityPattern
    local SimCode.JacobianMatrix jm;
    case SOME(jm) then SOME(list(Util.tuple22(e) for e in jm.sparsityT));
    else NONE();
  end match;
  numStates := numScalarElems(simCode.modelInfo.vars.stateVars);
  stateVRs := listArray(list(getFMI3ValueReference(v, simCode) for v in simCode.modelInfo.vars.stateVars));
  algebraicVRs := listArray(list(getFMI3ValueReference(v, simCode) for v in dmd.algebraicVars));
  for var in dmd.residualVars loop
    attributes := "";
    if isSome(rows) then
      SOME(rest) := rows;
      if listEmpty(rest) then
        cols := {};
      else
        cols := listHead(rest);
        rows := SOME(listRest(rest));
      end if;
      acc := {};
      for c in cols loop
        if c < numStates then
          vr := arrayGet(stateVRs, c + 1);
          acc := String(stringInt(vr) + numStates) :: vr :: acc;
        else
          acc := arrayGet(algebraicVRs, c - numStates + 1) :: acc;
        end if;
      end for;
      acc := listReverse(acc);
      attributes := " dependencies=\"" + stringDelimitList(acc, " ") + "\" dependenciesKind=\""
        + stringDelimitList(list("dependent" for s in acc), " ") + "\"";
    end if;
    residuals := (String(daeModeVR + 1 + var.index), attributes) :: residuals;
  end for;
  residuals := listReverse(residuals);
end fmi3DaeResiduals;

public function getLocalValueReference
 "returns the local value reference of current OMSIFuncton of a variable for
  direct memory access considering aliases and array storage order."
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  outValueReference := matchcontinue (inSimVar, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref;
      String valueReference;
      HashTableCrefSimVar.HashTable crefToSimVarHT;

    // default case
    case (SimCodeVar.SIMVAR(name=cref), crefToSimVarHT)
    algorithm
      valueReference := localCref2Index(cref, crefToSimVarHT);
      // if localy no index was found search globaly
      if stringEqual(valueReference, "-1") then
        valueReference := getValueReference(inSimVar, inSimCode, inElimNegAliases);
      end if;
      then valueReference;
    else
      algorithm
      Error.addInternalError("getLocalValueReference failed.", sourceInfo());
      then "ERROR: getLocalValueReference failed";
  end matchcontinue;
end getLocalValueReference;

protected function getNLSysRHS
    input list<SimCode.SimEqSystem> eqs;
    input list<DAE.ComponentRef> res ;
    output list<DAE.ComponentRef> unknowns;
algorithm
    unknowns := matchcontinue (eqs,res)
        local list<SimCode.SimEqSystem> tail;
              DAE.Exp exp;
        case ({},_)
            then res;
        case (SimCode.SES_RESIDUAL(exp=exp) :: tail,_)
            then getNLSysRHS(tail,listAppend(res,Expression.getAllCrefs(exp)));
        case (SimCode.SES_FOR_RESIDUAL(exp=exp) :: tail,_)
            then getNLSysRHS(tail,listAppend(res,Expression.getAllCrefs(exp))); // strip crefs?
        case (SimCode.SES_GENERIC_RESIDUAL(exp=exp) :: tail,_)
            then getNLSysRHS(tail,listAppend(res,Expression.getAllCrefs(exp))); // strip crefs?
        case (_,)
            algorithm
                print("getNLSysRHS failed\n");
            then
                fail();
    end matchcontinue;
end getNLSysRHS;

protected function computeDependenciesHelper
    input list<SimCode.SimEqSystem> eqs;
    input list<DAE.ComponentRef> unknowns;
    input list<SimCode.SimEqSystem> res;
    output list<SimCode.SimEqSystem> deps;
algorithm
    deps := matchcontinue (eqs, res)
        local list<SimCode.SimEqSystem> tail;
              SimCode.SimEqSystem head;
              list<DAE.ComponentRef> new_unknowns;
              list<SimCode.SimEqSystem> r;
              DAE.ComponentRef cref;
              list<DAE.ComponentRef> linsys_unk;
              list<DAE.ComponentRef> nlsys_unk;
              list<SimCode.SimEqSystem> nlsys_eqs;
              DAE.Exp exp;
              list<DAE.Exp> beqs;
    case ({}, r)
        then r;
    case ((head as SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp))::tail, r)
        algorithm
            true := List.isMemberOnTrue(cref,unknowns,ComponentReferenceBasics.crefEqual);
            // We must include this equation in the ODE
            new_unknowns := Expression.getAllCrefs(exp);
            // And include all those one defining the RHS
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns), listAppend(r,{head}));
    case ((head as SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(cref=cref,exp=exp))::tail, r)
        algorithm
            true := List.isMemberOnTrue(cref,unknowns,ComponentReferenceBasics.crefEqual);
            // We must include this equation in the ODE
            new_unknowns := Expression.getAllCrefs(exp);
            // And include all those one defining the RHS
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns), listAppend(r,{head}));
    case ((head as SimCode.SES_LINEAR(lSystem = SimCode.LINEARSYSTEM( beqs=beqs)))::tail, r)
        algorithm
            // This linear system defines the following crefs
            linsys_unk := getSimEqSystemCrefsLHS(head);
            // If any of those are in our unkowns me must include this equation system
            false := listEmpty(List.intersectionOnTrue(linsys_unk,unknowns,ComponentReferenceBasics.crefEqual));
            // And include all the variables of the RHS to the unkowns
            new_unknowns := List.flatten(List.map(beqs, Expression.getAllCrefs));
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns),listAppend(r,{head}));
    case ((head as SimCode.SES_NONLINEAR(nlSystem=SimCode.NONLINEARSYSTEM(crefs=nlsys_unk, eqs=nlsys_eqs)))::tail, r)
        algorithm
        // If any of the uknwonw of the NL system are in our unkowns me must include this equation system
        false := listEmpty(List.intersectionOnTrue(nlsys_unk,unknowns,ComponentReferenceBasics.crefEqual));
        new_unknowns := getNLSysRHS(nlsys_eqs,{});
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns),listAppend(r,{head}));
    case (_::tail, r)
        then  computeDependenciesHelper(tail,unknowns,r);
    end matchcontinue;
end computeDependenciesHelper;

public function computeDependencies
    input list<SimCode.SimEqSystem> eqs;
    input DAE.ComponentRef cref;
    output list<SimCode.SimEqSystem> deps;
algorithm
    deps := match cref
    case _
        then listReverse(computeDependenciesHelper(listReverse(eqs),{cref},{}));
    end match;
end computeDependencies;

public function getSimEqSystemsByIndexLst
  input list<Integer> idcs;
  input list<SimCode.SimEqSystem> allSes;
  output list<SimCode.SimEqSystem> sesOut;
algorithm
  sesOut := List.map1(idcs,getSimEqSysForIndex,allSes);
end getSimEqSystemsByIndexLst;

public function getInputIndex
  input SimCodeVar.SimVar var;
  output Integer inputIndex;
protected
  array<Integer> v;
algorithm
  inputIndex := match var
    case SimCodeVar.SIMVAR(inputIndex=SOME(v)) guard arrayLength(v)==1 then arrayGet(v, 1);
    case SimCodeVar.SIMVAR(inputIndex=SOME(_))
      algorithm
        Error.addInternalError("Failed to SimCodeUtil.getInputIndex of variable", sourceInfo());
      then fail();
    else -1;
  end match;
end getInputIndex;

public function resetFunctionIndex
algorithm
  setGlobalRoot(Global.codegenFunctionList, DoubleEnded.fromList({}));
end resetFunctionIndex;

public function addFunctionIndex
  input String prefix, suffix;
  output String newName;
protected
  DoubleEnded.MutableList<String> delst;
algorithm
  delst := getGlobalRoot(Global.codegenFunctionList);
  newName := prefix + String(DoubleEnded.length(delst)) + suffix;
  DoubleEnded.push_back(delst, newName);
end addFunctionIndex;

public function nVariablesReal
  input SimCode.VarInfo varInfo;
  output Integer n;
algorithm
  n := 2*varInfo.numStateVars+varInfo.numAlgVars+varInfo.numDiscreteReal+varInfo.numOptimizeConstraints+varInfo.numOptimizeFinalConstraints;
end nVariablesReal;

public function getSimCode
  output SimCode.SimCode code;
protected
  Option<SimCode.SimCode> ocode;
algorithm
  ocode := getGlobalRoot(Global.optionSimCode);
  code := match ocode
    local SimCode.SimCode c;
    case SOME(c) then c;
    else algorithm Error.addInternalError("Tried to generate code that requires the SimCode structure, but this is not set (function context?)", sourceInfo()); then fail();
  end match;
end getSimCode;

public function isSimulationCodegen
  "Whether the templates are running for a simulation or an FMU rather than for
   functions on their own. Only those set the SimCode structure, and only those
   compile against the counted runtime, so it also answers which of the two
   vocabularies the generated C is written in."
  output Boolean simulation;
protected
  Option<SimCode.SimCode> ocode;
algorithm
  ocode := getGlobalRoot(Global.optionSimCode);
  simulation := match ocode case SOME(_) then true; else false; end match;
end isSimulationCodegen;

public function isContiguousArrayCref
  "Whether the scalarized elements of an array cref occupy consecutive slots of
   one variable array, so the C target may address them through the first one.
   A Jacobian's own variables only if its table has the array itself, as the
   new backend's does."
  input DAE.ComponentRef inCref;
  input SimCodeFunction.Context context;
  output Boolean outContiguous = true;
protected
  SimCode.SimCode simCode = getSimCode();
  SimCodeVar.SimVar v;
  Integer next = -1;
  Boolean param, firstParam = false, jacVar;
  list<DAE.ComponentRef> crefs;
algorithm
  if not simCode.scalarized then
    return;
  end if;
  crefs := ComponentReference.expandCref(inCref, true);
  (jacVar, outContiguous) := match (context, crefs)
    local
      HashTableCrefSimVar.HashTable jacHT;
      DAE.ComponentRef cr;
    case (SimCodeFunction.JACOBIAN_CONTEXT(jacHT = SOME(jacHT)), cr :: _)
      guard isJacobianColumnCref(cr) or List.any(crefs, function BaseHashTable.hasKey(hashTable = jacHT))
      then (true, BaseHashTable.hasKey(ComponentReference.crefStripSubs(inCref), jacHT));
    else (false, true);
  end match;
  if jacVar then
    return;
  end if;
  for cr in crefs loop
    v := cref2simvar(cr, simCode);
    // A cref the SimCode does not know is a whole-array Jacobian seed,
    // addressed through the seed's own value array.
    if v.index < 0 then
      return;
    end if;
    // Parameters live in their own value array (`varArrayName`).
    param := match v.varKind case BackendDAE.PARAM() then true; else false; end match;
    if next == -1 then
      firstParam := param;
    end if;
    outContiguous := match v.aliasvar
      case SimCodeVar.NOALIAS() then param == firstParam and (next == -1 or v.index == next);
      else false;
    end match;
    if not outContiguous then
      return;
    end if;
    next := v.index + 1;
  end for;
end isContiguousArrayCref;

public function isJacobianColumnCref
  "Whether cr is x.$pDER<M>.dummyVar<M>, an element of a Jacobian column. The
   Jacobian only has the elements that depend on the seeds; the others are zero."
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := match cr
    local
      String id, last;
    case DAE.CREF_QUAL(ident = id, componentRef = DAE.CREF_IDENT(ident = last))
      then StringUtil.startsWith(id, DAE.partialDerivativeNamePrefix) and StringUtil.startsWith(last, "dummyVar");
    case DAE.CREF_QUAL() then isJacobianColumnCref(cr.componentRef);
    else false;
  end match;
end isJacobianColumnCref;

public function cref2simvar
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input SimCode.SimCode simCode;
  output SimCodeVar.SimVar outSimVar;
protected
  HashTableCrefSimVar.HashTable crefToSimVarHT;
  DAE.ComponentRef cref, badcref;
algorithm
  try
    SimCode.SIMCODE(crefToSimVarHT = crefToSimVarHT) := simCode;
    cref := if simCode.scalarized then inCref else ComponentReference.crefStripSubs(inCref);
    outSimVar := simVarFromHT(cref, crefToSimVarHT);
    // print("cref2simvar found via HT for cref: " + ComponentReferenceBasics.printComponentRefStr(outSimVar.name) + "\n");
  else
    // print("cref2simvar: " + ComponentReferenceBasics.printComponentRefStr(inCref) + " not found!\n");
    badcref := ComponentReferenceBasics.makeCrefIdent("ERROR_cref2simvar_failed " + ComponentReferenceBasics.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
    outSimVar := SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SOME(SimCodeVar.LOCAL()), NONE(), NONE(), {}, false, true, NONE(), false, NONE(), false, NONE(), NONE(), NONE(), SOME(badcref), false, false);
  end try;
end cref2simvar;

public function simVarExactFromHT
"Used by templates to find the SIMVAR that is stored for exactly this cref (no array offset lookup)."
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable crefToSimVarHT;
  output Option<SimCodeVar.SimVar> outSimVar;
algorithm
  outSimVar := if BaseHashTable.hasKey(inCref, crefToSimVarHT) then SOME(BaseHashTable.get(inCref, crefToSimVarHT)) else NONE();
end simVarExactFromHT;

public function simVarFromHT
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable crefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
protected
  DAE.ComponentRef cref, badcref;
  SimCodeVar.SimVar sv;
  list<DAE.Subscript> subs;
algorithm
  try
    if BaseHashTable.hasKey(inCref, crefToSimVarHT) then
      sv := BaseHashTable.get(inCref, crefToSimVarHT);
    else
      // lookup array variable and add offset for array element
      if Flags.isSet(Flags.NF_SCALARIZE) then
        sv := BaseHashTable.get(ComponentReferenceBasics.crefStripLastSubs(inCref), crefToSimVarHT);
        subs := ComponentReference.crefLastSubs(inCref);
        sv.name := ComponentReference.crefSetLastSubs(sv.name, subs);
      else
        sv := BaseHashTable.get(ComponentReference.crefStripSubs(inCref), crefToSimVarHT);
        subs := ComponentReferenceBasics.crefSubs(inCref);
        sv.name := ComponentReference.crefApplySubs(ComponentReference.crefStripSubs(sv.name), subs);
      end if;

      sv.variable_index := match sv.variable_index
        local Integer index;
        case SOME(index)
        then SOME(index + SimCodeUtilShared.getScalarElementIndex(subs, List.map(sv.numArrayElement, stringInt)) - 1);
        else sv.variable_index;
      end match;
      // fix fmi_index when using nfScalarize
      sv.fmi_index := match sv.fmi_index
        local Integer fmiIndex;
        case SOME(fmiIndex)
        then SOME(fmiIndex + SimCodeUtilShared.getScalarElementIndex(subs, List.map(sv.numArrayElement, stringInt)) - 1);
        else sv.fmi_index;
      end match;
    end if;
    sv := match sv.aliasvar
      case SimCodeVar.NOALIAS() then sv;
      case SimCodeVar.ALIAS(varName=cref) then simVarFromHT(cref, crefToSimVarHT); /* Possibly not needed; can't really hurt that much though */
      case SimCodeVar.NEGATEDALIAS() then sv;
    end match;
  else
    //print("cref2simvar: " + ComponentReferenceBasics.printComponentRefStr(inCref) + " not found!\n");
    badcref := ComponentReferenceBasics.makeCrefIdent("ERROR_simVarFromHT_failed " + ComponentReferenceBasics.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
    sv := SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SOME(SimCodeVar.LOCAL()), NONE(), NONE(), {}, false, true, NONE(), false, NONE(), false, NONE(), NONE(), NONE(), SOME(badcref), false, false);
  end try;
  outSimVar := sv;
end simVarFromHT;

public function createJacContext
  input String name;
  input Option<HashTableCrefSimVar.HashTable> jacHT;
  output SimCodeFunction.Context outContext;
algorithm
  outContext := SimCodeFunction.JACOBIAN_CONTEXT(name, jacHT);
end createJacContext;

public function localCref2SimVar
"Used by templates to find SIMVAR in given hashTable for given cref
 (to gain representaion index info mainly). Does not check if variable is alias."
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  outSimVar := matchcontinue (inCref, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref, badcref;
      SimCodeVar.SimVar sv;
      SimCode.HashTableCrefSimVar.HashTable crefToSimVarHT;
    case (cref, crefToSimVarHT)
      algorithm
        sv := BaseHashTable.get(cref, crefToSimVarHT);
      then sv;

    case (_,_)
      algorithm
        badcref := ComponentReferenceBasics.makeCrefIdent("ERROR_localCref2SimVar_failed " + ComponentReferenceBasics.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
        then SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SOME(SimCodeVar.LOCAL()), NONE(), NONE(), {}, false, true, NONE(), false, NONE(), false, NONE(), NONE(), NONE(), SOME(badcref), false, false);
  end matchcontinue;
end localCref2SimVar;

public function localCref2Index
"Finds local value reference for given cref and hash table"
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  output String outIndex;
algorithm
  outIndex:= matchcontinue (inCref, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref;
      HashTableCrefSimVar.HashTable crefToSimVarHT;
      SimCodeVar.SimVar sv;
    case (cref, crefToSimVarHT)
      algorithm
        sv := BaseHashTable.get(cref, crefToSimVarHT);
      then String(sv.index);
    else
      then "-1";
  end matchcontinue;
end localCref2Index;

public function codegenExpSanityCheck "Handle some things that Susan cannot handle:
* Expand simulation context arrays that contain variables stored in different locations...
* We could move collapsing arrays here since it should be safer to do so when we can lookup which index a variable corresponds to...
* Drop the boxing around calls through a function value (unboxFunctionReferenceCall).
"
  input output DAE.Exp e;
  input SimCodeFunction.Context context;
algorithm
  e := unboxFunctionReferenceCall(e);
  if SimCodeFunctionUtil.inFunctionContext(context) then
    return;
  end if;

  e := match e
    local
      list<SimCodeVar.SimVar> vars;
      SimCode.SimCode simCode;
      Integer index;
      list<DAE.ComponentRef> crf_lst;
    case DAE.CREF(ty=DAE.T_ARRAY())
      algorithm
        simCode := getSimCode();
        crf_lst := ComponentReference.expandCref(e.componentRef, true);
        vars := list(cref2simvar(cr, simCode) for cr in crf_lst);
        if not listEmpty(vars) then
          SimCodeVar.SIMVAR(index=index)::vars := vars;
          for v in vars loop
            // The array needs to be expanded because it's not stored in contiguous memory
            if v.index <> index+1 then
              e := Expression.expandCrefs(e, false /*do not expand records*/);
              break;
            end if;
            index := v.index;
          end for;
        end if;
      then e;
    else e;
  end match;
end codegenExpSanityCheck;

public function unboxFunctionReferenceCall
  "Drops the boxing around a call through a function value: C calls it with the
   unboxed signature of the function it refers to. MetaModelica keeps it, since
   a polymorphic function needs it and a closure there can outlive its frame."
  input output DAE.Exp exp;
protected
  DAE.Exp e;
  DAE.CallAttributes attr;
algorithm
  if Config.acceptMetaModelicaGrammar() then
    return;
  end if;

  exp := match exp
    case DAE.UNBOX(exp = e as DAE.CALL(attr = DAE.CALL_ATTR(isFunctionPointerCall = true)))
      then unboxFunctionReferenceCall(e);
    case DAE.UNBOX(exp = e as DAE.TSUB(exp = DAE.CALL(attr = DAE.CALL_ATTR(isFunctionPointerCall = true))))
      then unboxFunctionReferenceCall(e);
    case DAE.TSUB(exp = e as DAE.CALL(attr = DAE.CALL_ATTR(isFunctionPointerCall = true)))
      algorithm
        exp.exp := unboxFunctionReferenceCall(e);
        exp.ty := Types.unboxedType(exp.ty);
      then exp;
    case DAE.CALL(attr = attr as DAE.CALL_ATTR(isFunctionPointerCall = true))
      algorithm
        exp.expLst := list(unboxArgument(a) for a in exp.expLst);
        attr.ty := unboxResultType(attr.ty);
        exp.attr := attr;
      then exp;
    case DAE.PARTEVALFUNCTION()
      algorithm
        exp.expList := list(unboxArgument(a) for a in exp.expList);
        exp.ty := unboxFunctionReferenceType(exp.ty);
        exp.origType := unboxFunctionReferenceType(exp.origType);
      then exp;
    else exp;
  end match;
end unboxFunctionReferenceCall;

protected function unboxArgument
  "A boxed record literal is a METARECORDCALL with boxed fields."
  input output DAE.Exp exp;
protected
  DAE.Exp e;
  list<DAE.Exp> args;
algorithm
  exp := match exp
    case DAE.BOX() then unboxFunctionReferenceCall(exp.exp);
    case DAE.METARECORDCALL(index = -1)
      algorithm
        args := list(unboxArgument(a) for a in exp.args);
      then
        DAE.RECORD(exp.path, args, exp.fieldNames,
          DAE.T_COMPLEX(ClassInf.RECORD(exp.path),
            list(DAE.TYPES_VAR(n, DAE.dummyAttrVar, Expression.typeof(a), DAE.UNBOUND(), false, NONE())
              threaded for a in args, n in exp.fieldNames),
            NONE(), false));
    case DAE.SHARED_LITERAL(exp = e as DAE.BOX()) then unboxArgument(e);
    case DAE.SHARED_LITERAL(exp = e as DAE.METARECORDCALL(index = -1)) then unboxArgument(e);
    else unboxFunctionReferenceCall(exp);
  end match;
end unboxArgument;

protected function unboxResultType
  input output DAE.Type ty;
algorithm
  ty := match ty
    case DAE.T_TUPLE()
      algorithm
        ty.types := list(Types.unboxedType(t) for t in ty.types);
      then ty;
    else Types.unboxedType(ty);
  end match;
end unboxResultType;

protected function unboxFunctionReferenceType
  input output DAE.Type ty;
protected
  DAE.Type fty;
algorithm
  ty := match ty
    case DAE.T_FUNCTION_REFERENCE_VAR(functionType = fty as DAE.T_FUNCTION())
      algorithm
        fty.funcArg := list(unboxFuncArg(a) for a in fty.funcArg);
        fty.funcResultType := unboxResultType(fty.funcResultType);
        ty.functionType := fty;
      then ty;
    else ty;
  end match;
end unboxFunctionReferenceType;

protected function unboxFuncArg
  input output DAE.FuncArg arg;
algorithm
  arg := match arg
    case DAE.FUNCARG()
      algorithm
        arg.ty := Types.unboxedType(arg.ty);
      then arg;
  end match;
end unboxFuncArg;

public function absoluteClockIdxForBaseClock
  input Integer baseClockIdx; // one-based
  input list<SimCode.ClockedPartition> allBaseClockPartitions;
  output Integer absBaseClockIdx;
protected
  Integer i = 1;
algorithm
  absBaseClockIdx := 1;
  while i < baseClockIdx loop
    absBaseClockIdx := absBaseClockIdx + listLength(getSubPartition(listGet(allBaseClockPartitions,i)));
    i := i+1;
  end while;
end absoluteClockIdxForBaseClock;

public function getClockedPartitions
  input SimCode.SimCode simcode;
  output list<SimCode.ClockedPartition> clockedPartitions;
algorithm
   clockedPartitions := simcode.clockedPartitions;
end getClockedPartitions;

public function isScalarLiteralAssignment
  input SimCode.SimEqSystem eq;
  output Boolean b;
algorithm
  b := match eq
    case SimCode.SES_SIMPLE_ASSIGN() then Expression.isSimpleLiteralValue(eq.exp);
    else false;
  end match;
end isScalarLiteralAssignment;

public function selectScalarLiteralAssignments
  input output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := list(e for e guard isScalarLiteralAssignment(e) in eqs);
end selectScalarLiteralAssignments;

public function filterScalarLiteralAssignments
  input output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := list(e for e guard not isScalarLiteralAssignment(e) in eqs);
end filterScalarLiteralAssignments;

public function sortSimpleAssignmentBasedOnLhs
  input output list<SimCode.SimEqSystem> eqs;
protected
  SimCode.SimCode simCode = getSimCode();
algorithm
  eqs := list(Util.tuple21(e) for e in List.sort(list((eq, lhsSortKey(eq, simCode)) for eq in eqs), keyedLhsGreaterThan));
end sortSimpleAssignmentBasedOnLhs;

protected function lhsSortKey
  "Type, kind and index of a simple assignment's variable; none for other equations."
  input SimCode.SimEqSystem eq;
  input SimCode.SimCode simCode;
  output Option<tuple<Integer, Integer, Integer>> key;
algorithm
  key := match eq
    local
      SimCodeVar.SimVar v;
    case SimCode.SES_SIMPLE_ASSIGN()
      algorithm
        v := cref2simvar(eq.cref, simCode);
      then SOME((valueConstructor(v.type_), valueConstructor(v.varKind), v.index));
    else NONE();
  end match;
end lhsSortKey;

protected function keyedLhsGreaterThan
  input tuple<SimCode.SimEqSystem, Option<tuple<Integer, Integer, Integer>>> e1, e2;
  output Boolean b;
algorithm
  b := match (e1, e2)
    local
      Integer t1, k1, i1, t2, k2, i2;
    case ((_, SOME((t1, k1, i1))), (_, SOME((t2, k2, i2))))
      then if t1 == t2 then (if k1 == k2 then i1 > i2 else k1 > k2) else t1 > t2;
    else false;
  end match;
end keyedLhsGreaterThan;

public function getNumContinuousEquations
  input list<SimCode.SimEqSystem> eqns;
  input Integer numStates;
  output Integer n;
protected
  Integer numEqns =0;
algorithm
  for eqn in eqns loop
    numEqns := numEqns + getNumContinuousEquationsSingleEq(eqn);
  end for;
  n := numEqns+numStates;
end getNumContinuousEquations;

protected function getNumContinuousEquationsSingleEq
  input SimCode.SimEqSystem eqn;
  output Integer n;
algorithm
  n := match eqn
    local
      SimCode.LinearSystem ls;
      SimCode.NonlinearSystem nls;
    case SimCode.SES_MIXED() then getNumContinuousEquationsSingleEq(eqn.cont);
    case SimCode.SES_LINEAR(lSystem = ls as SimCode.LINEARSYSTEM(__)) then listLength(ls.vars);
    case SimCode.SES_NONLINEAR(nlSystem = nls as SimCode.NONLINEARSYSTEM(__)) then listLength(nls.crefs);
    else 1;
  end match;
end getNumContinuousEquationsSingleEq;

public function lookupVR
  input DAE.ComponentRef cr;
  input SimCode.SimCode simCode;
  output Integer vr;
algorithm
  vr := AvlTreeCRToInt.get(simCode.valueReferences, cr);
end lookupVR;

public function isFMUSimCode
  "True when this SimCode was built for an FMU export, so `valueReferences` --
   what lookupVR and the FMI alias tables index -- is filled."
  input SimCode.SimCode simCode;
  output Boolean isFMU;
algorithm
  isFMU := match simCode.valueReferences
    case AvlTreeCRToInt.EMPTY() then false;
    else true;
  end match;
end isFMUSimCode;

public function lookupVRForRealOutputDerivative
  "function which maps output Real var ValueReference to an internal real variable ValueReference of
  pattern $X_der where x = varname, this function will be used by fmi2GetRealOutputDerivatives"
  input DAE.ComponentRef cr;
  input SimCode.SimCode simCode;
  input String fmuType;
  output Integer vr;
protected
  DAE.ComponentRef outputRealDerivativeCref;
algorithm
  if (fmuType == "cs") then
    // map the cref to the internal real var (e.g) output Real y => $y_der
    outputRealDerivativeCref := ComponentReference.appendStringLastIdent("_der", cr); // append _der
    outputRealDerivativeCref := ComponentReference.prependStringCref("$", outputRealDerivativeCref); // prepend $
    vr := AvlTreeCRToInt.get(simCode.valueReferences, outputRealDerivativeCref);
  else
    vr := -1;
  end if;
end lookupVRForRealOutputDerivative;

public function fmi3ArrayView
  "The SimCode the FMI 3.0 modelDescription.xml is rendered from: one SimVar
   and one ModelStructure entry per array of modelStructure.fmiArrays."
  input SimCode.SimCode simCode;
  output SimCode.SimCode view = simCode;
protected
  SimCode.FmiModelStructure ms;
  SimCode.ModelInfo mi;
  SimCodeVar.SimVars vars;
  SimCode.FmiInitialUnknowns iu;
  UnorderedMap<DAE.ComponentRef, Integer> firsts;
  UnorderedMap<Integer, Integer> rep;
algorithm
  if isNone(simCode.modelStructure) then
    return;
  end if;
  SOME(ms) := simCode.modelStructure;
  if listEmpty(ms.fmiArrays) then
    return;
  end if;
  firsts := UnorderedMap.new<Integer>(ComponentReferenceBasics.hashComponentRef, ComponentReferenceBasics.crefEqual);
  rep := UnorderedMap.new<Integer>(Util.id, intEq);
  for a in ms.fmiArrays loop
    UnorderedMap.add(a.first, a.numElements, firsts);
    for k in 1:a.numElements - 1 loop
      UnorderedMap.add(a.fmiIndex + k, a.fmiIndex, rep);
    end for;
  end for;
  mi := simCode.modelInfo;
  vars := mi.vars;
  vars.stateVars := fmi3CollapseArrays(vars.stateVars, firsts);
  vars.derivativeVars := fmi3CollapseArrays(vars.derivativeVars, firsts);
  vars.algVars := fmi3CollapseArrays(vars.algVars, firsts);
  vars.discreteAlgVars := fmi3CollapseArrays(vars.discreteAlgVars, firsts);
  vars.paramVars := fmi3CollapseArrays(vars.paramVars, firsts);
  vars.intAlgVars := fmi3CollapseArrays(vars.intAlgVars, firsts);
  vars.intParamVars := fmi3CollapseArrays(vars.intParamVars, firsts);
  vars.boolAlgVars := fmi3CollapseArrays(vars.boolAlgVars, firsts);
  vars.boolParamVars := fmi3CollapseArrays(vars.boolParamVars, firsts);
  vars.stringAlgVars := fmi3CollapseArrays(vars.stringAlgVars, firsts);
  vars.stringParamVars := fmi3CollapseArrays(vars.stringParamVars, firsts);
  mi.vars := vars;
  view.modelInfo := mi;
  ms.fmiOutputs := SimCode.FMIOUTPUTS(fmi3CollapseUnknowns(ms.fmiOutputs.fmiUnknownsList, rep));
  ms.fmiDerivatives := SimCode.FMIDERIVATIVES(fmi3CollapseUnknowns(ms.fmiDerivatives.fmiUnknownsList, rep));
  ms.fmiDiscreteStates := SimCode.FMIDISCRETESTATES(fmi3CollapseUnknowns(ms.fmiDiscreteStates.fmiUnknownsList, rep));
  iu := ms.fmiInitialUnknowns;
  iu.fmiUnknownsList := fmi3CollapseUnknowns(iu.fmiUnknownsList, rep);
  ms.fmiInitialUnknowns := iu;
  view.modelStructure := SOME(ms);
end fmi3ArrayView;

protected function fmi3CollapseArrays
  input list<SimCodeVar.SimVar> vars;
  input UnorderedMap<DAE.ComponentRef, Integer> firsts "first element -> number of elements";
  output list<SimCodeVar.SimVar> outVars = {};
protected
  list<SimCodeVar.SimVar> rest = vars, elements;
  SimCodeVar.SimVar v;
  Integer n;
algorithm
  while not listEmpty(rest) loop
    v :: rest := rest;
    n := UnorderedMap.getOrDefault(v.name, firsts, 0);
    if n > 1 then
      (elements, rest) := List.split(rest, n - 1);
      v := fmi3ArrayVar(v, elements);
    end if;
    outVars := v :: outVars;
  end while;
  outVars := listReverse(outVars);
end fmi3CollapseArrays;

protected function fmi3ArrayVar
  "The array variable of first and the elements after it."
  input SimCodeVar.SimVar first;
  input list<SimCodeVar.SimVar> others;
  output SimCodeVar.SimVar var = first;
algorithm
  var.type_ := DAE.T_ARRAY(first.type_, list(DAE.DIM_INTEGER(stringInt(d)) for d in first.numArrayElement));
  var.exportVar := SOME(ComponentReferenceBasics.crefStripLastSubs(Util.getOption(first.exportVar)));
  var.initialValue := match first.initialValue
    case SOME(_) then SOME(DAE.ARRAY(var.type_, true, list(Util.getOption(v.initialValue) for v in first :: others)));
    else NONE();
  end match;
end fmi3ArrayVar;

protected function fmi3CollapseUnknowns
  input list<SimCode.FmiUnknown> unknowns;
  input UnorderedMap<Integer, Integer> rep "element FMI index -> the array's";
  output list<SimCode.FmiUnknown> outUnknowns = {};
protected
  UnorderedMap<Integer, Integer> slot = UnorderedMap.new<Integer>(Util.id, intEq) "representative -> position in deps";
  array<list<Integer>> deps = arrayCreate(listLength(unknowns), {});
  list<Integer> order = {}, ds;
  Integer r, i, n = 0;
algorithm
  for u in unknowns loop
    r := UnorderedMap.getOrDefault(u.index, rep, u.index);
    ds := list(UnorderedMap.getOrDefault(d, rep, d) for d in u.dependencies);
    i := UnorderedMap.getOrDefault(r, slot, 0);
    if i == 0 then
      n := n + 1;
      i := n;
      UnorderedMap.add(r, i, slot);
      order := r :: order;
    end if;
    arrayUpdate(deps, i, listAppend(ds, arrayGet(deps, i)));
  end for;
  for r in order loop
    ds := List.sortedUnique(List.sort(arrayGet(deps, UnorderedMap.getOrFail(r, slot)), intGt), intEq);
    outUnknowns := SimCode.FMIUNKNOWN(r, ds, List.fill("dependent", listLength(ds))) :: outUnknowns;
  end for;
end fmi3CollapseUnknowns;

public function fmi3ArrayDefines
  "The FMI 3.0 array variables as (value reference, number of elements) tables
   for fmu3_model_interface.c, sorted by value reference."
  input SimCode.SimCode simCode;
  output String defines;
protected
  list<tuple<Integer, Integer>> arrays = {};
  SimCode.HashTableCrefToSimVar ht;
  SimCodeVar.SimVar v;
algorithm
  _ := match simCode.modelStructure
    local SimCode.FmiModelStructure ms;
    case SOME(ms) guard not listEmpty(ms.fmiArrays)
      algorithm
        ht := createCrefToSimVarHT(simCode.modelInfo);
        for a in ms.fmiArrays loop
          v := BaseHashTable.get(a.first, ht);
          arrays := (stringInt(getFMI3ValueReference(v, simCode)), a.numElements) :: arrays;
        end for;
        arrays := List.sort(arrays, Util.compareTupleIntGt);
      then ();
    else ();
  end match;
  defines := "#define FMI3_NUMBER_OF_ARRAYS " + intString(listLength(arrays)) + "\n"
    + "#define FMI3_ARRAY_VRS { " + stringDelimitList(list(intString(Util.tuple21(a)) for a in arrays), ", ") + " }\n"
    + "#define FMI3_ARRAY_LENGTHS { " + stringDelimitList(list(intString(Util.tuple22(a)) for a in arrays), ", ") + " }";
end fmi3ArrayDefines;

public function isFMI3NestableAlias
  "True if a SimVar can be represented as an FMI 3.0 <Alias> child element of its
   canonical variable (sharing the canonical valueReference) instead of a separate
   ModelVariables entry. Only positive (non-negated) scalar aliases with no
   causality of their own (local) qualify: an <Alias> element carries no factor and
   no causality, so negated aliases and input/output/parameter aliases must stay
   as full variables."
  input SimCodeVar.SimVar simVar;
  output Boolean nestable;
algorithm
  nestable := match simVar
    case SimCodeVar.SIMVAR(aliasvar = SimCodeVar.ALIAS())
      guard isSome(simVar.exportVar)
            and not Types.isArray(simVar.type_)
            and (match simVar.causality
                   case NONE() then true;
                   case SOME(SimCodeVar.LOCAL()) then true;
                   case SOME(SimCodeVar.NONECAUS()) then true;
                   else false;
                 end match)
      then true;
    else false;
  end match;
end isFMI3NestableAlias;

protected function fmi3AliasTargetValueReference
  "The value reference the nestable alias `v` shares with its target, i.e. the
   value reference of the canonical variable it is an <Alias> of. `None` when the
   target is not a variable this FMU exports."
  input SimCodeVar.SimVar v;
  input SimCode.SimCode simCode;
  output Option<Integer> vr;
algorithm
  vr := match v.aliasvar
    local
      DAE.ComponentRef cr;
      Integer local_;
    case SimCodeVar.ALIAS(varName = cr)
      then match AvlTreeCRToInt.getOpt(simCode.valueReferences, cr)
        case SOME(local_) then SOME(getFMI3TypeOffset(v.type_, simCode.modelInfo) + local_);
        else NONE();
      end match;
    else NONE();
  end match;
end fmi3AliasTargetValueReference;

public function cacheFMI3VariableAliases
  "Build the value reference -> <Alias> members table getFMI3VariableAliases reads,
   and keep it for as long as one modelDescription.xml is being written (see
   clearFMI3VariableAliases).

   Without it every variable emitted searches every alias the model has for the
   ones nested under it, which is quadratic and is what rendering an FMI 3.0
   modelDescription.xml costs: 14 of FullRobot's 24 export seconds."
  input SimCode.SimCode simCode;
  // Susan calls this for its effect; the empty string is what it interpolates.
  output String dummy = "";
protected
  SimCodeVar.SimVars vars = simCode.modelInfo.vars;
  list<list<SimCodeVar.SimVar>> aliasLists =
    {vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars};
  array<list<SimCodeVar.SimVar>> table;
  Integer n = 0, vr;
algorithm
  // Two passes: the table is indexed by value reference, whose range is only
  // known once every alias has been resolved.
  for lst in aliasLists loop
    for v in lst loop
      if isFMI3NestableAlias(v) then
        n := match fmi3AliasTargetValueReference(v, simCode) case SOME(vr) then intMax(n, vr + 1); else n; end match;
      end if;
    end for;
  end for;
  table := arrayCreate(n, {});
  for lst in aliasLists loop
    for v in lst loop
      if isFMI3NestableAlias(v) then
        _ := match fmi3AliasTargetValueReference(v, simCode)
          case SOME(vr)
            algorithm arrayUpdate(table, vr + 1, v :: arrayGet(table, vr + 1)); then ();
          else ();
        end match;
      end if;
    end for;
  end for;
  for i in 1:n loop
    arrayUpdate(table, i, listReverse(arrayGet(table, i)));
  end for;
  setGlobalRoot(Global.fmi3VariableAliasCache, SOME(table));
end cacheFMI3VariableAliases;

public function clearFMI3VariableAliases
  "Drop what cacheFMI3VariableAliases built, so the next model builds its own."
  output String dummy = "";
algorithm
  setGlobalRoot(Global.fmi3VariableAliasCache, NONE());
end clearFMI3VariableAliases;

public function getFMI3VariableAliases
  "Return the SimVars that are FMI 3.0 <Alias> members of `canonical`: the nestable
   (see isFMI3NestableAlias) positive aliases whose alias target is `canonical`.
   FMI 3.0 represents these as <Alias> child elements sharing the canonical
   variable's valueReference, rather than as separate variables."
  input SimCode.SimCode simCode;
  input SimCodeVar.SimVar canonical;
  output list<SimCodeVar.SimVar> aliases = {};
protected
  SimCodeVar.SimVars vars = simCode.modelInfo.vars;
  Option<array<list<SimCodeVar.SimVar>>> cached;
  array<list<SimCodeVar.SimVar>> table;
  Integer vr;
algorithm
  cached := getGlobalRoot(Global.fmi3VariableAliasCache);
  if isSome(cached) then
    SOME(table) := cached;
    vr := getFMI3TypeOffset(canonical.type_, simCode.modelInfo)
          + (match AvlTreeCRToInt.getOpt(simCode.valueReferences, canonical.name)
             local Integer local_;
             case SOME(local_) then local_;
             else -1;
             end match);
    if vr >= 0 and vr < arrayLength(table) then
      aliases := arrayGet(table, vr + 1);
    end if;
    return;
  end if;
  for lst in {vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars} loop
    for v in lst loop
      if isFMI3NestableAlias(v) then
        _ := match v.aliasvar
          local DAE.ComponentRef cr;
          case SimCodeVar.ALIAS(varName = cr)
            guard ComponentReferenceBasics.crefEqualNoStringCompare(cr, canonical.name)
            algorithm aliases := v :: aliases; then ();
          else ();
        end match;
      end if;
    end for;
  end for;
  aliases := listReverse(aliases);
end getFMI3VariableAliases;

public function getFMI3Terminals
  "Collect the FMI 3.0 terminals from the exported SimVars. The flat-model type of
   each variable tells us whether it stems from a connector: a variable whose cref
   has a connector-typed qualifier (identType = T_COMPLEX / T_SUBTYPE_BASIC with
   ClassInf.CONNECTOR) is a member of that connector instance. Members are grouped
   by their connector instance (the terminal), preserving the variable order. Used
   by CodegenFMU3 to emit terminalsAndIcons.xml."
  input SimCode.SimCode simCode;
  output list<SimCode.FmiTerminal> terminals = {};
protected
  SimCodeVar.SimVars vars;
  list<SimCodeVar.SimVar> allVars;
  list<tuple<String, String, Boolean, SimCode.FmiTerminalMember>> flat = {};
  list<String> names = {};
  list<String> memberNames;
  Option<tuple<String, String, Boolean, SimCode.FmiTerminalMember>> om;
  String tname, tname2, tkind, tkind2;
  Boolean texp, texp2;
  SimCode.FmiTerminalMember mem;
  list<SimCode.FmiTerminalMember> mems;
algorithm
  vars := simCode.modelInfo.vars;
  // Gather the variables that also end up in modelDescription.xml. The alias var
  // lists are included on purpose: a connector member can itself be an alias
  // (e.g. flange_a.phi == flange_b.phi == the state phi). Such a member is a real
  // <Terminal> member and is emitted in modelDescription.xml (CodegenFMU3 writes
  // the alias var lists into ModelVariables), so its canonical variable (`phi`) is
  // NOT the connector member and dropping the alias would lose the member entirely.
  // connectorMemberOf filters to connector members, so non-connector aliases are
  // ignored. Real vars come first so the canonical member ordering is preserved.
  allVars := List.flatten({vars.stateVars, vars.derivativeVars, vars.algVars,
    vars.discreteAlgVars, vars.paramVars, vars.intAlgVars, vars.intParamVars,
    vars.boolAlgVars, vars.boolParamVars, vars.stringAlgVars, vars.stringParamVars,
    vars.aliasVars, vars.intAliasVars, vars.boolAliasVars, vars.stringAliasVars});
  for v in allVars loop
    om := connectorMemberOf(v);
    if isSome(om) then
      flat := Util.getOption(om) :: flat;
    end if;
  end for;
  flat := listReverse(flat);
  // distinct terminal names in first-seen order
  for t in flat loop
    (tname, _, _, _) := t;
    if not listMember(tname, names) then
      names := tname :: names;
    end if;
  end for;
  names := listReverse(names);
  // one terminal per connector instance, members in first-seen order. memberName
  // must be unique per terminal (FMI 3.0), so skip a member whose name was already
  // added (e.g. a real var and an alias mapping to the same connector member).
  for nm in names loop
    mems := {};
    memberNames := {};
    texp := false;
    tkind := "";
    for t in flat loop
      (tname2, tkind2, texp2, mem) := t;
      if stringEq(tname2, nm) and not listMember(mem.memberName, memberNames) then
        mems := mem :: mems;
        memberNames := mem.memberName :: memberNames;
        texp := texp2;
        tkind := tkind2;
      end if;
    end for;
    terminals := SimCode.FMI_TERMINAL(nm, tkind, texp, listReverse(mems)) :: terminals;
  end for;
  // Append the simple signal ports: top-level scalar input/output variables. A
  // signal connector (e.g. Modelica.Blocks.Interfaces.RealInput/RealOutput, the
  // short class `connector RealInput = input Real`) collapses to a plain
  // input/output Real in the flat model, so it cannot be told apart from a
  // structured connector member by the cref type. Instead we take the model's
  // input/output interface variables (already partitioned by causality in the
  // flat model, no annotation/JSON needed) and make each top-level scalar its own
  // single-member terminal; structured connector members are qualified crefs and
  // are already grouped above, so they are skipped here.
  terminals := listAppend(listReverse(terminals), simplePortTerminals(vars, names));
end getFMI3Terminals;

protected function simplePortTerminals
  "One single-member terminal per top-level scalar input/output variable (the FMU
   signal ports). These come from a signal connector (e.g. RealInput/RealOutput)
   that collapsed to a plain input/output Real, so the member is a `signal`
   variableKind (a non-flow value intended to be equal across a connection); the
   connector type was lost in the flat model, so terminalKind is left empty. Skips
   variables already part of a structured connector terminal (`taken`)."
  input SimCodeVar.SimVars vars;
  input list<String> taken;
  output list<SimCode.FmiTerminal> terminals = {};
protected
  list<String> seen = taken;
algorithm
  for v in listAppend(vars.inputVars, vars.outputVars) loop
    terminals := matchcontinue v
      local
        DAE.ComponentRef cr;
        String nm;
      // a top-level scalar interface variable: cref is a bare identifier
      case _ guard isSome(v.exportVar)
        algorithm
          cr := Util.getOption(v.exportVar);
          DAE.CREF_IDENT(ident = nm, subscriptLst = {}) := cr;
          if listMember(nm, seen) then
            fail();
          end if;
          seen := nm :: seen;
        then SimCode.FMI_TERMINAL(nm, "", false, {SimCode.FMI_TERMINAL_MEMBER(cr, nm, "signal")}) :: terminals;
      else terminals;
    end matchcontinue;
  end for;
  terminals := listReverse(terminals);
end simplePortTerminals;

protected function connectorMemberOf
  "If the variable stems from a connector, return its terminal (connector instance)
   name, the connector type path (terminalKind), the isExpandable flag and the
   terminal member descriptor. variableKind is the FMI 3.0 connection-semantics
   kind: `inflow` for a flow member (Kirchhoff's law), `signal` otherwise (values
   intended to be equal across a connection) - NOT the variable causality, which
   is already in modelDescription.xml."
  input SimCodeVar.SimVar var;
  output Option<tuple<String, String, Boolean, SimCode.FmiTerminalMember>> result;
algorithm
  result := matchcontinue var
    local
      DAE.ComponentRef cref;
      String tname, member, tkind, kind;
      Boolean isExp;
    case _ guard isSome(var.exportVar)
      algorithm
        cref := Util.getOption(var.exportVar);
        (tname, member, isExp, tkind) := crefConnectorSplit(cref);
        // flow connector member -> Kirchhoff (inflow); otherwise a `signal` whose
        // values are intended to be equal across a connection. The flow flag comes
        // from the BackendDAE connectorType captured in the SimVar (the connector
        // type stored in the cref keeps only the type path, not member attributes).
        kind := if var.isConnectorFlow then "inflow" else "signal";
      then SOME((tname, tkind, isExp, SimCode.FMI_TERMINAL_MEMBER(cref, member, kind)));
    else NONE();
  end matchcontinue;
end connectorMemberOf;

public function getFMI3VisualizationResource
  "The <name>_visual.xml resource -d=visxml exported, or \"\" if none. CodegenFMU3
   emits it as the OpenModelica <Visualization> vendor annotation."
  input SimCode.SimCode simCode;
  output String resource = "";
protected
  String path;
algorithm
  if Flags.isSet(Flags.VISUAL_XML) then
    path := simCode.fileNamePrefix + "_visual.xml";
    if System.regularFileExists(path) then
      resource := simCode.fileNamePrefix + "_visual.xml";
    end if;
  end if;
end getFMI3VisualizationResource;

protected function crefConnectorSplit
  "Split a cref at its outermost connector-typed qualifier: returns the connector
   instance name (terminal), the remaining member path, the connector's
   isExpandable flag and the connector type path (for terminalKind). Fails if no
   qualifier has a connector type."
  input DAE.ComponentRef cref;
  output String terminalName;
  output String memberName;
  output Boolean isExpandable;
  output String terminalKind;
algorithm
  (terminalName, memberName, isExpandable, terminalKind) := match cref
    local
      DAE.ComponentRef rest;
      DAE.Type ity;
      String id, innerT, innerM, innerK;
      Boolean isExp;
    // the outermost qualifier is itself a connector: bus.a -> terminal bus, member a
    case DAE.CREF_QUAL(ident = id, identType = ity, componentRef = rest)
      guard Types.isConnector(ity)
      then (id, ComponentReference.crefStr(rest), connectorIsExpandable(ity),
            connectorTypePath(ity));
    // a non-connector qualifier wrapping a connector deeper in: comp.bus.a
    case DAE.CREF_QUAL(ident = id, componentRef = rest)
      algorithm
        (innerT, innerM, isExp, innerK) := crefConnectorSplit(rest);
      then (id + "." + innerT, innerM, isExp, innerK);
  end match;
end crefConnectorSplit;

protected function connectorIsExpandable
  input DAE.Type ty;
  output Boolean isExpandable;
algorithm
  isExpandable := match ty
    local Boolean b;
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(isExpandable = b)) then b;
    case DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(isExpandable = b)) then b;
    else false;
  end match;
end connectorIsExpandable;

protected function connectorTypePath
  "The connector type path (e.g. Modelica....Flange_a) used as the FMI 3.0
   terminalKind. Empty string if the path is not available."
  input DAE.Type ty;
  output String path;
algorithm
  path := match ty
    local Absyn.Path p;
    case DAE.T_COMPLEX(complexClassType = ClassInf.CONNECTOR(path = p)) then AbsynUtil.pathString(p);
    case DAE.T_SUBTYPE_BASIC(complexClassType = ClassInf.CONNECTOR(path = p)) then AbsynUtil.pathString(p);
    else "";
  end match;
end connectorTypePath;

public function getFMI3Clocks
  "Collect the FMI 3.0 output clocks from the model's clocked partitions: each
   base clock becomes one <Clock> variable (causality output). The value
   reference lies in the clock base-type block, after reals/integers/booleans/
   strings/binaries, matching FMI3_CLOCK_VR_OFFSET in the generated code."
  input SimCode.SimCode simCode;
  output list<SimCode.FmiClock> clocks = {};
protected
  Integer offset, i = 0;
algorithm
  offset := getFMI3ClockVROffset(simCode.modelInfo);
  for p in simCode.clockedPartitions loop
    clocks := makeFmiClock(p.baseClock, offset + i, i) :: clocks;
    i := i + 1;
  end for;
  clocks := listReverse(clocks);
end getFMI3Clocks;

protected function getFMI3ClockVROffset
  "First value reference of the clock base-type block (after the real, integer,
   boolean, string and binary/external-object blocks)."
  input SimCode.ModelInfo modelInfo;
  output Integer offset;
protected
  SimCodeVar.SimVars vars = modelInfo.vars;
algorithm
  offset := 2*numScalarElems(vars.stateVars) + numScalarElems(vars.algVars) + numScalarElems(vars.discreteAlgVars) + numScalarElems(vars.paramVars) + numScalarElems(vars.aliasVars)
          + numScalarElems(vars.intAlgVars) + numScalarElems(vars.intParamVars) + numScalarElems(vars.intAliasVars)
          + numScalarElems(vars.boolAlgVars) + numScalarElems(vars.boolParamVars) + numScalarElems(vars.boolAliasVars)
          + numScalarElems(vars.stringAlgVars) + numScalarElems(vars.stringParamVars) + numScalarElems(vars.stringAliasVars)
          + numScalarElems(vars.extObjVars);
end getFMI3ClockVROffset;

protected function makeFmiClock
  "Map an OpenModelica clock kind to an FMI 3.0 <Clock> descriptor."
  input DAE.ClockKind kind;
  input Integer vr;
  input Integer idx;
  output SimCode.FmiClock clk;
protected
  String nm = "$clock" + intString(idx + 1);
algorithm
  clk := match kind
    local DAE.Exp e, ic, res; String iv;
    // periodic real clock: constant interval if the period is a literal
    case DAE.REAL_CLOCK(interval = e)
      then SimCode.FMI_CLOCK(vr, nm, (if stringEq(clockConstString(e), "") then "fixed" else "constant"), false, clockConstString(e), "", "");
    // rational clock: counter/resolution fraction
    case DAE.RATIONAL_CLOCK(intervalCounter = ic, resolution = res)
      then SimCode.FMI_CLOCK(vr, nm, "constant", true, "", clockConstString(ic), clockConstString(res));
    // event clock: ticks when a condition becomes true
    case DAE.EVENT_CLOCK()
      then SimCode.FMI_CLOCK(vr, nm, "triggered", false, "", "", "");
    else SimCode.FMI_CLOCK(vr, nm, "fixed", false, "", "", "");
  end match;
end makeFmiClock;

protected function clockConstString
  "The numeric value of a clock interval/counter expression as a string, or \"\"
   when it is not a literal constant."
  input DAE.Exp e;
  output String s;
algorithm
  s := match e
    local Real r; Integer i;
    case DAE.RCONST(r) then realString(r);
    case DAE.ICONST(i) then intString(i);
    else "";
  end match;
end clockConstString;

public function unbalancedEqSystemPartition
  input list<SimCode.SimEqSystem> inList;
  input Integer maxLength;
  output list<list<SimCode.SimEqSystem>> partitions;
protected
  Integer length, eqLength;
  list<SimCode.SimEqSystem> lst, cur;
  SimCode.SimEqSystem first;
algorithm
  lst := inList;
  cur := {};
  partitions := {};
  length := 0;
  while not listEmpty(lst) loop
    first::lst := lst;
    eqLength := getNumContinuousEquationsSingleEq(first);
    if length > 0 and length + eqLength > maxLength then
      partitions := cur :: partitions;
      length := 0;
      cur := {};
    end if;
    length := eqLength + length;
    cur := first :: cur;
  end while;
  if not listEmpty(cur) then
    partitions := cur :: partitions;
  end if;
end unbalancedEqSystemPartition;

public function selectNLEqSys
  input list<SimCode.SimEqSystem> simEqSysIn;
  output list<SimCode.SimEqSystem> eqs;
protected
  SimCode.SimEqSystem e;
algorithm
  eqs := list(match eq case SimCode.SES_NONLINEAR() then eq; case SimCode.SES_MIXED(cont=e as SimCode.SES_NONLINEAR()) then e; end match for eq guard match eq case SimCode.SES_NONLINEAR() then true; case SimCode.SES_MIXED(cont=SimCode.SES_NONLINEAR()) then true; else false; end match in simEqSysIn);
end selectNLEqSys;

protected function matrixFormatC
  "The SOLVER_MATRIX_FORMAT for a system of this shape. An unknown count, which is
   any pattern only built at runtime, counts as dense."
  input Integer size;
  input Option<Integer> nnz;
  input Boolean isLinear;
  output String format;
protected
  Integer entries = Util.getOptionOrDefault(nnz, size * size);
algorithm
  format := if useSparseSolver(size, entries, isLinear) then "OMC_MATRIX_SPARSE" else "OMC_MATRIX_DENSE";
end matrixFormatC;

public function linearSystemMatrixFormat
  "Format for this linear system, counting nonzeros off the Jacobian's sparsity
   where there is one, which is what the runtime used to measure itself."
  input SimCode.LinearSystem ls;
  output String format;
protected
  Option<Integer> nnz;
algorithm
  nnz := sparsityNonzeros(ls.jacobianMatrix);
  if isNone(nnz) then
    // No sparsity info at all -- fall back to the simJac entry count.
    nnz := simJacNonzeros(ls.simJac);
  end if;
  format := matrixFormatC(listLength(ls.vars), nnz, true);
end linearSystemMatrixFormat;

public function nonlinearSystemMatrixFormat
  "Format for this nonlinear system."
  input SimCode.NonlinearSystem nls;
  output String format;
algorithm
  format := match nls
    case SimCode.NONLINEARSYSTEM()
      then matrixFormatC(listLength(nls.crefs), sparsityNonzeros(nls.jacobianMatrix), false);
  end match;
end nonlinearSystemMatrixFormat;

protected function simJacNonzeros
  "Entries of A, which a torn system does not give elementwise."
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
  output Option<Integer> nnz = if listEmpty(simJac) then NONE() else SOME(listLength(simJac));
end simJacNonzeros;

protected function sparsityNonzeros
  "Entries of a Jacobian's sparsity pattern, unknown without one."
  input Option<SimCode.JacobianMatrix> ojac;
  output Option<Integer> nnz;
protected
  Integer entries = 0;
algorithm
  nnz := match ojac
    local
      SimCode.SparsityPattern sparsity;
      list<SimCode.SparsityRow> rows;
    case SOME(SimCode.JAC_MATRIX(sparsity = sparsity)) guard not listEmpty(sparsity) algorithm
      for col in sparsity loop
        entries := entries + listLength(Util.tuple22(col));
      end for;
    then SOME(entries);
    case SOME(SimCode.JAC_MATRIX(sparsityMatrix = SimCode.Sparsity.SPARSITY(rows = rows))) algorithm
      for row in rows loop
        entries := entries + listLength(row.dependencies);
      end for;
    then SOME(entries);
    else NONE();
  end match;
end sparsityNonzeros;

public function getExpNominal
  "Returns the nominal value of an expression.
  Used to scale zero-crossings like `a > b`."
  input DAE.Exp expr;
  output DAE.Exp nominal;
algorithm
  nominal := match expr
    local
      DAE.ComponentRef cr;
      SimCodeVar.SimVar v;
      Real r1, r2;
      DAE.Exp e1, e2;
      DAE.Type t;

    // for const 0 use zero nominal to not saturate the rest of the expression
    case DAE.ICONST() then DAE.RCONST(abs(intReal(expr.integer)));
    case DAE.RCONST() then DAE.RCONST(abs(expr.real));

    case DAE.CREF(componentRef = cr, ty = t) algorithm
      v := cref2simvar(cr, getSimCode());
    then match v.nominalValue
      case SOME(DAE.RCONST(r1)) then DAE.RCONST(abs(r1));
      case SOME(e1) then Expression.makePureBuiltinCall("abs", {e1}, t);
      case NONE() then match v.varKind
        // for parameters use their actual value
        case BackendDAE.PARAM() then Expression.makePureBuiltinCall("abs", {expr}, t);
        else DAE.RCONST(1.0);
        // TODO use min/max to deduce better nominal value than 1.
      end match;
    end match;

    // a + b = (A*as) + (B*bs) = (A+B)*(A/(A+B)*as + B/(A+B)*bs)
    // FIXME if A = B and a and b have opposite signs then the nominal value of
    //   a+b may be arbitrarily small, but it's definitely smaller than A+B
    case DAE.BINARY(operator = DAE.ADD())
    then match (getExpNominal(expr.exp1), getExpNominal(expr.exp2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(r1 + r2);
      case (e1, e2) then DAE.BINARY(e1, expr.operator, e2);
    end match;

    // similar to DAE.ADD
    case DAE.BINARY(operator = DAE.SUB(ty = t))
    then match (getExpNominal(expr.exp1), getExpNominal(expr.exp2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(r1 + r2);
      case (e1, e2) then DAE.BINARY(e1, DAE.ADD(t), e2);
    end match;

    // a*b = (A*as)*(B*bs) = (A*B)*(as*bs)
    case DAE.BINARY(operator = DAE.MUL())
    then match (getExpNominal(expr.exp1), getExpNominal(expr.exp2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(r1*r2);
      case (e1, e2) then DAE.BINARY(e1, expr.operator, e2);
    end match;

    // a/b = (A*as)/(B*bs) = (A/B)*(as/bs)
    case DAE.BINARY(operator = DAE.DIV())
    then match (getExpNominal(expr.exp1), getExpNominal(expr.exp2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(r1/r2);
      case (e1, e2) then DAE.BINARY(e1, expr.operator, e2);
    end match;

    // a^b = (A*as)^(B*bs) = (A^B)^bs * (as)^(B*bs)
    case DAE.BINARY(operator = DAE.POW())
    then match (getExpNominal(expr.exp1), getExpNominal(expr.exp2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(r1^r2);
      case (e1, e2) then DAE.BINARY(e1, expr.operator, e2);
    end match;

    // -a = -(A*as) = A*(-as)
    case DAE.UNARY(operator = DAE.UMINUS())
    then getExpNominal(expr.exp);

    // if cond then a else b = if cond then A*as else B*bs
    case DAE.IFEXP()
    then DAE.IFEXP(expr.expCond, getExpNominal(expr.expThen), getExpNominal(expr.expElse));

    // |a| = |A*as| = A*|as|
    case DAE.CALL(path = Absyn.IDENT(name = "abs"), expLst = {e1})
    then getExpNominal(e1);

    // sign has values {-1,0,1}
    case DAE.CALL(path = Absyn.IDENT(name = "sign"))
    then DAE.RCONST(1.0);

    // sqrt(a) = sqrt(A*as) = sqrt(A)*sqrt(as)
    case DAE.CALL(path = Absyn.IDENT(name = "sqrt"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(sqrt(r1));
      case e2 then Expression.makePureBuiltinCall("sqrt", {e2}, t);
    end match;

    // div(a, b) is approximately a/b as long as a >> b
    case DAE.CALL(path = Absyn.IDENT(name = "div"), expLst = {e1, e2})
    then match (getExpNominal(e1), getExpNominal(e2))
      case (DAE.RCONST(r1), DAE.RCONST(r2)) then DAE.RCONST(max(1.0, abs(r1 / r2)));
      else DAE.RCONST(1.0);
    end match;

    // mod(a, b) has values in [0, b]
    case DAE.CALL(path = Absyn.IDENT(name = "mod"), expLst = {_, e2})
    then match getExpNominal(e2)
      case DAE.RCONST(r2) then DAE.RCONST(r2);
      else DAE.RCONST(1.0);
    end match;

    // rem(a, b) has values in [-b, b]
    case DAE.CALL(path = Absyn.IDENT(name = "rem"), expLst = {_, e2})
    then match getExpNominal(e2)
      case DAE.RCONST(r2) then DAE.RCONST(r2);
      else DAE.RCONST(1.0);
    end match;

    // ceil(a) is approximately a as long as a >> 0
    case DAE.CALL(path = Absyn.IDENT(name = "ceil"), expLst = {e1})
    then getExpNominal(e1);

    // floor(a) is approximately a as long as a >> 0
    case DAE.CALL(path = Absyn.IDENT(name = "floor"), expLst = {e1})
    then getExpNominal(e1);

    // sin(a) has values in [-1, 1]
    // TODO for a << 1, sin(a) is approximately a
    case DAE.CALL(path = Absyn.IDENT(name = "sin"))
    then DAE.RCONST(1.0);

    // cos(a) has values in [-1, 1]
    case DAE.CALL(path = Absyn.IDENT(name = "cos"))
    then DAE.RCONST(1.0);

    // NOTE: tan(a) is all over the place and proper scaling can be very hard
    // for a << 1, tan(a) is approximately a
    case DAE.CALL(path = Absyn.IDENT(name = "tan"), expLst = {e1})
    then getExpNominal(e1);

    // for a << 1, asin(a) is approximately a
    case DAE.CALL(path = Absyn.IDENT(name = "asin"), expLst = {e1})
    then getExpNominal(e1);

    // acos(a) has values in [0, pi]
    case DAE.CALL(path = Absyn.IDENT(name = "acos"))
    then DAE.RCONST(1.0);

    // atan(a) has values in [-pi/2, pi/2]
    // TODO for a << 1, atan(a) is approximately a
    case DAE.CALL(path = Absyn.IDENT(name = "atan"))
    then DAE.RCONST(1.0);

    // atan2(a,b) has values in [-pi, pi]
    case DAE.CALL(path = Absyn.IDENT(name = "atan"))
    then DAE.RCONST(1.0);

    // for these just calculate the value
    // f(a) = f(A*as) = f(A + A*(as-1)) = f(A) + o(A*(as-1))
    case DAE.CALL(path = Absyn.IDENT(name = "sinh"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(sinh(r1));
      case e2 then Expression.makePureBuiltinCall("sinh", {e2}, t);
    end match;

    case DAE.CALL(path = Absyn.IDENT(name = "cosh"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(cosh(r1));
      case e2 then Expression.makePureBuiltinCall("cosh", {e2}, t);
    end match;

    case DAE.CALL(path = Absyn.IDENT(name = "tanh"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(tanh(r1));
      case e2 then Expression.makePureBuiltinCall("tanh", {e2}, t);
    end match;

    // exp(a) = exp(A*as) = exp(A)^as
    case DAE.CALL(path = Absyn.IDENT(name = "exp"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(exp(r1));
      case e2 then Expression.makePureBuiltinCall("exp", {e2}, t);
    end match;

    // log(a) = log(A*as) = log(A) + log(as)
    case DAE.CALL(path = Absyn.IDENT(name = "log"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(log(r1));
      case e2 then Expression.makePureBuiltinCall("log", {e2}, t);
    end match;

    // log10(a) = log10(A*as) = log10(A) + log10(as)
    case DAE.CALL(path = Absyn.IDENT(name = "log10"), expLst = {e1}, attr = DAE.CALL_ATTR(ty = t))
    then match getExpNominal(e1)
      case DAE.RCONST(r1) then DAE.RCONST(log10(r1));
      case e2 then Expression.makePureBuiltinCall("log10", {e2}, t);
    end match;

    else DAE.RCONST(1.0);
  end match;
end getExpNominal;

public function simIteratorString
  input BackendDAE.SimIterator iter;
  output String str;
algorithm
  str := match iter
    case BackendDAE.SIM_ITERATOR_RANGE()  then ComponentReferenceBasics.printComponentRefStr(iter.name) + " in " + ExpressionBasics.printExpStr(iter.start) + ":" + ExpressionBasics.printExpStr(iter.step) + ":" + ExpressionBasics.printExpStr(iter.stop);
    case BackendDAE.SIM_ITERATOR_LIST()   then ComponentReferenceBasics.printComponentRefStr(iter.name) + " in " + List.toString(iter.lst, intString, List.Style.FLAT_CURLY_SHORT);
  end match;
end simIteratorString;

public function useSparseSolver
"Whether a system of this size and sparsity is factorized sparse or dense. The
 runtime used to decide this itself, which left the backend guessing."
  input Integer size;
  input Integer nnz;
  input Boolean isLinear;
  output Boolean sparse;
protected
  constant Real maxDensityLinear = 0.2, maxDensityNonlinear = 0.1;
  constant Integer minSize = 1000;
algorithm
  sparse := if size <= 0 then false
            else intReal(nnz) / intReal(size * size) < (if isLinear then maxDensityLinear else maxDensityNonlinear)
                 or size > minSize;
end useSparseSolver;

annotation(__OpenModelica_Interface="codegen_util");
end SimCodeCodegenUtil;
