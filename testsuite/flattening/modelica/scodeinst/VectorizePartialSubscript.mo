// name: VectorizePartialSubscript
// keywords:
// status: correct
//
// Typing fills the missing subscripts of c[i] with :, also for the component
// array that the equations are vectorized over.

function f
  input Real t;
  input Real v[3];
  output Real y = t*v[1] + v[2] - v[3];
end f;

model A
  parameter Real c[2, 3];
  Real u[2, 3];
  Real x[2];
equation
  for i in 1:2 loop
    u[i] = c[i] * time;
    x[i] = f(time, c[i]);
  end for;
end A;

model B
  A a[2](each c = {{1, 2, 3}, {4, 5, 6}});
end B;

model VectorizePartialSubscript
  A a[3](each c = {{1, 2, 3}, {4, 5, 6}});
  B b[2];
  annotation(__OpenModelica_commandLineOptions="-d=-nfScalarize");
end VectorizePartialSubscript;

// Result:
// function f
//   input Real t;
//   input Real[3] v;
//   output Real y = t * v[1] + v[2] - v[3];
// end f;
//
// class VectorizePartialSubscript
//   parameter Real[3, 2, 3] a.c = fill({{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}}, 3);
//   Real[3, 2, 3] a.u;
//   Real[3, 2] a.x;
//   parameter Real[2, 2, 2, 3] b.a.c = fill({{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}}, 2, 2);
//   Real[2, 2, 2, 3] b.a.u;
//   Real[2, 2, 2] b.a.x;
// equation
//   for $i0 in 1:3 loop
//     for i in 1:2 loop
//       a[$i0].x[i] = f(time, a[$i0].c[i,:]);
//       a[$i0].u[i,:] = a[$i0].c[i,:] * time;
//     end for;
//   end for;
//   for $i2 in 1:2 loop
//     for $i1 in 1:2 loop
//       for i in 1:2 loop
//         b[$i2].a[$i1].u[i,:] = b[$i2].a[$i1].c[i,:] * time;
//         b[$i2].a[$i1].x[i] = f(time, b[$i2].a[$i1].c[i,:]);
//       end for;
//     end for;
//   end for;
// end VectorizePartialSubscript;
// endResult
