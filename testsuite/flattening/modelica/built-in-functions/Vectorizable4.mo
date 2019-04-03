// name:     Vectorizable4
// keywords: vectorized calls
// status:   correct
//
// This tests vectorized calls.
//


model Vectorizable4
  Real x[2,2];
  Real y[2];
  Real z[2,2,2];
equation
  x=der([time*1,time*2;time*3,time*4]);
  der(y)=fill(-1,2);
  der(z)=fill(-1,2,2,2);
end Vectorizable4;


// Result:
// class Vectorizable4
//   Real x[1,1];
//   Real x[1,2];
//   Real x[2,1];
//   Real x[2,2];
//   Real y[1];
//   Real y[2];
//   Real z[1,1,1];
//   Real z[1,1,2];
//   Real z[1,2,1];
//   Real z[1,2,2];
//   Real z[2,1,1];
//   Real z[2,1,2];
//   Real z[2,2,1];
//   Real z[2,2,2];
// equation
//   x[1,1] = der(time);
//   x[1,2] = der(2.0 * time);
//   x[2,1] = der(3.0 * time);
//   x[2,2] = der(4.0 * time);
//   der(y[1]) = -1.0;
//   der(y[2]) = -1.0;
//   der(z[1,1,1]) = -1.0;
//   der(z[1,1,2]) = -1.0;
//   der(z[1,2,1]) = -1.0;
//   der(z[1,2,2]) = -1.0;
//   der(z[2,1,1]) = -1.0;
//   der(z[2,1,2]) = -1.0;
//   der(z[2,2,1]) = -1.0;
//   der(z[2,2,2]) = -1.0;
// end Vectorizable4;
// endResult
