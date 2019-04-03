// name: TypeDim3
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Integer n = 3;
  type Reals = Real[n];
end P;

model TypeDim3
  P.Reals x;
end TypeDim3;

// Result:
// class TypeDim3
//   Real x[1];
//   Real x[2];
//   Real x[3];
// end TypeDim3;
// endResult
