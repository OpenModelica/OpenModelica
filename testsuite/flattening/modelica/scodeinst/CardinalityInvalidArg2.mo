// name: CardinalityInvalidArg2
// keywords: cardinality
// status: incorrect
// cflags: -d=newInst
//
// Cardinality can only be applied to scalar connectors.
//

connector C
  Real e;
  flow Real f;
end C;

model A
  C c;
end A;

model CardinalityInvalidArg2
  A a1[2], a2[2];
equation
  connect(a1.c, a2.c);

  if cardinality(a1.c) == 0 then
  end if;
end CardinalityInvalidArg2;

// Result:
// Error processing file: CardinalityInvalidArg2.mo
// [flattening/modelica/scodeinst/CardinalityInvalidArg2.mo:23:3-24:9:writable] Error: Type mismatch for positional argument 1 in cardinality(=a1.c). The argument has type:
//   C[2]
// expected type:
//   connector
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
