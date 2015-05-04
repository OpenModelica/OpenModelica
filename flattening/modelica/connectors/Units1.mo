// name:     Units1
// keywords: connect,modification
// status:   incorrect
//
// Conversion between units is not supported within the Modelica
// language. Consequently in the following example the generation
// of equations from connect statements does not depend on the
// specified units. The model is thus incorrect.
//

type Voltage = Real(unit = "V");
type Current = Real(unit = "A");

connector Pin1
  Voltage v(unit="kV");
  flow Current i;
end Pin1;

connector Pin2
  Voltage v;
  flow Current i;
end Pin2;

model Units1
  Pin1 p1;
  Pin2 p2;
equation
  connect(p1,p2);
  p1.v=0;
  p2.i=1;
end Units1;

// Result:
// class Units1
// Real p1.v(unit = "kV");
// Real p1.i(unit = "A");
// Real p2.v(unit = "V");
// Real p2.i(unit = "A");
// equation
//   p1.v = 0.0;
//   p2.i = 1.0;
//   (-p1.i) + (-p2.i) = 0.0;
// p1.v = p2.v;
//   p2.i = 0.0;
//   p1.i = 0.0;
// end Units1;
// endResult
