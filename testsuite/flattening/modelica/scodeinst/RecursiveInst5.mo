// name: RecursiveInst5
// keywords:
// status: incorrect
//
// A conditional component is added and then removed if the condition is false
// (MLS 3.7, section 4.4.5), so the instance tree is infinite.
//

model RecursiveInst5
  extends M(i = 1);

  model N
    parameter Integer i;
    M m(i = i + 1) if i < 10;
  end N;

  model M
    parameter Integer i;
    N n(i = i + 1) if i < 10;
  end M;
end RecursiveInst5;

// Result:
// Error processing file: RecursiveInst5.mo
// [flattening/modelica/scodeinst/RecursiveInst5.mo:18:5-18:24:writable] Error: Recursion limit reached while instantiating 'n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.n.m.i'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
