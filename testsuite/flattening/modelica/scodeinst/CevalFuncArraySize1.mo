// name: CevalFuncArraySize1
// keywords:
// status: incorrect
//
// Constant evaluation of an element-wise operation on arrays of different
// sizes (#18477).
//

function f
  input Real a[:];
  input Real b[:];
  output Real y;
algorithm
  y := (a - b)[2];
end f;

model CevalFuncArraySize1
  constant Real x = f({1, 2}, {1, 2, 3});
end CevalFuncArraySize1;

// Result:
// Error processing file: CevalFuncArraySize1.mo
// [flattening/modelica/scodeinst/CevalFuncArraySize1.mo:14:3-14:18:writable] Error: Cannot resolve type of expression {1.0, 2.0} - {1.0, 2.0, 3.0}. The operands have types Real[2], Real[3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
