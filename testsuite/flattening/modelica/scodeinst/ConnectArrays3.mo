// name: ConnectArrays3
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model ConnectArrays3
  model B
    connector InReal = input Real;
    connector OutReal = output Real;
    parameter Integer p = 3;
    InReal x[p];
    OutReal y[p+1];
  end B;

  B b1[3], b2[3];
equation
  connect(b1[1:3].x[1:3], b2[1:3].y[1:3]);
end ConnectArrays3;

// Result:
// class ConnectArrays3
//   parameter Integer b1[1].p = 3;
//   Real b1[1].x[1];
//   Real b1[1].x[2];
//   Real b1[1].x[3];
//   Real b1[1].y[1];
//   Real b1[1].y[2];
//   Real b1[1].y[3];
//   Real b1[1].y[4];
//   parameter Integer b1[2].p = 3;
//   Real b1[2].x[1];
//   Real b1[2].x[2];
//   Real b1[2].x[3];
//   Real b1[2].y[1];
//   Real b1[2].y[2];
//   Real b1[2].y[3];
//   Real b1[2].y[4];
//   parameter Integer b1[3].p = 3;
//   Real b1[3].x[1];
//   Real b1[3].x[2];
//   Real b1[3].x[3];
//   Real b1[3].y[1];
//   Real b1[3].y[2];
//   Real b1[3].y[3];
//   Real b1[3].y[4];
//   parameter Integer b2[1].p = 3;
//   Real b2[1].x[1];
//   Real b2[1].x[2];
//   Real b2[1].x[3];
//   Real b2[1].y[1];
//   Real b2[1].y[2];
//   Real b2[1].y[3];
//   Real b2[1].y[4];
//   parameter Integer b2[2].p = 3;
//   Real b2[2].x[1];
//   Real b2[2].x[2];
//   Real b2[2].x[3];
//   Real b2[2].y[1];
//   Real b2[2].y[2];
//   Real b2[2].y[3];
//   Real b2[2].y[4];
//   parameter Integer b2[3].p = 3;
//   Real b2[3].x[1];
//   Real b2[3].x[2];
//   Real b2[3].x[3];
//   Real b2[3].y[1];
//   Real b2[3].y[2];
//   Real b2[3].y[3];
//   Real b2[3].y[4];
// equation
//   b1[1].x[1] = b2[1].y[1];
//   b1[1].x[2] = b2[1].y[2];
//   b1[1].x[3] = b2[1].y[3];
//   b1[2].x[1] = b2[2].y[1];
//   b1[2].x[2] = b2[2].y[2];
//   b1[2].x[3] = b2[2].y[3];
//   b1[3].x[1] = b2[3].y[1];
//   b1[3].x[2] = b2[3].y[2];
//   b1[3].x[3] = b2[3].y[3];
// end ConnectArrays3;
// endResult
