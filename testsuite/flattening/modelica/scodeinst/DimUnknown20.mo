// name: DimUnknown20
// keywords:
// status: correct
//
//

model A
  parameter Real inc;
  parameter Real t[:,:] = if inc <= 1 then {{1,2}} else {{1,2},{3,4}};
end A;

model DimUnknown20
  A a[2](inc = fill(2, 2));
end DimUnknown20;

// Result:
// class DimUnknown20
//   final parameter Real a[1].inc = 2.0;
//   parameter Real a[1].t[1,1] = 1.0;
//   parameter Real a[1].t[1,2] = 2.0;
//   parameter Real a[1].t[2,1] = 3.0;
//   parameter Real a[1].t[2,2] = 4.0;
//   final parameter Real a[2].inc = 2.0;
//   parameter Real a[2].t[1,1] = 1.0;
//   parameter Real a[2].t[1,2] = 2.0;
//   parameter Real a[2].t[2,1] = 3.0;
//   parameter Real a[2].t[2,2] = 4.0;
// end DimUnknown20;
// endResult
