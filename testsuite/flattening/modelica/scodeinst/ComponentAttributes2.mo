// name: ComponentAttributes2
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  input Real x;
end A;

model ComponentAttributes2
  input A a;
end ComponentAttributes2;

// Result:
// Error processing file: ComponentAttributes2.mo
// [flattening/modelica/scodeinst/ComponentAttributes2.mo:8:3-8:15:writable] Error: Invalid type prefix 'input' on component x, due to existing type prefix 'input'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
