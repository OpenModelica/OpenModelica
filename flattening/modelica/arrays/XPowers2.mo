// name:     Xpowers2
// keywords: equation,array
// status:   correct
//
// <decription>
//
// Drmodelica: 8.2 XPowers (p. 242)
//
model Xpowers2
  parameter Real x=10;
  Real xpowers[n];
  parameter Integer i=1;
  parameter Integer n = 5;
equation
  xpowers[1]=1;
    for i in 1:n-1 loop
  xpowers[i + 1] = xpowers[i]*x;
  end for;
end Xpowers2;

// Result:
// class Xpowers2
// parameter Real x = 10.0;
// Real xpowers[1];
// Real xpowers[2];
// Real xpowers[3];
// Real xpowers[4];
// Real xpowers[5];
// parameter Integer i = 1;
// parameter Integer n = 5;
// equation
//   xpowers[1] = 1.0;
//   xpowers[2] = xpowers[1] * x;
//   xpowers[3] = xpowers[2] * x;
//   xpowers[4] = xpowers[3] * x;
//   xpowers[5] = xpowers[4] * x;
// end Xpowers2;
// endResult
