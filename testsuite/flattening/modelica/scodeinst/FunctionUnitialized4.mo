// name: FunctionUnitialized4
// keywords:
// status: correct
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
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:13:3-15:8:writable] Notification: From here:
// [flattening/modelica/scodeinst/FunctionUnitialized4.mo:10:5-10:18:writable] Warning: Output parameter y was not assigned a value
//
// endResult
