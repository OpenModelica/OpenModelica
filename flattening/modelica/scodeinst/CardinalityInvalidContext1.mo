// name: CardinalityInvalidContext1
// keywords: cardinality
// status: incorrect
// cflags: -d=newInst
//
// Cardinality may only be used in the conditions of if-statements/equations and
// asserts.
//

connector C
  Real e;
  flow Real f;
end C;

model CardinalityInvalidContext1
  C c;
  Integer n = cardinality(c);
end CardinalityInvalidContext1;

// Result:
// Error processing file: CardinalityInvalidContext1.mo
// [flattening/modelica/scodeinst/CardinalityInvalidContext1.mo:17:3-17:29:writable] Error: cardinality may only be used in the condition of an if-statement/equation or an assert.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
