// name:     RedeclareClass4
// keywords: class, extends
// status:   correct
//
// Tests redeclare in local class.
//

partial package PP end PP;

model A
  replaceable package P = PP;
end A;

model RedeclareClass4
  package P = PP;
  model M = A(redeclare package P = P);
  M m;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RedeclareClass4;

// Result:
// class RedeclareClass4
// end RedeclareClass4;
// endResult
