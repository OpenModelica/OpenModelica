// name:     WhenStatement1
// keywords: when
// status:   correct
//
//
//

class WhenStat
  Real x(start=1);
  Real y1;
  parameter Real y2 = 5;
  Real y3;
algorithm
  when x > 2 then
    y1 := sin(x);
    y3 := 2*x + pre(y1) + y2;
  end when;
equation
  der(x) = 2*x;
end WhenStat;


// Result:
// class WhenStat
//   Real x(start = 1.0);
//   Real y1;
//   parameter Real y2 = 5.0;
//   Real y3;
// equation
//   der(x) = 2.0 * x;
// algorithm
//   when x > 2.0 then
//     y1 := sin(x);
//     y3 := 2.0 * x + pre(y1) + y2;
//   end when;
// end WhenStat;
// endResult
