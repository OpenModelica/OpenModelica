// name: ActualStreamMul
// keywords: stream actualStream connector
// status: correct
//
// Checks that flow * actualStream() is wrapped in smooth().
//

connector S
  Real r;
  flow Real f;
  stream Real s;
  stream Real sa[2];
end S;

model A
  S s1, s2;
end A;

model ActualStreamMul
  A a;
  Real x;
  Real y[2];
equation
  connect(a.s1, a.s2);
  x = a.s1.f * actualStream(a.s1.s);
  y = a.s1.f * actualStream(a.s1.sa);
  y = a.s1.f * {actualStream(a.s1.sa[1]), actualStream(a.s1.sa[2])};
  y = {1, a.s1.f} .* {2, actualStream(a.s1.sa[2])};
  x = actualStream(a.s1.s) * a.s1.f;
  y = actualStream(a.s1.sa) * a.s1.f;
  y = {actualStream(a.s1.sa[1]), actualStream(a.s1.sa[2])} * a.s1.f;
  y = {2, actualStream(a.s1.sa[2])} .* {1, a.s1.f};
end ActualStreamMul;

// Result:
// class ActualStreamMul
//   Real a.s1.r;
//   Real a.s1.f;
//   Real a.s1.s;
//   Real a.s1.sa[1];
//   Real a.s1.sa[2];
//   Real a.s2.r;
//   Real a.s2.f;
//   Real a.s2.s;
//   Real a.s2.sa[1];
//   Real a.s2.sa[2];
//   Real x;
//   Real y[1];
//   Real y[2];
// equation
//   a.s1.r = a.s2.r;
//   a.s2.f + a.s1.f = 0.0;
//   x = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.s else a.s1.s));
//   y[1] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[1] else a.s1.sa[1]));
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
//   y[1] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[1] else a.s1.sa[1]));
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
//   y[1] = 2.0;
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
//   x = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.s else a.s1.s));
//   y[1] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[1] else a.s1.sa[1]));
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
//   y[1] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[1] else a.s1.sa[1]));
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
//   y[1] = 2.0;
//   y[2] = smooth(0, a.s1.f * (if a.s1.f > 0.0 then a.s2.sa[2] else a.s1.sa[2]));
// end ActualStreamMul;
// endResult
