// name: InStreamFlowThreshold
// keywords: stream instream connector outside
// cflags: --flowThreshold=2 -d=newInst
// status: correct
//
// Checks that the --flowThreshold flag works.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model A
  S s1;
  S s2;
  S s3;
  Real instream_s1;
  Real instream_s2;
  Real instream_s3;
equation
  connect(s1, s2);
  connect(s2, s3);
  instream_s1 = inStream(s1.s);
  instream_s2 = inStream(s2.s);
end A;

model InStreamFlowThreshold
  A a;
  Real instream_a_s1;
  Real instream_a_s2;
equation
  instream_a_s1 = inStream(a.s1.s);
  instream_a_s2 = inStream(a.s2.s);
end InStreamFlowThreshold;

// Result:
// class InStreamFlowThreshold
//   Real a.s1.r;
//   Real a.s1.f;
//   Real a.s1.s;
//   Real a.s2.r;
//   Real a.s2.f;
//   Real a.s2.s;
//   Real a.s3.r;
//   Real a.s3.f;
//   Real a.s3.s;
//   Real a.instream_s1;
//   Real a.instream_s2;
//   Real a.instream_s3;
//   Real instream_a_s1;
//   Real instream_a_s2;
// equation
//   a.s2.r = a.s3.r;
//   a.s2.r = a.s1.r;
//   (-a.s2.f) + (-a.s3.f) + (-a.s1.f) = 0.0;
//   a.s1.s = ($OMC$PositiveMax(a.s3.f, 2.0) * a.s3.s + $OMC$PositiveMax(a.s2.f, 2.0) * a.s2.s) / ($OMC$PositiveMax(a.s3.f, 2.0) + $OMC$PositiveMax(a.s2.f, 2.0)) " equation generated from stream connection";
//   a.s3.s = ($OMC$PositiveMax(a.s1.f, 2.0) * a.s1.s + $OMC$PositiveMax(a.s2.f, 2.0) * a.s2.s) / ($OMC$PositiveMax(a.s1.f, 2.0) + $OMC$PositiveMax(a.s2.f, 2.0)) " equation generated from stream connection";
//   a.s2.s = ($OMC$PositiveMax(a.s1.f, 2.0) * a.s1.s + $OMC$PositiveMax(a.s3.f, 2.0) * a.s3.s) / ($OMC$PositiveMax(a.s1.f, 2.0) + $OMC$PositiveMax(a.s3.f, 2.0)) " equation generated from stream connection";
//   a.s1.f = 0.0;
//   a.s2.f = 0.0;
//   a.s3.f = 0.0;
//   a.instream_s1 = a.s1.s;
//   a.instream_s2 = a.s2.s;
//   instream_a_s1 = a.s1.s;
//   instream_a_s2 = a.s2.s;
// end InStreamFlowThreshold;
// endResult
