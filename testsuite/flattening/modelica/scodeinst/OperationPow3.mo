// name: OperationPow3
// keywords:
// status: incorrect
//

model OperationPow3
  Integer i1;
  Real[2, 2] r1, r2;
equation
  r1 = r2 ^ (-1);
end OperationPow3;

// Result:
// Error processing file: OperationPow3.mo
// [flattening/modelica/scodeinst/OperationPow3.mo:10:3-10:17:writable] Error: Cannot resolve type of expression r2 ^ (-1). The operands have types Real[2, 2], Integer in component <NO_COMPONENT>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
