// name:     ConnectInnerOuter3
// keywords: connect inner outer
// status:   correct
//
// Connect to inner outer references


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

model A2
  inner outer Pin world;
  A a;
  Pin a2Pin;
equation
  connect(world,a2Pin);
end A2;

model Top2
  inner Pin world;
  Pin topPin;
  A2 a1;
equation
  connect(world,topPin);
end Top2;

// Result:
// class Top2
//   Real world.i;
//   Real world.v;
//   Real topPin.i;
//   Real topPin.v;
//   Real a1.world.i;
//   Real a1.world.v;
//   Real a1.a.aPin.i;
//   Real a1.a.aPin.v;
//   Real a1.a2Pin.i;
//   Real a1.a2Pin.v;
// equation
//   world.i = 0.0;
//   topPin.i = 0.0;
//   a1.world.i = 0.0;
//   a1.a.aPin.i = 0.0;
//   a1.a2Pin.i = 0.0;
//   (-world.i) + (-topPin.i) + (-a1.a2Pin.i) = 0.0;
//   a1.a2Pin.v = topPin.v;
//   a1.a2Pin.v = world.v;
//   (-a1.world.i) + (-a1.a.aPin.i) = 0.0;
//   a1.a.aPin.v = a1.world.v;
// end Top2;
// endResult
