// name: FunctionUnitialized4
// keywords:
// status: correct
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
// function FunctionUnitialized4.f
//   input Real x;
//   output Real y;
// end FunctionUnitialized4.f;
//
// class FunctionUnitialized4
//   Real x = FunctionUnitialized4.f(time);
// end FunctionUnitialized4;
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:14:3-16:8:writable] Notification: From here:
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:11:5-11:18:writable] Warning: Output parameter y was not assigned a value
//
// endResult
