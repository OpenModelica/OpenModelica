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
  Pin pin;
equation
  connect(subWorld.pin, pin);
end World;

model A
  outer World world;
  Pin aPin;
equation
  connect(world.pin, aPin);
end A;

model Top
  inner World world;
  Pin topPin;
  A a1,a2;
equation
  connect(world.pin, topPin);
end Top;

// Result:
// class Top
//   Real world.subWorld.pin.i;
//   Real world.subWorld.pin.v;
//   Real world.pin.i;
//   Real world.pin.v;
//   Real topPin.i;
//   Real topPin.v;
//   Real a1.aPin.i;
//   Real a1.aPin.v;
//   Real a2.aPin.i;
//   Real a2.aPin.v;
// equation
//   world.subWorld.pin.v = world.pin.v;
//   world.pin.v = topPin.v;
//   world.pin.v = a2.aPin.v;
//   world.pin.v = a1.aPin.v;
//   world.pin.i - topPin.i - a2.aPin.i - a1.aPin.i = 0.0;
//   world.subWorld.pin.i - world.pin.i = 0.0;
//   topPin.i = 0.0;
//   a1.aPin.i = 0.0;
//   a2.aPin.i = 0.0;
// end Top;
// endResult
