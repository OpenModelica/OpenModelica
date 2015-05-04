// name:     WhenStatement2
// keywords: when
// status:   correct
//
//
// Drmodelica: 9.1 When-Statements (p. 293)
//

class WhenStat2
  Real x(start = 1);
  Real y1;
  parameter Real y2 = 5;
  Real y3;
algorithm
  when {x > 2, sample(0, 2), x < 5} then
    y1 := sin(x);
    y3 := 2*x + y1 + y2;
  end when;
equation
  der(x) = 2*x;
end WhenStat2;


// class WhenStat2
// Real x(start = 1.0);
// Real y1;
// parameter Real y2 = 5;
// Real y3;
// equation
//  der(x) = 2.0 * x;
// algorithm
//  when {x > 2.0,sample(0,2),x < 5.0} then
//   y1 := sin(x);
//   y3 := 2.0 * x + y1 + y2;
//  end when;
// end WhenStat2;
