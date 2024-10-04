// name: IntSub
// keywords: integer, subtraction
// status: correct
//
// tests Integer subtraction
//

model IntSub
  constant Integer i = 4711 - 1138;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end IntSub;

// Result:
// class IntSub
//   constant Integer i = 3573;
// end IntSub;
// endResult
