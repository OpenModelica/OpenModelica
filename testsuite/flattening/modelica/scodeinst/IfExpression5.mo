// name: IfExpression5
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model IfExpression5
  Real x[2] = if time > 1 then {1, 2} else {3, 4, 5};
end IfExpression5;

// Result:
// Error processing file: IfExpression5.mo
// [flattening/modelica/scodeinst/IfExpression5.mo:8:3-8:53:writable] Error: Type mismatch in if-expression in component . True branch: {1, 2} has type Integer[2], false branch: {3, 4, 5} has type Integer[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
