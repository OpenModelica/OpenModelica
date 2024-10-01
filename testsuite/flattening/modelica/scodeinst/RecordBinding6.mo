// name: RecordBinding6
// keywords:
// status: correct
//

record R
  Real x;
  final constant Real y = 2.0;
  Real z;
end R;

model RecordBinding6
  constant R r = R(1.0, 3.0);
  constant Real x = r.x;
  constant Real y = r.y;
  constant Real z = r.z;
end RecordBinding6;

// Result:
// class RecordBinding6
//   constant Real r.x = 1.0;
//   final constant Real r.y = 2.0;
//   constant Real r.z = 3.0;
//   constant Real x = 1.0;
//   constant Real y = 2.0;
//   constant Real z = 3.0;
// end RecordBinding6;
// endResult
