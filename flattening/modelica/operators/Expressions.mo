// name: Expressions
// keywords: expression, integer, add, subtract, multiply, divide, power
// status: correct
//
// tests the basic math operators
//

model Expressions
  constant Real r1 = 1 + 2;
  constant Real r2 = 3 - 4;
  constant Real r3 = 5 * 6;
  constant Real r4 = 7 / 8;
  Real r;
equation
  r = 2 ^ 3;
end Expressions;

// Result:
// class Expressions
//   constant Real r1 = 3.0;
//   constant Real r2 = -1.0;
//   constant Real r3 = 30.0;
//   constant Real r4 = 0.875;
//   Real r;
// equation
//   r = 8.0;
// end Expressions;
// endResult
