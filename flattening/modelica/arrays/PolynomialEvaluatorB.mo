// name:     PolynomialEvaluatorB
// keywords:
// status:   correct
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


class PolyEvaluate2
  Real p;
  PolynomialEvaluator polyeval(c = {1, 2, 3, 4}, x = time, y = p);

end PolyEvaluate2;


// Result:
// class PolyEvaluate2
//   Real p;
//   parameter Real polyeval.c[1] = 1.0;
//   parameter Real polyeval.c[2] = 2.0;
//   parameter Real polyeval.c[3] = 3.0;
//   parameter Real polyeval.c[4] = 4.0;
//   Real polyeval.x = time;
//   Real polyeval.y = p;
//   protected parameter Integer polyeval.n = 3;
//   protected Real polyeval.xpowers[1];
//   protected Real polyeval.xpowers[2];
//   protected Real polyeval.xpowers[3];
//   protected Real polyeval.xpowers[4];
// equation
//   polyeval.xpowers[1] = 1.0;
//   polyeval.xpowers[2] = polyeval.xpowers[1] * polyeval.x;
//   polyeval.xpowers[3] = polyeval.xpowers[2] * polyeval.x;
//   polyeval.xpowers[4] = polyeval.xpowers[3] * polyeval.x;
//   polyeval.y = polyeval.c[1] * polyeval.xpowers[4];
// end PolyEvaluate2;
// endResult
