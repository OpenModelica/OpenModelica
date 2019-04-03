// name:     Non-expanded Array3
// keywords: array
// status:   correct
// cflags:   +a
//
// A test of non-expanded arrays for the case of array containing arrays with bindings.
//

model Array3
  type B = Real[3];

  class A
    Real[3] x;
    B y;
  end A;

  A[2] a (x = {{1,2,3},{4,5,6}}, y = {{1,2,3},{4,5,6}});
end Array3;

// Result:
// class Array3
//   Real a[1:2].x[1:3];
//   Real a[1:2].y[1:3];
// equation
//   a[2].x = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}};
//   a[2].y = {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}};
// end Array3;
// endResult
