/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2018, Open Source Modelica Consortium (OSMC),
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

encapsulated package MidToMid

public
import MidCode;

/*
Longjmps are not allowed to land in the same function.
This is handled in midtomid.
Handling it here allows other tranformations to
deal with goto instead of longjmp, which might enable
further transformation.

pushpopjmp possible.
can remove push-pop -jmp pairs if there is no possible longjmp in between.

Typechecking possible.
Useful for correctness of midcode transformations.

Normalisation possble. (AKA canonicalisation)
Probably essential to simplify other transformations.
Remove greater than comparisons and similar.

Inlining possible.
Important catalyst for other optimisations.

Common subexpression elimination possible.
But requires some data flow and side effect analysis.
Some SSA variables and purity marked functions perhaps.

*/


function longJmpGoto
  "
  Replace a longjmp within a function call with goto.
  longjmp within function calls isn't allowed so
  this is necessary to form correct c form midcode.
  "
  input MidCode.Function oldFunction;
  output MidCode.Function newFunction;
protected
  list<MidCode.Block> newBody, oldBody;
  MidCode.Block newBlock, oldBlock;
  Integer node,jump;
  list<Integer> jumps;
  list<Integer> nodes_tmp, checkedNodes;
  list<tuple<list<Integer>,Integer>> tasks, tasks_tmp; // [ ([Int], Int) ]
algorithm
  /*
  do depth first search
  keep a stack of jmp_targets
  when encoutering a PUSHJMP: push the target label onto jmp_targets
  when encountering a LONGJMP and jmp_targets in't empty: replace with goto the top of jmp_targets
  when encountering a POPJMP: pop jmp_targets
  */
  /*
  How to depth first
    maybe not use program stack ~1000 blocks might cause stack overflow
    so jmp_targets is a list
    while loop with empty check on nodes
    start wih entryId-block
    keep list of used ids, alreadyChecked
    need to look up blockId in Function structure
    find the successors of current node, add all that are not in alreadyChecked
    build a new list of blocks with terminators maybe replaced
    replace the body part of function
  */
  /*
  Leave the buffer variables in the function still declared.
  */
  oldBody := oldFunction.body;
  newBody := {};
  checkedNodes := {oldFunction.entryId};
  tasks := {({},oldFunction.entryId)};

  while not listEmpty(tasks) loop
    ((jumps,node) :: tasks) := tasks; // pop
    oldBlock := lookupId(oldBody,node); // O(length(oldBody))
    newBlock := oldBlock; // don't change the block by defualt
    if isPushJmp(oldBlock.terminator) then
      jumps := (listHead(getSuccessors(oldBlock)) :: jumps); // push
    elseif isLongJmp(oldBlock.terminator) and not listEmpty(jumps) then
      (jump :: _) := jumps; // peek
      newBlock := MidCode.BLOCK(id=oldBlock.id,stmts=oldBlock.stmts, terminator=MidCode.GOTO(jump));
    elseif isPopJmp(oldBlock.terminator) then
      (_ :: jumps) := jumps; // pop
    end if;
    newBody := newBlock :: newBody;

    nodes_tmp := List.setDifference(getSuccessors(oldBlock), checkedNodes);
    checkedNodes := listAppend(nodes_tmp, checkedNodes);
    tasks_tmp := list( (jumps,node_tmp) for node_tmp in nodes_tmp );
    tasks := listAppend(tasks_tmp, tasks);
  end while;
  newBody := listReverse(newBody);

  newFunction := MidCode.FUNCTION(
     name=oldFunction.name
    ,locals=oldFunction.locals
    ,localBufs=oldFunction.localBufs
    ,localBufPtrs=oldFunction.localBufPtrs
    ,inputs=oldFunction.inputs
    ,outputs=oldFunction.outputs
    ,body=newBody
    ,entryId=oldFunction.entryId
    ,exitId=oldFunction.exitId
    );
end longJmpGoto;

function lookupId
  input list<MidCode.Block> blocks;
  input Integer id;
  output MidCode.Block block_;
protected
  list<MidCode.Block> blocks_local;
  MidCode.Block block_local;
algorithm
  block_ := match blocks
    case (block_local :: _) guard (block_local.id == id) then block_local;
    case (_ :: blocks_local) then lookupId(blocks_local, id);
    //else listHead(blocks);
  end match;
end lookupId;

protected
import SimCode;
import SimCodeFunction;
import DAE;
import List;

function getSuccessors
  input MidCode.Block block_;
  output list<Integer> neighbours;
protected
  Integer l0,l1;
  list<tuple<Integer,Integer>> switchList;
algorithm
  neighbours := match block_.terminator
  case MidCode.GOTO(l0) then {l0};
  case MidCode.BRANCH(_,l0,l1) then {l0,l1};
  case MidCode.CALL(_,_,_,_,l0) then {l0};
  case MidCode.RETURN() then {};
  case MidCode.SWITCH(_,switchList) then list(tupleSnd(x) for x in switchList);
  case MidCode.LONGJMP() then {};
  case MidCode.PUSHJMP(_,_,l0) then {l0};
  case MidCode.POPJMP(_,l0) then {l0};
  end match;
end getSuccessors;

function tupleSnd
  input tuple<Integer, Integer> t;
  output Integer i;
algorithm
  (_,i) := t;
end tupleSnd;

function isLongJmp
  input MidCode.Terminator t;
  output Boolean b;
algorithm
  b := match t
  case MidCode.LONGJMP() then true;
  else false;
  end match;
end isLongJmp;

function isPushJmp
  input MidCode.Terminator t;
  output Boolean b;
algorithm
  b := match t
  case MidCode.PUSHJMP(_,_,_) then true;
  else false;
  end match;
end isPushJmp;

function isPopJmp
  input MidCode.Terminator t;
  output Boolean b;
algorithm
  b := match t
  case MidCode.POPJMP(_,_) then true;
  else false;
  end match;
end isPopJmp;

annotation(__OpenModelica_Interface="backend");

end MidToMid;
