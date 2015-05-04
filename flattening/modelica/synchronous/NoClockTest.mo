// name: NoClockTest
// keywords: synchronous features
// status: correct

model NoClockTest
  output Real x;
  output Integer y[2];
  Integer z[2];
  output Integer yy[2];
equation
  x = noClock(3);
  y = noClock(z);
  yy = noClock(vector([3;4]));
end NoClockTest;

// Result:
// class NoClockTest
//   output Real x;
//   output Integer y[1];
//   output Integer y[2];
//   Integer z[1];
//   Integer z[2];
//   output Integer yy[1];
//   output Integer yy[2];
// equation
//   x = /*Real*/(noClock(3));
//   y[1] = noClock(z[1]);
//   y[2] = noClock(z[2]);
//   yy[1] = noClock(3);
//   yy[2] = noClock(4);
// end NoClockTest;
// endResult
