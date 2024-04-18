// name: ConnectArrays1
// keywords:
// status: correct
// cflags:   -d=newInst
//
//

model ConnectArrays1
  connector A
    Real e;
    flow Real f;
  end A;

  constant Integer n=5;
  A a[n];
equation
  a[1].e = 1;
  connect(a[1:n-1],a[2:n]);
end ConnectArrays1;

// Result:
// class ConnectArrays1
//   constant Integer n = 5;
//   Real a[1].e;
//   Real a[1].f;
//   Real a[2].e;
//   Real a[2].f;
//   Real a[3].e;
//   Real a[3].f;
//   Real a[4].e;
//   Real a[4].f;
//   Real a[5].e;
//   Real a[5].f;
// equation
//   a[4].e = a[5].e;
//   a[4].e = a[3].e;
//   a[4].e = a[2].e;
//   a[4].e = a[1].e;
//   -(a[4].f + a[5].f + a[3].f + a[2].f + a[1].f) = 0.0;
//   a[1].f = 0.0;
//   a[2].f = 0.0;
//   a[3].f = 0.0;
//   a[4].f = 0.0;
//   a[5].f = 0.0;
//   a[1].e = 1.0;
// end ConnectArrays1;
// endResult
