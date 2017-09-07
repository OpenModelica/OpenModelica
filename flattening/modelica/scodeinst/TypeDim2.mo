// name: TypeDim2
// keywords:
// status: correct
// cflags: -d=newInst
//

model TypeDim2
  type Reals = Real[3];
  type Reals2 = Reals[2];
  Reals2 x[1];
end TypeDim2;

// Result:
// class TypeDim2
//   Real x[1,1,1];
//   Real x[1,1,2];
//   Real x[1,1,3];
//   Real x[1,2,1];
//   Real x[1,2,2];
//   Real x[1,2,3];
// end TypeDim2;
// endResult
