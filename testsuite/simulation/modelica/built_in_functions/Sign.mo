// name: Sign
// keywords: sign
// status: correct
//
// Testing the built-in sign function in c code
//

model Sign
  Real r1, r2;
equation
  r1 = sign(time);
  r2 = sign(-time);
end Sign;

// class Sign
// Real r1;
// Real r2;
// equation
// r1 = 1.0;
// r2 = -1.0;
// end Sign;
