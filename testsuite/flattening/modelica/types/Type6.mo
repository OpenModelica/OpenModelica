// name:     Type6
// keywords: type,declaration
// status:   correct
//
// Simple variable declarations, take two.
//

model Type6
  parameter Integer i             "an integer";
  parameter Real r                "a real value";
  parameter String s              "a string";
  parameter Boolean b             "a boolean";
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Type6;

// Result:
// class Type6
//   parameter Integer i "an integer";
//   parameter Real r "a real value";
//   parameter String s "a string";
//   parameter Boolean b "a boolean";
// end Type6;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
