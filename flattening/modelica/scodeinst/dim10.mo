// name: dim10.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model M
  Real x[:, :] = {{1, 2, 3}, {1, 2, 3}};
end M;

// Result:
// class M
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
// equation
//   x = {{1.0, 2.0, 3.0}, {1.0, 2.0, 3.0}};
// end M;
// endResult
