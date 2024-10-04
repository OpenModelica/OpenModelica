// name: AssignConstant1
// keywords:
// status: incorrect
//

model AssignConstant1
  constant Real x = 2;
algorithm
  x := 3;
end AssignConstant1;

// Result:
// Error processing file: AssignConstant1.mo
// [flattening/modelica/scodeinst/AssignConstant1.mo:9:3-9:9:writable] Error: Trying to assign to constant component in x := 3.0
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
