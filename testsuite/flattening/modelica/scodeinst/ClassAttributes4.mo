// name: ClassAttributes4
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model ClassAttributes4
  type InputReal = input Real;
  output InputReal x;
end ClassAttributes4;

// Result:
// Error processing file: ClassAttributes4.mo
// [flattening/modelica/scodeinst/ClassAttributes4.mo:9:3-9:21:writable] Error: Invalid type prefix 'input' on component x, due to existing type prefix 'output'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
