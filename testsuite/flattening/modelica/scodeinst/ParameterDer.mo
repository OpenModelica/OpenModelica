// name: ParameterDer
// keywords: der
// status: correct
// cflags: -d=newInst
//
// Tests the builtin der operator.
//

model ParameterDer
  parameter Real p;
  Real x;
equation
  der(p) = x;
end ParameterDer;

// Result:
// class ParameterDer
//   parameter Real p;
//   Real x;
// equation
//   0.0 = x;
// end ParameterDer;
// endResult
