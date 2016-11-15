// name: eq10.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  constant Integer j;

  package P2
    package P
      constant Integer i = j;
    end P;
  end P2;
end A;

model B
  A a[3](j = {1, 2, 3});
  Real x[3], y[3];
equation
  x = a.P2.P.i .* y;
end B;

// Result:
// Error processing file: eq10.mo
// [flattening/modelica/scodeinst/eq10.mo:21:3-21:20:writable] Error: Lookup of element P2 is not allowed via component a when looking for a.P2.P.i (only function calls may be looked up via a component).
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
