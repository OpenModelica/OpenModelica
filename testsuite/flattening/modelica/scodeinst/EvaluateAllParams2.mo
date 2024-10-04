// name: EvaluateAllParams2
// keywords:
// status: correct
//

model EvaluateAllParams2
  parameter Real p(fixed = false);
  parameter Real q = 2*p;
  parameter Real r = 2;
initial equation
  p - r = 0;
  annotation(__OpenModelica_commandLineOptions="-d=evaluateAllParameters");
end EvaluateAllParams2;

// Result:
// class EvaluateAllParams2
//   parameter Real p(fixed = false);
//   parameter Real q = 2.0 * p;
//   final parameter Real r = 2.0;
// initial equation
//   p - 2.0 = 0.0;
// end EvaluateAllParams2;
// endResult
