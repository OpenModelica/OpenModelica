// name: const6.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//


model M
  constant Integer i = 3;
  constant Integer j = x;
  parameter Integer x = i;
end M;

// Result:
// Error processing file: const6.mo
// [flattening/modelica/scodeinst/const6.mo:11:3-11:25:writable] Error: Component j of variability constant has binding 'x' of higher variability parameter.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
