// name: AssignModel1
// keywords:
// status: incorrect
//

model A
  Real x;
end A;

model AssignModel1
  A a1, a2;
algorithm
  a1 := a2;
end AssignModel1;

// Result:
// Error processing file: AssignModel1.mo
// [flattening/modelica/scodeinst/AssignModel1.mo:13:3-13:11:writable] Error: Component 'a1' may not be assigned to due to class specialization 'model'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
