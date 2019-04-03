// name: TypeDim1
// keywords:
// status: correct
// cflags: -d=newInst
//

model TypeDim1
  type Reals = Real[3];
  Reals x[2];
end TypeDim1;

// Result:
// class TypeDim1
//   Real x[1,1];
//   Real x[1,2];
//   Real x[1,3];
//   Real x[2,1];
//   Real x[2,2];
//   Real x[2,3];
// end TypeDim1;
// endResult
