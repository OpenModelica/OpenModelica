// name: AssignParameter1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model AssignParameter1
  parameter Real x = 2;
algorithm
  x := 3;
end AssignParameter1;

// Result:
// Error processing file: AssignParameter1.mo
// [flattening/modelica/scodeinst/AssignParameter1.mo:10:3-10:9:writable] Error: Trying to assign to parameter component in x := 3.0
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
