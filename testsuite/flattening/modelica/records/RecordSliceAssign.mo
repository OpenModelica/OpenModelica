// name:     RecordSliceAssign
// keywords: record slice #3245
// status:   correct
// cflags: -d=gen
//
// Checks that assigning to a slice of an array of records works.
//

record R
  Real x;
end R;

function f
  input Integer N;
  output Real y[N];
protected
  R r[N];
algorithm
  for i in 1:N loop
    r[i].x := i;
    y[i] := r[i].x;
  end for;
end f;

model RecordSliceAssign
  Real y[:] = f(4);
end RecordSliceAssign;

// Result:
// function R "Automatically generated record constructor for R"
//   input Real x;
//   output R res;
// end R;
//
// function f
//   input Integer N;
//   output Real[N] y;
//   protected R[N] r;
// algorithm
//   for i in 1:N loop
//     r[i].x := /*Real*/(i);
//     y[i] := r[i].x;
//   end for;
// end f;
//
// class RecordSliceAssign
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
// equation
//   y = {1.0, 2.0, 3.0, 4.0};
// end RecordSliceAssign;
// endResult
