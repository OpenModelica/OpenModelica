// name:     SimplifyAbs
// keywords: simplify #2517
// status:   correct
//


model SimplifyAbs
  Real a, b;
equation
  a = abs(a-b)/abs(b);
  a = abs(a-b)*abs(b);
end SimplifyAbs;

// Result:
// class SimplifyAbs
//   Real a;
//   Real b;
// equation
//   a = abs((a - b) / b);
//   a = abs((a - b) * b);
// end SimplifyAbs;
// endResult
