// name: ParameterDer
// keywords: der
// status: correct
//
// Tests the builtin der operator.
//

model ParameterDer
  parameter Real p = 0;
  Real x;
equation
  der(p) = x;
end ParameterDer;

// Result:
// class ParameterDer
//   parameter Real p = 0.0;
//   Real x;
// equation
//   0.0 = x;
// end ParameterDer;
// endResult
