// name: LessThan
// keywords: logic, operator
// status: correct
//
// tests the LessThan operator (<)
//

model LessThan
  constant Boolean b1 = 5 < 7;
  constant Boolean b2 = 7 < 5;
end LessThan;

// Result:
// class LessThan
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end LessThan;
// endResult
