// name: ModifierVariable
// keywords: modifier
// status: correct
// cflags: -d=-newInst
//
// Tests modification of variables
//

model ModifierVariable
  parameter Real r1(start = 4711.0);
end ModifierVariable;

// Result:
// class ModifierVariable
//   parameter Real r1(start = 4711.0);
// end ModifierVariable;
// endResult
