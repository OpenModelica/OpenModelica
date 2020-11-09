// name:     Connect3
// keywords: connect
// status:   incorrect
// cflags: -d=-newInst
//
// Only connector variables can be connected.

model Connect3
  Real e1,e2;
  flow Real f1,f2;
equation
  connect(e1,e2);
  connect(f1,f2);
end Connect3;
