// name: Enum12
// status: incorrect

model Enum12
  type E1 = enumeration(A);
  type E2 = enumeration(A,B);
  E1 e = E2.B;
end Enum12;

// Result:
// Error processing file: Enum12.mo
// [flattening/modelica/enums/Enum12.mo:7:3-7:14:writable] Error: Type mismatch in binding e = Enum12.E2.B, expected subtype of enumeration(A), got type enumeration(A, B).
// Error: Error occurred while flattening model Enum12
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
