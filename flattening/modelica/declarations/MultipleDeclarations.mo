// name:     MultipleDeclarations
// keywords: declaration, extends
// status:   incorrect
//
// Multiple declarations (through extends) must be identical.
//
model A
 parameter Integer n(min=1);
 Real x[n];
end A;

model B
 extends A;
 parameter Integer n(min=1);
end B;

model B2
 extends A;
 parameter Integer n(min=3);
end B2;

model test
  B b(n=1);
  B2 b2(n=1); // Error n in B2 and A is not identical
end test;

// Result:
// Error processing file: MultipleDeclarations.mo
// [flattening/modelica/declarations/MultipleDeclarations.mo:19:2-19:28:writable] Notification: From here:
// [flattening/modelica/declarations/MultipleDeclarations.mo:8:2-8:28:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  parameter Integer n(min = 3)
//   second element is: parameter .Integer n(min = 1)
// Error: Error occurred while flattening model test
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
