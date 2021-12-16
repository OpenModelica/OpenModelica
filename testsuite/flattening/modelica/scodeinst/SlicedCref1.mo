// name: SlicedCref1
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  Real x;
end R;

function extract
  input R[2] v;
  output Real t[2];
algorithm
  t := v.x;
end extract;

model SlicedCref1
  R[2] c = {R(1.0), R(3.0)};
  Real[2] x;
equation
  x = extract(c);
end SlicedCref1;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// function extract
//   input R[2] v;
//   output Real[2] t;
// algorithm
//   t := array(v[$i1].x for $i1 in 1:2);
// end extract;
//
// class SlicedCref1
//   Real c[1].x = 1.0;
//   Real c[2].x = 3.0;
//   Real x[1];
//   Real x[2];
// equation
//   x = extract(c);
// end SlicedCref1;
// endResult
