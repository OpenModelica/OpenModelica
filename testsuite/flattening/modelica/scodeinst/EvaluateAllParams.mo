// name: EvaluateAllParams
// keywords:
// status: correct
// cflags: -d=newInst,evaluateAllParameters
//

model EvaluateAllParams
  parameter Real p = 10;
  Real x;
equation
  x = time * p;
end EvaluateAllParams;

// Result:
// class EvaluateAllParams
//   parameter Real p = 10.0;
//   Real x;
// equation
//   x = time * 10.0;
// end EvaluateAllParams;
// endResult
