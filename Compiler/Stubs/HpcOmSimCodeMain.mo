encapsulated package HpcOmSimCodeMain

function getSimCodeEqByIndexAndMapping<T>
  input array<Option<T>> iSimEqIdxSimEqMapping; //All SimEqSystems
  input Integer iIdx; //The index of the required system
  output T oSimEqSystem;
algorithm
  assert(false, getInstanceName());
end getSimCodeEqByIndexAndMapping;

function getSimCodeEqByIndex<T>
  input list<T> iEqs;
  input Integer iIdx;
  output T oEq;
algorithm
  assert(false, getInstanceName());
end getSimCodeEqByIndex;

annotation(__OpenModelica_Interface="backend");
end HpcOmSimCodeMain;
