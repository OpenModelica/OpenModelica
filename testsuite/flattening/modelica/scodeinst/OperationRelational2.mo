// name: OperationRelational2
// keywords:
// status: incorrect
//

model OperationRelational2
  Real r1, r2;
  Boolean b1;
equation
  b1 = r1 == r2;
end OperationRelational2;

// Result:
// Error processing file: OperationRelational2.mo
// [flattening/modelica/scodeinst/OperationRelational2.mo:10:3-10:16:writable] Error: In relation r1 == r2, == on Real operands is not allowed in non-function contexts. Use --allowNonStandardModelica=realEquality to ignore this error.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
