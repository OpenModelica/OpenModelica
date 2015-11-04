// name:     DiscreteVectorStateSpace
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//

model DiscreteVectorStateSpace
  parameter Integer n = 5, m = 4, p = 2;
  parameter Real A[n, n] = fill(1, n, n);
  parameter Real B[n, m] = fill(2, n, m);
  parameter Real C[p, n] = fill(3, p, n);
  parameter Real D[p, m] = fill(4, p, m);
  parameter Real T = 1;
  input Real u[m];
  discrete output Real y[p];
protected
  discrete Real x[n];// = fill(2, n);
equation
  when sample(0, T) then
    x = A * pre(x) + B * u;
    y = C * pre(x) + D * u;
  end when;
end DiscreteVectorStateSpace;

model DVSSTest
  DiscreteVectorStateSpace dvss;
equation
  dvss.u= fill(time,dvss.m);
end DVSSTest;


// Result:
// class DVSSTest
//   parameter Integer dvss.n = 5;
//   parameter Integer dvss.m = 4;
//   parameter Integer dvss.p = 2;
//   parameter Real dvss.A[1,1] = 1.0;
//   parameter Real dvss.A[1,2] = 1.0;
//   parameter Real dvss.A[1,3] = 1.0;
//   parameter Real dvss.A[1,4] = 1.0;
//   parameter Real dvss.A[1,5] = 1.0;
//   parameter Real dvss.A[2,1] = 1.0;
//   parameter Real dvss.A[2,2] = 1.0;
//   parameter Real dvss.A[2,3] = 1.0;
//   parameter Real dvss.A[2,4] = 1.0;
//   parameter Real dvss.A[2,5] = 1.0;
//   parameter Real dvss.A[3,1] = 1.0;
//   parameter Real dvss.A[3,2] = 1.0;
//   parameter Real dvss.A[3,3] = 1.0;
//   parameter Real dvss.A[3,4] = 1.0;
//   parameter Real dvss.A[3,5] = 1.0;
//   parameter Real dvss.A[4,1] = 1.0;
//   parameter Real dvss.A[4,2] = 1.0;
//   parameter Real dvss.A[4,3] = 1.0;
//   parameter Real dvss.A[4,4] = 1.0;
//   parameter Real dvss.A[4,5] = 1.0;
//   parameter Real dvss.A[5,1] = 1.0;
//   parameter Real dvss.A[5,2] = 1.0;
//   parameter Real dvss.A[5,3] = 1.0;
//   parameter Real dvss.A[5,4] = 1.0;
//   parameter Real dvss.A[5,5] = 1.0;
//   parameter Real dvss.B[1,1] = 2.0;
//   parameter Real dvss.B[1,2] = 2.0;
//   parameter Real dvss.B[1,3] = 2.0;
//   parameter Real dvss.B[1,4] = 2.0;
//   parameter Real dvss.B[2,1] = 2.0;
//   parameter Real dvss.B[2,2] = 2.0;
//   parameter Real dvss.B[2,3] = 2.0;
//   parameter Real dvss.B[2,4] = 2.0;
//   parameter Real dvss.B[3,1] = 2.0;
//   parameter Real dvss.B[3,2] = 2.0;
//   parameter Real dvss.B[3,3] = 2.0;
//   parameter Real dvss.B[3,4] = 2.0;
//   parameter Real dvss.B[4,1] = 2.0;
//   parameter Real dvss.B[4,2] = 2.0;
//   parameter Real dvss.B[4,3] = 2.0;
//   parameter Real dvss.B[4,4] = 2.0;
//   parameter Real dvss.B[5,1] = 2.0;
//   parameter Real dvss.B[5,2] = 2.0;
//   parameter Real dvss.B[5,3] = 2.0;
//   parameter Real dvss.B[5,4] = 2.0;
//   parameter Real dvss.C[1,1] = 3.0;
//   parameter Real dvss.C[1,2] = 3.0;
//   parameter Real dvss.C[1,3] = 3.0;
//   parameter Real dvss.C[1,4] = 3.0;
//   parameter Real dvss.C[1,5] = 3.0;
//   parameter Real dvss.C[2,1] = 3.0;
//   parameter Real dvss.C[2,2] = 3.0;
//   parameter Real dvss.C[2,3] = 3.0;
//   parameter Real dvss.C[2,4] = 3.0;
//   parameter Real dvss.C[2,5] = 3.0;
//   parameter Real dvss.D[1,1] = 4.0;
//   parameter Real dvss.D[1,2] = 4.0;
//   parameter Real dvss.D[1,3] = 4.0;
//   parameter Real dvss.D[1,4] = 4.0;
//   parameter Real dvss.D[2,1] = 4.0;
//   parameter Real dvss.D[2,2] = 4.0;
//   parameter Real dvss.D[2,3] = 4.0;
//   parameter Real dvss.D[2,4] = 4.0;
//   parameter Real dvss.T = 1.0;
//   Real dvss.u[1];
//   Real dvss.u[2];
//   Real dvss.u[3];
//   Real dvss.u[4];
//   discrete Real dvss.y[1];
//   discrete Real dvss.y[2];
//   protected discrete Real dvss.x[1];
//   protected discrete Real dvss.x[2];
//   protected discrete Real dvss.x[3];
//   protected discrete Real dvss.x[4];
//   protected discrete Real dvss.x[5];
// equation
//   when sample(0.0, dvss.T) then
//     dvss.x[1] = dvss.A[1,1] * pre(dvss.x[1]) + dvss.A[1,2] * pre(dvss.x[2]) + dvss.A[1,3] * pre(dvss.x[3]) + dvss.A[1,4] * pre(dvss.x[4]) + dvss.A[1,5] * pre(dvss.x[5]) + dvss.B[1,1] * dvss.u[1] + dvss.B[1,2] * dvss.u[2] + dvss.B[1,3] * dvss.u[3] + dvss.B[1,4] * dvss.u[4];
//     dvss.x[2] = dvss.A[2,1] * pre(dvss.x[1]) + dvss.A[2,2] * pre(dvss.x[2]) + dvss.A[2,3] * pre(dvss.x[3]) + dvss.A[2,4] * pre(dvss.x[4]) + dvss.A[2,5] * pre(dvss.x[5]) + dvss.B[2,1] * dvss.u[1] + dvss.B[2,2] * dvss.u[2] + dvss.B[2,3] * dvss.u[3] + dvss.B[2,4] * dvss.u[4];
//     dvss.x[3] = dvss.A[3,1] * pre(dvss.x[1]) + dvss.A[3,2] * pre(dvss.x[2]) + dvss.A[3,3] * pre(dvss.x[3]) + dvss.A[3,4] * pre(dvss.x[4]) + dvss.A[3,5] * pre(dvss.x[5]) + dvss.B[3,1] * dvss.u[1] + dvss.B[3,2] * dvss.u[2] + dvss.B[3,3] * dvss.u[3] + dvss.B[3,4] * dvss.u[4];
//     dvss.x[4] = dvss.A[4,1] * pre(dvss.x[1]) + dvss.A[4,2] * pre(dvss.x[2]) + dvss.A[4,3] * pre(dvss.x[3]) + dvss.A[4,4] * pre(dvss.x[4]) + dvss.A[4,5] * pre(dvss.x[5]) + dvss.B[4,1] * dvss.u[1] + dvss.B[4,2] * dvss.u[2] + dvss.B[4,3] * dvss.u[3] + dvss.B[4,4] * dvss.u[4];
//     dvss.x[5] = dvss.A[5,1] * pre(dvss.x[1]) + dvss.A[5,2] * pre(dvss.x[2]) + dvss.A[5,3] * pre(dvss.x[3]) + dvss.A[5,4] * pre(dvss.x[4]) + dvss.A[5,5] * pre(dvss.x[5]) + dvss.B[5,1] * dvss.u[1] + dvss.B[5,2] * dvss.u[2] + dvss.B[5,3] * dvss.u[3] + dvss.B[5,4] * dvss.u[4];
//     dvss.y[1] = dvss.C[1,1] * pre(dvss.x[1]) + dvss.C[1,2] * pre(dvss.x[2]) + dvss.C[1,3] * pre(dvss.x[3]) + dvss.C[1,4] * pre(dvss.x[4]) + dvss.C[1,5] * pre(dvss.x[5]) + dvss.D[1,1] * dvss.u[1] + dvss.D[1,2] * dvss.u[2] + dvss.D[1,3] * dvss.u[3] + dvss.D[1,4] * dvss.u[4];
//     dvss.y[2] = dvss.C[2,1] * pre(dvss.x[1]) + dvss.C[2,2] * pre(dvss.x[2]) + dvss.C[2,3] * pre(dvss.x[3]) + dvss.C[2,4] * pre(dvss.x[4]) + dvss.C[2,5] * pre(dvss.x[5]) + dvss.D[2,1] * dvss.u[1] + dvss.D[2,2] * dvss.u[2] + dvss.D[2,3] * dvss.u[3] + dvss.D[2,4] * dvss.u[4];
//   end when;
//   dvss.u[1] = time;
//   dvss.u[2] = time;
//   dvss.u[3] = time;
//   dvss.u[4] = time;
// end DVSSTest;
// endResult
