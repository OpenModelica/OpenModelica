// name:     ArrayMatrixSimplifier
// keywords: simplify array matrix
// status:   correct
//
// This tests checks that the simplifying process from a[{x,y,z}] simplifies to
// {a[x], a[y], a[z]} and x[{1,2},{3,4}] simplifies to {{x[1,3], x[1,4]}, {x[2,3], x[2,4]}}
//
model ArrayMatrixSimplifier
  parameter Real a[:]={1,1};
  output Real x[size(a, 1) - 1];
  parameter Real u = 3;
  protected
  Real x1;
  Real z[4,4];
  Real q[2,2];
equation
  z[{1,2},{3,4}]=q;
  x1=(u - a[2:size(a, 1)]*pre(x))/a[1];
end ArrayMatrixSimplifier;

// Result:
// class ArrayMatrixSimplifier
//   parameter Real a[1] = 1.0;
//   parameter Real a[2] = 1.0;
//   output Real x[1];
//   parameter Real u = 3.0;
//   protected Real x1;
//   protected Real z[1,1];
//   protected Real z[1,2];
//   protected Real z[1,3];
//   protected Real z[1,4];
//   protected Real z[2,1];
//   protected Real z[2,2];
//   protected Real z[2,3];
//   protected Real z[2,4];
//   protected Real z[3,1];
//   protected Real z[3,2];
//   protected Real z[3,3];
//   protected Real z[3,4];
//   protected Real z[4,1];
//   protected Real z[4,2];
//   protected Real z[4,3];
//   protected Real z[4,4];
//   protected Real q[1,1];
//   protected Real q[1,2];
//   protected Real q[2,1];
//   protected Real q[2,2];
// equation
//   z[1,3] = q[1,1];
//   z[1,4] = q[1,2];
//   z[2,3] = q[2,1];
//   z[2,4] = q[2,2];
//   x1 = (u - a[2] * pre(x[1])) / a[1];
// end ArrayMatrixSimplifier;
// endResult
