// name:     PolynomialEvaluatorA
// keywords:
// status:   correct
//
// Drmodelica: 8.2 Polynomial Evaluator (p. 242)
// cflags: -d=-newInst
//

block PolynomialEvaluator
  parameter Real c[:];
  input Real x;
  output Real y;
protected
  parameter Integer n = size(c, 1) - 1;
  Real xpowers[n + 1];
equation
  xpowers[1] = 1;
  for i in 1:n loop
    xpowers[i + 1] = xpowers[i]*x;
  end for;
  y = c[1] * xpowers[n + 1];
end PolynomialEvaluator;

class PolyEvaluate1
  Real p;
  PolynomialEvaluator polyeval(c = {1, 2, 3, 4});
equation
  polyeval.x = time;
  p = polyeval.y;              // p gets the result
end PolyEvaluate1;

// class PolyEvaluate1
// Real p;
// parameter Real polyeval.c[1] = 1;
// parameter Real polyeval.c[2] = 2;
// parameter Real polyeval.c[3] = 3;
// parameter Real polyeval.c[4] = 4;
// input Real polyeval.x;
// output Real polyeval.y;
// protected parameter Integer polyeval.n = 3;
// protected Real polyeval.xpowers[1];
// protected Real polyeval.xpowers[2];
// protected Real polyeval.xpowers[3];
// protected Real polyeval.xpowers[4];
// equation
//   polyeval.xpowers[1] = 1.0;
//   polyeval.xpowers[2] = polyeval.xpowers[1] * polyeval.x;
//   polyeval.xpowers[3] = polyeval.xpowers[2] * polyeval.x;
//   polyeval.xpowers[4] = polyeval.xpowers[3] * polyeval.x;
//   polyeval.y = polyeval.c[1] * polyeval.xpowers[4];
//   polyeval.x = time;
//   p = polyeval.y;
// end PolyEvaluate1;
