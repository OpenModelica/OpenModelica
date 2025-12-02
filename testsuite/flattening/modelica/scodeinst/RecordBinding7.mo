// name: RecordBinding7
// keywords:
// status: correct
//

record R
  Real x;
  final constant Real y = x / 2.0;
  Real z;
end R;

model RecordBinding7
  constant R r = R(1.0, 3.0);
  constant Real x = r.x;
  constant Real y = r.y;
  constant Real z = r.z;
end RecordBinding7;

// Result:
// class RecordBinding7
//   constant Real r.x = 1.0;
//   final constant Real r.y = 0.5;
//   constant Real r.z = 3.0;
//   constant Real x = 1.0;
//   constant Real y = 0.5;
//   constant Real z = 3.0;
// end RecordBinding7;
// endResult
