// name:     Type6
// keywords: type,declaration
// status:   correct
//
// Simple variable declarations, take two.
//

model Type6
  parameter Integer i(fixed = false)             "an integer";
  parameter Real r(fixed = false)                "a real value";
  parameter String s(fixed = false)              "a string";
  parameter Boolean b(fixed = false)             "a boolean";
end Type6;

// Result:
// class Type6
//   parameter Integer i(fixed = false) "an integer";
//   parameter Real r(fixed = false) "a real value";
//   parameter String s "a string";
//   parameter Boolean b(fixed = false) "a boolean";
// end Type6;
// endResult
