// name:     Connect9
// keywords: connect
// status:   correct
//
// Testing of input/output flags
//

connector C1
  input Real x;
end C1;

connector C2
  output Real x;
end C2;

class Connect9
  C1 c1;
  C2 c2;
equation
  connect(c1,c2);
end Connect9;

// Result:
// class Connect9
//   input Real c1.x;
//   output Real c2.x;
// equation
//   c1.x = c2.x;
// end Connect9;
// endResult
