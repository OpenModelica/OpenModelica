// name: LessThanEqual
// keywords: logic, operator
// status: correct
//
// tests the LessThanEqual operator (<=)
//

model LessThanEqual
  constant Boolean b1 = 5 <= 7;
  constant Boolean b2 = 5 <= 5;
  constant Boolean b3 = 7 <= 5;
end LessThanEqual;

// Result:
// class LessThanEqual
//   constant Boolean b1 = true;
//   constant Boolean b2 = true;
//   constant Boolean b3 = false;
// end LessThanEqual;
// endResult
