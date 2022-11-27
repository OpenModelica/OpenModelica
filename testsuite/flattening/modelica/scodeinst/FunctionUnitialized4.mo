// name: FunctionUnitialized4
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

model FunctionUnitialized4
  partial function pf
    input Real x;
    output Real y;
  end pf;

  function f
    extends pf;
  end f;

  Real x = f(time);
end FunctionUnitialized4;

// Result:
// Error processing file: FunctionUnitialized4.mo
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:14:3-16:8:writable] Notification: From here:
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:11:5-11:18:writable] Error: Output parameter y was not assigned a value
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
