// name: ConnectArrays2
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model ConnectArrays2
  connector InReal = input Real;
  connector OutReal = output Real;
  parameter Integer p = 3;
  InReal x[p];
  OutReal y[p+1];
equation
  connect(x,y[2:p+1]);
end ConnectArrays2;

// Result:
// class ConnectArrays2
//   parameter Integer p = 3;
//   input Real x[1];
//   input Real x[2];
//   input Real x[3];
//   output Real y[1];
//   output Real y[2];
//   output Real y[3];
//   output Real y[4];
// equation
//   x[1] = y[2];
//   x[2] = y[3];
//   x[3] = y[4];
// end ConnectArrays2;
// endResult
