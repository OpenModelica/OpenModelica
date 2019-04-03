// name: usertype2.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

type MyReal = Real(start = 1.0);

model M
  MyReal x;
  Real y(start = 1.0);
end M;

// Result:
// class M
//   Real x(start = 1.0);
//   Real y(start = 1.0);
// end M;
// endResult
