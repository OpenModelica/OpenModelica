// name:     WhenStatement3
// keywords: when
// status:   correct
//
//
//

class WhenStat3
  Real x(start = 1);
  Real y1;
  Real y2;
  Real y3;

algorithm
  when x > 2 then
    y1 := sin(x);
  end when;

equation
  y2 = sin(y1);

algorithm
  when x > 2 then
    y3 := 2*x + pre(y1) + y2;
  end when;

equation
  der(x) = 2*x;

end WhenStat3;


// Result:
// class WhenStat3
//   Real x(start = 1.0);
//   Real y1;
//   Real y2;
//   Real y3;
// equation
//   der(x) = 2.0 * x;
//   y2 = sin(y1);
// algorithm
//   when x > 2.0 then
//     y1 := sin(x);
//   end when;
// algorithm
//   when x > 2.0 then
//     y3 := 2.0 * x + pre(y1) + y2;
//   end when;
// end WhenStat3;
// endResult
