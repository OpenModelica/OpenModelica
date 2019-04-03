// name: InStreamTwoInside
// keywords: stream inStream connector inside
// status: correct
// cflags: -d=newInst
//
// Checks that inStream is evaluated correctly for a model where the stream just
// passes through some components.
//

connector S
  flow Real f;
  Real e;
  stream Real s;
end S;

model A
  S s1;
  S s2;
  Real s1_instream;
  Real s2_instream;
equation
  connect(s1, s2);
  s1_instream = inStream(s1.s);
  s2_instream = inStream(s2.s);
end A;

model B
  S s;
equation
  s.f = 1;
  s.s = 10;
end B;

model C
  S s;
equation
  s.e = 0;
  s.s = 20;
end C;

model InStreamPipeline
  A a1;
  A a2;
  B b;
  C c;
equation
  connect(b.s, a1.s1);
  connect(a1.s2, a2.s1);
  connect(a2.s2, c.s);
end InStreamPipeline;

// Result:
// class InStreamPipeline
//   Real a1.s1.f;
//   Real a1.s1.e;
//   Real a1.s1.s;
//   Real a1.s2.f;
//   Real a1.s2.e;
//   Real a1.s2.s;
//   Real a1.s1_instream;
//   Real a1.s2_instream;
//   Real a2.s1.f;
//   Real a2.s1.e;
//   Real a2.s1.s;
//   Real a2.s2.f;
//   Real a2.s2.e;
//   Real a2.s2.s;
//   Real a2.s1_instream;
//   Real a2.s2_instream;
//   Real b.s.f;
//   Real b.s.e;
//   Real b.s.s;
//   Real c.s.f;
//   Real c.s.e;
//   Real c.s.s;
// equation
//   a1.s1.e = a1.s2.e;
//   (-a1.s1.f) + (-a1.s2.f) = 0.0;
//   a1.s1.s = a2.s1.s;
//   a1.s2.s = b.s.s;
//   a2.s1.e = a2.s2.e;
//   (-a2.s1.f) + (-a2.s2.f) = 0.0;
//   a2.s1.s = c.s.s;
//   a2.s2.s = a1.s2.s;
//   b.s.e = a1.s1.e;
//   a1.s2.e = a2.s1.e;
//   a2.s2.e = c.s.e;
//   a2.s1.f + a1.s2.f = 0.0;
//   c.s.f + a2.s2.f = 0.0;
//   b.s.f + a1.s1.f = 0.0;
//   a1.s1_instream = b.s.s;
//   a1.s2_instream = a2.s1.s;
//   a2.s1_instream = a1.s2.s;
//   a2.s2_instream = c.s.s;
//   b.s.f = 1.0;
//   b.s.s = 10.0;
//   c.s.e = 0.0;
//   c.s.s = 20.0;
// end InStreamPipeline;
// endResult
