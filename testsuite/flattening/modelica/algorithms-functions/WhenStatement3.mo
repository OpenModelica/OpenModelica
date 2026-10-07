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
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:9:3-9:20:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:10:3-10:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:11:3-11:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:12:3-12:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:28:3-28:15:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement3.mo:15:3-17:11:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
