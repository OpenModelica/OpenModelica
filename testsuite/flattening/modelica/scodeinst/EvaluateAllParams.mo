// name: EvaluateAllParams
// keywords:
// status: correct
//

model EvaluateAllParams
  parameter Real p = 10;
  Real x;
equation
  x = time * p;
  annotation(__OpenModelica_commandLineOptions="-d=evaluateAllParameters");
end EvaluateAllParams;

// Result:
// class EvaluateAllParams
//   final parameter Real p = 10.0;
//   Real x;
// equation
//   x = time * 10.0;
// end EvaluateAllParams;
// endResult
