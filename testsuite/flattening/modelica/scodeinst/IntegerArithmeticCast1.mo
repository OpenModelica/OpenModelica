// name: IntegerArithmeticCast1
// keywords:
// status: correct
//
// Integer arithmetic in a Real context is done on the operands cast to Real,
// so a result too large for an Integer keeps its value.
//

model IntegerArithmeticCast1
  parameter Integer n = 2000;
  Integer i = 3;
  Real c = 2100000 * 2000;
  parameter Real p = 2100000 * n - 1;
  Real q = i * i + 1;
  Real r[2] = 2 * {i, 2100000} .* {1, n};
  Integer m = i * i;
end IntegerArithmeticCast1;

// Result:
// class IntegerArithmeticCast1
//   parameter Integer n = 2000;
//   Integer i = 3;
//   Real c = 4.2e9;
//   parameter Real p = 2.1e6 * /*Real*/(n) - 1.0;
//   Real q = /*Real*/(i) * /*Real*/(i) + 1.0;
//   Real r[1];
//   Real r[2];
//   Integer m = i * i;
// equation
//   r = {2.0 * /*Real*/(i), 4.2e6 * /*Real*/(n)};
// end IntegerArithmeticCast1;
// endResult
