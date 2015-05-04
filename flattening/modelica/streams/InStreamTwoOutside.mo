// name: InStreamTwoOutside
// keywords: stream instream connector outside
// status: correct
//
// Checks that inStream is evaluated correctly on two outside connected stream
// connectors.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s1;
  S s2;
  Real instream_s1;
  Real instream_s2;
equation
  connect(s1, s2);
  instream_s1 = inStream(s1.s);
  instream_s2 = inStream(s2.s);
end A;

model InStreamTwoInside
  A a;
  Real instream_a_s1;
  Real instream_a_s2;
equation
  instream_a_s1 = inStream(a.s1.s);
  instream_a_s2 = inStream(a.s2.s);
end InStreamTwoInside;

// Result:
// class InStreamTwoInside
//   Real a.s1.r;
//   Real a.s1.f;
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f;
//   Real a.s2.s;
//   Real a.instream_s1;
//   Real a.instream_s2;
//   Real instream_a_s1;
//   Real instream_a_s2;
// equation
//   a.instream_s1 = a.s1.s;
//   a.instream_s2 = a.s2.s;
//   instream_a_s1 = a.s1.s;
//   instream_a_s2 = a.s2.s;
//   a.s1.f = 0.0;
//   a.s2.f = 0.0;
//   (-a.s1.f) + (-a.s2.f) = 0.0;
//   a.s1.r = a.s2.r;
//   a.s1.s = a.s2.s;
//   a.s2.s = a.s1.s;
// end InStreamTwoInside;
// endResult
