// name: RecordBinding10
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  parameter Real x = 3;
  parameter Real[:] y = {1, 2, 3};
  parameter Real[size(y, 1)] z = {1, 2, 3};
end R;

model A
  parameter Real x = 3;
  parameter Real[:] y = {1};
end A;

model B
  replaceable record Data = R;
  final parameter Data data;
end B;

model RecordBinding10
  A a(x = b.data.x, y = b.data.y);
  B b;
end RecordBinding10;

// Result:
// class RecordBinding10
//   parameter Real a.x = b.data.x;
//   parameter Real a.y[1] = b.data.y[1];
//   parameter Real a.y[2] = b.data.y[2];
//   parameter Real a.y[3] = b.data.y[3];
//   final parameter Real b.data.x = 3.0;
//   final parameter Real b.data.y[1] = 1.0;
//   final parameter Real b.data.y[2] = 2.0;
//   final parameter Real b.data.y[3] = 3.0;
//   final parameter Real b.data.z[1] = 1.0;
//   final parameter Real b.data.z[2] = 2.0;
//   final parameter Real b.data.z[3] = 3.0;
// end RecordBinding10;
// endResult
