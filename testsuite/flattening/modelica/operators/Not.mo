// name: Not
// keywords: logic, operator
// status: correct
//
// tests the Not operator(not)
//

model Not
  constant Boolean b1 = not false;
  constant Boolean b2 = not true;
end Not;

// Result:
// class Not
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end Not;
// endResult
