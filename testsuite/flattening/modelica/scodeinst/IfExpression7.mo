// name: IfExpression7
// keywords:
// status: incorrect
//

model IfExpression7
  parameter Boolean b = false;
  Real x[2] = if b then {1, 2} else {3, 4, 5};
end IfExpression7;

// Result:
// Error processing file: IfExpression7.mo
// [flattening/modelica/scodeinst/IfExpression7.mo:8:3-8:46:writable] Error: Array dimension mismatch, expression {3.0, 4.0, 5.0} has type Real[3], expected array dimensions [2].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
