// name: Constant12
// status: correct

class A
  class B
  Real z = A.y;
  end B;
  constant Real y;
  B[3] b;
end A;

class Constant12
  A[2] a(y = {1,2});
end Constant12;

// Result:
// class Constant12
//   constant Real a[1].y = 1.0;
//   Real a[1].b[1].z = A.y;
//   Real a[1].b[2].z = A.y;
//   Real a[1].b[3].z = A.y;
//   constant Real a[2].y = 2.0;
//   Real a[2].b[1].z = A.y;
//   Real a[2].b[2].z = A.y;
//   Real a[2].b[3].z = A.y;
// end Constant12;
// endResult
