encapsulated package InstStateMachineUtil

import DAE;
type SMNodeToFlatSMGroupTable = Integer;

function getSMStatesInContext<A,B>
  input A eqns;
  input B inPrefix;
  output list<DAE.ComponentRef> states = {};
  output list<DAE.ComponentRef> initialStates = {};
end getSMStatesInContext;

function createSMNodeToFlatSMGroupTable<A>
  input A inDae;
  output SMNodeToFlatSMGroupTable smNodeToFlatSMGroup = 0;
end createSMNodeToFlatSMGroupTable;

function wrapSMCompsInFlatSMs<A,B>
  input A inIH;
  input B inDae1;
  input B inDae2;
  input SMNodeToFlatSMGroupTable smNodeToFlatSMGroup;
  input list<DAE.ComponentRef> smInitialCrefs;
  output B outDae1 = inDae1;
  output B outDae2 = inDae2;
end wrapSMCompsInFlatSMs;

annotation(__OpenModelica_Interface="frontend");
end InstStateMachineUtil;
