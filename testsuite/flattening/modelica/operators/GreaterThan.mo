// name: GreaterThan
// keywords: logic, operator
// status: correct
//
// tests the GreaterThan operator (<)
//

model GreaterThan
  constant Boolean b1 = 7 > 5;
  constant Boolean b2 = 5 > 7;
end GreaterThan;

// Result:
// class GreaterThan
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end GreaterThan;
// endResult
