// name: ArrayConstructorRecord1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

model ArrayConstructorRecord1
  parameter R r[3](x = {1, 2, 3});
  Real x[:] = {i.x for i in r};
end ArrayConstructorRecord1;

// Result:
// class ArrayConstructorRecord1
//   parameter Real r[1].x = 1.0;
//   parameter Real r[2].x = 2.0;
//   parameter Real r[3].x = 3.0;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 2.0, 3.0};
// end ArrayConstructorRecord1;
// endResult
