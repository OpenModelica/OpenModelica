// name:     ConditionalArrayExpression1
// keywords: equation, array
// status:   incorrect
//
// The sizes must fit in array expressions and equations.
//

model ConditionalArrayExpression1
  Real a=1, b=2, c[2], d, e;
equation
  0 = if a > b then c else [d; e];
end ConditionalArrayExpression1;

// Result:
// Error processing file: ConditionalArrayExpression1.mo
// [flattening/modelica/equations/ConditionalArrayExpression1.mo:11:3-11:34:writable] Error: Type mismatch in if-expression in component <NO COMPONENT>. True branch: {c[1], c[2]} has type Real[2], false branch: {{d}, {e}} has type Real[2, 1].
// Error: Error occurred while flattening model ConditionalArrayExpression1
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
