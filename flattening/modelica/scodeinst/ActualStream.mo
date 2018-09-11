// name: ActualStream
// keywords: stream actualStream connector
// status: correct
// cflags: -d=newInst
//
// Checks that actualStream is evaluated correctly.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s1, s2;
end A;

model ActualStream
  A a;
  Real actual_stream_s1;
  Real actual_stream_s2;
equation
  connect(a.s1, a.s2);
  actual_stream_s1 = actualStream(a.s1.s);
  actual_stream_s2 = actualStream(a.s2.s);
end ActualStream;

// Result:
// class ActualStream
//   Real a.s1.r;
//   Real a.s1.f;
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f;
//   Real a.s2.s;
//   Real actual_stream_s1;
//   Real actual_stream_s2;
// equation
//   a.s1.r = a.s2.r;
//   a.s2.f + a.s1.f = 0.0;
//   actual_stream_s1 = smooth(0, if a.s1.f > 0.0 then a.s2.s else a.s1.s);
//   actual_stream_s2 = smooth(0, if a.s2.f > 0.0 then a.s1.s else a.s2.s);
// end ActualStream;
// endResult
