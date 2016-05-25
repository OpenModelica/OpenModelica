// name: usertype2.mo
// keywords:
// status: correct
// cflags: -d=scodeInst
//

type MyReal = Real(start = 1.0);

model M
  MyReal x;
  Real y(start = 1.0);
end M;
