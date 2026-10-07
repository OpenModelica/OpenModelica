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
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:9:3-9:18:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:10:3-10:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:11:3-11:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:12:3-12:10:writable] Warning: Components are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:19:3-19:15:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/algorithms-functions/WhenStatement1.mo:14:3-17:11:writable] Warning: Algorithm sections are deprecated in class.
//
// endResult
