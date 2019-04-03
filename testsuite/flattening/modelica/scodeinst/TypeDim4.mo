// name: TypeDim4
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Integer n = 3;
  type Reals = Real[n];
end P;

model TypeDim4
  package P2 = P(n = 1);
  package P3 = P(n = 2);
  P2.Reals x;
  P3.Reals y;
end TypeDim4;

// Result:
// class TypeDim4
//   Real x[1];
//   Real y[1];
//   Real y[2];
// end TypeDim4;
// endResult
