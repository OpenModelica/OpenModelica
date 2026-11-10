// name: And
// keywords: logic, operator
// status: correct
//
// tests the And operator(and)
//

model And
  constant Boolean b1 = true and true;
  constant Boolean b2 = true and false;
  constant Boolean b3 = false and true;
  constant Boolean b4 = false and false;
end And;

// Result:
// class And
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
//   constant Boolean b3 = false;
//   constant Boolean b4 = false;
// end And;
// endResult
