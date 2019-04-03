// name:     FunctionDefaultArgsCycle
// keywords: functions, default arguments, #2640
// status:   incorrect
//
// Tests default arguments in functions where the values are cyclically
// dependent.
//

function f
  input Real x;
  input Real y = 2 * x + z;
  input Real z = x / y;
  output Real o;
algorithm
  o := x+y+z;
end f;

model FunctionDefaultArgsCycle
  Real x = f(4);
end FunctionDefaultArgsCycle;

// Result:
// Error processing file: FunctionDefaultArgsCycle.mo
// [flattening/modelica/algorithms-functions/FunctionDefaultArgsCycle.mo:19:3-19:16:writable] Error: The default value of y causes a cyclic dependency.
// Error: Error occurred while flattening model FunctionDefaultArgsCycle
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
