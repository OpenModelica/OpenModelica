// name: FunctionUnitialized6
// keywords:
// status: correct
//
//

record R
  Real x[3];
end R;

function f
  input Real x;
  output R r;
algorithm
  r.x[1] := x;
end f;

model FunctionUnitialized6
  constant R r = f(1.0);
end FunctionUnitialized6;

// Result:
// class FunctionUnitialized6
//   constant Real r.x[1] = 0.0;
//   constant Real r.x[2] = 0.0;
//   constant Real r.x[3] = 0.0;
// end FunctionUnitialized6;
// [flattening/modelica/scodeinst/FunctionUnitialized6.mo:13:3-13:13:writable] Warning: Output parameter r.x[2] was not assigned a value
//
// endResult
