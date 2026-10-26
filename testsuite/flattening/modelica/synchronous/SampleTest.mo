// name: SampleTest
// keywords: synchronous features
// status: correct

model SampleTest
  Clock c;
  Boolean cb = sample(0.1,0.1);
  Real x1,x2,y;
equation
  c = Clock(0.1);
  x1 = sample(1.0);
  x2 = sample(1.1, c);
  y = x1 + x2;
end SampleTest;

// Result:
// class SampleTest
//   Clock c;
//   Boolean cb = sample(0.1, 0.1);
//   Real x1;
//   Real x2;
//   Real y;
// equation
//   c = Clock(0.1);
//   x1 = sample(1.0, Clock());
//   x2 = sample(1.1, c);
//   y = x1 + x2;
// end SampleTest;
// endResult
