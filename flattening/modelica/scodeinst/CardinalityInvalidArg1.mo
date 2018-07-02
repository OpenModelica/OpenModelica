// name: CardinalityInvalidArg1
// keywords: cardinality
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin cardinality operator.
//

model CardinalityInvalidArg1
  connector C
    Real e;
    flow Real f;
  end C;

  Integer r1 = cardinality(C);
end CardinalityInvalidArg1;

// Result:
// Error processing file: CardinalityInvalidArg1.mo
// [flattening/modelica/scodeinst/CardinalityInvalidArg1.mo:15:3-15:30:writable] Error: Expected C to be a component, but found class instead.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
