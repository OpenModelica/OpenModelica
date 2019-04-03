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
end Type6;

// Result:
// class Type6
//   parameter Integer i "an integer";
//   parameter Real r "a real value";
//   parameter String s "a string";
//   parameter Boolean b "a boolean";
// end Type6;
// endResult
