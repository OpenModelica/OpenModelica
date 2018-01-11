// name: BuiltinAttribute10
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x[2];
end A;

model BuiltinAttribute10
  Real x[3](start = {1, 2, 3});
  A a[3](x.start = {{1, 2}, {3, 4}, {5, 6}});
end BuiltinAttribute10;

// Result:
// class BuiltinAttribute10
//   Real x[1](start = 1.0);
//   Real x[2](start = 2.0);
//   Real x[3](start = 3.0);
//   Real a[1].x[1](start = 1.0);
//   Real a[1].x[2](start = 2.0);
//   Real a[2].x[1](start = 3.0);
//   Real a[2].x[2](start = 4.0);
//   Real a[3].x[1](start = 5.0);
//   Real a[3].x[2](start = 6.0);
// end BuiltinAttribute10;
// endResult
