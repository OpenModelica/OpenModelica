// name: func7.mo
// keywords:
// status: incorrect
// cflags:   -d=newInst
//

model A
  function f
    inner input Real x;
    output Real y;
  algorithm
    y := x;
  end f;

  Real x = f(x);
end A;

// Result:
// Error processing file: func7.mo
// [flattening/modelica/scodeinst/func7.mo:9:5-9:23:writable] Error: Invalid prefix inner on formal parameter x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
