// name:     Connect10
// keywords: connect
// status:   incorrect
//
// Testing of input/output flags
//

connector C1
  input Real x;
end C1;

connector C2
  input Real x;
end C2;

class Connect10
  C1 c1;
  C2 c2;
equation
  connect(c1,c2);
end Connect10;
