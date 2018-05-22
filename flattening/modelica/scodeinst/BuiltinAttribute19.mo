// name: BuiltinAttribute19
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  Real x[3](start = {1, 2, 3});
end A;

model BuiltinAttribute19
  A a[2];
end BuiltinAttribute19;

// Result:
// class BuiltinAttribute19
//   Real a[1].x[1](start = 1.0);
//   Real a[1].x[2](start = 2.0);
//   Real a[1].x[3](start = 3.0);
//   Real a[2].x[1](start = 1.0);
//   Real a[2].x[2](start = 2.0);
//   Real a[2].x[3](start = 3.0);
// end BuiltinAttribute19;
// endResult
