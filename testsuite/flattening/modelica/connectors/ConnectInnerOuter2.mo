// name:     ConnectInnerOuter2
// keywords: connect inner outer
// status:   correct
//
// Connect to inner outer references


connector Pin
  flow Real i;
  Real v;
end Pin;

model Resistor
  Pin p;
  Pin n;
end Resistor;

model A
  outer Resistor world;
  Pin aPin;
equation
  connect(world.p,aPin);
end A;

model Top
  inner Resistor world;
  Pin topPin;
  A a1,a2;
equation
  connect(world.p,topPin);
end Top;

// Result:
// class Top
//   Real world.p.i;
//   Real world.p.v;
//   Real world.n.i;
//   Real world.n.v;
//   Real topPin.i;
//   Real topPin.v;
//   Real a1.aPin.i;
//   Real a1.aPin.v;
//   Real a2.aPin.i;
//   Real a2.aPin.v;
// equation
//   world.p.v = topPin.v;
//   world.p.v = a2.aPin.v;
//   world.p.v = a1.aPin.v;
//   world.p.i - topPin.i - a2.aPin.i - a1.aPin.i = 0.0;
//   world.n.i = 0.0;
//   topPin.i = 0.0;
//   a1.aPin.i = 0.0;
//   a2.aPin.i = 0.0;
// end Top;
// endResult
