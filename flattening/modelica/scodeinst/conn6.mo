// name: conn6.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Connect equation not expanded.
//

model M
  connector InReal = input Real;
  connector OutReal = output Real;
  parameter Integer p = 3;
  InReal x[p];
  OutReal y[p+1];
equation
  connect(x,y[2:p+1]);
end M;
