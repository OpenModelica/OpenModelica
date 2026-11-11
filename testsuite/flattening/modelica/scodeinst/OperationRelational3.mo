// name: OperationRelational3
// keywords:
// status: incorrect
//

model OperationRelational3
  Real r1, r2;
  Boolean b1;
equation
  b1 = r1 <> r2;
end OperationRelational3;

// Result:
// Error processing file: OperationRelational3.mo
// [flattening/modelica/scodeinst/OperationRelational3.mo:10:3-10:16:writable] Error: In relation r1 <> r2, <> on Real operands is not allowed in non-function contexts. Use --allowNonStandardModelica=realEquality to ignore this error.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
