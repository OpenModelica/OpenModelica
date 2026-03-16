// name:     BreakComponentInvalid3
// keywords: modification break
// status:   incorrect
//

package P
  parameter Real x = 0;
end P;

model A
  import P.x;
end A;

model BreakComponentInvalid3
  extends A(break x);
end BreakComponentInvalid3;

// Result:
// Error processing file: BreakComponentInvalid3.mo
// [flattening/modelica/modification/BreakComponentInvalid3.mo:15:13-15:20:writable] Error: Modified element x not found in class A.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
