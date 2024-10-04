// name: IntAdd
// keywords: integer, addition
// status: correct
//
// tests Integer addition
//

model IntAdd
  constant Integer i = 4711 + 1138;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end IntAdd;

// Result:
// class IntAdd
//   constant Integer i = 5849;
// end IntAdd;
// endResult
