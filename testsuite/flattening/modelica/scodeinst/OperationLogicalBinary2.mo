// name: OperationLogicalBinary2
// keywords:
// status: correct
// cflags: -d=newInst
//

model OperationLogicalBinary2
  Boolean b1[:] = {false, false, true, true} or {true, false, true, false};
  Boolean b2[:] = {false, false, true, true} and {true, false, true, false};
end OperationLogicalBinary2;

// Result:
// class OperationLogicalBinary2
//   Boolean b1[1];
//   Boolean b1[2];
//   Boolean b1[3];
//   Boolean b1[4];
//   Boolean b2[1];
//   Boolean b2[2];
//   Boolean b2[3];
//   Boolean b2[4];
// equation
//   b1 = {true, false, true, true};
//   b2 = {false, false, true, false};
// end OperationLogicalBinary2;
// endResult
