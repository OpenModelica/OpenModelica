// name:     VectorizeConstCref2D
// keywords: vectorization cref matrix bug3386
// status:   correct
//
// Tests vectorization of constant 2d cref.
//

model VectorizeConstCref2D
  constant Real[2, 6] phi = {{1, 2, 3, 4, 5, 6}, {21, 22, 23, 24, 25, 26}};
  Real[2] tmp;
  parameter Real[3] f = {0, 1, 0};
  parameter Real[3] t = {0, 0, -1};
equation
   tmp = phi[:, 1:3] * f + phi[:, 4:6] * t;
end VectorizeConstCref2D;

// Result:
// class VectorizeConstCref2D
//   constant Real phi[1,1] = 1.0;
//   constant Real phi[1,2] = 2.0;
//   constant Real phi[1,3] = 3.0;
//   constant Real phi[1,4] = 4.0;
//   constant Real phi[1,5] = 5.0;
//   constant Real phi[1,6] = 6.0;
//   constant Real phi[2,1] = 21.0;
//   constant Real phi[2,2] = 22.0;
//   constant Real phi[2,3] = 23.0;
//   constant Real phi[2,4] = 24.0;
//   constant Real phi[2,5] = 25.0;
//   constant Real phi[2,6] = 26.0;
//   Real tmp[1];
//   Real tmp[2];
//   parameter Real f[1] = 0.0;
//   parameter Real f[2] = 1.0;
//   parameter Real f[3] = 0.0;
//   parameter Real t[1] = 0.0;
//   parameter Real t[2] = 0.0;
//   parameter Real t[3] = -1.0;
// equation
//   tmp[1] = f[1] + 2.0 * f[2] + 3.0 * f[3] + 4.0 * t[1] + 5.0 * t[2] + 6.0 * t[3];
//   tmp[2] = 21.0 * f[1] + 22.0 * f[2] + 23.0 * f[3] + 24.0 * t[1] + 25.0 * t[2] + 26.0 * t[3];
// end VectorizeConstCref2D;
// endResult
