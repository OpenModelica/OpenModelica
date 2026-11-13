// name: Or
// keywords: logic, operator
// status: correct
//
// tests the or operator(or)
//

model Or
  constant Boolean b1 = true or true;
  constant Boolean b2 = true or false;
  constant Boolean b3 = false or true;
  constant Boolean b4 = false or false;
end Or;

// Result:
// class Or
//   constant Boolean b1 = true;
//   constant Boolean b2 = true;
//   constant Boolean b3 = true;
//   constant Boolean b4 = false;
// end Or;
// endResult
