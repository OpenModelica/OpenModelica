// name:     Type5
// keywords: type,declaration
// status:   correct
//
// Simple variable declarations.
//

type Voltage = Real(unit="V");

model Type5
  Voltage v;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Type5;

// Result:
// class Type5
//   Real v(unit = "V");
// end Type5;
// endResult
