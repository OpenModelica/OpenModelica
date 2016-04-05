// name:     ConnectArrayCond
// keywords: connect conditional
// status:   correct
//
// Tests connecting deleted conditional array components.
//

connector C
  flow Real f;
  Real e;
end C;

model A
  C c;
end A;

model ConnectArrayCond
  C c1[2] if false;
equation
  connect(c1[1].c, c1[2].c);
end ConnectArrayCond;

// Result:
// class ConnectArrayCond
// end ConnectArrayCond;
// endResult
