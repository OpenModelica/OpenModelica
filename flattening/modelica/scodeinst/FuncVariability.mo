// name: FuncVariability
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that variability is checked on function parameters.
//

function f
  parameter input Real x;
  output Real y = x;
end f;

model FuncVariability
  Real x = f(time);
end FuncVariability;

// Result:
// Error processing file: FuncVariability.mo
// [flattening/modelica/scodeinst/FuncVariability.mo:15:3-15:19:writable] Error: Function argument x=time in call to f has variability continuous which is not a parameter expression.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
