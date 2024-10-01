// name: FuncInnerParam
// keywords:
// status: incorrect
//
// Checks that inner is not a valid function parameter prefix.
//

model FuncInnerParam
  function f
    inner input Real x;
    output Real y;
  algorithm
    y := x;
  end f;

  Real x = f(x);
end FuncInnerParam;

// Result:
// Error processing file: FuncInnerParam.mo
// [flattening/modelica/scodeinst/FuncInnerParam.mo:10:5-10:23:writable] Error: Invalid prefix inner on formal parameter x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
