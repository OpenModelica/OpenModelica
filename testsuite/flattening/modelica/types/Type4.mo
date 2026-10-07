// name:     Type4
// keywords: type,declaration
// status:   correct
//
// Simple variable declarations.
//

model Type4
  Integer i = 17                "an integer";
  Real r = 18.0                 "a real value";
  String s = "hi"               "a string";
  Boolean b = false             "a boolean";
end Type4;

// Result:
// class Type4
//   Integer i = 17 "an integer";
//   Real r = 18.0 "a real value";
//   String s = "hi" "a string";
//   Boolean b = false "a boolean";
// end Type4;
// endResult
