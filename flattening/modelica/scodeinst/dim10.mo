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
//   Real x[1,1] = 1.0;
//   Real x[1,2] = 2.0;
//   Real x[1,3] = 3.0;
//   Real x[2,1] = 1.0;
//   Real x[2,2] = 2.0;
//   Real x[2,3] = 3.0;
// end M;
// endResult
