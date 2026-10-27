// name: ModifierVariable
// keywords: modifier
// status: correct
//
// Tests modification of variables
//

model ModifierVariable
  parameter Real r1(start = 4711.0);
end ModifierVariable;

// Result:
// class ModifierVariable
//   parameter Real r1(start = 4711.0) = 4711.0;
// end ModifierVariable;
// [flattening/modelica/modification/ModifierVariable.mo:9:3-9:36:writable] Warning: Parameter r1 has no value, and is fixed during initialization (fixed=true), using available start value (start=4711.0) as default value.
//
// endResult
