// name: Integer
// keywords: integer
// status: correct
//
// Tests the built-in integer function
//

model IntegerTest
  Real r;
equation
  r = integer(4.5);
end IntegerTest;

// Result:
// class IntegerTest
//   Real r;
// equation
//   r = 4.0;
// end IntegerTest;
// endResult
