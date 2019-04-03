// name: InStreamTwoInside
// keywords: stream inStream connector inside
// status: correct
//
// Checks that inStream is evaluated correctly on two inside connected stream
// connectors.
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

model InStreamTwoInside
  A a1, a2;
  Real instream_s_a1;
  Real instream_s_a2;
equation
  connect(a1.s, a2.s);
  instream_s_a1 = inStream(a1.s.s);
  instream_s_a2 = inStream(a2.s.s);
end InStreamTwoInside;

// Result:
// class InStreamTwoInside
//   Real a1.s.r;
//   Real a1.s.f;
//   Real a1.s.s;
//   Real a1.instream_s;
//   Real a2.s.r;
//   Real a2.s.f;
//   Real a2.s.s;
//   Real a2.instream_s;
//   Real instream_s_a1;
//   Real instream_s_a2;
// equation
//   a1.instream_s = a2.s.s;
//   a2.instream_s = a1.s.s;
//   instream_s_a1 = a2.s.s;
//   instream_s_a2 = a1.s.s;
//   a1.s.f + a2.s.f = 0.0;
//   a1.s.r = a2.s.r;
// end InStreamTwoInside;
// endResult
