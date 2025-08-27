// name: RecordBinding18
// keywords:
// status: correct
//

record R
  Real im;
  Real re;
end R;

function f
  input Real x;
  input Real y;
  output R r;
algorithm
  r := R(x, y);
end f;

model RecordBinding18
  parameter Real x = 1;
  final parameter R r = f(0, atan(1/x));
end RecordBinding18;

// Result:
// class RecordBinding18
//   parameter Real x = 1.0;
//   final parameter Real r.im = 0.0;
//   final parameter Real r.re = atan(1.0 / x);
// end RecordBinding18;
// endResult
