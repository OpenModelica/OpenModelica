// name: FunctionRecordArg6
// keywords:
// status: correct
//

function f
  input R inR;
  output R outR = inR;
algorithm
  outR.v[end] := 0.0;
end f;

record R
  Real v[:];
end R;

model FunctionRecordArg6
  record R2
    extends R(v = {1,1,1});
  end R2;

  R2 r1;
  R2 r2 = f(r1);
end FunctionRecordArg6;

// Result:
// function FunctionRecordArg6.R2 "Automatically generated record constructor for FunctionRecordArg6.R2"
//   input Real[:] v = {1.0, 1.0, 1.0};
//   output R2 res;
// end FunctionRecordArg6.R2;
//
// function R "Automatically generated record constructor for R"
//   input Real[:] v;
//   output R res;
// end R;
//
// function f
//   input R inR;
//   output R outR = inR;
// algorithm
//   outR.v[size(outR.v, 1)] := 0.0;
// end f;
//
// class FunctionRecordArg6
//   Real r1.v[1];
//   Real r1.v[2];
//   Real r1.v[3];
//   Real r2.v[1];
//   Real r2.v[2];
//   Real r2.v[3];
// equation
//   r1.v = {1.0, 1.0, 1.0};
//   r2 = f(r1);
// end FunctionRecordArg6;
// endResult
