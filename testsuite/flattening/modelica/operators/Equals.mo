// name: Equals
// keywords: logic, operator
// status: correct
//
// tests the Equals operator(==)
//

model Equals
  constant Boolean b1 = 5 == 5;
  constant Boolean b2 = 5 == 7;
end Equals;

// Result:
// class Equals
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end Equals;
// endResult
