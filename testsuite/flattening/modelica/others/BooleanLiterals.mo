// name: BooleanLiterals
// keywords: boolean
// status: correct
//
// Tests Boolean literals, true and false
//

model BooleanLiterals
  constant Boolean b1 = true;
  constant Boolean b2 = false;
  Boolean b;
equation
  b = true;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end BooleanLiterals;

// Result:
// class BooleanLiterals
//   constant Boolean b1 = true;
//   constant Boolean b2 = false;
//   Boolean b;
// equation
//   b = true;
// end BooleanLiterals;
// endResult
