/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2015, Open Source Modelica Consortium (OSMC),
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

encapsulated package InstStateMachineUtil
" file:        InstStateMachineUtil.mo
  package:     InstStateMachineUtil
  description: Model instantiation

  This module contains utility functions for the instantiation of Modelica state machines."

public import DAE;

protected import Flags;
protected import List;
protected import ComponentReference;
protected import HashTable;
protected import HashTableSM1;
protected import HashTableCG;
protected import HashTable3;
protected import HashSet;
protected import Util;
protected import Array;
protected import DAEUtil;
protected import InnerOuter;
protected import Expression;
protected import Debug;
protected import PrefixUtil;
protected import DAEDump;

public uniontype SMNode
  record SMNODE "Collecting information about a state/mode"
    //DAE.Ident ident;
    DAE.ComponentRef componentRef;
    Boolean isInitial;
    HashSet.HashSet edges "relations to other modes due to in- and out-going transitions";
  end SMNODE;
end SMNode;

public uniontype FlatSMGroup
  record FLAT_SM_GROUP "Collecting information about a group of state components forming a flat state machine"
    DAE.ComponentRef initState;
    array<DAE.ComponentRef> states;
  end FLAT_SM_GROUP;
end FlatSMGroup;

public uniontype IncidenceTable
  record INCIDENCE_TABLE
    HashTable.HashTable cref2index "Map cref to corresponding index in incidence matrix";
    Boolean incidence[:,:] "Incidence matrix showing which modes are connected by transitions";
  end INCIDENCE_TABLE;
end IncidenceTable;

// Table having crefs as keys and corresponding SMNODE as value
type SMNodeTable = HashTableSM1.HashTable;

// Table mapping crefs of SMNodes to corresponding crefs of FlatSMGroup
type SMNodeToFlatSMGroupTable = HashTableCG.HashTable;

constant String SMS_PRE = "smOf" "prefix for flat State Machine names";
constant Boolean DEBUG_SMDUMP = false "enable verbose stdout debug information during elaboration";

public function createSMNodeToFlatSMGroupTable "
Author: BTH
Create table that associates a state instance with its governing flat state machine.
"
  input DAE.DAElist inDae;
  output SMNodeToFlatSMGroupTable smNodeToFlatSMGroup;
protected
  list<DAE.Element> elementLst;

  SMNodeTable smNodeTable;
  Integer nStates;
  IncidenceTable iTable, transClosure;
  list<DAE.ComponentRef> initialStates;
  list<FlatSMGroup> flatSMGroup;
algorithm
  if intLt(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33) then
    smNodeToFlatSMGroup := HashTableCG.emptyHashTableSized(1);
    return;
  else
    smNodeToFlatSMGroup := HashTableCG.emptyHashTable();
  end if;

  DAE.DAE(elementLst=elementLst) := inDae;

  smNodeTable := getSMNodeTable(elementLst);
  nStates := BaseHashTable.hashTableCurrentSize(smNodeTable);

  if nStates > 0 then
    if DEBUG_SMDUMP then print("***** InstStateMachineUtil.createSMNodeToFlatSMGroupTable: START ***** \n"); end if;
    if DEBUG_SMDUMP then print("***** State machine node table: ***** \n"); end if;
    if DEBUG_SMDUMP then BaseHashTable.dumpHashTable(smNodeTable); end if;

    if DEBUG_SMDUMP then print("***** Incidence Matrix: ***** \n"); end if;
    iTable := createIncidenceTable(smNodeTable, nStates);
    if DEBUG_SMDUMP then printIncidenceTable(iTable, nStates); end if;

    if DEBUG_SMDUMP then print("***** Transitive Closure: ***** \n"); end if;
    transClosure := transitiveClosure(iTable, nStates);
    if DEBUG_SMDUMP then printIncidenceTable(transClosure, nStates); end if;

    if DEBUG_SMDUMP then print("***** Initial States: ***** \n"); end if;
    initialStates := extractInitialStates(smNodeTable);
    if DEBUG_SMDUMP then print( stringDelimitList(List.map(initialStates, ComponentReference.printComponentRefStr), ", ") + "\n"); end if;

    if DEBUG_SMDUMP then print("***** Flat State Machine Groups: ***** \n"); end if;
    flatSMGroup := extractFlatSMGroup(initialStates, transClosure, nStates);
    if DEBUG_SMDUMP then print(stringDelimitList(List.map(flatSMGroup,dumpFlatSMGroupStr), "\n") + "\n"); end if;

    if DEBUG_SMDUMP then print("***** SM Node cref to SM Group cref mapping: ***** \n"); end if;
    smNodeToFlatSMGroup := List.fold(flatSMGroup, relateNodesToGroup, smNodeToFlatSMGroup);
    if DEBUG_SMDUMP then BaseHashTable.dumpHashTable(smNodeToFlatSMGroup); end if;

    if DEBUG_SMDUMP then print("***** InstStateMachineUtil.createSMNodeToFlatSMGroupTable: END ***** \n"); end if;
  end if;

end createSMNodeToFlatSMGroupTable;

public function wrapSMCompsInFlatSMs "
Author: BTH
Wrap state machine components into corresponding flat state machine containers.
"
  input InnerOuter.InstHierarchy inIH;
  input DAE.DAElist inDae1;
  input DAE.DAElist inDae2;
  input SMNodeToFlatSMGroupTable smNodeToFlatSMGroup;
  input list<DAE.ComponentRef> smInitialCrefs "every smInitialCrefs corresponds to a flat state machine group";
  output DAE.DAElist outDae1;
  output DAE.DAElist outDae2;
protected
  list<DAE.Element> elementLst1, elementLst2, smCompsLst, otherLst1, otherLst2, smTransitionsLst, flatSmLst, flatSMsAndMergingEqns;
algorithm
  //print("InstStateMachineUtil.wrapSMCompsInFlatSMs: smInitialCrefs: " + stringDelimitList(List.map(smInitialCrefs, ComponentReference.crefStr), ",") + "\n");
  //print("InstStateMachineUtil.wrapSMCompsInFlatSMs: smNodeToFlatSMGroup:\n"); BaseHashTable.dumpHashTable(smNodeToFlatSMGroup);

  DAE.DAE(elementLst=elementLst1) := inDae1;
  // extract SM_COMPs
  (smCompsLst, otherLst1) := List.extractOnTrue(elementLst1, isSMComp);

  DAE.DAE(elementLst=elementLst2) := inDae2;
  // extract transition and initialState statements
  (smTransitionsLst, otherLst2) := List.extractOnTrue(elementLst2, isSMStatement2);

  // Create list of FLAT_SM(..). Every FLAT_SM contains the components that constitute that flat state machine
  //flatSmLst := List.map2(smInitialCrefs, createFlatSM, smCompsLst, smNodeToFlatSMGroup);
  flatSmLst := List.map2(smInitialCrefs, createFlatSM, listAppend(smCompsLst, smTransitionsLst), smNodeToFlatSMGroup);
  // Merge variable definitions in flat state machine and create elements list containing FLAT_SMs and merging equations
  flatSMsAndMergingEqns := List.fold1(flatSmLst, mergeVariableDefinitions, inIH, {});

  outDae1 := DAE.DAE(listAppend(flatSMsAndMergingEqns, otherLst1));
  outDae2 := DAE.DAE(otherLst2);
end wrapSMCompsInFlatSMs;



protected function mergeVariableDefinitions "
Author: BTH
Create fresh equations for merging outer output variable definitions
"
  input DAE.Element inFlatSM;
  input InnerOuter.InstHierarchy inIH;
  input list<DAE.Element> inStartElementLst;
  output list<DAE.Element> outElementLst = inStartElementLst;
protected
  HashTableCG.HashTable outerOutputCrefToSMCompCref "Table to map outer outputs to corresponding state";
  HashTableCG.HashTable outerOutputCrefToInnerCref "Table to map outer output to corresponding inners";
  HashTable3.HashTable innerCrefToOuterOutputCrefs "Kind of \"inverse\" of  outerOutputCrefToInnerCref";
  List<tuple<DAE.ComponentRef, DAE.ComponentRef>> hashEntries;
  List<DAE.ComponentRef> uniqueHashValues;
  DAE.FunctionTree emptyTree;
  list<DAE.Element> dAElistNew, mergeEqns;
  // FLAT_SM
  DAE.Ident ident;
  list<DAE.Element> dAElist "The states/modes within the the flat state machine";
algorithm
  DAE.FLAT_SM(ident=ident, dAElist=dAElist) := inFlatSM;

  // Create table that maps outer outputs to corresponding state
  outerOutputCrefToSMCompCref := List.fold(dAElist, collectOuterOutputs, HashTableCG.emptyHashTable());
  //print("InstStateMachineUtil.mergeVariableDefinitions OuterToSTATE:\n"); BaseHashTable.dumpHashTable(outerOutputCrefToSMCompCref);

  // Create table that maps outer outputs crefs to corresponding inner crefs
  outerOutputCrefToInnerCref := List.fold1(BaseHashTable.hashTableKeyList(outerOutputCrefToSMCompCref), matchOuterWithInner, inIH, HashTableCG.emptyHashTable());
  //print("InstStateMachineUtil.mergeVariableDefinitions OuterToINNER:\n"); BaseHashTable.dumpHashTable(outerOutputCrefToInnerCref);

  // Create table that maps inner crefs from above to a list of corresponding outer crefs
  hashEntries := BaseHashTable.hashTableList(outerOutputCrefToInnerCref);
  uniqueHashValues := List.unique(BaseHashTable.hashTableValueList(outerOutputCrefToInnerCref));
  //print("InstStateMachineUtil.mergeVariableDefinitions uniqueHashValues: (" + stringDelimitList(List.map(uniqueHashValues, ComponentReference.crefStr), ",") + ")\n");
  innerCrefToOuterOutputCrefs := List.fold1(uniqueHashValues, collectCorrespondingKeys, hashEntries, HashTable3.emptyHashTable());
  //print("InstStateMachineUtil.mergeVariableDefinitions: innerCrefToOuterOutputCrefs:\n"); BaseHashTable.dumpHashTable(innerCrefToOuterOutputCrefs);

  // Substitute occurrences of previous(outerCref) by previous(innerCref)
  emptyTree := DAE.AVLTREENODE(NONE(),0,NONE(),NONE());
  (DAE.DAE(dAElist), _, _) := DAEUtil.traverseDAE(DAE.DAE(dAElist), emptyTree, traverserHelperSubsOuterByInnerExp, outerOutputCrefToInnerCref);

  // FIXME add support for outers that don't have "inner outer" or "inner" at closest instance level (requires to introduce a fresh intermediate variable)
  mergeEqns := List.map1(BaseHashTable.hashTableKeyList(innerCrefToOuterOutputCrefs), freshMergingEqn, innerCrefToOuterOutputCrefs);

  // add processed flat state machine and corresponding merging equations to the dae element list
  //outElementLst := listAppend(outElementLst, {DAE.FLAT_SM(ident=ident, dAElist=listAppend(dAElist, mergeEqns))}); // put merge equations in FLAT_SM element
  outElementLst := listAppend(outElementLst, DAE.FLAT_SM(ident=ident, dAElist=dAElist) :: mergeEqns); // put equations after FLAT_SM element
end mergeVariableDefinitions;

protected function freshMergingEqn "
Author: BTH
Helper function to mergeVariableDefinition.
Create a fresh equation for merging outer output variable defintions
"
  input DAE.ComponentRef inInnerCref;
  input HashTable3.HashTable inInnerCrefToOuterOutputCrefs;
  output DAE.Element outEqn;
protected
  List<DAE.ComponentRef> outerCrefs, outerCrefsStripped;
  DAE.Type ty;
algorithm
  ty := ComponentReference.crefLastType(inInnerCref);
  // FIXME use instead 'ty := ComponentReference.crefTypeConsiderSubs(inInnerCref);'?
  outerCrefs := BaseHashTable.get(inInnerCref, inInnerCrefToOuterOutputCrefs);
  outerCrefsStripped := List.map(outerCrefs, ComponentReference.crefStripLastIdent);

  outEqn := DAE.EQUATION(DAE.CREF(inInnerCref, ty), mergingRhs(outerCrefs, inInnerCref, ty), DAE.emptyElementSource);
end freshMergingEqn;

protected function mergingRhs "
Author: BTH
Helper function to freshMergingEqn.
Create RHS expression of merging equation.
"
  input List<DAE.ComponentRef> inOuterCrefs "List of the crefs of the outer variables";
  input DAE.ComponentRef inInnerCref;
  input DAE.Type ty "type of inner cref (inner cref type expected to the same as outer crefs type)";
  output DAE.Exp res;
protected
  DAE.CallAttributes callAttributes = DAE.CALL_ATTR(ty,false,true,false,false,DAE.NO_INLINE(),DAE.NO_TAIL());
algorithm
  res := match (inOuterCrefs)
    local
      DAE.ComponentRef outerCref, crefState;
      List<DAE.ComponentRef> rest;
      DAE.Exp outerCrefExp, innerCrefExp, crefStateExp, ifExp, expCond, expElse;
    case (outerCref::{})
      equation
        outerCrefExp = DAE.CREF(outerCref, ty);
        innerCrefExp = DAE.CREF(inInnerCref, ty);
        crefState = ComponentReference.crefStripLastIdent(outerCref);
        crefStateExp = DAE.CREF(crefState, ty);
        expCond = DAE.CALL(Absyn.IDENT("activeState"), {crefStateExp}, callAttributes);
        expElse = DAE.CALL(Absyn.IDENT("previous"), {innerCrefExp}, callAttributes);
        ifExp = DAE.IFEXP(expCond, outerCrefExp, expElse);
      then ifExp;
    case (outerCref::rest)
      equation
        outerCrefExp = DAE.CREF(outerCref, ty);
        crefState = ComponentReference.crefStripLastIdent(outerCref);
        crefStateExp = DAE.CREF(crefState, ty);
        expCond = DAE.CALL(Absyn.IDENT("activeState"), {crefStateExp}, callAttributes);
        expElse = mergingRhs(rest, inInnerCref, ty);
        ifExp = DAE.IFEXP(expCond, outerCrefExp, expElse);
      then ifExp;
  end match;

end mergingRhs;

protected function collectCorrespondingKeys "
Author: BTH
Helper function to mergeVariableDefinitions"
  input DAE.ComponentRef inInnerCref;
  input list<tuple<DAE.ComponentRef, DAE.ComponentRef>> inHashEntries;
  input HashTable3.HashTable inInnerCrefToOuterOutputCrefs;
  output HashTable3.HashTable outInnerCrefToOuterOutputCrefs = inInnerCrefToOuterOutputCrefs;
protected
  list<DAE.ComponentRef> outerRefs;
algorithm
  outerRefs := List.filterMap1(inHashEntries, crefEqualTuple22, inInnerCref);
  outInnerCrefToOuterOutputCrefs := BaseHashTable.addUnique((inInnerCref, outerRefs), outInnerCrefToOuterOutputCrefs);
end collectCorrespondingKeys;

protected function crefEqualTuple22 "
Helper function to collect collectCorrespondingKeys"
  input tuple<DAE.ComponentRef, DAE.ComponentRef> inHashEntry;
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
protected
  Boolean isEqual;
  DAE.ComponentRef tuple22;
algorithm
  tuple22 := Util.tuple22(inHashEntry);
  isEqual := ComponentReference.crefEqual(tuple22, inCref);
  if (not isEqual) then fail(); end if;
  outCref := Util.tuple21(inHashEntry);
end crefEqualTuple22;


protected function traverserHelperSubsOuterByInnerExp "
Author: BTH
Substitute outer variables in previous(x) by corresponding 'inner'.
Helper function to mergeVariableDefinitions"
  input DAE.Exp inExp;
  input HashTableCG.HashTable inOuterToInner;
  output DAE.Exp outExp;
  output HashTableCG.HashTable outOuterToInner;
algorithm
  (outExp, outOuterToInner) := Expression.traverseExpBottomUp(inExp, traverserHelperSubsOuterByInner, inOuterToInner);
end traverserHelperSubsOuterByInnerExp;

protected function traverserHelperSubsOuterByInner "
Author: BTH
Helper function to traverserHelperSubsOuterByInnerExp"
  input DAE.Exp inExp;
  input HashTableCG.HashTable inOuterToInner;
  output DAE.Exp outExp;
  output HashTableCG.HashTable outOuterToInner;
algorithm
  (outExp,outOuterToInner) := match inExp
    local
      DAE.ComponentRef componentRef;
      DAE.Type ty;
      DAE.CallAttributes attr;
    // Substitute outer variables in previous(x) by corresponding 'inner:
    case DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(componentRef, ty)}, attr)
      guard BaseHashTable.hasKey(componentRef, inOuterToInner) then
        (DAE.CALL(Absyn.IDENT("previous"), {DAE.CREF(BaseHashTable.get(componentRef, inOuterToInner), ty)}, attr), inOuterToInner);
    else (inExp,inOuterToInner);
  end match;
end traverserHelperSubsOuterByInner;

protected function matchOuterWithInner "
Author: BTH
Helper function to mergeVariableDefinitions
"
  input DAE.ComponentRef inOuterCref;
  input InnerOuter.InstHierarchy inIH;
  input HashTableCG.HashTable inOuterCrefToInnerCref;
  output HashTableCG.HashTable outOuterCrefToInnerCref = inOuterCrefToInnerCref;
protected
  DAE.ComponentRef crefIdent, crefFound, strippedCref1, strippedCref2;
algorithm
  crefIdent := ComponentReference.crefLastCref(inOuterCref);

  // inOuterCref is supposed to be "outer" or "inner outer" and we want to move one level up the instance hierachy for starting the search for the corresponding inner
  strippedCref1 := ComponentReference.crefStripLastIdent(inOuterCref);
  // Go up one instance level, append identifier and try again. If already at top level, try to find identifier at top level
  strippedCref2 := if ComponentReference.crefDepth(strippedCref1) >= 2 then
    ComponentReference.joinCrefs( ComponentReference.crefStripLastIdent(strippedCref1), crefIdent)
    else crefIdent;
  // now use strippedCref2 for starting the search in the instance hierarchy
  crefFound := findInner(strippedCref2, crefIdent, inIH);

  outOuterCrefToInnerCref := BaseHashTable.addUnique((inOuterCref, crefFound), outOuterCrefToInnerCref);
end matchOuterWithInner;

protected function findInner "
Author: BTH
Helper function to matchOuterWithInner
"
  input DAE.ComponentRef inCrefTest;
  input DAE.ComponentRef inCrefIdent;
  input InnerOuter.InstHierarchy inIH;
  output DAE.ComponentRef outCrefFound;
protected
  DAE.ComponentRef testCref, strippedCref1, strippedCref2;
  InnerOuter.InstHierarchyHashTable ht;
algorithm
  InnerOuter.TOP_INSTANCE(ht=ht) := listHead(inIH);
  try
    _ := InnerOuter.get(inCrefTest, ht);
    outCrefFound := inCrefTest;
  else
    strippedCref1 := ComponentReference.crefStripLastIdent(inCrefTest);
    // Go up one instance level, append identifier and try again. If already at top level, try to find identifier at top level
    strippedCref2 := if ComponentReference.crefDepth(strippedCref1) >= 2 then
      ComponentReference.joinCrefs( ComponentReference.crefStripLastIdent(strippedCref1), inCrefIdent)
      else inCrefIdent;
    outCrefFound := findInner(strippedCref2, inCrefIdent, inIH);
  end try;
end findInner;

protected function collectOuterOutputs "
Author: BTH
Helper function to mergeVariableDefinitions.
"
  input DAE.Element inElem;
  input HashTableCG.HashTable inOuterAcc;
  output HashTableCG.HashTable outOuterAcc = inOuterAcc;
protected
  list<DAE.Element> outerOutputs;
  list<DAE.ComponentRef> outerOutputCrefs;
  list<tuple<HashTableCG.Key,HashTableCG.Value>> outerOutputCrefToSMCompCref;
  // SM_COMP
  DAE.ComponentRef componentRef;
  list<DAE.Element> dAElist "a component with subelements";
algorithm
  outOuterAcc := match inElem
    case DAE.SM_COMP(componentRef=componentRef, dAElist=dAElist)
      algorithm
			  outerOutputs := List.filter(dAElist, isOuterOutput);
			  outerOutputCrefs := List.map(outerOutputs, DAEUtil.varCref);
			  outerOutputCrefToSMCompCref := List.map(outerOutputCrefs, function Util.makeTuple(inValue2=componentRef));
		  then List.fold(outerOutputCrefToSMCompCref, BaseHashTable.addUnique, outOuterAcc);
    else then inOuterAcc;
  end match;
end collectOuterOutputs;

protected function isOuterOutput "
Author: BTH
Helper function to collectOuterOutputs.
"
  input DAE.Element inElem;
algorithm
  _ := match inElem
    local
      DAE.VarDirection direction;
      Absyn.InnerOuter innerOuter;
    case DAE.VAR(direction=direction as DAE.OUTPUT(), innerOuter=innerOuter as Absyn.OUTER()) then ();
    case DAE.VAR(direction=direction as DAE.OUTPUT(), innerOuter=innerOuter as Absyn.INNER_OUTER()) then ();
  end match;
end isOuterOutput;

protected function createFlatSM "
Author: BTH
Helper function to wrapSMCompsInFlatSMs.
"
  input DAE.ComponentRef smInitialCref;
  input list<DAE.Element> smElemsLst;
  input SMNodeToFlatSMGroupTable smNodeToFlatSMGroup;
  output DAE.Element flatSM;
protected
  list<DAE.Element> smElemsInFlatSM;
algorithm
  smElemsInFlatSM := List.filter2OnTrue(smElemsLst, isInFlatSM, smInitialCref, smNodeToFlatSMGroup);
  flatSM := DAE.FLAT_SM(ComponentReference.printComponentRefStr(smInitialCref), smElemsInFlatSM);
end createFlatSM;

protected function isInFlatSM "
Author: BTH
Check if SM_COMP, transition or initialState (first argument) is part of the flat state machine which corresponds to smInitialCref.
"
  input DAE.Element inElement;
  input DAE.ComponentRef smInitialCref;
  input SMNodeToFlatSMGroupTable smNodeToFlatSMGroup "Table which maps the cref of an SM_COMP to the cref of its corresponding flat state machine group";
  output Boolean outResult;
protected
  DAE.ComponentRef crefCorrespondingFlatSMGroup;
algorithm
  crefCorrespondingFlatSMGroup := match inElement
    local
      DAE.ComponentRef cref1;
    case DAE.SM_COMP(componentRef=cref1) guard BaseHashTable.hasKey(cref1, smNodeToFlatSMGroup)
      then BaseHashTable.get(cref1, smNodeToFlatSMGroup);
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("transition"),
      expLst=DAE.CREF(componentRef=cref1)::_)) guard BaseHashTable.hasKey(cref1, smNodeToFlatSMGroup)
      // Note that it suffices to check for the "from" state, since the "to" state must be in the same FlatSMGroup
      then BaseHashTable.get(cref1, smNodeToFlatSMGroup);
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("initialState"),
      expLst={DAE.CREF(componentRef=cref1)})) guard BaseHashTable.hasKey(cref1, smNodeToFlatSMGroup)
      then BaseHashTable.get(cref1, smNodeToFlatSMGroup);
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- InstStateMachineUtil.isInFlatSM failed: Hash table lookup failed for " + DAEDump.dumpElementsStr({inElement}));
      then fail();
  end match;

  outResult := if ComponentReference.crefEqual(crefCorrespondingFlatSMGroup, smInitialCref) then true else false;
end isInFlatSM;

protected function isSMComp "
Author: BTH
Check if element is a SM_COMP.
"
  input DAE.Element inElement;
  output Boolean outResult;
algorithm
  outResult := match (inElement)
    local
      DAE.ComponentRef componentRef;
      list<DAE.Element> dAElist "a component with subelements";
    case DAE.SM_COMP(_,_) then true;
    else false;
  end match;
end isSMComp;

protected function relateNodesToGroup "
Author: BTH
Relate crefs of SMNodes with cref of the FlatSMGroup that it belongs to.
"
  input FlatSMGroup flatSMGroup;
  input SMNodeToFlatSMGroupTable inNodeToGroup;
  output SMNodeToFlatSMGroupTable outNodeToGroup = inNodeToGroup;
protected
  array<tuple<DAE.ComponentRef, DAE.ComponentRef>> nodeGroup;
  // FLAT_SM_GROUP
  DAE.ComponentRef initState;
  array<DAE.ComponentRef> states;
algorithm
  FLAT_SM_GROUP(initState, states) := flatSMGroup;
  nodeGroup := Array.map(states, function Util.makeTuple(inValue2=initState));
  outNodeToGroup := Array.fold(nodeGroup, BaseHashTable.add, outNodeToGroup);
end relateNodesToGroup;

protected function extractFlatSMGroup "
Author: BTH
For each initial state extract the (flat) state machine group that is defined by the
transitive closure associated with that initial state."
  input list<DAE.ComponentRef> initialStates;
  input IncidenceTable iTable;
  input Integer nStates "Number of states";
  output list<FlatSMGroup> flatSMGroup;
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nStates,nStates];
  list<tuple<DAE.ComponentRef, Integer>> entries;
  array<DAE.ComponentRef> i2cref;
  DAE.ComponentRef cref;
  list<DAE.ComponentRef> members;
  array<DAE.ComponentRef> membersArr;
  HashSet.HashSet memberSet;
  Integer n,i,j;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  n := BaseHashTable.hashTableCurrentSize(cref2index);
  // sanity check:
  assert(n == nStates, "Value of nStates needs to be equal to number of modes within state table argument.");

  entries := BaseHashTable.hashTableList(cref2index);
  entries := List.sort(entries, crefIndexCmp);
  //i2cref := arrayCreate(n, ComponentReference.makeDummyCref());
  i2cref := listArray(List.map(entries, Util.tuple21));

  flatSMGroup := {};
  for cref in initialStates loop
    i := BaseHashTable.get(cref, cref2index);
    members := {};
    for j in 1:n loop
      if incidence[i,j] then
        members := i2cref[j]::members;
      end if;
    end for;

    // Ensure uniquenes of entries
    memberSet := HashSet.emptyHashSetSized(listLength(members));
    memberSet := List.fold(members, BaseHashSet.add, memberSet);

    // Ensure that initialState comes first in array
    memberSet := BaseHashSet.delete(cref, memberSet);
    membersArr := listArray(cref :: BaseHashSet.hashSetList(memberSet));

    flatSMGroup := FLAT_SM_GROUP(cref, membersArr)::flatSMGroup;
  end for;

end extractFlatSMGroup;


public function dumpFlatSMGroupStr "
Author: BTH
Dump flat state machine group to string"
  input FlatSMGroup flatA;
  output String flatStr;
protected
  list<DAE.ComponentRef> crefs;
  String initialStateStr, statesStr;
  list<String> statesStrs;
  // FLAT_SM_GROUP fields
  DAE.ComponentRef initState;
  array<DAE.ComponentRef> states;
algorithm
  FLAT_SM_GROUP(initState=initState, states=states) := flatA;
  initialStateStr := ComponentReference.printComponentRefStr(initState);
  crefs := arrayList(states);
  statesStrs := List.map(crefs, ComponentReference.printComponentRefStr);
  statesStr := stringDelimitList(statesStrs, ", ");

  flatStr := initialStateStr+"( states("+statesStr+"))";
end dumpFlatSMGroupStr;


protected function extractInitialStates "
Author: BTH
Return crefs of states declared as 'initialState'. "
  input SMNodeTable smNodeTable;
  output list<DAE.ComponentRef> initialStates;
protected
  list<tuple<DAE.ComponentRef, SMNode>> entries;
  tuple<DAE.ComponentRef, SMNode> e;
  DAE.ComponentRef cref;
  SMNode smNode;
  Boolean isInitial;
algorithm
  entries := BaseHashTable.hashTableList(smNodeTable);
  initialStates := {};
  for e in entries loop
    (cref, smNode) := e;
    SMNODE(isInitial=isInitial) := smNode;
    if isInitial then
      initialStates := cref::initialStates;
    end if;
  end for;
end extractInitialStates;

protected function transitiveClosure "
Author: BTH
Compute the transitive closure over the transition relation between states.
This allows to group states that are part of the same (flat) state machine.
The function uses the Warshall's algorithm for that task, c.f.
http://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm
or the more succinct (and potentially more readable) description
http://de.wikipedia.org/wiki/Warshall-Algorithmus
"
  input IncidenceTable iTable;
  input Integer nStates "Number of states";
  output IncidenceTable  transClosure;
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nStates,nStates];
  Integer n,k,i,j;
  Boolean c;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  n := BaseHashTable.hashTableCurrentSize(cref2index);
  // sanity check:
  assert(n == nStates, "Value of nStates needs to be equal to number of states within state table argument.");

  // Warshall's algorithm for computing the transitive closure
  for k in 1:n loop
    for i in 1:n loop
      if incidence[i,k] then
        for j in 1:n loop
          if incidence[k,j] then
            incidence[i,j] := true;
          end if;
        end for;
      end if;
    end for;
  end for;

  transClosure := INCIDENCE_TABLE(cref2index, incidence);
end transitiveClosure;

protected function createIncidenceTable "
Author: BTH
Create incidence table showing which modes are connected by transitions."
  input SMNodeTable smNodes;
  input Integer nStates "Number of states";
  output IncidenceTable iTable;
protected
  HashTable.HashTable cref2index "Map cref to corresponding index in incidence matrix";
  Boolean incidence[nStates,nStates] "Incidence matrix showing which states are connected by transitions";
  array<Boolean> iRow;
  Integer n,m,i,j,k;
  DAE.ComponentRef cref;
  HashSet.HashSet edges;
  array<DAE.ComponentRef> crefs1,crefs2;
algorithm
  crefs1 := listArray(BaseHashTable.hashTableKeyList(smNodes));
  n := arrayLength(crefs1);
  cref2index := HashTable.emptyHashTableSized(n);
  assert(n == nStates, "Value of nStates needs to be equal to number of modes within mode table argument.");
  incidence := fill(false,n,n);

  for i in 1:n loop
    cref2index := BaseHashTable.addNoUpdCheck((crefs1[i], i), cref2index);
  end for;

  for i in 1:n loop
    SMNODE(edges=edges) := BaseHashTable.get(crefs1[i], smNodes);
    crefs2 := listArray(BaseHashSet.hashSetList(edges));
    m := arrayLength(crefs2);
    for j in 1:m loop
      cref := crefs2[j];
      k := BaseHashTable.get(cref, cref2index);
      incidence[i,k] := true;
    end for;
  end for;

  iTable := INCIDENCE_TABLE(cref2index, incidence);
end createIncidenceTable;

protected function printIncidenceTable "
Author: BTH
Print incidence table."
  input IncidenceTable iTable;
  input Integer nStates "Number of states";
protected
  HashTable.HashTable cref2index;
  Boolean incidence[nStates,nStates];
  list<tuple<DAE.ComponentRef, Integer>> entries;
  tuple<DAE.ComponentRef, Integer> entry;
  DAE.ComponentRef cref;
  Integer n,i,j,padn;
  array<Boolean> row;
  String str,pads;
  Boolean b;
algorithm
  INCIDENCE_TABLE(cref2index, incidence) := iTable;
  entries := BaseHashTable.hashTableList(cref2index);

  // sanity check:
  n := listLength(entries);
  assert(n == nStates, "Value of nStates needs to be equal to number of modes within state table argument.");

  entries := List.sort(entries, crefIndexCmp);
  for entry in entries loop
    (cref, i) := entry;
    print( ComponentReference.printComponentRefStr(cref) + ": " + intString(i) + "\n" );
  end for;

  pads := " ";
  padn := 8;
  // Print table header
  str := Util.stringPadRight("i", padn, pads);
  for i in 1:n loop
    str := str + Util.stringPadLeft(intString(i)+",", padn, pads);
  end for;
  print(str + "\n");
  // print incidence matrix rows
  for i in 1:n loop
    str := Util.stringPadRight(intString(i), padn, pads);
    for j in 1:n loop
      b := incidence[i,j];
      str := str + Util.stringPadLeft(boolString(b)+",", padn, pads);
    end for;
    print(str + "\n");
  end for;
end printIncidenceTable;

protected function crefIndexCmp "
Author: BTH
Compare the indices assigned to two crefs (helper function for sorting)"
  input tuple<DAE.ComponentRef, Integer> inElement1;
  input tuple<DAE.ComponentRef, Integer> inElement2;
  output Boolean inRes;
protected
  Integer i1, i2;
algorithm
  (_, i1) := inElement1;
  (_, i2) := inElement2;
  inRes := i1 > i2;
end crefIndexCmp;

public function getSMNodeTable "
Author: BTH
Traverse the equations, search for 'transition' and 'initialState' operators,
extract the state arguments from them and collect them in the table."
  input list<DAE.Element> elementLst;
  output SMNodeTable smNodeTable;
protected
  list<DAE.Element> elementLst2;
algorithm
  elementLst2 := list(e for e guard isSMStatement2(e) in elementLst);
  smNodeTable := List.fold(elementLst2,  extractSMStates2, HashTableSM1.emptyHashTable());
end getSMNodeTable;

protected function isSMStatement "
Author: BTH
Return true if element is a state machine statement, otherwise false"
  input SCode.Equation inElement;
  output Boolean outIsSMStatement;
algorithm
  outIsSMStatement := match inElement
    local
      String name;

    case SCode.EQUATION(eEquation = SCode.EQ_NORETCALL(exp = Absyn.CALL(function_ =
        Absyn.CREF_IDENT(name = name))))
      then (name == "transition" or name == "initialState") and
           intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);

    else false;
  end match;
end isSMStatement;

protected function isSMStatement2 "
Author: BTH
Return true if element is a state machine statement, otherwise false"
  input DAE.Element inElement;
  output Boolean outIsSMStatement;
algorithm
  outIsSMStatement := match inElement
    local
      String name;

    case DAE.NORETCALL(exp = DAE.CALL(path = Absyn.IDENT(name)))
      then (name == "transition" or name == "initialState") and
           intGe(Flags.getConfigEnum(Flags.LANGUAGE_STANDARD), 33);

    else false;
  end match;
end isSMStatement2;

protected function extractSMStates2 "
Author: BTH
Helper function to getSMNodeTable"
  input DAE.Element inElement;
  input SMNodeTable inTable;
  output SMNodeTable outTable = inTable;
algorithm

  outTable := match (inElement)
    local
      SMNode smnode1, smnode2;
      DAE.ComponentRef cref1, cref2;
      Boolean isInitial1, isInitial2;
      HashSet.HashSet edges1, edges2;
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("transition"),
      expLst=DAE.CREF(componentRef=cref1)::DAE.CREF(componentRef=cref2)::_))
      equation
        //print("InstStateMachineUtil.extractSMStates: transition("+ComponentReference.crefStr(cref1)+", "+ComponentReference.crefStr(cref2)+")\n");
        smnode1 = if BaseHashTable.hasKey(cref1, outTable)
          then BaseHashTable.get(cref1, outTable)
            else SMNODE(cref1, false, HashSet.emptyHashSet());
        SMNODE(_,isInitial1,edges1) = smnode1;
        edges1 = BaseHashSet.add(cref1, edges1);
        edges1 = BaseHashSet.add(cref2, edges1);
        smnode1 = SMNODE(cref1, isInitial1, edges1);
        outTable = BaseHashTable.add((cref1, smnode1), outTable);

        smnode2 = if BaseHashTable.hasKey(cref2, outTable)
          then BaseHashTable.get(cref2, outTable)
            else SMNODE(cref2, false, HashSet.emptyHashSet());
        SMNODE(_,isInitial2,edges2) = smnode2;
        edges2 = BaseHashSet.add(cref1, edges2);
        edges2 = BaseHashSet.add(cref2, edges2);
        smnode2 = SMNODE(cref2, isInitial2, edges2);
        outTable = BaseHashTable.add((cref2, smnode2), outTable);
      then outTable;
    case DAE.NORETCALL(exp=DAE.CALL(path=Absyn.IDENT("initialState"),
      expLst={DAE.CREF(componentRef=cref1)}))
      equation
        //print("InstStateMachineUtil.extractSMStates: initialState("+ComponentReference.crefStr(cref1)+")\n");
        smnode1 = if BaseHashTable.hasKey(cref1, outTable)
          then BaseHashTable.get(cref1, outTable)
            else SMNODE(cref1, true, HashSet.emptyHashSet());
        SMNODE(_,isInitial1,edges1) = smnode1;
        edges1 = BaseHashSet.add(cref1, edges1);
        smnode1 = SMNODE(cref1,true,edges1);
        outTable = BaseHashTable.add((cref1, smnode1), outTable);
      then outTable;
  end match;

end extractSMStates2;



public function getSMStatesInContext "
Author: BTH
Return list of states defined in current context (by checking 'transtion' and 'initialState' operators)"
  input list<SCode.Equation> eqns;
  input Prefix.Prefix inPrefix;
  output list<DAE.ComponentRef> states "Initial and non-initial states";
  output list<DAE.ComponentRef> initialStates "Only initial states";
protected
  list<SCode.Equation> eqns1;
  list<list<Absyn.ComponentRef>> statesLL;
  list<Absyn.ComponentRef> initialStatesCR, statesCR;
algorithm
  eqns1 := list(eq for eq guard isSMStatement(eq) in eqns);
  // Extract initial states
  initialStatesCR := List.filterMap(eqns1, extractInitialSMStates);
  initialStates := List.map(initialStatesCR, ComponentReference.toExpCref);
  // prefix the names
  initialStates := List.map1(initialStates, prefixCrefNoContext2, inPrefix);
  // 01.06.2015 Strange. I get a compile error if using below instead of above AND removing prefixCrefNoContext2(..) function definitions
  // initialStates := List.map(initialStates, function PrefixUtil.prefixCrefNoContext(inPre=inPrefix));

  // Extract states (initial as well as non-initial)
  statesLL := List.map(eqns1, extractSMStates);
  statesCR := List.flatten(statesLL);
  states := List.map(statesCR, ComponentReference.toExpCref);
  // prefix the names
  states := List.map(states, function PrefixUtil.prefixCrefNoContext(inPre=inPrefix));
end getSMStatesInContext;

protected function prefixCrefNoContext2 "
Helper function to getSMStatesInContext.
Swapped order of inputs of PrefixUtil.prefixCrefNoContext(..) in order to use it with map1"
  input DAE.ComponentRef inCref;
  input Prefix.Prefix inPre;
  output DAE.ComponentRef outCref;
algorithm
  outCref := PrefixUtil.prefixCrefNoContext(inPre, inCref);
end prefixCrefNoContext2;


protected function extractInitialSMStates "
Author: BTH
Helper function to getSMStatesInContext.
Return state instance componenent refs used as arguments in operator 'initialState'.
"
input SCode.Equation inElement;
output Absyn.ComponentRef outElement;
algorithm
  outElement := match (inElement)
    local
      Absyn.ComponentRef cref1, cref2;
      list<Absyn.Exp> args;
    case SCode.EQUATION(eEquation=SCode.EQ_NORETCALL(exp=Absyn.CALL(function_=
      Absyn.CREF_IDENT(name="initialState"),
      functionArgs = Absyn.FUNCTIONARGS(args =
        {Absyn.CREF(componentRef = cref1)}
        ))))
      then cref1;
  end match;
end extractInitialSMStates;

protected function extractSMStates "
Author: BTH
Helper function to getSMStatesInContext.
Return list of state instance componenent refs used as arguments in operators 'transtion' or 'initialState'.
"
input SCode.Equation inElement;
output list<Absyn.ComponentRef> outElement;
algorithm
  outElement := match (inElement)
    local
      Absyn.ComponentRef cref1, cref2;
      list<Absyn.Exp> args;
    case SCode.EQUATION(eEquation=SCode.EQ_NORETCALL(exp=Absyn.CALL(function_=
      Absyn.CREF_IDENT(name="transition"),
      functionArgs = Absyn.FUNCTIONARGS(args =
        {Absyn.CREF(componentRef = cref1),
        Absyn.CREF(componentRef = cref2),_}
        ))))
      then {cref1, cref2};
    case SCode.EQUATION(eEquation=SCode.EQ_NORETCALL(exp=Absyn.CALL(function_=
      Absyn.CREF_IDENT(name="initialState"),
      functionArgs = Absyn.FUNCTIONARGS(args =
        {Absyn.CREF(componentRef = cref1)}
        ))))
      then {cref1};
    else {};
  end match;
end extractSMStates;

annotation(__OpenModelica_Interface="frontend");
end InstStateMachineUtil;
