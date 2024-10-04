// name: IntMul
// keywords: integer, multiplication
// status: correct
//
// tests Integer multiplication
//

model IntMul
  constant Integer i = 4711 * 1138;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end IntMul;

// Result:
// class IntMul
//   constant Integer i = 5361118;
// end IntMul;
// endResult
