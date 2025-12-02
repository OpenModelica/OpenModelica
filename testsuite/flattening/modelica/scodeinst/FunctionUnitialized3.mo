// name: FunctionUnitialized3
// keywords:
// status: correct
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
// function FunctionUnitialized3.f
//   input Real x;
//   output Real y;
// end FunctionUnitialized3.f;
//
// class FunctionUnitialized3
//   Real y = FunctionUnitialized3.f(time);
// end FunctionUnitialized3;
// [flattening/modelica/scodeinst/FunctionUnitialized3.mo:12:5-12:18:writable] Warning: Output parameter y was not assigned a value
//
// endResult
