// name:     ConnectInnerOuter
// keywords: connect inner outer
// status:   correct
//
// Connections to inner outer references


connector Pin
  flow Real i;
  Real v;
end Pin;

model A
  outer Pin world;
  Pin aPin;
equation
  connect(world,aPin);
end A;

model Top
  inner Pin world;
  Pin topPin;
  A a1,a2;
equation
  connect(world,topPin);
end Top;

// Result:
// class Top
//   Real world.i;
//   Real world.v;
//   Real topPin.i;
//   Real topPin.v;
//   Real a1.aPin.i;
//   Real a1.aPin.v;
//   Real a2.aPin.i;
//   Real a2.aPin.v;
// equation
//   world.i = 0.0;
//   topPin.i = 0.0;
//   a1.aPin.i = 0.0;
//   a2.aPin.i = 0.0;
//   (-world.i) + (-topPin.i) + (-a1.aPin.i) + (-a2.aPin.i) = 0.0;
//   a1.aPin.v = a2.aPin.v;
//   a1.aPin.v = topPin.v;
//   a1.aPin.v = world.v;
// end Top;
// endResult
