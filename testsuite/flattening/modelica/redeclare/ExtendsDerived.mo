// name:     ExtendsDerived.mo
// keywords: extends modifier handling
// status:   correct
//
// check that modifiers on derived classes which are extended are not lost
//


package B
  model X = Y(k=u);
  model Y
    parameter Real k = 2;
    parameter Real z = 10;
  end Y;
  constant Real u = 10;
end B;

model A
 extends B.X(z = 15);
end A;

// Result:
// class A
//   parameter Real k = 10.0;
//   parameter Real z = 15.0;
// end A;
// endResult
