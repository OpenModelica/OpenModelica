// name: IfExpression5
// keywords:
// status: incorrect
//

model IfExpression5
  Real x[2] = if time > 1 then {1, 2} else {3, 4, 5};
end IfExpression5;

// Result:
// Error processing file: IfExpression5.mo
// [flattening/modelica/scodeinst/IfExpression5.mo:7:3-7:53:writable] Error: Type mismatch in if-expression in component . True branch: {1.0, 2.0} has type Real[2], false branch: {3.0, 4.0, 5.0} has type Real[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
