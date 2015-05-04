// name:     Xpowers3
// keywords: equation,array
// status:   correct
//
// <decription>
//
// Drmodelica: 8.2 XPowers (p. 242)
//
model Xpowers3
  parameter Real x=10;
  Real xpowers[n+1];
  parameter Integer n = 5;
equation
  xpowers[1]=1;
  xpowers[2:n+1] = xpowers[1:n]*x;
end Xpowers3;


// Result:
// class Xpowers3
//   parameter Real x = 10.0;
//   Real xpowers[1];
//   Real xpowers[2];
//   Real xpowers[3];
//   Real xpowers[4];
//   Real xpowers[5];
//   Real xpowers[6];
//   parameter Integer n = 5;
// equation
//   xpowers[1] = 1.0;
//   xpowers[2] = xpowers[1] * x;
//   xpowers[3] = xpowers[2] * x;
//   xpowers[4] = xpowers[3] * x;
//   xpowers[5] = xpowers[4] * x;
//   xpowers[6] = xpowers[5] * x;
// end Xpowers3;
// endResult
