// name: FuncBuiltinDerInvalid2
// keywords: der
// status: incorrect
// cflags: -d=newInst
//
// Tests the builtin der operator.
//

model FuncBuiltinDerInvalid2
  Integer x = 0;
  Real y = der(x);
equation
  when initial() then
    x = 1;
  end when;
end FuncBuiltinDerInvalid2;

// Result:
// Error processing file: FuncBuiltinDerInvalid2.mo
// [flattening/modelica/scodeinst/FuncBuiltinDerInvalid2.mo:11:3-11:18:writable] Error: Argument 'x' of der is not differentiable.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
