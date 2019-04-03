// name: CardinalityInvalidContext2
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

model CardinalityInvalidContext2
  C c;
  Integer n;
equation
  if time > 0 then
    n = cardinality(c);
  end if;
end CardinalityInvalidContext2;

// Result:
// Error processing file: CardinalityInvalidContext2.mo
// [flattening/modelica/scodeinst/CardinalityInvalidContext2.mo:20:5-20:23:writable] Error: cardinality may only be used in the condition of an if-statement/equation or an assert.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
