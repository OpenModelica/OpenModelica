// name: FuncBuiltinDerInvalid1
// keywords: der
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin der operator.
//

model FuncBuiltinDerInvalid1
  discrete Real x = 0;
  Real y = der(x);
equation
  when initial() then
    x = 1.0;
  end when;
end FuncBuiltinDerInvalid1;

// Result:
// Error processing file: FuncBuiltinDerInvalid1.mo
// [flattening/modelica/scodeinst/FuncBuiltinDerInvalid1.mo:11:3-11:18:writable] Error: Argument 'x' of der is not differentiable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
