// name: ActualStreamMinMax
// keywords: stream actualStream connector
// status: correct
// cflags: -d=newInst
//
// Checks that actualStream is simplified when the flow direction can be
// determined from the min/max attributes.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s1(f(min = 0)), s2(f(max = 0));
  S s3(f(min = -5)), s4(f(max = 3));
end A;

model ActualStreamMinMax
  A a;
  Real actual_stream_s1;
  Real actual_stream_s2;
  Real actual_stream_s3;
  Real actual_stream_s4;
equation
  connect(a.s1, a.s2);
  connect(a.s3, a.s4);
  actual_stream_s1 = actualStream(a.s1.s);
  actual_stream_s2 = actualStream(a.s2.s);
  actual_stream_s3 = actualStream(a.s3.s);
  actual_stream_s4 = actualStream(a.s4.s);
end ActualStreamMinMax;

// Result:
// class ActualStreamMinMax
//   Real a.s1.r;
//   Real a.s1.f(min = 0.0);
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f(max = 0.0);
//   Real a.s2.s;
//   Real a.s3.r;
//   Real a.s3.f(min = -5.0);
//   Real a.s3.s;
//   Real a.s4.r;
//   Real a.s4.f(max = 3.0);
//   Real a.s4.s;
//   Real actual_stream_s1;
//   Real actual_stream_s2;
//   Real actual_stream_s3;
//   Real actual_stream_s4;
// equation
//   a.s1.r = a.s2.r;
//   a.s3.r = a.s4.r;
//   a.s2.f + a.s1.f = 0.0;
//   a.s4.f + a.s3.f = 0.0;
//   actual_stream_s1 = smooth(0, a.s2.s);
//   actual_stream_s2 = smooth(0, a.s2.s);
//   actual_stream_s3 = smooth(0, if a.s3.f > 0.0 then a.s4.s else a.s3.s);
//   actual_stream_s4 = smooth(0, if a.s4.f > 0.0 then a.s3.s else a.s4.s);
// end ActualStreamMinMax;
// endResult
