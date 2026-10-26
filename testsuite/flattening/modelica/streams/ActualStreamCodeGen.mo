// name: ActualStreamCodeGen
// keywords: stream actualStream connector
// status: correct
//
// Used by ActualStreamCodeGen.mos to check code generation for the actualStream
// operator.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s1, s2;
equation
  s1.r = 1.0;
  s1.s = 2.0;
  s2.f = 3.0;
  s2.s = 4.0;
end A;

model ActualStreamCodeGen
  A a;
  Real actual_stream_s1;
  Real actual_stream_s2;
equation
  connect(a.s1, a.s2);
  actual_stream_s1 = actualStream(a.s1.s);
  actual_stream_s2 = actualStream(a.s2.s);
end ActualStreamCodeGen;

// Result:
// class ActualStreamCodeGen
//   Real a.s1.r;
//   Real a.s1.f;
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f;
//   Real a.s2.s;
//   Real actual_stream_s1;
//   Real actual_stream_s2;
// equation
//   a.s1.r = 1.0;
//   a.s1.s = 2.0;
//   a.s2.f = 3.0;
//   a.s2.s = 4.0;
//   actual_stream_s1 = if a.s1.f > 0.0 then a.s2.s else a.s1.s;
//   actual_stream_s2 = if a.s2.f > 0.0 then a.s1.s else a.s2.s;
//   a.s1.f + a.s2.f = 0.0;
//   a.s1.r = a.s2.r;
// end ActualStreamCodeGen;
// endResult
