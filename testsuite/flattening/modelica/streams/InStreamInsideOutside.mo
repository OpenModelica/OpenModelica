// name: InStreamInsideOutside
// keywords: stream inStream connector inside outside
// status: correct
//
// Checks that inStream is evaluated correctly for an inside and an outside
// connected stream connector.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s;
  Real instream_s;
equation
  instream_s = inStream(s.s);
end A;

model InStreamInsideOutside
  A a;
  S s;
  Real instream_s;
  Real instream_s_a;
equation
  connect(a.s, s);
  instream_s = inStream(s.s);
  instream_s_a = inStream(a.s.s);
end InStreamInsideOutside;

// Result:
// class InStreamInsideOutside
//   Real a.s.r;
//   Real a.s.f;
//   Real a.s.s;
//   Real a.instream_s;
//   Real s.r;
//   Real s.f;
//   Real s.s;
//   Real instream_s;
//   Real instream_s_a;
// equation
//   a.instream_s = s.s;
//   instream_s = s.s;
//   instream_s_a = s.s;
//   a.s.f + (-s.f) = 0.0;
//   s.f = 0.0;
//   a.s.r = s.r;
//   a.s.s = s.s;
// end InStreamInsideOutside;
// endResult
