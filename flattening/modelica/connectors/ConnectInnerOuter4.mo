// name:     ConnectInnerOuter4
// keywords: connect inner outer
// status:   correct
//
// Connect to references in outer class

connector Pin
  flow Real i;
  Real v;
end Pin;

model World
  model SubWorld
    Pin pin;
  end SubWorld;
  SubWorld subWorld;
end World;

model A
  outer World world;
  Pin aPin;
equation
  connect(world.subWorld.pin, aPin);
end A;

model Top
  inner World world;
  Pin topPin;
  A a1,a2;
equation
  connect(world.subWorld.pin, topPin);
end Top;

// Result:
// class Top
//   Real world.subWorld.pin.i;
//   Real world.subWorld.pin.v;
//   Real topPin.i;
//   Real topPin.v;
//   Real a1.aPin.i;
//   Real a1.aPin.v;
//   Real a2.aPin.i;
//   Real a2.aPin.v;
// equation
//   world.subWorld.pin.i + (-topPin.i) + (-a1.aPin.i) + (-a2.aPin.i) = 0.0;
//   topPin.i = 0.0;
//   a1.aPin.i = 0.0;
//   a2.aPin.i = 0.0;
//   a1.aPin.v = a2.aPin.v;
//   a1.aPin.v = topPin.v;
//   a1.aPin.v = world.subWorld.pin.v;
// end Top;
// endResult
