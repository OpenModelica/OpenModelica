// name: FunctionUnitialized3
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model FunctionUnitialized3
  Real y = f(time);

  function f
    input Real x;
    output Real y;
  end f;
end FunctionUnitialized3;

// Result:
// Error processing file: FunctionUnitialized3.mo
// [flattening/modelica/scodeinst/FunctionUnitialized3.mo:13:5-13:18:writable] Error: Output parameter y was not assigned a value
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
