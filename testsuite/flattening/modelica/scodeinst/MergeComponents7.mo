// name: MergeComponents7
// keywords:
// status: correct
// cflags: -d=newInst,mergeComponents,-nfScalarize
//

model A
  parameter Real p = 1;
  input Real u;
  Real y;
  Real x;
equation
  der(x) = -p*x+u;
  y = 2*p*x;
end A;

model B
  parameter Real q = 1;
  input Real u;
  output Real y;
  A aa(p = q*2);
  A ab(p = q*3);
equation
  aa.u = u;
  ab.u = aa.y;
  y = ab.y;
end B;

model MergeComponents7
  B b1(q = 3);
  B b2;
  B b3(q = 4);
  A a1(p = 3);
  A a2;
equation
  a1.u = 1;
  a2.u = a1.y;
  b1.u = a2.u;
  b2.u = b1.y;
  b3.u = b2.y;
end MergeComponents7;

// Result:
// class MergeComponents7
//   parameter Real b2.q = 1.0;
//   Real b2.u;
//   Real b2.y;
//   parameter Real b2.aa.p = b2.q * 2.0;
//   Real b2.aa.u;
//   Real b2.aa.y;
//   Real b2.aa.x;
//   parameter Real b2.ab.p = b2.q * 3.0;
//   Real b2.ab.u;
//   Real b2.ab.y;
//   Real b2.ab.x;
//   parameter Real a1.p = 3.0;
//   Real a1.u;
//   Real a1.y;
//   Real a1.x;
//   parameter Real a2.p = 1.0;
//   Real a2.u;
//   Real a2.y;
//   Real a2.x;
//   Real[2] $B1.ab.x;
//   Real[2] $B1.ab.y;
//   Real[2] $B1.ab.u;
//   parameter Real[2] $B1.ab.p = fill($B1.q * 3.0, 2);
//   Real[2] $B1.aa.x;
//   Real[2] $B1.aa.y;
//   Real[2] $B1.aa.u;
//   parameter Real[2] $B1.aa.p = fill($B1.q * 2.0, 2);
//   Real[2] $B1.y;
//   Real[2] $B1.u;
//   parameter Real[2] $B1.q = {3.0, 4.0};
// equation
//   der(b2.aa.x) = (-b2.aa.p * b2.aa.x) + b2.aa.u;
//   b2.aa.y = 2.0 * b2.aa.p * b2.aa.x;
//   der(b2.ab.x) = (-b2.ab.p * b2.ab.x) + b2.ab.u;
//   b2.ab.y = 2.0 * b2.ab.p * b2.ab.x;
//   b2.aa.u = b2.u;
//   b2.ab.u = b2.aa.y;
//   b2.y = b2.ab.y;
//   der(a1.x) = (-a1.p * a1.x) + a1.u;
//   a1.y = 2.0 * a1.p * a1.x;
//   der(a2.x) = (-a2.p * a2.x) + a2.u;
//   a2.y = 2.0 * a2.p * a2.x;
//   for $i1 in 1:2 loop
//     der($B1[$i1].aa.x) = (-$B1[$i1].aa.p * $B1[$i1].aa.x) + $B1[$i1].aa.u;
//   end for;
//   for $i1 in 1:2 loop
//     $B1[$i1].aa.y = 2.0 * $B1[$i1].aa.p * $B1[$i1].aa.x;
//   end for;
//   for $i1 in 1:2 loop
//     der($B1[$i1].ab.x) = (-$B1[$i1].ab.p * $B1[$i1].ab.x) + $B1[$i1].ab.u;
//   end for;
//   for $i1 in 1:2 loop
//     $B1[$i1].ab.y = 2.0 * $B1[$i1].ab.p * $B1[$i1].ab.x;
//   end for;
//   $B1.aa.u = $B1.u;
//   $B1.ab.u = $B1.aa.y;
//   $B1.y = $B1.ab.y;
//   a1.u = 1.0;
//   a2.u = a1.y;
//   $B1[1].u = a2.u;
//   b2.u = $B1[1].y;
//   $B1[2].u = b2.y;
// end MergeComponents7;
// endResult
