// name:     ConditionalComponent
// keywords: conditional component
// status:   correct
//
// This is a simple test conditional components.
//

connector Pin
  Real v;
  flow Real i;
end Pin;

model Resistor
  Pin p,n;
equation

end Resistor;

model ConditionalComponent
  parameter Boolean b=true;

  Resistor R1, R2 if b, R3 if not b;
equation
  connect(R1.n,R2.p);
  connect(R2.n,R3.p);
  connect(R3.p,R1.p);
end ConditionalComponent;

model Array1
  Integer x[5] = {1,2,3,4,5};
  Integer y[3] = 1:3;
end Array1;

// Result:
// class Array1
//   Integer x[1];
//   Integer x[2];
//   Integer x[3];
//   Integer x[4];
//   Integer x[5];
//   Integer y[1];
//   Integer y[2];
//   Integer y[3];
// equation
//   x = {1, 2, 3, 4, 5};
//   y = {1, 2, 3};
// end Array1;
// endResult
