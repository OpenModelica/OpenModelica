// name: InStreamUnconnected
// keywords: stream inStream connector unconnected
// status: correct
//
// Checks that inStream of an unconnected stream connector is correctly
// evaluated.
//

connector S
  Real r;
  flow Real f;
  stream Real s;
end S;

model InStreamUnconnected
  S s;
  Real instream_s;
equation
  instream_s = inStream(s.s);
end InStreamUnconnected;

// Result:
// class InStreamUnconnected
//   Real s.r;
//   Real s.f;
//   Real s.s;
//   Real instream_s;
// equation
//   instream_s = s.s;
//   s.f = 0.0;
// end InStreamUnconnected;
// endResult
