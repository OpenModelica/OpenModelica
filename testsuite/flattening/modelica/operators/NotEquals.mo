// name: NotEquals
// keywords: logic, operator
// status: correct
//
// tests the NotEquals operator(<>)
//

model NotEquals
  constant Boolean b1 = 5 <> 7;
  constant Boolean b2 = 5 <> 5;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end NotEquals;

// Result:
// class NotEquals
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
// end NotEquals;
// endResult
