// name: GreaterThan
// keywords: logic, operator
// status: correct
//
// tests the GreaterThan operator (<)
//

model GreaterThan
  constant Boolean b1 = 7 > 5;
  constant Boolean b2 = 5 > 7;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end GreaterThan;

// Result:
// class GreaterThan
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end GreaterThan;
// endResult
