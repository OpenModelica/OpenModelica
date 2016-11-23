// name: usertype3.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

type MyReal = Real;

model M
  MyReal x;
  MyReal y(start = 1.0);
  MyReal z(start = 2.0);
end M;

// Result:
// class M
//   Real x;
//   Real y(start = 1.0);
//   Real z(start = 2.0);
// end M;
// endResult
