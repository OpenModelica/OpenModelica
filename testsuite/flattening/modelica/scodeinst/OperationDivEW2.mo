// name: OperationDivEW2
// keywords:
// status: correct
//

model OperationDivEW2
  Integer i1;
  Integer i2[2];
  Integer i3[3, 3];
  Real r1;
  Real r2[2];
  Real r3[3, 3];
equation
  r1 = r1 ./ r1;
  r2 = r2 ./ r1;
  r3 = r3 ./ r1;
  r2 = i2 ./ i1;
  r3 = r3 ./ i3;
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end OperationDivEW2;

// Result:
// class OperationDivEW2
//   Integer i1;
//   Integer[2] i2;
//   Integer[3, 3] i3;
//   Real r1;
//   Real[2] r2;
//   Real[3, 3] r3;
// equation
//   r1 = r1 / r1;
//   r2 = r2 / r1;
//   r3 = r3 / r1;
//   r2 = /*Real[2]*/(i2) / /*Real*/(i1);
//   r3 = r3 ./ /*Real[3, 3]*/(i3);
// end OperationDivEW2;
// endResult
