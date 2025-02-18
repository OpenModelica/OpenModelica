// name: ActualStreamMinMax2
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
  parameter Boolean cond = true;
  S s1(f(min = if cond then 0 else -1)), s2(f(min = if cond then 0 else 1));
end A;

model ActualStreamMinMax2
  A a;
  Real actual_stream_s1;
  Real actual_stream_s2;
equation
  connect(a.s1, a.s2);
  actual_stream_s1 = actualStream(a.s1.s);
  actual_stream_s2 = actualStream(a.s2.s);
end ActualStreamMinMax2;

// Result:
// class ActualStreamMinMax2
//   final parameter Boolean a.cond = true;
//   Real a.s1.r;
//   Real a.s1.f(min = 0.0);
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f(min = 0.0);
//   Real a.s2.s;
//   Real actual_stream_s1;
//   Real actual_stream_s2;
// equation
//   a.s1.r = a.s2.r;
//   a.s2.f + a.s1.f = 0.0;
//   actual_stream_s1 = a.s1.s;
//   actual_stream_s2 = a.s2.s;
// end ActualStreamMinMax2;
// endResult
