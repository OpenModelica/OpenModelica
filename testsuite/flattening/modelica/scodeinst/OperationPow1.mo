// name: OperationPow1
// keywords: 
// status: correct
// cflags: -d=newInst
//

model OperationPow1
  Real r1, r2;
  Integer i1;
equation
  r1 = r1 ^ r2;
  r1 = r1 ^ i1;
end OperationPow1;

// Result:
// class OperationPow1
//   Real r1;
//   Real r2;
//   Integer i1;
// equation
//   r1 = r1 ^ r2;
//   r1 = r1 ^ /*Real*/(i1);
// end OperationPow1;
// endResult
