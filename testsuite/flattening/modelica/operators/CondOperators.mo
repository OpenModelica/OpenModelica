// name: CondOperators
// keywords: conditional operators, boolean
// status: correct
//
// Tests conditional operators
//

model CondOperators
  constant Boolean b1 = 1 < 2;
  constant Boolean b2 = 3 <= 2;
  constant Boolean b3 = 4 > 3;
  constant Boolean b4 = 4 >= 5;
  constant Boolean b5 = 6 == 6;
  constant Boolean b6 = 7 <> 7;
  constant Boolean b7 = not false;
  constant Boolean b8 = true and false;
  constant Boolean b9 = true or false;
end CondOperators;

// Result:
// class CondOperators
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
//   constant Boolean b3 = true;
//   constant Boolean b4 = false;
//   constant Boolean b5 = true;
//   constant Boolean b6 = false;
//   constant Boolean b7 = true;
//   constant Boolean b8 = false;
//   constant Boolean b9 = true;
// end CondOperators;
// endResult
