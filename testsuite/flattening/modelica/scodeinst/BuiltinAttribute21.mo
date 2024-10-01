// name: BuiltinAttribute21
// keywords:
// status: correct
//

model BuiltinAttribute21
  parameter Real x[3](each fixed = false);
  Real y[3](start = x);
end BuiltinAttribute21;

// Result:
// class BuiltinAttribute21
//   parameter Real x[1](fixed = false);
//   parameter Real x[2](fixed = false);
//   parameter Real x[3](fixed = false);
//   Real y[1](start = x[1]);
//   Real y[2](start = x[2]);
//   Real y[3](start = x[3]);
// end BuiltinAttribute21;
// endResult
