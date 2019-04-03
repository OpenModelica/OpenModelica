// name: loop1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//


model A
  constant Integer b = a;
  constant Integer a = i;
  constant Integer i = j;
  constant Integer x[i];
  constant Integer j = size(x, 1);
end A;

// Result:
// Error processing file: loop1.mo
// [flattening/modelica/scodeinst/loop1.mo:13:3-13:24:writable] Error: Dimension 1 of x, 'i', could not be evaluated due to a cyclic dependency.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
