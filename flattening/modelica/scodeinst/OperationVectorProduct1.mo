// name: OperationVectorProduct1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationVectorProduct1
  Real[3] x, y;
  Real z;
equation
  z = x * y;
end OperationVectorProduct1;

// Result:
// class OperationVectorProduct1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real z;
// equation
//   z = x * y;
// end OperationVectorProduct1;
// endResult
