// name: AssignInput1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f
  input Real x;
  output Real y;
algorithm
  x := x + 1;
  y := x;
end f;

model AssignInput1
  constant Real x = f(2);
end AssignInput1;

// Result:
// Error processing file: AssignInput1.mo
// [flattening/modelica/scodeinst/AssignInput1.mo:11:3-11:13:writable] Error: Trying to assign to input component x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
