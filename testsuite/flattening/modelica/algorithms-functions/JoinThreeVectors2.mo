// name:     joinThreeVectors2
// keywords: external functions
// status:   correct
//
// External C function with column-major arrays
// Drmodelica: 11.1 Function Annotations (p. 372)
//


function joinThreeVectors2
  input Real v1[:],v2[:],v3[:];
  output Real vres[size(v1,1)+size(v2,1)+size(v3,1)];
external "C"
  join3vec(v1,v2,v3,vres,size(v1,1),size(v2,1),size(v3,1));
  annotation(arrayLayout = "columnMajor");
end joinThreeVectors2;

model joinThreeVectors
  Real a[2]={1,2};
  Real b[3]={3,4,5};
  Real c[4]={6,7,8,9};
  Real x[9];
algorithm
  x:=joinThreeVectors2(a,b,c);
end joinThreeVectors;

// Result:
// function joinThreeVectors2
//   input Real[:] v1;
//   input Real[:] v2;
//   input Real[:] v3;
//   output Real[size(v1, 1) + size(v2, 1) + size(v3, 1)] vres;
//
//   external "C" join3vec(v1, v2, v3, vres, size(v1, 1), size(v2, 1), size(v3, 1));
// end joinThreeVectors2;
//
// class joinThreeVectors
//   Real a[1];
//   Real a[2];
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real c[1];
//   Real c[2];
//   Real c[3];
//   Real c[4];
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
//   Real x[7];
//   Real x[8];
//   Real x[9];
// equation
//   a = {1.0, 2.0};
//   b = {3.0, 4.0, 5.0};
//   c = {6.0, 7.0, 8.0, 9.0};
// algorithm
//   x := joinThreeVectors2({a[1], a[2]}, {b[1], b[2], b[3]}, {c[1], c[2], c[3], c[4]});
// end joinThreeVectors;
// endResult
