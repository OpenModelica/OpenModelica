// name: RecordBinding4
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
  Real y;
end R;

model RecordBinding4
  parameter R r1;
  parameter R r2 = r1;
end RecordBinding4;

// Result:
// class RecordBinding4
//   parameter Real r1.x;
//   parameter Real r1.y;
//   parameter Real r2.x = r1.x;
//   parameter Real r2.y = r1.y;
// end RecordBinding4;
// endResult
