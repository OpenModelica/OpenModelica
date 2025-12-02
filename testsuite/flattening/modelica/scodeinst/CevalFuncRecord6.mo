// name: CevalFuncRecord6
// keywords:
// status: correct
//
//

record R
  Real x;
  Real y;
end R;

function f
  input R r[:];
  output Real res[size(r, 1)];
algorithm
  for i in 1:size(r, 1) loop
    res[i] := r[i].x;
  end for;
end f;

model CevalFuncRecord6
  constant R r[:] = {R(1.0, 2.0), R(3.0, 4.0)};
  constant Real x[:] = f(r);
end CevalFuncRecord6;

// Result:
// class CevalFuncRecord6
//   constant Real r[1].x = 1.0;
//   constant Real r[1].y = 2.0;
//   constant Real r[2].x = 3.0;
//   constant Real r[2].y = 4.0;
//   constant Real x[1] = 1.0;
//   constant Real x[2] = 3.0;
// end CevalFuncRecord6;
// endResult
