// name: FuncBuiltinSmoothArray
// keywords: smooth noEvent scalarize
// status: correct
//
// Checks that array equations with smooth and noEvent are scalarized, unless
// the argument contains a function call returning an array.
//

model FuncBuiltinSmoothArray
  function f
    input Real x[2];
    output Real y[2] = 2*x;
  end f;

  Real r[2] = {time, 2*time};
  Real e1[2], e2[2], e3[2], e4[2];
equation
  e1 = smooth(0, if r[1] > 0 then r else 2*r);
  e2 = noEvent(if r[1] > 0 then r else 2*r);
  e3 = smooth(1, noEvent(if r[1] > 0 then r else 2*r));
  e4 = smooth(0, f(r));
end FuncBuiltinSmoothArray;
// Result:
// function FuncBuiltinSmoothArray.f
//   input Real[2] x;
//   output Real[2] y = {2.0 * x[1], 2.0 * x[2]};
// end FuncBuiltinSmoothArray.f;
//
// class FuncBuiltinSmoothArray
//   Real r[1];
//   Real r[2];
//   Real e1[1];
//   Real e1[2];
//   Real e2[1];
//   Real e2[2];
//   Real e3[1];
//   Real e3[2];
//   Real e4[1];
//   Real e4[2];
// equation
//   r = {time, 2.0 * time};
//   e1[1] = smooth(0, if r[1] > 0.0 then r[1] else 2.0 * r[1]);
//   e1[2] = smooth(0, if r[1] > 0.0 then r[2] else 2.0 * r[2]);
//   e2[1] = noEvent(if r[1] > 0.0 then r[1] else 2.0 * r[1]);
//   e2[2] = noEvent(if r[1] > 0.0 then r[2] else 2.0 * r[2]);
//   e3[1] = smooth(1, noEvent(if r[1] > 0.0 then r[1] else 2.0 * r[1]));
//   e3[2] = smooth(1, noEvent(if r[1] > 0.0 then r[2] else 2.0 * r[2]));
//   e4 = smooth(0, FuncBuiltinSmoothArray.f(r));
// end FuncBuiltinSmoothArray;
// endResult
