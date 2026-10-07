// name: GreaterThanEqual
// keywords: logic, operator
// status: correct
//
// tests the GreaterThanEqual operator (>=)
//

model GreaterThanEqual
  constant Boolean b1 = 7 >= 5;
  constant Boolean b2 = 7 >= 7;
  constant Boolean b3 = 5 >= 7;
end GreaterThanEqual;

// Result:
// class GreaterThanEqual
//   constant Boolean b1 = true;
//   constant Boolean b2 = true;
//   constant Boolean b3 = false;
// end GreaterThanEqual;
// endResult
